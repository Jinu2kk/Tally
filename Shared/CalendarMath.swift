import Foundation

/// EventKit 일정을 화면용 값으로 옮긴 것 (IC-14)
struct DayEvent: Identifiable, Hashable {
    /// 반복 일정은 같은 eventIdentifier가 여러 번 나오므로 시작 시각을 붙여 구분
    let id: String
    let eventID: String
    let title: String
    let start: Date
    let end: Date
    let isAllDay: Bool
    let colorHex: String
    let calendarID: String

    init(eventID: String, title: String, start: Date, end: Date, isAllDay: Bool, colorHex: String, calendarID: String) {
        self.id = "\(eventID)@\(start.timeIntervalSinceReferenceDate)"
        self.eventID = eventID
        self.title = title
        self.start = start
        self.end = end
        self.isAllDay = isAllDay
        self.colorHex = colorHex
        self.calendarID = calendarID
    }
}

/// 날짜 칸에 보여 줄 일정 (최대 limit개)과 넘친 개수
struct DayCellLayout: Equatable {
    let shown: [DayEvent]
    let overflow: Int
}

/// 기간 통계 (FR-7.8)
struct PeriodStats: Equatable {
    let eventCount: Int
    let busyDays: Int
}

enum CalendarPeriod: String, CaseIterable, Identifiable {
    case month, year
    var id: String { rawValue }
    var title: String {
        switch self {
        case .month: String(localized: "이번 달")
        case .year: String(localized: "올해")
        }
    }
}

enum CalendarMath {
    /// 6주(42칸) 월 그리드. 앞뒤 달 날짜로 채운다 (FR-7.2, 7.10)
    static func monthGrid(for month: Date, calendar: Calendar) -> [Date] {
        guard let first = calendar.dateInterval(of: .month, for: month)?.start else { return [] }
        let blanks = (calendar.component(.weekday, from: first) - calendar.firstWeekday + 7) % 7
        let start = calendar.addingDays(-blanks, to: first)
        return (0..<42).map { calendar.addingDays($0, to: start) }
    }

    /// 그리드 전체 기간 (조회 범위)
    static func gridInterval(for month: Date, calendar: Calendar) -> DateInterval? {
        let grid = monthGrid(for: month, calendar: calendar)
        guard let first = grid.first, let last = grid.last else { return nil }
        return DateInterval(start: first, end: calendar.addingDays(1, to: last))
    }

    /// 해당 날짜에 걸친 일정 (FR-7.5). 끝 시각이 자정 정각이면 그날은 포함하지 않는다
    static func events(on day: Date, from all: [DayEvent], calendar: Calendar) -> [DayEvent] {
        let dayStart = calendar.startOfDay(for: day)
        let dayEnd = calendar.addingDays(1, to: dayStart)
        return sorted(all.filter { e in
            let end = e.end > e.start ? e.end : e.start.addingTimeInterval(1) // 길이 0 일정도 시작일에 표시
            return e.start < dayEnd && end > dayStart
        })
    }

    /// 종일 먼저, 그다음 시작 시각, 같으면 제목 (FR-7.3)
    static func sorted(_ events: [DayEvent]) -> [DayEvent] {
        events.sorted {
            if $0.isAllDay != $1.isAllDay { return $0.isAllDay }
            if $0.start != $1.start { return $0.start < $1.start }
            return $0.title < $1.title
        }
    }

    /// 날짜 칸 배치: 최대 limit개, 넘치면 마지막 자리를 +n으로 쓴다 (FR-7.2)
    static func cellLayout(_ events: [DayEvent], limit: Int = 4) -> DayCellLayout {
        guard events.count > limit else { return DayCellLayout(shown: events, overflow: 0) }
        let shown = Array(events.prefix(limit - 1))
        return DayCellLayout(shown: shown, overflow: events.count - shown.count)
    }

    /// 날짜별로 미리 묶어 두기 (그리드 42칸 × 일정 수 반복 계산을 피함)
    static func eventsByDay(_ all: [DayEvent], days: [Date], calendar: Calendar) -> [Date: [DayEvent]] {
        var map: [Date: [DayEvent]] = [:]
        for d in days { map[calendar.startOfDay(for: d)] = events(on: d, from: all, calendar: calendar) }
        return map
    }

