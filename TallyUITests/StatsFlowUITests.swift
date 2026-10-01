import XCTest

/// MT-4.2 ~ 4.4 자동화
final class StatsFlowUITests: XCTestCase {
    func testHabitFilterAndMonthNavigation() {
        let app = XCUIApplication()
        app.launchArguments += ["-uiTesting", "YES", "-seedDemo", "YES", "-tab", "habits"]
        app.launch()

        // MT-4.3 오늘 탭의 연속 기록 값을 기억
        let walkRow = app.buttons.containing(NSPredicate(format: "label CONTAINS '30분 걷기'")).firstMatch
        XCTAssertTrue(walkRow.waitForExistence(timeout: 5))
        let streak = walkRow.label.components(separatedBy: "연속 ").last?.components(separatedBy: "일").first ?? "?"

        app.tabBars.buttons["기록"].tap()
        // MT-4.2 습관 선택
        app.buttons["🚶, 30분 걷기"].firstMatch.tap()
        let tile = app.descendants(matching: .any).matching(NSPredicate(format: "label BEGINSWITH '현재 연속'")).firstMatch
        XCTAssertTrue(tile.waitForExistence(timeout: 2))
        XCTAssertTrue(tile.label.contains(", \(streak),") || tile.label.contains(" \(streak) "), "기록 탭 '\(tile.label)'이 오늘 탭 연속 \(streak)일과 일치해야 함")

        // MT-4.4 이전 달 이동
        let thisMonth = Calendar.current.component(.month, from: .now)
        let prev = thisMonth == 1 ? 12 : thisMonth - 1
        app.swipeUp()
        app.buttons["이전 달"].tap()
        XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", " \(prev)월")).firstMatch.waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["%"].exists)
    }
}
