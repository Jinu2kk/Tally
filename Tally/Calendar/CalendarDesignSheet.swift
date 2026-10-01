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

/// 세로 슬라이더 (위 = 0, 아래 = 1)
struct VerticalSlider: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    var onEditingEnded: () -> Void = {}

    var body: some View {
        GeometryReader { g in
            let h = g.size.height
            let knob: CGFloat = 28
            let t = (value - range.lowerBound) / (range.upperBound - range.lowerBound)
            ZStack(alignment: .top) {
                Capsule().fill(Ink.empty).frame(width: 6)
                Capsule().fill(Color.accentColor).frame(width: 6, height: max(0, CGFloat(t) * (h - knob) + knob / 2))
                Circle().fill(.white)
                    .frame(width: knob, height: knob)
                    .shadow(color: .black.opacity(0.2), radius: 3, y: 1)
                    .offset(y: CGFloat(t) * (h - knob))
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
            .gesture(DragGesture(minimumDistance: 0)
                .onChanged { v in
                    // 손잡이 가운데가 손가락 위치에 오도록: 손잡이가 움직이는 구간(h - knob) 기준으로 환산
                    let p = min(1, max(0, Double((v.location.y - knob / 2) / max(1, h - knob))))
                    value = range.lowerBound + p * (range.upperBound - range.lowerBound)
                }
                .onEnded { _ in onEditingEnded() })
        }
        .frame(width: 36)
        .accessibilityElement()
        .accessibilityLabel("세로 위치")
        .accessibilityValue("\(Int(value * 100))%")
        .accessibilityAdjustableAction { dir in
            let step = (range.upperBound - range.lowerBound) / 20
            value = min(range.upperBound, max(range.lowerBound, value + (dir == .increment ? step : -step)))
        }
    }
}

/// 잠금화면 미리보기 (실제 배경화면과 같은 뷰를 축소해서 보여 준다, IC-18)
/// 시계·위젯·하단 버튼 자리도 함께 그려서 달력 위치를 맞추기 쉽게 한다
struct LockScreenPreview: View {
    let style: CalendarStyle
    let photo: UIImage?
    var width: CGFloat = 190

    static func height(width: CGFloat) -> CGFloat {
        let s = CalendarWallpaper.screen.size
        return width * s.height / s.width
    }

    var body: some View {
        let screen = CalendarWallpaper.screen.size
        let k = width / screen.width
        let h = screen.height * k
        let fg: Color = style.onImage ? .white.opacity(0.9) : Ink.ink.opacity(0.75)
        ZStack(alignment: .top) {
            if let snapshot = CalendarWallpaper.snapshot(style: style) {
                CalendarWallpaperView(size: screen, style: style, photo: photo, snapshot: snapshot)
                    .scaleEffect(k, anchor: .topLeading)
                    .frame(width: width, height: h, alignment: .topLeading)
            }
            // 잠금화면 요소 자리 (날짜 · 시계 · 위젯 줄 · 하단 버튼)
            VStack(spacing: 0) {
                Text(Date.now.formatted(.dateTime.locale(.app).month().day().weekday()))
                    .font(.system(size: h * 0.022, weight: .semibold))
                    .padding(.top, h * 0.085)
                Text(Date.now.formatted(.dateTime.hour(.twoDigits(amPM: .omitted)).minute()))
                    .font(.system(size: h * 0.12, weight: .light, design: .rounded))
                    .padding(.top, -h * 0.01)
                widgetRow(h: h, fg: fg)
                    .padding(.top, h * 0.005)
                Spacer()
                HStack {
                    bottomButton("flashlight.off.fill", h: h)
                    Spacer()
                    bottomButton("camera.fill", h: h)
                }
                .padding(.horizontal, width * 0.11)
                .padding(.bottom, h * 0.06)
            }
            .foregroundStyle(fg)
            .frame(width: width, height: h)
            .allowsHitTesting(false)
        }
        .frame(width: width, height: h)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(RoundedRectangle(cornerRadius: 24).strokeBorder(Ink.ink, lineWidth: 4))
        .accessibilityLabel("잠금 화면 미리보기")
    }

    private func widgetRow(h: CGFloat, fg: Color) -> some View {
        let d = h * 0.05
        return HStack(spacing: d * 0.35) {
            ForEach(["cloud.sun.fill", "sun.max.fill", "cloud.sun.fill", "cloud.fill"], id: \.self) { icon in
                Image(systemName: icon)
                    .font(.system(size: d * 0.45))
                    .frame(width: d, height: d)
                    .background(Circle().fill(fg.opacity(0.18)))
            }
            RoundedRectangle(cornerRadius: d * 0.3)
                .fill(fg.opacity(0.18))
                .frame(width: d * 2.4, height: d)
                .overlay(Image(systemName: "calendar").font(.system(size: d * 0.45)))
        }
    }