    /// 기간 통계: 기간과 겹치는 일정 수(반복 일정은 회차별), 일정 있는 날 수
    static func periodStats(_ all: [DayEvent], in interval: DateInterval, calendar: Calendar) -> PeriodStats {
        let inPeriod = all.filter { $0.start < interval.end && max($0.end, $0.start.addingTimeInterval(1)) > interval.start }
        var busy = Set<Date>()
        for e in inPeriod {
            var d = max(calendar.startOfDay(for: e.start), interval.start)
            let end = max(e.end, e.start.addingTimeInterval(1))
            while d < end && d < interval.end {
                busy.insert(d)
                d = calendar.addingDays(1, to: d)
            }
        }
        return PeriodStats(eventCount: inPeriod.count, busyDays: busy.count)
    }

    static func interval(of period: CalendarPeriod, containing date: Date, calendar: Calendar) -> DateInterval? {
        calendar.dateInterval(of: period == .month ? .month : .year, for: date)
    }
}

// MARK: - 주 단위 막대 배치 (IC-15)

struct WeekItem: Identifiable, Equatable {
    enum Style { case bar, line }
    let event: DayEvent
    let startCol: Int
    let endCol: Int
    let lane: Int
    let style: Style
    var id: String { event.id }
    /// 이전 주에서 이어지는 막대인지 (왼쪽 모서리를 각지게)
    let continuesFromPrevious: Bool
    let continuesToNext: Bool
}

struct WeekLayout: Equatable {
    let items: [WeekItem]
    /// 칸별로 레인이 모자라 숨긴 일정 수
    let overflow: [Int]
}

extension CalendarMath {
    static func weekLayout(week: [Date], events all: [DayEvent], calendar: Calendar, lanes: Int = 4) -> WeekLayout {
        guard let first = week.first, week.count == 7 else { return WeekLayout(items: [], overflow: []) }
        let weekStart = calendar.startOfDay(for: first)
        let weekEnd = calendar.addingDays(7, to: weekStart)

        struct Candidate { let e: DayEvent; let s: Int; let t: Int; let bar: Bool }
        let candidates: [Candidate] = all.compactMap { e in
            let end = e.end > e.start ? e.end : e.start.addingTimeInterval(1)
            guard e.start < weekEnd, end > weekStart else { return nil }
            let s = max(0, calendar.days(from: weekStart, to: max(e.start, weekStart)))
            let lastMoment = min(end.addingTimeInterval(-1), weekEnd.addingTimeInterval(-1))
            let t = min(6, max(s, calendar.days(from: weekStart, to: lastMoment)))
            let multiDay = calendar.days(from: e.start, to: end.addingTimeInterval(-1)) > 0
            return Candidate(e: e, s: s, t: t, bar: e.isAllDay || multiDay)
        }
        .sorted { a, b in
            if a.bar != b.bar { return a.bar }
            if a.s != b.s { return a.s < b.s }
            if (a.t - a.s) != (b.t - b.s) { return (a.t - a.s) > (b.t - b.s) }
            if a.e.start != b.e.start { return a.e.start < b.e.start }
            return a.e.title < b.e.title
        }

        var used = Array(repeating: Array(repeating: false, count: 7), count: lanes)
        var overflow = Array(repeating: 0, count: 7)
        var items: [WeekItem] = []
        for c in candidates {
            if let lane = (0..<lanes).first(where: { l in (c.s...c.t).allSatisfy { !used[l][$0] } }) {
                (c.s...c.t).forEach { used[lane][$0] = true }
                let end = c.e.end > c.e.start ? c.e.end : c.e.start.addingTimeInterval(1)
                items.append(WeekItem(event: c.e, startCol: c.s, endCol: c.t, lane: lane,
                                      style: c.bar ? .bar : .line,
                                      continuesFromPrevious: c.e.start < weekStart,
                                      continuesToNext: end > weekEnd))
            } else {
                (c.s...c.t).forEach { overflow[$0] += 1 }
            }
        }
        return WeekLayout(items: items, overflow: overflow)
    }

    // MARK: 공휴일 (IC-16)

    static func isHolidayCalendar(title: String) -> Bool {
        let t = title.lowercased()
        return t.contains("휴일") || t.contains("holiday")
    }

    static func holidays(_ events: [DayEvent], holidayCalendarIDs: Set<String>, calendar: Calendar) -> Set<Date> {
        var days = Set<Date>()
        for e in events where holidayCalendarIDs.contains(e.calendarID) {
            var d = calendar.startOfDay(for: e.start)
            let end = max(e.end, e.start.addingTimeInterval(1))
            while d < end {
                days.insert(d)
                d = calendar.addingDays(1, to: d)
            }
        }
        return days
    }
}
