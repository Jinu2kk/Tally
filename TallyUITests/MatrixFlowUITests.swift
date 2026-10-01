import XCTest

/// MT-3.1 ~ 3.4 자동화
final class MatrixFlowUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments += ["-uiTesting", "YES"]
        app.launch()
        app.tabBars.buttons["할 일"].tap()
    }

    private func addTask(_ title: String, to quadrant: String) {
        app.buttons["\(quadrant)에 추가"].firstMatch.tap()
        let field = app.textFields["할 일"]
        XCTAssertTrue(field.waitForExistence(timeout: 3))
        field.tap()
        field.typeText(title)
        app.buttons["저장"].tap()
    }

    func testAddCompleteMoveAndDelete() {
        addTask("보고서", to: "지금 하기")
        let q1 = app.otherElements["quadrant-Q1"]
        let task = app.staticTexts["보고서"]
        XCTAssertTrue(task.waitForExistence(timeout: 3))

        // MT-3.2 완료 + 숨기기
        app.buttons["완료"].firstMatch.tap()
        XCTAssertTrue(app.buttons["완료 취소"].firstMatch.exists)
        app.buttons["완료 항목 숨기기"].tap()
        XCTAssertTrue(task.waitForDisappearance())
        app.buttons["완료 항목 보이기"].tap()
        XCTAssertTrue(task.waitForExistence(timeout: 2))

        // MT-3.3 드래그로 Q2 이동
        let q2 = app.otherElements["quadrant-Q2"]
        task.press(forDuration: 0.8, thenDragTo: q2)
        XCTAssertTrue(q2.staticTexts["보고서"].waitForExistence(timeout: 3), "Q2로 이동해야 함")
        XCTAssertFalse(q1.staticTexts["보고서"].exists)

        // MT-3.4 목록 보기 → 스와이프 삭제
        app.buttons["목록 보기"].tap()
        let row = app.staticTexts["보고서"]
        XCTAssertTrue(row.waitForExistence(timeout: 2))
        app.otherElements.matching(identifier: "task-row").firstMatch.swipeLeft()
        XCTAssertTrue(row.waitForDisappearance())
    }
}