    private func bottomButton(_ icon: String, h: CGFloat) -> some View {
        let d = h * 0.06
        return Image(systemName: icon)
            .font(.system(size: d * 0.4))
            .frame(width: d, height: d)
            .background(Circle().fill(.black.opacity(0.25)))
    }
}

/// 배경화면 배치 편집: 미리보기(가운데) + 세로 위치(오른쪽) + 크기 + 월간/주간.
/// 디자인 시트와 배경화면 공유 시트가 같은 설정값을 함께 쓴다
struct WallpaperLayoutEditor: View {
    let style: CalendarStyle
    let photo: UIImage?
    @AppStorage(SettingsKey.wallpaperScale, store: AppSettings.store) private var scale = 0.95
    @AppStorage(SettingsKey.wallpaperWeekly, store: AppSettings.store) private var weekly = false
    @AppStorage(SettingsKey.wallpaperOffset, store: AppSettings.store) private var offset = -1.0

    private let previewWidth: CGFloat = 190

    var body: some View {
        let ph = LockScreenPreview.height(width: previewWidth)
        let range = CalendarStyle.offsetRange
        let knob: CGFloat = 28
        VStack(spacing: 14) {
            Text("잠금 화면 미리보기").font(.caption.weight(.semibold)).foregroundStyle(Ink.faint)
            LockScreenPreview(style: style, photo: style.background == .photo ? photo : nil, width: previewWidth)
                .frame(maxWidth: .infinity)
                .overlay(alignment: .topTrailing) {
                    // 손잡이 가운데가 미리보기 속 달력 윗변과 같은 높이에 오도록 맞춘다
                    VStack(spacing: 6) {
                        VerticalSlider(value: Binding(
                            get: { style.wallpaperTop(weeks: weekly ? 1 : 5) },
                            set: { offset = $0 }
                        ), range: range)
                        .frame(height: ph * CGFloat(range.upperBound - range.lowerBound) + knob)
                        Button(offset >= 0 ? "자동" : "자동 ✓") { offset = -1 }
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(offset >= 0 ? Color.accentColor : Ink.faint)
                            .accessibilityLabel("세로 위치 자동")
                    }
                    .padding(.top, ph * CGFloat(range.lowerBound) - knob / 2)
                    .padding(.trailing, 8)
                }
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Label("크기 조절", systemImage: "arrow.up.left.and.arrow.down.right")
                    Spacer()
                    Text("\(Int(scale * 100))%").monospacedDigit()
                }
                .font(.subheadline).foregroundStyle(Ink.faint)
                Slider(value: $scale, in: 0.6...1, step: 0.01).accessibilityLabel("크기 조절")
            }
            Picker("형태", selection: $weekly) {
                Text("월간").tag(false)
                Text("주간").tag(true)
            }
            .pickerStyle(.segmented)
        }
    }
}

