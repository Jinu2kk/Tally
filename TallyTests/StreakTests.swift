import XCTest
import SwiftData

final class StreakTests: XCTestCase {
    let cal = TS.calendar()

    // T-1.1
    func testThreeConsecutiveDaysIncludingToday() {
        let done = TS.days([(2026, 10, 1), (2026, 9, 30), (2026, 9, 29)])
        XCTAssertEqual(Streaks.current(done, today: TS.date(2026, 10, 1), calendar: cal), 3)
    }

    // T-1.2 오늘 미완료여도 어제까지 이어졌으면 유지 (IC-5)
    func testTodayNotDoneKeepsYesterdayStreak() {
        let done = TS.days([(2026, 9, 30), (2026, 9, 29)])
        XCTAssertEqual(Streaks.current(done, today: TS.date(2026, 10, 1), calendar: cal), 2)
    }

    // T-1.3
    func testMissedYesterdayAndTodayResets() {
        let done = TS.days([(2026, 9, 29), (2026, 9, 28)])
        XCTAssertEqual(Streaks.current(done, today: TS.date(2026, 10, 1), calendar: cal), 0)
    }

    // T-1.4
    func testLongest() {
        let done = TS.days([(2026, 1, 1), (2026, 1, 2), (2026, 1, 3), (2026, 1, 4), (2026, 1, 10), (2026, 1, 11)])
        XCTAssertEqual(Streaks.longest(done, calendar: cal), 4)
        XCTAssertEqual(Streaks.longest([], calendar: cal), 0)
    }

    // T-1.5 월 경계와 윤년
    func testMonthBoundaryAndLeapDay() {
        let done = TS.days([(2028, 2, 28), (2028, 2, 29), (2028, 3, 1)])
        XCTAssertEqual(Streaks.current(done, today: TS.date(2028, 3, 1), calendar: cal), 3)
        let gap = TS.days([(2027, 2, 28), (2027, 3, 1)]) // 2027은 평년 → 연속
        XCTAssertEqual(Streaks.longest(gap, calendar: cal), 2)
    }

    // T-1.6 같은 날 두 번 토글하면 기록 0개 (IC-6)
    func testToggleTwiceRemovesLog() throws {
        let context = ModelContext(SharedStore.makeContainer(inMemory: true))
        let h = Habit(name: "물", icon: "💧", colorHex: "1B998B", sortOrder: 0)
        context.insert(h)
        let day = TS.date(2026, 10, 1, hour: 9)
        XCTAssertTrue(HabitActions.toggle(h, on: day, in: context, calendar: cal))
        XCTAssertTrue(HabitActions.isDone(h, on: TS.date(2026, 10, 1, hour: 22), calendar: cal))
        XCTAssertFalse(HabitActions.toggle(h, on: day, in: context, calendar: cal))
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<HabitLog>()), 0)
    }
}
