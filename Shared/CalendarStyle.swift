import CoreImage
import CoreImage.CIFilterBuiltins
import SwiftUI
import UIKit

/// 달력 배경 종류 (FR-7.11)
enum CalendarBackgroundKind: String, CaseIterable, Identifiable {
    case none, color, photo, pattern
    var id: String { rawValue }
}

/// 달력 표시 설정 묶음. 앱 화면·배경화면·단축어가 같은 값을 쓴다 (IC-18)
struct CalendarStyle: Equatable {
    var emphasizeHoliday = true
    var emphasizeSaturday = false
    var emphasizeSunday = true
    var hideAdjacentDays = false
    var todayHex = ""
    var tintHex = ThemeTint.tomato.hex
    var background = CalendarBackgroundKind.none
    var backgroundHex = "1E3A3A"
    var pattern = 0
    var opacity = 0.7
    var blur = 0.0
    var wallpaperScale = 0.95
    var wallpaperWeekly = false
    /// 배경화면에서 달력 윗변 위치(화면 높이 비율). 음수면 자동(시계 아래)
    var wallpaperOffset = -1.0

    static let offsetRange = 0.08...0.75
    func wallpaperTop(weeks: Int) -> Double {
        wallpaperOffset >= 0 ? wallpaperOffset : (weeks == 1 ? 0.62 : 0.345)
    }

    /// 배경이 사진·패턴·단색이면 글자를 밝게 (배경 위 가독성)
    var onImage: Bool { background != .none }
    var todayColor: Color { Color(hex: todayHex.isEmpty ? tintHex : todayHex) }

    static var current: CalendarStyle {
        let d = AppSettings.store
        var s = CalendarStyle()
        if d.object(forKey: SettingsKey.emphasizeHoliday) != nil { s.emphasizeHoliday = d.bool(forKey: SettingsKey.emphasizeHoliday) }
        s.emphasizeSaturday = d.bool(forKey: SettingsKey.emphasizeSaturday)
        if d.object(forKey: SettingsKey.emphasizeSunday) != nil { s.emphasizeSunday = d.bool(forKey: SettingsKey.emphasizeSunday) }
        s.hideAdjacentDays = d.bool(forKey: SettingsKey.hideAdjacentDays)
        s.todayHex = d.string(forKey: SettingsKey.todayColor) ?? ""
        s.tintHex = AppSettings.tint.hex
        s.background = CalendarBackgroundKind(rawValue: d.string(forKey: SettingsKey.calendarBackground) ?? "") ?? .none
        s.backgroundHex = d.string(forKey: SettingsKey.backgroundColor) ?? s.backgroundHex
        s.pattern = d.integer(forKey: SettingsKey.backgroundPattern)
        if d.object(forKey: SettingsKey.backgroundOpacity) != nil { s.opacity = d.double(forKey: SettingsKey.backgroundOpacity) }
        s.blur = d.double(forKey: SettingsKey.backgroundBlur)
        if d.object(forKey: SettingsKey.wallpaperScale) != nil { s.wallpaperScale = d.double(forKey: SettingsKey.wallpaperScale) }
        s.wallpaperWeekly = d.bool(forKey: SettingsKey.wallpaperWeekly)
        if d.object(forKey: SettingsKey.wallpaperOffset) != nil { s.wallpaperOffset = d.double(forKey: SettingsKey.wallpaperOffset) }
        return s
    }

    /// 디자인 시트의 '기본값으로 재설정'
    static func resetStored() {
        [SettingsKey.emphasizeHoliday, SettingsKey.emphasizeSaturday, SettingsKey.emphasizeSunday, SettingsKey.hideAdjacentDays,
         SettingsKey.todayColor, SettingsKey.calendarBackground, SettingsKey.backgroundColor, SettingsKey.backgroundPattern,
         SettingsKey.backgroundOpacity, SettingsKey.backgroundBlur, SettingsKey.wallpaperScale, SettingsKey.wallpaperWeekly,
         SettingsKey.wallpaperOffset]
            .forEach { AppSettings.store.removeObject(forKey: $0) }
        CalendarBackgroundStore.removePhoto()
    }
}

