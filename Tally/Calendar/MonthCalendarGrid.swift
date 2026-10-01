import SwiftUI

/// 달력 그리기에 필요한 값 (EventKit과 무관한 순수 데이터)
struct CalendarSnapshot {
    let month: Date
    /// 그릴 주들 (월간 6주, 주간 1주)
    let weeks: [[Date]]
    let events: [DayEvent]
    let holidays: Set<Date>
    let today: Date
    let calendar: Calendar
    var lanes = 4

    static func make(month: Date, events: [DayEvent], holidays: Set<Date>, today: Date = .now,
                     calendar: Calendar, weekly: Bool = false) -> CalendarSnapshot {
        if weekly {
            let grid = CalendarMath.monthGrid(for: today, calendar: calendar)
            let todayStart = calendar.startOfDay(for: today)
            let row = stride(from: 0, to: 42, by: 7).map { Array(grid[$0..<$0 + 7]) }.first { $0.contains(todayStart) } ?? []
            return CalendarSnapshot(month: today, weeks: [row], events: events, holidays: holidays, today: today, calendar: calendar, lanes: 7)
        }
        let grid = CalendarMath.monthGrid(for: month, calendar: calendar)
        let weeks = stride(from: 0, to: grid.count, by: 7).map { Array(grid[$0..<$0 + 7]) }
        return CalendarSnapshot(month: month, weeks: weeks, events: events, holidays: holidays, today: today, calendar: calendar)
    }

    var interval: DateInterval? {
        guard let f = weeks.first?.first, let l = weeks.last?.last else { return nil }
        return DateInterval(start: calendar.startOfDay(for: f), end: calendar.addingDays(1, to: l))
    }

    func inMonth(_ d: Date) -> Bool { weeks.count == 1 || calendar.isDate(d, equalTo: month, toGranularity: .month) }
}

/// 월간(또는 주간) 달력. 앱 화면과 배경화면이 같은 뷰를 쓴다 (IC-18)
/// 크기는 폭에 비례(unit = 폭 / 393)해서 어느 크기로 그려도 같은 모양이 된다
struct MonthCalendarGrid: View {
    let snapshot: CalendarSnapshot
    let style: CalendarStyle
    let width: CalendarWidth
    var showHeader = true
    /// 주어진 높이에 맞춰 행 높이와 일정 줄 수를 줄인다 (앱 화면용). nil이면 기본 크기
    var maxHeight: CGFloat? = nil
    var onTapDay: ((Date) -> Void)?

    struct CalendarWidth { let value: CGFloat; var unit: CGFloat { value / 393 } }

    private var u: CGFloat { width.unit }
    private var colW: CGFloat { width.value / 7 }
    private var numberRowH: CGFloat { 26 * u }
    private var laneH: CGFloat { 17 * u }
    private var naturalRowH: CGFloat { numberRowH + CGFloat(snapshot.lanes) * laneH + 8 * u }
    private var fixedH: CGFloat { (showHeader ? 72 * u : 0) + 16 * u + 20 * u }
    private var rowH: CGFloat {
        guard let maxHeight else { return naturalRowH }
        return max(numberRowH + laneH + 6 * u, min(naturalRowH, (maxHeight - fixedH) / CGFloat(max(1, snapshot.weeks.count))))
    }
    /// 행 높이에 들어가는 일정 줄 수
    private var lanes: Int { max(1, min(snapshot.lanes, Int((rowH - numberRowH - 6 * u) / laneH))) }

    private var ink: Color { style.onImage ? .white : Ink.ink }
    private var faint: Color { style.onImage ? .white.opacity(0.55) : Ink.faint }

    var body: some View {
        VStack(alignment: .leading, spacing: 10 * u) {
            if showHeader { header }
            weekdayRow
            VStack(spacing: 0) {
                ForEach(Array(snapshot.weeks.enumerated()), id: \.offset) { _, week in
                    weekRow(week)
                }
            }
        }
        .frame(width: width.value)
        .shadow(color: style.onImage ? .black.opacity(0.35) : .clear, radius: 2 * u, y: 0.5 * u)
    }

    // MARK: 머리글

