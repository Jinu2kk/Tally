import XCTest

/// MT-1.1 ~ 1.3 자동화
final class HabitFlowUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments += ["-uiTesting", "YES"]
        app.launch()
    }

    func testCreateAndToggleHabit() {
        XCTAssertTrue(app.staticTexts["첫 습관을 적어 보세요"].waitForExistence(timeout: 5))
        app.navigationBars.buttons["습관 추가"].tap()

        let name = app.textFields["예: 물 2L 마시기"]
        XCTAssertTrue(name.waitForExistence(timeout: 3))
        name.tap()
        name.typeText("물 마시기")
        app.buttons["💧"].tap()
        app.buttons["저장"].tap()

        let row = app.buttons.containing(NSPredicate(format: "label CONTAINS '물 마시기'")).firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 3))
        XCTAssertEqual(row.value as? String, "미완료")

        row.tap()
        XCTAssertEqual(row.value as? String, "완료")
        XCTAssertTrue(app.staticTexts["1"].exists)

        // 스와이프로 취소
        row.swipeRight()
        XCTAssertEqual(row.value as? String, "미완료")
    }
}
