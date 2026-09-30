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

struct TallyShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: MakeWallpaperIntent(),
            phrases: ["\(.applicationName) 배경화면 만들기", "Make \(.applicationName) wallpaper"],
            shortTitle: "배경화면 만들기",
            systemImageName: "photo.on.rectangle"
        )
    }
}
