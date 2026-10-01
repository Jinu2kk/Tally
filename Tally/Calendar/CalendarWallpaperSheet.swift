import SwiftUI
import UIKit

/// 배경화면 만들기 시트 (FR-7.13, 7.15)
struct CalendarWallpaperSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @AppStorage(SettingsKey.wallpaperScale, store: AppSettings.store) private var scale = 0.95
    @AppStorage(SettingsKey.wallpaperWeekly, store: AppSettings.store) private var weekly = false
    @AppStorage(SettingsKey.emphasizeHoliday, store: AppSettings.store) private var h = true
    @AppStorage(SettingsKey.emphasizeSaturday, store: AppSettings.store) private var sa = false
    @AppStorage(SettingsKey.emphasizeSunday, store: AppSettings.store) private var su = true

    @State private var image: UIImage?
    @State private var fileURL: URL?
    @State private var error: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    Text("잠금 화면 미리보기").labelStyle()
                    preview
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Label("크기 조절", systemImage: "arrow.up.left.and.arrow.down.right")
                            Spacer()
                            Text("\(Int(scale * 100))%").monospacedDigit()
                        }
                        .font(.subheadline).foregroundStyle(Ink.faint)
                        Slider(value: $scale, in: 0.7...1, step: 0.01).accessibilityLabel("크기 조절")
                    }
                    Picker("형태", selection: $weekly) {
                        Text("월간").tag(false)
                        Text("주간").tag(true)
                    }
                    .pickerStyle(.segmented)
                    EmphasisChips().inkCard(padding: 14)
                    Text("앱에서와 동일하게 표시됩니다").font(.caption).foregroundStyle(Ink.faint)

                    if let fileURL, image != nil {
                        Button { ShareSheet.present([fileURL]) } label: {
                            Label("이미지 저장 · 공유", systemImage: "square.and.arrow.down")
                                .font(.headline)
                                .frame(maxWidth: .infinity).padding(.vertical, 14)
                                .background(RoundedRectangle(cornerRadius: 14).fill(Ink.ink))
                                .foregroundStyle(Ink.paper)
                        }
                    }
                    automationGuide
                }
                .padding(Metrics.gutter)
            }
            .background(Ink.paper)
            .navigationTitle("배경화면")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("완료") { dismiss() } } }
            .task(id: "\(scale)-\(weekly)-\(h)-\(sa)-\(su)") { render() }
        }
    }

    private var preview: some View {
        let size = CalendarWallpaper.screen.size
        return Group {
            if let image {
                Image(uiImage: image).resizable().scaledToFit()
            } else if let error {
                Text(error).font(.footnote).foregroundStyle(.red).padding()
            } else {
                ProgressView()
            }
        }
        .frame(width: 200, height: 200 * size.height / size.width)
        .clipShape(RoundedRectangle(cornerRadius: 26))
        .overlay(RoundedRectangle(cornerRadius: 26).strokeBorder(Ink.ink, lineWidth: 5))
        .accessibilityLabel("배경화면 미리보기")
    }

    /// FR-7.15 자동화 안내
    private var automationGuide: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("매일 자동으로 바꾸기").font(.headline)
            VStack(alignment: .leading, spacing: 6) {
                step(1, "단축어 앱 → 자동화 → 새로운 자동화")
                step(2, "‘특정 시간’(예: 00:01, 매일) 또는 ‘앱’ → Tally → ‘닫힘’을 고르고 ‘즉시 실행’")
                step(3, "동작 추가: ‘Tally 달력 배경화면 만들기’")
                step(4, "동작 추가: ‘배경화면 설정’ → 잠금 화면, 미리보기 끄기")
            }
            .font(.subheadline)
            Button { if let url = URL(string: "shortcuts://") { openURL(url) } } label: {
                Label("단축어 앱 열기", systemImage: "arrow.up.forward.app")
            }
            .font(.subheadline.weight(.semibold))
        }
        .inkCard(padding: 16)
    }

    private func step(_ n: Int, _ text: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text("\(n)").font(.label).frame(width: 18, height: 18).background(Circle().fill(Ink.empty))
            Text(text).foregroundStyle(Ink.ink)
        }
    }

    @MainActor private func render() {
        do {
            let img = try CalendarWallpaper.render()
            image = img
            fileURL = img.temporaryPNG(named: "Tally 달력 배경화면")
            error = nil
        } catch {
            image = nil
            self.error = String(localized: "\(error.localizedDescription)")
        }
    }
}
