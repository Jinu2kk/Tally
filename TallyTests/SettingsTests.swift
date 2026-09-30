import XCTest

final class SettingsTests: XCTestCase {
    private let keys = [SettingsKey.tint, SettingsKey.lifeExpectancy, SettingsKey.birthDate, SettingsKey.weekStartsOnMonday]
    private var saved: [String: Any] = [:]

    override func setUp() {
        keys.forEach { saved[$0] = AppSettings.store.object(forKey: $0); AppSettings.store.removeObject(forKey: $0) }
    }

    override func tearDown() {
        keys.forEach { k in
            if let v = saved[k] { AppSettings.store.set(v, forKey: k) } else { AppSettings.store.removeObject(forKey: k) }
        }
    }

    // T-6.1 기본값과 잘못된 값 처리
    func testDefaults() {
        XCTAssertEqual(AppSettings.tint, .tomato)
        XCTAssertEqual(AppSettings.lifeExpectancy, 80)
        XCTAssertNil(AppSettings.birthDate)
        XCTAssertEqual(AppSettings.calendar.firstWeekday, 1)

        AppSettings.store.set(500, forKey: SettingsKey.lifeExpectancy)
        XCTAssertEqual(AppSettings.lifeExpectancy, 80, "범위 밖이면 기본값")
        AppSettings.store.set("nope", forKey: SettingsKey.tint)
        XCTAssertEqual(AppSettings.tint, .tomato)
        AppSettings.store.set(true, forKey: SettingsKey.weekStartsOnMonday)
        XCTAssertEqual(AppSettings.calendar.firstWeekday, 2)
    }

    func testThemeHasAtLeastFiveTints() {
        XCTAssertGreaterThanOrEqual(ThemeTint.allCases.count, 5) // FR-2.4
    }
}