    private var header: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(monthTitle)
                .font(.system(size: 42 * u, weight: .heavy, design: .rounded))
                .foregroundStyle(ink)
            Text(String(snapshot.calendar.component(.year, from: snapshot.month)))
                .font(.system(size: 15 * u, weight: .semibold, design: .monospaced))
                .tracking(1.5 * u)
                .foregroundStyle(faint)
        }
        .padding(.leading, 10 * u)
    }

    private var monthTitle: String {
        if snapshot.weeks.count == 1 {
            return snapshot.today.formatted(.dateTime.locale(.app).month(.wide).day())
        }
        return snapshot.month.formatted(.dateTime.locale(.app).month(.wide))
    }

    private var weekdayRow: some View {
        var cal = snapshot.calendar
        cal.locale = .app
        let symbols = cal.veryShortWeekdaySymbols
        return HStack(spacing: 0) {
            ForEach(0..<7, id: \.self) { i in
                let weekday = (i + snapshot.calendar.firstWeekday - 1) % 7 + 1
                Text(symbols[weekday - 1])
                    .font(.system(size: 11 * u, weight: .semibold, design: .monospaced))
                    .foregroundStyle(weekdayColor(weekday) ?? faint)
                    .frame(width: colW)
            }
        }
    }

    private func weekdayColor(_ weekday: Int) -> Color? {
        if weekday == 1 && style.emphasizeSunday { return Self.red }
        if weekday == 7 && style.emphasizeSaturday { return Self.blue }
        return nil
    }

    static let red = Color(hex: "F0524A")
    static let blue = Color(hex: "4C8DF6")

    // MARK: 주

    private func weekRow(_ week: [Date]) -> some View {
        let visibleEvents = style.hideAdjacentDays && snapshot.weeks.count > 1 ? clippedToMonth : snapshot.events
        let layout = CalendarMath.weekLayout(week: week, events: visibleEvents, calendar: snapshot.calendar, lanes: lanes)
        let todayStart = snapshot.calendar.startOfDay(for: snapshot.today)

        return ZStack(alignment: .topLeading) {
            // 오늘 열 강조
            if let col = week.firstIndex(of: todayStart) {
                RoundedRectangle(cornerRadius: 8 * u)
                    .fill(ink.opacity(0.08))
                    .frame(width: colW - 4 * u, height: rowH - 4 * u)
                    .offset(x: CGFloat(col) * colW + 2 * u, y: 2 * u)
            }
            Rectangle().fill(ink.opacity(0.12)).frame(height: 0.7 * u)

            // 날짜 숫자 + 넘친 일정 수
            HStack(spacing: 0) {
                ForEach(Array(week.enumerated()), id: \.offset) { i, day in
                    dayNumber(day, today: todayStart, overflow: layout.overflow[safe: i] ?? 0)
                        .frame(width: colW, height: numberRowH)
                }
            }
            .padding(.top, 3 * u)

            // 일정
            ForEach(layout.items) { item in
                itemView(item, week: week)
                    .frame(width: CGFloat(item.endCol - item.startCol + 1) * colW - 4 * u, height: laneH - 2 * u, alignment: .leading)
                    .offset(x: CGFloat(item.startCol) * colW + 2 * u, y: numberRowH + 4 * u + CGFloat(item.lane) * laneH)
                    .allowsHitTesting(false)
            }
        }
        .frame(width: width.value, height: rowH, alignment: .topLeading)
        .contentShape(Rectangle())
        .simultaneousGesture(SpatialTapGesture().onEnded { v in
            let col = min(6, max(0, Int(v.location.x / colW)))
            onTapDay?(week[col])
        })
    }

    /// 앞뒤 달 미리보기를 숨길 때: 일정을 이번 달 범위로 자른다 (FR-7.12)
    private var clippedToMonth: [DayEvent] {
        guard let m = snapshot.calendar.dateInterval(of: .month, for: snapshot.month) else { return snapshot.events }
        return snapshot.events.compactMap { e in
            let end = max(e.end, e.start.addingTimeInterval(1))
            guard e.start < m.end, end > m.start else { return nil }
            return DayEvent(eventID: e.eventID, title: e.title, start: max(e.start, m.start), end: min(e.end, m.end),
                            isAllDay: e.isAllDay, colorHex: e.colorHex, calendarID: e.calendarID)
        }
    }

    @ViewBuilder
    private func dayNumber(_ day: Date, today: Date, overflow: Int) -> some View {
        let isToday = day == today
        let adjacent = !snapshot.inMonth(day)
        let hidden = adjacent && style.hideAdjacentDays
        let n = "\(snapshot.calendar.component(.day, from: day))"
        ZStack(alignment: .topTrailing) {
            if !hidden {
                Text(n)
                    .font(.system(size: 15 * u, weight: .bold, design: .rounded))
                    .foregroundStyle(isToday ? (style.onImage ? Color.black : Ink.paper) : numberColor(day))
                    .padding(.horizontal, 5 * u)
                    .padding(.vertical, 1 * u)
                    .background {
                        if isToday {
                            RoundedRectangle(cornerRadius: 6 * u).fill(style.onImage ? Color.white : style.todayColor)
                        }
                    }
                    .opacity(adjacent ? 0.4 : 1)
                    .frame(maxWidth: .infinity)
                if overflow > 0 {
                    Text("+\(overflow)")
                        .font(.system(size: 9 * u, weight: .bold, design: .rounded))
                        .foregroundStyle(faint)
                        .padding(.trailing, 3 * u)
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(day.formatted(.dateTime.locale(.app).month().day()))
        .accessibilityAddTraits(.isButton)
    }

    private func numberColor(_ day: Date) -> Color {
        let weekday = snapshot.calendar.component(.weekday, from: day)
        if style.emphasizeHoliday && snapshot.holidays.contains(day) { return Self.red }
        return weekdayColor(weekday) ?? ink
    }

    @ViewBuilder
    private func itemView(_ item: WeekItem, week: [Date]) -> some View {
        let color = Color(hex: item.event.colorHex)
        let adjacent = !snapshot.inMonth(week[item.startCol]) && !snapshot.inMonth(week[item.endCol])
        let font = Font.system(size: 10.5 * u, weight: .semibold)
        Group {
            switch item.style {
            case .bar:
                Text(item.event.title)
                    .font(font)
                    .foregroundStyle(style.onImage ? .white : Ink.ink)
                    .lineLimit(1)
                    .padding(.horizontal, 4 * u)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                    .background {
                        UnevenRoundedRectangle(
                            topLeadingRadius: item.continuesFromPrevious ? 0 : 3 * u,
                            bottomLeadingRadius: item.continuesFromPrevious ? 0 : 3 * u,
                            bottomTrailingRadius: item.continuesToNext ? 0 : 3 * u,
                            topTrailingRadius: item.continuesToNext ? 0 : 3 * u
                        )
                        .fill(color.opacity(style.onImage ? 0.72 : 0.26))
                    }
            case .line:
                HStack(spacing: 3 * u) {
                    Capsule().fill(color).frame(width: 2.5 * u)
                    Text(item.event.title)
                        .font(font)
                        .foregroundStyle(ink)
                        .lineLimit(1)
                }
                .padding(.leading, 2 * u)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            }
        }
        .opacity(adjacent ? 0.45 : 1)
    }
}

extension Array {
    subscript(safe i: Int) -> Element? { indices.contains(i) ? self[i] : nil }
}
