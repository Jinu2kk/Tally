import XCTest

/// MT-6.1, 6.3, 6.4 자동화
final class SettingsFlowUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments += ["-uiTesting", "YES", "-tab", "habits", "-seedDemo", "YES"]
        app.launch()
    }

    func testWeekStartAndReset() {
        // 기본: 일요일 시작 → 주간 스트립 첫 칸 '일'
        XCTAssertTrue(app.staticTexts["물 2L 마시기"].waitForExistence(timeout: 5))
        app.navigationBars.buttons["설정"].tap()

        // MT-6.3 월요일 시작
        app.segmentedControls.buttons["월요일"].tap()

        // MT-6.1 다크 모드
        app.segmentedControls.buttons["다크"].tap()

        // MT-6.4 취소 시 유지
        app.buttons["모든 데이터 초기화"].tap()
        app.buttons["취소"].firstMatch.tap()
        app.buttons["완료"].tap()
        XCTAssertTrue(app.staticTexts["물 2L 마시기"].waitForExistence(timeout: 3))
        XCTAssertEqual(app.staticTexts.matching(NSPredicate(format: "label == '월'")).firstMatch.frame.minX <
                       app.staticTexts.matching(NSPredicate(format: "label == '일'")).firstMatch.frame.minX, true,
                       "월요일이 일요일보다 앞")
        saveShot("dark-monday")

        // 확인 시 삭제
        app.navigationBars.buttons["설정"].tap()
        app.buttons["모든 데이터 초기화"].tap()
        app.buttons["모두 삭제"].tap()
        XCTAssertTrue(app.staticTexts["첫 습관을 적어 보세요"].waitForExistence(timeout: 3))
    }

    private func saveShot(_ name: String) {
        guard let dir = ProcessInfo.processInfo.environment["SHOT_DIR"] else { return }
        try? XCUIScreen.main.screenshot().pngRepresentation.write(to: URL(fileURLWithPath: dir).appendingPathComponent("\(name).png"))
    }
}
