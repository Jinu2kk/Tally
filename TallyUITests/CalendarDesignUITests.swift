import XCTest

/// MT-8.7, 8.10(셔플·제거), 8.11, 8.12, 8.15 자동화
final class CalendarDesignUITests: XCTestCase {
    func testDesignAndWallpaperSheets() {
        let app = XCUIApplication()
        app.launchArguments += ["-uiTesting", "YES", "-seedEvents", "YES"]
        app.launch()
        XCTAssertTrue(app.staticTexts["국군의날"].waitForExistence(timeout: 8))

        // 디자인: 셔플 → 토 강조 → 미리보기 숨기기
        app.buttons["디자인"].tap()
        XCTAssertTrue(app.buttons["셔플"].firstMatch.waitForExistence(timeout: 3))
        app.buttons["셔플"].firstMatch.tap()
        app.buttons["토 강조"].tap()
        XCTAssertEqual(app.buttons["토 강조"].value as? String, "켜짐")
        app.switches["이전/다음 달 미리보기 숨기기"].firstMatch.switches.firstMatch.tap()
        saveShot("design-sheet")
        app.buttons["완료"].tap()

        // MT-8.11 앞 달(9월 말) 날짜 숨김: 월 그리드 첫 칸의 앞 달 날짜 접근성 요소가 없어짐
        let prevMonth = Calendar.current.date(byAdding: .month, value: -1, to: .now)!
        let lastPrev = Calendar.current.range(of: .day, in: .month, for: prevMonth)!.count
        let pm = Calendar.current.component(.month, from: prevMonth)
        XCTAssertFalse(app.staticTexts["\(pm)월 \(lastPrev)일"].exists && app.staticTexts["\(lastPrev)"].isHittable)
        saveShot("calendar-pattern")

        // MT-8.12 배경화면 시트
        app.buttons["배경화면 만들기"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["잠금 화면 미리보기"].firstMatch.waitForExistence(timeout: 5))
        // MT-8.15 세로 위치: 슬라이더를 내린 뒤 '자동'으로 되돌린다
        let position = app.descendants(matching: .any)["세로 위치"].firstMatch
        XCTAssertTrue(position.exists)
        position.swipeDown()
        app.buttons["세로 위치 자동"].tap()
        app.buttons["주간"].tap()
        XCTAssertTrue(app.buttons["이미지 저장 · 공유"].waitForExistence(timeout: 5))
        saveShot("wallpaper-sheet")
        app.buttons["월간"].tap()
        // 공유 시트가 크래시 없이 뜨는지
        app.buttons["이미지 저장 · 공유"].tap()
        XCTAssertTrue(app.otherElements["ActivityListView"].waitForExistence(timeout: 5) || app.navigationBars["UIActivityContentView"].waitForExistence(timeout: 2))
        saveShot("wallpaper-share")
        // 설정은 다음 테스트 실행 때 -uiTesting으로 초기화된다
    }

    private func saveShot(_ name: String) {
        guard let dir = ProcessInfo.processInfo.environment["SHOT_DIR"] else { return }
        try? XCUIScreen.main.screenshot().pngRepresentation.write(to: URL(fileURLWithPath: dir).appendingPathComponent("\(name).png"))
    }
}
