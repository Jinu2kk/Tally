import SwiftUI
import AppIntents

/// 배경화면 종류 (FR-2.5, 2.6)
enum WallpaperKind: String, CaseIterable, Identifiable, AppEnum {
    case year, life

    var id: String { rawValue }

    var title: String {
        switch self {
        case .year: String(localized: "올해")
        case .life: String(localized: "인생")
        }
    }

    static var typeDisplayRepresentation: TypeDisplayRepresentation { "배경화면 종류" }
    static var caseDisplayRepresentations: [WallpaperKind: DisplayRepresentation] {
        [.year: "올해 진행률", .life: "라이프 캘린더"]
    }
}

/// 잠금화면 시계 영역을 비워 둔 세로 배경화면
struct WallpaperView: View {
    let kind: WallpaperKind
    let size: CGSize
    let tint: Color
    let now: Date
    let birth: Date?
    let expectancy: Int
    let calendar: Calendar

    var body: some View {
        ZStack {
            Ink.paper
            VStack(spacing: size.width * 0.05) {
                Spacer().frame(height: size.height * 0.36)
                grid.frame(width: size.width * 0.78)
                caption
                Spacer()
            }
        }
        .frame(width: size.width, height: size.height)
    }

    @ViewBuilder private var grid: some View {
        switch kind {
        case .year:
            let y = YearProgress(now: now, calendar: calendar)
            DotCanvas(count: y.daysInYear, columns: 19, tint: tint) { i in
                i < y.dayOfYear - 1 ? .filled : (i == y.dayOfYear - 1 ? .today : .empty)
            }
        case .life:
            if let birth {
                let l = LifeProgress(birth: birth, expectancy: expectancy, now: now, calendar: calendar)
                DotCanvas(count: l.totalWeeks, columns: 52, spacingRatio: 0.45, tint: tint) { i in
                    i < l.livedWeeks ? .filled : (i == l.livedWeeks ? .today : .empty)
                }
            } else {
                Text("설정에서 생년월일을 입력하세요").foregroundStyle(Ink.faint)
            }
        }
    }

    @ViewBuilder private var caption: some View {
        let font = Font.system(size: size.width * 0.034, weight: .semibold, design: .monospaced)
        Group {
            switch kind {
            case .year:
                let y = YearProgress(now: now, calendar: calendar)
                Text("\(String(y.year)) · \(y.percent)% · 남은 \(y.daysLeft)일")
            case .life:
                if let birth {
                    let l = LifeProgress(birth: birth, expectancy: expectancy, now: now, calendar: calendar)
                    Text("MEMENTO MORI · 남은 \(l.weeksLeft)주")
                }
            }
        }
        .font(font)
        .tracking(2)
        .foregroundStyle(Ink.ink)
    }
}

extension UIImage {
    /// 공유용 임시 PNG 파일. Image를 직접 공유하면 iOS 17.0에서 CoreTransferable 예외가 나서 파일 URL로 공유한다
    func temporaryPNG(named name: String) -> URL? {
        let url = FileManager.default.temporaryDirectory.appending(path: "\(name).png")
        guard let data = pngData(), (try? data.write(to: url, options: .atomic)) != nil else { return nil }
        return url
    }
}

enum Wallpaper {
    /// 기본 크기: 6.1인치 iPhone (393×852pt @3x)
    static let defaultSize = CGSize(width: 393, height: 852)

    @MainActor
    static func render(kind: WallpaperKind, size: CGSize = defaultSize, scale: CGFloat = 3, dark: Bool = false, now: Date = .now) -> UIImage? {
        let view = WallpaperView(kind: kind, size: size, tint: AppSettings.tint.color, now: now,
                                 birth: AppSettings.birthDate, expectancy: AppSettings.lifeExpectancy,
                                 calendar: AppSettings.calendar)
            .environment(\.colorScheme, dark ? .dark : .light)
        let renderer = ImageRenderer(content: view)
        renderer.scale = scale
        return renderer.uiImage
    }
}
