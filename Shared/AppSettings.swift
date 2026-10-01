import Foundation

/// 설정 키. 앱은 `@AppStorage(key, store: AppSettings.store)`로 사용 (IC-4)
enum SettingsKey {
    static let appearance = "appearance"          // AppearanceMode.rawValue
    static let tint = "tint"                      // ThemeTint.rawValue
    static let weekStartsOnMonday = "weekStartsOnMonday"
    static let birthDate = "birthDate"            // timeIntervalSinceReferenceDate, 0 = 미입력
    static let lifeExpectancy = "lifeExpectancy"
    static let hideDoneTasks = "hideDoneTasks"
    static let matrixListMode = "matrixListMode"
    static let wallpaperKind = "wallpaperKind"
    // 달력 (FR-7)
    static let hiddenCalendars = "hiddenCalendars"        // [String] calendarIdentifier
    static let emphasizeHoliday = "emphasizeHoliday"
    static let emphasizeSaturday = "emphasizeSaturday"
    static let emphasizeSunday = "emphasizeSunday"
    static let hideAdjacentDays = "hideAdjacentDays"
    static let todayColor = "todayColor"                  // hex, "" = 테마 색
    static let calendarBackground = "calendarBackground"  // CalendarBackgroundKind.rawValue
    static let backgroundColor = "backgroundColor"        // hex (단색)
    static let backgroundPattern = "backgroundPattern"    // 셔플 패턴 번호
    static let backgroundOpacity = "backgroundOpacity"    // 0...1
    static let backgroundBlur = "backgroundBlur"          // 0...20
    static let wallpaperScale = "wallpaperScale"          // 0.7...1
    static let wallpaperWeekly = "wallpaperWeekly"
    static let wallpaperOffset = "wallpaperOffset"        // 달력 윗변 위치(화면 높이 비율), -1 = 자동
    static let statsPeriod = "statsPeriod"                // CalendarPeriod.rawValue
}

enum AppearanceMode: String, CaseIterable, Identifiable {
    case system, light, dark
    var id: String { rawValue }
    var title: String {
        switch self {
        case .system: String(localized: "시스템")
        case .light: String(localized: "라이트")
        case .dark: String(localized: "다크")
        }
    }
}

enum AppSettings {
    static let store: UserDefaults = UserDefaults(suiteName: SharedStore.appGroupID) ?? .standard

    static let defaultLifeExpectancy = 80
    static let lifeExpectancyRange = 1...120

    static var tint: ThemeTint {
        ThemeTint(rawValue: store.string(forKey: SettingsKey.tint) ?? "") ?? .tomato
    }

    static var weekStartsOnMonday: Bool { store.bool(forKey: SettingsKey.weekStartsOnMonday) }

    static var birthDate: Date? {
        let raw = store.double(forKey: SettingsKey.birthDate)
        return raw == 0 ? nil : Date(timeIntervalSinceReferenceDate: raw)
    }

    static var lifeExpectancy: Int {
        let v = store.integer(forKey: SettingsKey.lifeExpectancy)
        return lifeExpectancyRange.contains(v) ? v : defaultLifeExpectancy
    }

    /// 주 시작 요일 설정을 반영한 달력
    static var calendar: Calendar { calendar(mondayFirst: weekStartsOnMonday) }

    static func calendar(mondayFirst: Bool) -> Calendar {
        var cal = Calendar.current
        cal.firstWeekday = mondayFirst ? 2 : 1
        return cal
    }
}

extension Locale {
    /// 날짜 표기 언어. 다국어 확장 시 .current로 바꾼다 (C-4)
    static let app = Locale(identifier: "ko_KR")
}
