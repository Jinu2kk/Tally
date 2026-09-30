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
    static var calendar: Calendar {
        var cal = Calendar.current
        cal.firstWeekday = weekStartsOnMonday ? 2 : 1
        return cal
    }
}
