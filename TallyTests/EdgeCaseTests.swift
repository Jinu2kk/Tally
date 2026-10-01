import XCTest

/// Phase 7 경계값
final class EdgeCaseTests: XCTestCase {
    func testStreakInNewYorkAcrossDST() {
        let ny = TS.calendar(tz: "America/New_York")
        // 2026-11-01 서머타임 종료일을 끼고 3일 연속
        let done = TS.days([(2026, 10, 31), (2026, 11, 1), (2026, 11, 2)], cal: ny)
        XCTAssertEqual(Streaks.current(done, today: TS.date(2026, 11, 2, cal: ny), calendar: ny), 3)
        XCTAssertEqual(Streaks.longest(done, calendar: ny), 3)
    }

    func testYearProgressInNewYork() {
        let ny = TS.calendar(tz: "America/New_York")
        let y = YearProgress(now: TS.date(2026, 3, 8, cal: ny), calendar: ny) // 서머타임 시작일
        XCTAssertEqual(y.dayOfYear, 67)
    }

    func testLifeExpectancyBounds() {
        let cal = TS.calendar()
        let birth = TS.date(1990, 1, 1)
        XCTAssertEqual(LifeProgress(birth: birth, expectancy: 1, now: TS.date(1990, 6, 1), calendar: cal).totalWeeks, 52)
        XCTAssertEqual(LifeProgress(birth: birth, expectancy: 120, now: .now, calendar: cal).totalWeeks, 6240)
        XCTAssertEqual(LifeProgress(birth: birth, expectancy: 0, now: .now, calendar: cal).totalWeeks, 52, "0 이하는 1년으로")
    }

    func testBirthInFuture() {
        let cal = TS.calendar()
        let l = LifeProgress(birth: TS.date(2030, 1, 1), expectancy: 80, now: TS.date(2026, 1, 1), calendar: cal)
        XCTAssertEqual(l.livedWeeks, 0)
        XCTAssertEqual(l.weeksLeft, l.totalWeeks)
    }

    func testNoHabits() {
        let cal = TS.calendar()
        XCTAssertEqual(DayRatio.ratio(on: .now, habits: [], calendar: cal), 0)
        XCTAssertEqual(ContributionSource(habits: [], calendar: cal).level(on: .now), 0)
        XCTAssertEqual(Streaks.current([], today: .now, calendar: cal), 0)
    }

    func testHexColorParsing() {
        // 잘못된 값도 크래시 없이 처리
        _ = Color(hex: "#E4572E")
        _ = Color(hex: "zz")
        _ = Color(hex: "")
    }
}

import SwiftUI
