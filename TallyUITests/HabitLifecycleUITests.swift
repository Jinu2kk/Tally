import XCTest

/// MT-1.4, 1.7, 1.9 자동화
final class HabitLifecycleUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments += ["-uiTesting", "YES"]
        app.launch()
    }

    private func addHabit(_ name: String) {
        app.navigationBars.buttons["습관 추가"].tap()
        let field = app.textFields["예: 물 2L 마시기"]
        XCTAssertTrue(field.waitForExistence(timeout: 3))
        field.tap()
        field.typeText(name)
        app.buttons["저장"].tap()
    }

    private func row(_ name: String) -> XCUIElement {
        app.buttons.containing(NSPredicate(format: "label CONTAINS %@", name)).firstMatch
    }

    private func openEditor(_ name: String) {
        row(name).press(forDuration: 1.2)
        app.buttons["편집"].tap()
    }

    func testCheckYesterdayArchiveAndDelete() {
        addHabit("스트레칭")
        XCTAssertTrue(row("스트레칭").waitForExistence(timeout: 3))

        // MT-1.4 어제 체크 → 오늘로 돌아오면 연속 1일
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: .now)!
        let day = Calendar.current.component(.day, from: yesterday)
        var dayButton = app.buttons.matching(NSPredicate(format: "label ENDSWITH %@", ", \(day)")).firstMatch
        if !dayButton.exists {
            app.buttons["이전 주"].tap()
            dayButton = app.buttons.matching(NSPredicate(format: "label ENDSWITH %@", ", \(day)")).firstMatch
        }
        dayButton.tap()
        row("스트레칭").tap()
        XCTAssertEqual(row("스트레칭").value as? String, "완료")
        // 오늘로 복귀
        let today = Calendar.current.component(.day, from: .now)
        var todayButton = app.buttons.matching(NSPredicate(format: "label ENDSWITH %@", ", \(today)")).firstMatch
        if !todayButton.exists {
            app.buttons["다음 주"].tap()
            todayButton = app.buttons.matching(NSPredicate(format: "label ENDSWITH %@", ", \(today)")).firstMatch
        }
        todayButton.tap()
        XCTAssertTrue(app.staticTexts["오늘"].waitForExistence(timeout: 2))
        XCTAssertEqual(row("스트레칭").value as? String, "미완료")
        XCTAssertTrue(row("스트레칭").label.contains("연속 1일"), row("스트레칭").label)

        // MT-1.9 보관 → 목록에서 사라지고 설정의 보관함에 표시
        addHabit("독서")
        openEditor("독서")
        app.buttons["보관하기"].tap()
        XCTAssertTrue(row("독서").waitForDisappearance())
        app.navigationBars.buttons["설정"].tap()
        XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS '독서'")).firstMatch.waitForExistence(timeout: 2))
        app.buttons["꺼내기"].tap()
        app.buttons["완료"].tap()
        XCTAssertTrue(row("독서").waitForExistence(timeout: 2))

        // MT-1.7 삭제(확인 대화상자)
        openEditor("독서")
        app.collectionViews.firstMatch.swipeUp()
        app.buttons["삭제"].firstMatch.tap()
        let deletes = app.buttons.matching(identifier: "삭제")
        XCTAssertTrue(deletes.element(boundBy: 1).waitForExistence(timeout: 2), "확인 대화상자")
        deletes.allElementsBoundByIndex.max { $0.frame.minY < $1.frame.minY }!.tap()
        XCTAssertTrue(row("독서").waitForDisappearance())
    }
}
