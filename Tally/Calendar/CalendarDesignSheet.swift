import PhotosUI
import SwiftUI
import UIKit

extension Color {
    var hexString: String {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(self).getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(format: "%02X%02X%02X", Int(max(0, min(1, r)) * 255), Int(max(0, min(1, g)) * 255), Int(max(0, min(1, b)) * 255))
    }
}

/// 강조 칩: 공휴일 · 토 · 일 (FR-7.7)
struct EmphasisChips: View {
    @AppStorage(SettingsKey.emphasizeHoliday, store: AppSettings.store) private var holiday = true
    @AppStorage(SettingsKey.emphasizeSaturday, store: AppSettings.store) private var sat = false
    @AppStorage(SettingsKey.emphasizeSunday, store: AppSettings.store) private var sun = true

    var body: some View {
        HStack {
            Text("강조").font(.headline)
            Spacer()
            chip("공휴일", $holiday)
            chip("토", $sat)
            chip("일", $sun)
        }
    }

    private func chip(_ title: String, _ on: Binding<Bool>) -> some View {
        Button { on.wrappedValue.toggle() } label: {
            Text(title).font(.subheadline.weight(.bold))
                .padding(.horizontal, 14).padding(.vertical, 8)
                .foregroundStyle(on.wrappedValue ? Ink.paper : Ink.ink)
                .background(Capsule().fill(on.wrappedValue ? Ink.ink : .clear))
                .overlay(Capsule().strokeBorder(Ink.ink, lineWidth: Metrics.border))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title) 강조")
        .accessibilityValue(on.wrappedValue ? "켜짐" : "꺼짐")
    }
}

