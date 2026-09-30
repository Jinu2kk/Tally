import XCTest

final class ContributionTests: XCTestCase {
    // T-4.1 마지막 주에 오늘이 들어 있고, 주 길이는 7
    func testGridEndsWithTodaysWeek() {
        let cal = TS.calendar()
        let today = TS.date(2026, 10, 1) // 목요일
        let grid = Contribution.grid(weeks: 53, today: today, calendar: cal)
        XCTAssertEqual(grid.count, 53)
        XCTAssertTrue(grid.allSatisfy { $0.count == 7 })
        XCTAssertTrue(grid.last!.contains(cal.startOfDay(for: today)))
        XCTAssertEqual(cal.component(.weekday, from: grid[0][0]), 1, "일요일 시작")
    }

    // T-4.2 월요일 시작
    func testMondayFirstGrid() {
        let cal = TS.calendar(mondayFirst: true)
        let grid = Contribution.grid(weeks: 4, today: TS.date(2026, 10, 4, cal: cal), calendar: cal) // 일요일
        XCTAssertEqual(cal.component(.weekday, from: grid[0][0]), 2)
        XCTAssertEqual(grid.last!.last, cal.startOfDay(for: TS.date(2026, 10, 4, cal: cal)), "일요일은 월요일 시작 주의 마지막 칸")
    }

    // T-4.3 농도 경계
    func testLevels() {
        XCTAssertEqual(Contribution.level(0), 0)
        XCTAssertEqual(Contribution.level(0.2), 1)
        XCTAssertEqual(Contribution.level(0.5), 2)
        XCTAssertEqual(Contribution.level(0.8), 3)
        XCTAssertEqual(Contribution.level(1), 4)
    }

    // T-4.4 월 달성률: 생성일 이전과 미래는 제외
    func testMonthRateExcludesBeforeCreationAndFuture() {
        let cal = TS.calendar()
        let eligible = MonthStats.eligibleDays(in: TS.date(2026, 10, 15), since: TS.date(2026, 10, 3),
                                               today: TS.date(2026, 10, 6), calendar: cal)
        XCTAssertEqual(eligible.count, 4) // 3,4,5,6일
        let done = TS.days([(2026, 10, 3), (2026, 10, 5), (2026, 10, 1)])
        XCTAssertEqual(MonthStats.rate(done: done, eligible: eligible), 0.5)
        XCTAssertNil(MonthStats.rate(done: done, eligible: []))
        XCTAssertEqual(MonthStats.days(in: TS.date(2028, 2, 10), calendar: cal).count, 29)
    }

    func testLeadingBlanks() {
        let sun = TS.calendar(), mon = TS.calendar(mondayFirst: true)
        // 2026-10-01은 목요일
        XCTAssertEqual(MonthStats.leadingBlanks(for: TS.date(2026, 10, 1), calendar: sun), 4)
        XCTAssertEqual(MonthStats.leadingBlanks(for: TS.date(2026, 10, 1), calendar: mon), 3)
    }

    func testDailyRatioIgnoresHabitsNotYetCreated() {
        let cal = TS.calendar()
        let day = TS.date(2026, 10, 1)
        let a = (created: TS.date(2026, 1, 1), done: TS.days([(2026, 10, 1)]))
        let b = (created: TS.date(2026, 12, 1), done: Set<Date>())
        XCTAssertEqual(DailyRatio.ratio(on: day, habits: [a, b], calendar: cal), 1)
    }
}