/// 디자인 시트 (FR-7.11, 7.12, 7.13)
struct CalendarDesignSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(CalendarStore.self) private var store
    @AppStorage(SettingsKey.calendarBackground, store: AppSettings.store) private var bgKind = CalendarBackgroundKind.none.rawValue
    @AppStorage(SettingsKey.backgroundColor, store: AppSettings.store) private var bgHex = "1E3A3A"
    @AppStorage(SettingsKey.backgroundPattern, store: AppSettings.store) private var pattern = 0
    @AppStorage(SettingsKey.backgroundOpacity, store: AppSettings.store) private var opacity = 0.7
    @AppStorage(SettingsKey.backgroundBlur, store: AppSettings.store) private var blur = 0.0
    @AppStorage(SettingsKey.todayColor, store: AppSettings.store) private var todayHex = ""
    @AppStorage(SettingsKey.hideAdjacentDays, store: AppSettings.store) private var hideAdjacent = false
    @AppStorage(SettingsKey.wallpaperScale, store: AppSettings.store) private var scale = 0.95
    @AppStorage(SettingsKey.wallpaperWeekly, store: AppSettings.store) private var weekly = false
    @AppStorage(SettingsKey.wallpaperOffset, store: AppSettings.store) private var offset = -1.0
    // 강조 값이 바뀌면 미리보기도 다시 그리도록 구독
    @AppStorage(SettingsKey.emphasizeHoliday, store: AppSettings.store) private var emH = true
    @AppStorage(SettingsKey.emphasizeSaturday, store: AppSettings.store) private var emSa = false
    @AppStorage(SettingsKey.emphasizeSunday, store: AppSettings.store) private var emSu = true

    @State private var pick: PhotosPickerItem?
    @State private var photo: UIImage? = CalendarBackgroundStore.load()
    @State private var confirmReset = false
    @State private var error: String?

    private var kind: CalendarBackgroundKind { CalendarBackgroundKind(rawValue: bgKind) ?? .none }

    var body: some View {
        let style = CalendarStyle.current
        let _ = (bgKind, bgHex, pattern, opacity, blur, todayHex, hideAdjacent, scale, weekly, offset, emH, emSa, emSu, store.revision)
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    WallpaperLayoutEditor(style: style, photo: photo)
                    EmphasisChips().inkCard(padding: 16)
                    Text("앱에서와 동일하게 표시됩니다").font(.caption).foregroundStyle(Ink.faint).frame(maxWidth: .infinity)
                    backgroundTiles
                    if let error { Text(error).font(.footnote).foregroundStyle(.red) }
                    backgroundControls
                    todaySection
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
                Button("재설정", role: .destructive) {
                    CalendarStyle.resetStored(); photo = nil
                    bgKind = CalendarBackgroundKind.none.rawValue; offset = -1; scale = 0.95; weekly = false
                }
            }
            .onChange(of: pick) { _, item in Task { await load(item) } }
        }
        .presentationDetents([.large])
    }

    // MARK: 배경 타일 (FR-7.11)

    private var backgroundTiles: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(String(localized: "배경화면"))
            ScrollView(.horizontal) {
                HStack(spacing: 12) {
                    Button { bgKind = CalendarBackgroundKind.none.rawValue } label: {
                        tile(selected: kind == .none, label: "종이") { Ink.paper }
                    }
                    .buttonStyle(.plain).accessibilityLabel("종이 배경")

                    // 단색: 타일을 누르면 선택, 안의 색 버튼으로 색 변경
                    Button { bgKind = CalendarBackgroundKind.color.rawValue } label: {
                        tile(selected: kind == .color, label: "단색") { Color(hex: bgHex) }
                    }
                    .buttonStyle(.plain).accessibilityLabel("단색 배경")
                    .overlay(alignment: .bottom) {
                        ColorPicker("단색 색상", selection: Binding(
                            get: { Color(hex: bgHex) },
                            set: { bgHex = $0.hexString; bgKind = CalendarBackgroundKind.color.rawValue }
                        ), supportsOpacity: false)
                        .labelsHidden()
                        .padding(.bottom, 32)
                    }

                    photoTile

                    Button { shuffle() } label: {
                        tile(selected: kind == .pattern, label: "셔플") {
                            ZStack {
                                CalendarPattern.view(pattern)
                                Image(systemName: "square.3.layers.3d").font(.title2).foregroundStyle(.white.opacity(0.9))
                            }
                        }
                    }
                    .buttonStyle(.plain).accessibilityLabel("셔플")
                }
                .padding(.vertical, 6).padding(.horizontal, 2)
            }
            .scrollIndicators(.hidden)
        }
    }

    /// 사진: 고른 사진이 있으면 누를 때 그 사진을 선택. 바꾸려면 X로 지운 뒤 다시 고른다
    @ViewBuilder private var photoTile: some View {
        if let photo {
            Button { bgKind = CalendarBackgroundKind.photo.rawValue } label: {
                tile(selected: kind == .photo, label: "사진") { Image(uiImage: photo).resizable().scaledToFill() }
            }
            .buttonStyle(.plain).accessibilityLabel("사진 배경")
            .overlay(alignment: .topTrailing) {
                Button {
                    CalendarBackgroundStore.removePhoto()
                    self.photo = nil
                    if kind == .photo { bgKind = CalendarBackgroundKind.none.rawValue }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.white, .black.opacity(0.6))
                }
                .offset(x: 8, y: -8)
                .accessibilityLabel("사진 지우기")
            }
        } else {
            PhotosPicker(selection: $pick, matching: .images) {
                tile(selected: false, label: "사진") {
                    ZStack { Ink.empty; Image(systemName: "photo.badge.plus").font(.title2).foregroundStyle(Ink.faint) }
                }
            }
            .accessibilityLabel("사진 고르기")
        }
    }

    private var backgroundControls: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("배경").font(.headline)
            Group {
                slider("불투명도", value: $opacity, range: 0...1, text: "\(Int(opacity * 100))%")
                slider("블러", value: $blur, range: 0...20, text: "\(Int(blur))")
            }
            .disabled(kind == .none)
            .opacity(kind == .none ? 0.4 : 1)
        }
        .inkCard(padding: 16)
    }

    private var todaySection: some View {
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
        .contentShape(Rectangle())
    }

    private func slider(_ title: String, value: Binding<Double>, range: ClosedRange<Double>, text: String) -> some View {
        VStack(spacing: 4) {
            HStack { Text(title).foregroundStyle(Ink.faint); Spacer(); Text(text).monospacedDigit().foregroundStyle(Ink.faint) }
                .font(.subheadline)
            Slider(value: value, in: range).accessibilityLabel(title)
        }
    }

    private func shuffle() {
        pattern = kind == .pattern ? (pattern + 1) % CalendarPattern.count : pattern
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
        pick = nil
    }
}
