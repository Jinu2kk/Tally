import AppIntents
import UIKit

/// 단축어: 배경화면 PNG 반환 (FR-2.6, IC-8)
struct MakeWallpaperIntent: AppIntent {
    static var title: LocalizedStringResource = "Tally 배경화면 만들기"
    static var description = IntentDescription("올해 진행률 또는 라이프 캘린더를 오늘 날짜 기준 배경화면 이미지로 만듭니다.")

    @Parameter(title: "종류", default: .year)
    var kind: WallpaperKind

    @Parameter(title: "어두운 배경", default: false)
    var dark: Bool

    static var parameterSummary: some ParameterSummary {
        Summary("\(\.$kind) 배경화면 만들기") { \.$dark }
    }

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<IntentFile> {
        guard let data = Wallpaper.render(kind: kind, dark: dark)?.pngData() else {
            throw WallpaperError.renderFailed
        }
        return .result(value: IntentFile(data: data, filename: "tally-\(kind.rawValue).png", type: .png))
    }
}

enum WallpaperError: Error, CustomLocalizedStringResourceConvertible {
    case renderFailed
    var localizedStringResource: LocalizedStringResource { "배경화면을 만들지 못했어요." }
}

/// [핵심] 단축어 자동화로 잠금화면을 바꾸는 동작 (FR-7.15, IC-19).
/// 예: 자동화 '매일 00:01' → 이 동작 → '배경화면 설정'
struct MakeCalendarWallpaperIntent: AppIntent {
    static var title: LocalizedStringResource = "Tally 달력 배경화면 만들기"
    static var description = IntentDescription("배경 사진 위에 오늘 기준 일정 달력을 얹은 배경화면 이미지를 만듭니다. ‘배경화면 설정’ 동작에 연결하세요.")
    static var openAppWhenRun = false

    @Parameter(title: "형태", default: .saved)
    var form: CalendarWallpaperForm

    static var parameterSummary: some ParameterSummary {
        Summary("\(\.$form) 달력 배경화면 만들기")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<IntentFile> {
        let weekly: Bool? = switch form {
        case .saved: nil
        case .monthly: false
        case .weekly: true
        }
        let image = try CalendarWallpaper.render(weekly: weekly)
        guard let data = image.pngData() else { throw CalendarWallpaperError.renderFailed }
        return .result(value: IntentFile(data: data, filename: "tally-calendar.png", type: .png))
    }
}

enum CalendarWallpaperForm: String, AppEnum {
    case saved, monthly, weekly
    static var typeDisplayRepresentation: TypeDisplayRepresentation { "달력 형태" }
    static var caseDisplayRepresentations: [CalendarWallpaperForm: DisplayRepresentation] {
        [.saved: "앱 설정대로", .monthly: "월간", .weekly: "주간"]
    }
}

struct TallyShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: MakeCalendarWallpaperIntent(),
            phrases: ["\(.applicationName) 달력 배경화면 만들기", "Make \(.applicationName) calendar wallpaper"],
            shortTitle: "달력 배경화면",
            systemImageName: "calendar"
        )
        AppShortcut(
            intent: MakeWallpaperIntent(),
            phrases: ["\(.applicationName) 배경화면 만들기", "Make \(.applicationName) wallpaper"],
            shortTitle: "배경화면 만들기",
            systemImageName: "photo.on.rectangle"
        )
    }
}