/// 디자인 시트 (FR-7.11, 7.12)
struct CalendarDesignSheet: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage(SettingsKey.calendarBackground, store: AppSettings.store) private var bgKind = CalendarBackgroundKind.none.rawValue
    @AppStorage(SettingsKey.backgroundColor, store: AppSettings.store) private var bgHex = "1E3A3A"
    @AppStorage(SettingsKey.backgroundPattern, store: AppSettings.store) private var pattern = 0
    @AppStorage(SettingsKey.backgroundOpacity, store: AppSettings.store) private var opacity = 0.7
    @AppStorage(SettingsKey.backgroundBlur, store: AppSettings.store) private var blur = 0.0
    @AppStorage(SettingsKey.todayColor, store: AppSettings.store) private var todayHex = ""
    @AppStorage(SettingsKey.hideAdjacentDays, store: AppSettings.store) private var hideAdjacent = false

    @State private var pick: PhotosPickerItem?
    @State private var photo: UIImage? = CalendarBackgroundStore.load()
    @State private var confirmReset = false
    @State private var error: String?

    private var kind: CalendarBackgroundKind { CalendarBackgroundKind(rawValue: bgKind) ?? .none }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    EmphasisChips().inkCard(padding: 16)

                    SectionHeader(String(localized: "배경"))
                    ScrollView(.horizontal) {
                        HStack(spacing: 12) {
                            tile(selected: kind == .none, label: "종이") { Ink.paper }
                                .onTapGesture { bgKind = CalendarBackgroundKind.none.rawValue }
                                .accessibilityAddTraits(.isButton).accessibilityLabel("배경 없음")
                            ZStack {
                                tile(selected: kind == .color, label: "단색") { Color(hex: bgHex) }
                                ColorPicker("단색 배경", selection: Binding(
                                    get: { Color(hex: bgHex) },
                                    set: { bgHex = $0.hexString; bgKind = CalendarBackgroundKind.color.rawValue }
                                ), supportsOpacity: false)
                                .labelsHidden().opacity(0.02).frame(width: 84, height: 150)
                            }
                            PhotosPicker(selection: $pick, matching: .images) {
                                tile(selected: kind == .photo, label: "사진") {
                                    if let photo { Image(uiImage: photo).resizable().scaledToFill() } else {
                                        ZStack { Ink.empty; Image(systemName: "photo.badge.plus").font(.title2).foregroundStyle(Ink.faint) }
                                    }
                                }
                            }
                            .accessibilityLabel("사진 배경 선택")
                            tile(selected: kind == .pattern, label: "셔플") { CalendarPattern.view(pattern) }
                                .onTapGesture { shuffle() }
                                .accessibilityAddTraits(.isButton).accessibilityLabel("셔플")
                        }
                        .padding(.vertical, 4).padding(.trailing, 4)
                    }
                    .scrollIndicators(.hidden)
                    if let error { Text(error).font(.footnote).foregroundStyle(.red) }

                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Text("배경").font(.headline)
                            Spacer()
                            Button { shuffle() } label: { Label("셔플", systemImage: "square.3.layers.3d") }
                                .buttonStyle(.bordered).tint(Ink.ink)
                            Button(role: .destructive) {
                                CalendarBackgroundStore.removePhoto(); photo = nil
                                bgKind = CalendarBackgroundKind.none.rawValue
                            } label: { Label("제거", systemImage: "trash") }
                                .buttonStyle(.bordered)
                                .disabled(kind == .none)
                        }
                        Group {
                            slider("불투명도", value: $opacity, range: 0...1, text: "\(Int(opacity * 100))%")
                            slider("블러", value: $blur, range: 0...20, text: "\(Int(blur))")
                        }
                        .disabled(kind == .none)
                        .opacity(kind == .none ? 0.4 : 1)
                    }
                    .inkCard(padding: 16)

                    VStack(spacing: 14) {
                        HStack {
                            Text("오늘 컬러").font(.headline)
                            Spacer()
                            ForEach([""] + ThemeTint.allCases.map(\.hex), id: \.self) { h in
                                Button { todayHex = h } label: {
                                    Circle().fill(h.isEmpty ? AnyShapeStyle(LinearGradient(colors: ThemeTint.allCases.map(\.color), startPoint: .top, endPoint: .bottom)) : AnyShapeStyle(Color(hex: h)))
                                        .frame(width: 22, height: 22)
                                        .overlay(Circle().strokeBorder(Ink.ink, lineWidth: todayHex == h ? 2 : 0).padding(-3))
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel(h.isEmpty ? "테마 색" : h)
                            }
                        }
                        Toggle("이전/다음 달 미리보기 숨기기", isOn: $hideAdjacent).font(.headline)
                    }
                    .inkCard(padding: 16)

                    Button("기본값으로 재설정") { confirmReset = true }
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .foregroundStyle(Ink.faint)
                }
                .padding(Metrics.gutter)
            }
            .background(Ink.paper)
            .navigationTitle("디자인")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("완료") { dismiss() } } }
            .confirmationDialog("달력 디자인을 기본값으로 되돌릴까요? 배경 사진도 지워져요.", isPresented: $confirmReset, titleVisibility: .visible) {
                Button("재설정", role: .destructive) { CalendarStyle.resetStored(); photo = nil; bgKind = CalendarBackgroundKind.none.rawValue }
            }
            .onChange(of: pick) { _, item in Task { await load(item) } }
        }
        .presentationDetents([.large])
    }

    private func tile<C: View>(selected: Bool, label: String, @ViewBuilder _ content: () -> C) -> some View {
        VStack(spacing: 6) {
            content()
                .frame(width: 84, height: 150)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(selected ? Color.accentColor : Ink.ink.opacity(0.3), style: StrokeStyle(lineWidth: selected ? 3 : 1, dash: selected ? [] : [5, 4])))
            Text(label).font(.caption.weight(.semibold)).foregroundStyle(selected ? Color.accentColor : Ink.faint)
        }
    }

    private func slider(_ title: String, value: Binding<Double>, range: ClosedRange<Double>, text: String) -> some View {
        VStack(spacing: 4) {
            HStack { Text(title).foregroundStyle(Ink.faint); Spacer(); Text(text).monospacedDigit().foregroundStyle(Ink.faint) }
                .font(.subheadline)
            Slider(value: value, in: range).accessibilityLabel(title)
        }
    }

    private func shuffle() {
        pattern = (pattern + 1) % CalendarPattern.count
        bgKind = CalendarBackgroundKind.pattern.rawValue
    }

    @MainActor
    private func load(_ item: PhotosPickerItem?) async {
        guard let item else { return }
        do {
            guard let data = try await item.loadTransferable(type: Data.self), let img = UIImage(data: data) else { return }
            try CalendarBackgroundStore.save(img)
            photo = CalendarBackgroundStore.load()
            bgKind = CalendarBackgroundKind.photo.rawValue
            error = nil
        } catch {
            self.error = String(localized: "사진을 불러오지 못했어요.")
        }
    }
}
