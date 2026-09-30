import XCTest

/// MT-2.2 ~ 2.5 자동화
final class TimeFlowUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments += ["-uiTesting", "YES"]
        app.launch()
        app.tabBars.buttons["시간"].tap()
    }

    func testBirthDDayAndWallpaper() {
        // MT-2.2 생년월일 미입력 안내 → 입력
        XCTAssertTrue(app.buttons["생년월일 입력"].waitForExistence(timeout: 3))
        app.buttons["생년월일 입력"].tap()
        app.buttons["저장"].tap()
        XCTAssertTrue(app.staticTexts["주 남았어요"].waitForExistence(timeout: 3))

        // MT-2.4 D-Day 기본값은 7일 뒤
        app.buttons["D-Day 추가"].tap()
        let field = app.textFields["이름 (예: 여행)"]
        XCTAssertTrue(field.waitForExistence(timeout: 3))
        field.tap()
        field.typeText("여행")
        app.buttons["저장"].tap()
        XCTAssertTrue(app.staticTexts["D-7"].waitForExistence(timeout: 3))

        // MT-2.5 배경화면 공유 버튼
        let share = app.buttons["저장 · 공유"]
        for _ in 0..<5 where !share.isHittable { app.swipeUp() }
        XCTAssertTrue(share.isHittable)
        saveShot("time-bottom")
        share.tap()
        XCTAssertTrue(app.otherElements["ActivityListView"].waitForExistence(timeout: 5) || app.navigationBars["UIActivityContentView"].waitForExistence(timeout: 2))
        saveShot("share-sheet")
    }

    /// 환경 변수 SHOT_DIR이 있으면 호스트 경로로 스크린샷 저장 (시뮬레이터 전용)
    private func saveShot(_ name: String) {
        guard let dir = ProcessInfo.processInfo.environment["SHOT_DIR"] else { return }
        try? XCUIScreen.main.screenshot().pngRepresentation.write(to: URL(fileURLWithPath: dir).appendingPathComponent("\(name).png"))
    }
}