/// 배경 사진 저장 (IC-17)
enum CalendarBackgroundStore {
    static var photoURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: SharedStore.appGroupID)?
            .appending(path: "calendar-background.jpg")
            ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
            .appending(path: "calendar-background.jpg")
    }

    static func save(_ image: UIImage) throws {
        guard let url = photoURL else { throw CocoaError(.fileNoSuchFile) }
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        let resized = image.resized(maxSide: 2400)
        guard let data = resized.jpegData(compressionQuality: 0.88) else { throw CocoaError(.fileWriteUnknown) }
        try data.write(to: url, options: .atomic)
        cached = nil
    }

    static func removePhoto() {
        if let url = photoURL { try? FileManager.default.removeItem(at: url) }
        cached = nil
    }

    private static var cached: (Date, UIImage)?

    private static var blurCache: (key: String, image: UIImage)?
    private static let ciContext = CIContext()

    /// 블러를 이미지 자체에 입힌다. SwiftUI .blur는 사진 가장자리를 투명·검게 만들고
    /// 배경화면 렌더(ImageRenderer)에서도 결과가 달라서 CoreImage로 처리한다
    static func blurred(_ image: UIImage, radius: Double) -> UIImage {
        guard radius > 0.5 else { return image }
        let key = "\(ObjectIdentifier(image).hashValue)-\(image.size.width)x\(image.size.height)-\(Int(radius.rounded()))"
        if let c = blurCache, c.key == key { return c.image }
        let small = image.resized(maxSide: 1200)
        guard let input = CIImage(image: small) else { return image }
        let f = CIFilter.gaussianBlur()
        f.inputImage = input.clampedToExtent()
        // 슬라이더 값(0~20)은 화면 포인트 기준 → 이미지 픽셀 기준으로 환산
        f.radius = Float(radius * small.size.width / 393)
        guard let out = f.outputImage?.cropped(to: input.extent),
              let cg = ciContext.createCGImage(out, from: input.extent) else { return image }
        let result = UIImage(cgImage: cg)
        blurCache = (key, result)
        return result
    }

    static func load() -> UIImage? {
        guard let url = photoURL,
              let date = (try? FileManager.default.attributesOfItem(atPath: url.path()))?[.modificationDate] as? Date
        else { return nil }
        if let c = cached, c.0 == date { return c.1 }
        guard let img = UIImage(contentsOfFile: url.path()) else { return nil }
        cached = (date, img)
        return img
    }
}

extension UIImage {
    func resized(maxSide: CGFloat) -> UIImage {
        let longest = max(size.width, size.height)
        guard longest > maxSide else { return self }
        let s = maxSide / longest
        let target = CGSize(width: size.width * s, height: size.height * s)
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        return UIGraphicsImageRenderer(size: target, format: format).image { _ in draw(in: CGRect(origin: .zero, size: target)) }
    }
}

/// 셔플용 내장 패턴. 외부 이미지 없이 그린다 (IC-17)
enum CalendarPattern {
    static let count = 6

    @ViewBuilder
    static func view(_ i: Int) -> some View {
        switch ((i % count) + count) % count {
        case 0: LinearGradient(colors: [Color(hex: "0F2A2E"), Color(hex: "1D4A4A"), Color(hex: "0B1F24")], startPoint: .top, endPoint: .bottom)
        case 1: LinearGradient(colors: [Color(hex: "2B1E3F"), Color(hex: "B0546B"), Color(hex: "F2A65A")], startPoint: .top, endPoint: .bottom)
        case 2: ZStack {
                Color(hex: "1C1B1A")
                RadialGradient(colors: [Color(hex: "E4572E").opacity(0.55), .clear], center: .bottomTrailing, startRadius: 10, endRadius: 600)
            }
        case 3: LinearGradient(colors: [Color(hex: "16324F"), Color(hex: "2E5EAA"), Color(hex: "9EC1E8")], startPoint: .topLeading, endPoint: .bottomTrailing)
        case 4: ZStack {
                Color(hex: "2F3A2A")
                RadialGradient(colors: [Color(hex: "8DB36B").opacity(0.5), .clear], center: .top, startRadius: 0, endRadius: 700)
            }
        default: LinearGradient(colors: [Color(hex: "3A2E25"), Color(hex: "7A5C43"), Color(hex: "C9A27E")], startPoint: .bottom, endPoint: .top)
        }
    }
}

/// 달력 뒤 배경 (FR-7.11). photo는 미리 불러온 이미지를 넘긴다
struct CalendarBackgroundView: View {
    let style: CalendarStyle
    let photo: UIImage?

    var body: some View {
        GeometryReader { g in
            ZStack {
                Ink.paper
                switch style.background {
                case .none:
                    EmptyView()
                case .color:
                    Color(hex: style.backgroundHex)
                case .pattern:
                    CalendarPattern.view(style.pattern)
                        .blur(radius: style.blur)
                        .scaleEffect(1 + style.blur / 40) // 블러로 생기는 가장자리 번짐을 화면 밖으로
                case .photo:
                    if let photo {
                        Image(uiImage: CalendarBackgroundStore.blurred(photo, radius: style.blur))
                            .resizable().scaledToFill()
                            .frame(width: g.size.width, height: g.size.height)
                    } else {
                        CalendarPattern.view(0)
                    }
                }
                if style.onImage {
                    // 불투명도 = 배경이 얼마나 진하게 보이는지. 낮을수록 어두운 막을 덮는다
                    Color.black.opacity((1 - style.opacity) * 0.85)
                }
            }
            .frame(width: g.size.width, height: g.size.height)
            .clipped()
        }
    }
}
