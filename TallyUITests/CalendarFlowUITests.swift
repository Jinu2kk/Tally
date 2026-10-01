import XCTest

/// MT-8.2, 8.3, 8.6, 8.8, 8.13 자동화.
/// 전제: 시뮬레이터에 캘린더 권한 부여 (`xcrun simctl privacy booted grant calendar com.jinu2kk.tally`)
final class CalendarFlowUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments += ["-uiTesting", "YES", "-seedEvents", "YES"]
        app.launch()
    }

    func testMonthDaySheetPickerAndToday() {
        // MT-8.2 기본 캘린더 일정이 칸에 보임
        XCTAssertTrue(app.staticTexts["국군의날"].waitForExistence(timeout: 8))

        // MT-8.3 14일 탭 → 그날 일정 전체(시드 6개), 종일 없음 → 시간순
        let month = Calendar.current.component(.month, from: .now)
        app.buttons["\(month)월 14일"].firstMatch.tap()
        XCTAssertTrue(app.navigationBars.staticTexts.containing(NSPredicate(format: "label BEGINSWITH %@", "\(month)월 14일")).firstMatch.waitForExistence(timeout: 3))
        let list = app.collectionViews.firstMatch
        func row(_ t: String) -> XCUIElement { list.buttons.containing(NSPredicate(format: "label BEGINSWITH %@", t)).firstMatch }
        for t in ["헬스", "책 반납", "치과", "저녁 약속", "스터디"] {
            XCTAssertTrue(row(t).exists, t)
        }
        XCTAssertLessThan(row("헬스").frame.minY, row("스터디").frame.minY, "시간순")
        app.buttons["닫기"].tap()

        // MT-8.6 '집' 캘린더 끄기 → 가족 여행 사라짐, 다시 켜기
        XCTAssertTrue(app.staticTexts["가족 여행"].firstMatch.exists)
        app.buttons["캘린더 선택"].tap()
        let home = app.buttons.containing(NSPredicate(format: "label CONTAINS 'Tally 데모 · 집'")).firstMatch
        XCTAssertTrue(home.waitForExistence(timeout: 3))
        home.tap()
        app.buttons["완료"].tap()
        XCTAssertTrue(app.staticTexts["가족 여행"].firstMatch.waitForDisappearance())
        app.buttons["캘린더 선택"].tap()
        home.tap()
        app.buttons["완료"].tap()
        XCTAssertTrue(app.staticTexts["가족 여행"].firstMatch.waitForExistence(timeout: 3))

        // MT-8.8 통계 올해 전환 시 일정 수가 이번 달 이상
        let monthCount = statValue("일정")
        app.buttons["올해"].tap()
        XCTAssertGreaterThanOrEqual(statValue("일정"), monthCount)

        // MT-8.13 다음 달 → Today 버튼 → 이번 달
        XCTAssertFalse(app.buttons["오늘로"].exists)
        app.buttons["다음 달"].tap()
        XCTAssertTrue(app.buttons["오늘로"].waitForExistence(timeout: 2))
        app.buttons["오늘로"].tap()
        XCTAssertTrue(app.staticTexts["국군의날"].waitForExistence(timeout: 3))
        XCTAssertFalse(app.buttons["오늘로"].exists)
    }

    private func statValue(_ label: String) -> Int {
        let e = app.staticTexts.matching(NSPredicate(format: "label ENDSWITH %@", ", \(label)")).firstMatch
        return Int(e.label.prefix { $0.isNumber }) ?? -1
    }
}
