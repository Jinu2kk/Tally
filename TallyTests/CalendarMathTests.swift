import XCTest

final class CalendarMathTests: XCTestCase {
    let cal = TS.calendar()

    private func ev(_ title: String, _ s: Date, _ e: Date, allDay: Bool = false) -> DayEvent {
        DayEvent(eventID: title, title: title, start: s, end: e, isAllDay: allDay, colorHex: "E4572E", calendarID: "c")
    }

    private func at(_ y: Int, _ m: Int, _ d: Int, _ h: Int, _ min: Int = 0) -> Date {
        cal.date(from: DateComponents(year: y, month: m, day: d, hour: h, minute: min))!
    }

    // T-9.1
    func testMonthGrid() {
        let grid = CalendarMath.monthGrid(for: TS.date(2026, 10, 15), calendar: cal)
        XCTAssertEqual(grid.count, 42)
        XCTAssertEqual(cal.component(.weekday, from: grid[0]), 1)
        XCTAssertEqual(grid[4], cal.startOfDay(for: TS.date(2026, 10, 1)), "10/1 목요일은 다섯째 칸")
        let mon = TS.calendar(mondayFirst: true)
        let g2 = CalendarMath.monthGrid(for: TS.date(2026, 10, 15, cal: mon), calendar: mon)
        XCTAssertEqual(mon.component(.weekday, from: g2[0]), 2)
        XCTAssertEqual(g2[3], mon.startOfDay(for: TS.date(2026, 10, 1, cal: mon)))
    }

    // T-9.2
    func testMultiDayEventAppearsOnEachDay() {
        let trip = ev("여행", at(2026, 10, 3, 0), at(2026, 10, 6, 0), allDay: true) // 3,4,5일
        for d in 3...5 { XCTAssertEqual(CalendarMath.events(on: TS.date(2026, 10, d), from: [trip], calendar: cal).count, 1, "\(d)일") }
        XCTAssertTrue(CalendarMath.events(on: TS.date(2026, 10, 6), from: [trip], calendar: cal).isEmpty)
        XCTAssertTrue(CalendarMath.events(on: TS.date(2026, 10, 2), from: [trip], calendar: cal).isEmpty)
    }

    // T-9.3
    func testSortAllDayFirstThenTime() {
        let a = ev("회의", at(2026, 10, 1, 14), at(2026, 10, 1, 15))
        let b = ev("생일", at(2026, 10, 1, 0), at(2026, 10, 2, 0), allDay: true)
        let c = ev("아침", at(2026, 10, 1, 8), at(2026, 10, 1, 9))
        XCTAssertEqual(CalendarMath.events(on: TS.date(2026, 10, 1), from: [a, b, c], calendar: cal).map(\.title), ["생일", "아침", "회의"])
    }

    // T-9.4
    func testCellLayoutLimit() {
        let list = (0..<6).map { ev("e\($0)", at(2026, 10, 1, 9 + $0), at(2026, 10, 1, 10 + $0)) }
        XCTAssertEqual(CalendarMath.cellLayout(Array(list.prefix(4))), DayCellLayout(shown: Array(list.prefix(4)), overflow: 0))
        let l = CalendarMath.cellLayout(list)
        XCTAssertEqual(l.shown.count, 3)
        XCTAssertEqual(l.overflow, 3, "4번째 자리는 +3")
    }

    // T-9.5
    func testEventEndingAtMidnightAndZeroLength() {
        let late = ev("야근", at(2026, 10, 1, 22), at(2026, 10, 2, 0))
        XCTAssertEqual(CalendarMath.events(on: TS.date(2026, 10, 1), from: [late], calendar: cal).count, 1)
        XCTAssertTrue(CalendarMath.events(on: TS.date(2026, 10, 2), from: [late], calendar: cal).isEmpty)
        let point = ev("알림", at(2026, 10, 1, 9), at(2026, 10, 1, 9))
        XCTAssertEqual(CalendarMath.events(on: TS.date(2026, 10, 1), from: [point], calendar: cal).count, 1)
    }

    // T-9.6
    func testPeriodStats() {
        let events = [
            ev("a", at(2026, 10, 1, 9), at(2026, 10, 1, 10)),
            ev("b", at(2026, 10, 1, 13), at(2026, 10, 1, 14)),
            ev("trip", at(2026, 10, 30, 0), at(2026, 11, 2, 0), allDay: true), // 10/30, 10/31, 11/1
            ev("old", at(2026, 3, 1, 9), at(2026, 3, 1, 10)),
        ]
        let month = CalendarMath.interval(of: .month, containing: TS.date(2026, 10, 15), calendar: cal)!
        XCTAssertEqual(CalendarMath.periodStats(events, in: month, calendar: cal), PeriodStats(eventCount: 3, busyDays: 3))
        let year = CalendarMath.interval(of: .year, containing: TS.date(2026, 10, 15), calendar: cal)!
        XCTAssertEqual(CalendarMath.periodStats(events, in: year, calendar: cal), PeriodStats(eventCount: 4, busyDays: 5))
    }

    private func week(_ y: Int, _ m: Int, _ d: Int) -> [Date] {
        (0..<7).map { cal.addingDays($0, to: TS.date(y, m, d)) }
    }

    // T-9.7 여러 날 일정은 주 안에서 하나의 막대, 주 경계에서 잘림
    func testWeekLayoutSpansAndClips() {
        let long = ev("개편", at(2026, 10, 23, 0), at(2026, 11, 2, 0), allDay: true)
        let w = CalendarMath.weekLayout(week: week(2026, 10, 18), events: [long], calendar: cal)
        XCTAssertEqual(w.items.count, 1)
        XCTAssertEqual(w.items[0].startCol, 5)
        XCTAssertEqual(w.items[0].endCol, 6)
        XCTAssertTrue(w.items[0].continuesToNext)
        let next = CalendarMath.weekLayout(week: week(2026, 10, 25), events: [long], calendar: cal)
        XCTAssertEqual(next.items[0].startCol, 0)
        XCTAssertEqual(next.items[0].endCol, 6)
        XCTAssertTrue(next.items[0].continuesFromPrevious)
    }

    // T-9.8 막대 먼저, 겹치지 않는 레인 배정, 시간 일정은 line
    func testWeekLayoutLanes() {
        let bar = ev("여행", at(2026, 10, 19, 0), at(2026, 10, 22, 0), allDay: true) // 월~수
        let meet = ev("회의", at(2026, 10, 20, 10), at(2026, 10, 20, 11))         // 화
        let fri = ev("배포", at(2026, 10, 23, 15), at(2026, 10, 23, 16))          // 금
        let w = CalendarMath.weekLayout(week: week(2026, 10, 18), events: [meet, fri, bar], calendar: cal)
        let byTitle = Dictionary(uniqueKeysWithValues: w.items.map { ($0.event.title, $0) })
        XCTAssertEqual(byTitle["여행"]?.lane, 0)
        XCTAssertEqual(byTitle["여행"]?.style, .bar)
        XCTAssertEqual(byTitle["회의"]?.lane, 1)
        XCTAssertEqual(byTitle["회의"]?.style, .line)
        XCTAssertEqual(byTitle["배포"]?.lane, 0, "금요일은 0번 레인이 비어 있음")
    }

    // T-9.9 레인 초과분은 칸별 overflow
    func testWeekLayoutOverflow() {
        let list = (0..<6).map { ev("e\($0)", at(2026, 10, 20, 9 + $0), at(2026, 10, 20, 10 + $0)) }
        let w = CalendarMath.weekLayout(week: week(2026, 10, 18), events: list, calendar: cal, lanes: 4)
        XCTAssertEqual(w.items.count, 4)
        XCTAssertEqual(w.overflow, [0, 0, 2, 0, 0, 0, 0])
    }

    // T-9.10 공휴일
    func testHolidays() {
        XCTAssertTrue(CalendarMath.isHolidayCalendar(title: "대한민국 공휴일"))
        XCTAssertTrue(CalendarMath.isHolidayCalendar(title: "대한민국의 휴일"))
        XCTAssertTrue(CalendarMath.isHolidayCalendar(title: "Holidays in South Korea"))
        XCTAssertFalse(CalendarMath.isHolidayCalendar(title: "직장"))
        let h = DayEvent(eventID: "h", title: "개천절", start: at(2026, 10, 3, 0), end: at(2026, 10, 4, 0),
                         isAllDay: true, colorHex: "000000", calendarID: "hol")
        let other = DayEvent(eventID: "o", title: "회의", start: at(2026, 10, 5, 9), end: at(2026, 10, 5, 10),
                             isAllDay: false, colorHex: "000000", calendarID: "work")
        XCTAssertEqual(CalendarMath.holidays([h, other], holidayCalendarIDs: ["hol"], calendar: cal),
                       [cal.startOfDay(for: TS.date(2026, 10, 3))])
    }
}

final class CalendarSnapshotTests: XCTestCase {
    // T-10.1 필요한 주만: 2026-10 → 5주, 2026-02(일요일 시작, 28일) → 4주, 2026-08 → 6주
    func testWeeksTrimmed() {
        let cal = TS.calendar()
        XCTAssertEqual(CalendarSnapshot.make(month: TS.date(2026, 10, 1), events: [], holidays: [], calendar: cal).weeks.count, 5)
        XCTAssertEqual(CalendarSnapshot.make(month: TS.date(2026, 2, 1), events: [], holidays: [], calendar: cal).weeks.count, 4)
        XCTAssertEqual(CalendarSnapshot.make(month: TS.date(2026, 8, 1), events: [], holidays: [], calendar: cal).weeks.count, 6)
    }

    // T-10.2 주간: 오늘이 든 한 주, 줄 수 7
    func testWeeklySnapshot() {
        let cal = TS.calendar()
        let s = CalendarSnapshot.make(month: .now, events: [], holidays: [], today: TS.date(2026, 10, 14), calendar: cal, weekly: true)
        XCTAssertEqual(s.weeks.count, 1)
        XCTAssertTrue(s.weeks[0].contains(cal.startOfDay(for: TS.date(2026, 10, 14))))
        XCTAssertEqual(s.lanes, 7)
    }
}
