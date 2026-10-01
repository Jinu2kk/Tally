#if DEBUG
import EventKit
import UIKit

/// 디버그 전용: 실행 인자 `-seedEvents YES`면 시뮬레이터 기본 캘린더에 예시 캘린더·일정을 만든다.
/// 이미 만든 데모 캘린더('Tally 데모 · …')는 지우고 다시 만든다. 다른 캘린더는 건드리지 않는다
enum DemoEvents {
    @MainActor
    static func runIfRequested() async {
        guard UserDefaults.standard.bool(forKey: "seedEvents") else { return }
        let cs = CalendarStore.shared
        if !cs.hasAccess { await cs.requestAccess() }
        guard cs.hasAccess else { return }
        let store = cs.eventStore
        guard let source = store.sources.first(where: { $0.sourceType == .local })
                ?? store.defaultCalendarForNewEvents?.source else { return }

        for c in store.calendars(for: .event) where c.title.hasPrefix("Tally 데모") {
            try? store.removeCalendar(c, commit: true)
        }
        func makeCalendar(_ title: String, _ hex: UInt32) -> EKCalendar {
            let c = EKCalendar(for: .event, eventStore: store)
            c.title = title
            c.source = source
            c.cgColor = UIColor(red: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255,
                                blue: CGFloat(hex & 0xFF) / 255, alpha: 1).cgColor
            try? store.saveCalendar(c, commit: true)
            return c
        }
        let holiday = makeCalendar("Tally 데모 · 대한민국 공휴일", 0x1F8A5B)
        let work = makeCalendar("Tally 데모 · 직장", 0xC77A2B)
        let home = makeCalendar("Tally 데모 · 집", 0x3A86C8)

        let cal = Calendar.current
        let monthStart = cal.dateInterval(of: .month, for: .now)!.start
        func day(_ offset: Int, _ hour: Int = 0) -> Date { cal.date(byAdding: .hour, value: hour, to: cal.addingDays(offset, to: monthStart))! }
        func add(_ title: String, _ c: EKCalendar, _ start: Date, _ end: Date, allDay: Bool = false, weekly: Bool = false) {
            let e = EKEvent(eventStore: store)
            e.title = title; e.calendar = c; e.startDate = start; e.endDate = end; e.isAllDay = allDay
            if weekly { e.addRecurrenceRule(EKRecurrenceRule(recurrenceWith: .weekly, interval: 1, end: EKRecurrenceEnd(occurrenceCount: 9))) }
            try? store.save(e, span: .thisEvent, commit: false)
        }
        add("국군의날", holiday, day(0), day(1), allDay: true)
        add("개천절", holiday, day(2), day(3), allDay: true)
        add("한글날", holiday, day(8), day(9), allDay: true)
        add("대체공휴일", holiday, day(4), day(5), allDay: true)
        // 주간 반복 시간 일정
        let firstTue = (0..<7).first { cal.component(.weekday, from: day($0)) == 3 }!
        add("프론트 주간회의", work, day(firstTue, 10), day(firstTue, 11), weekly: true)
        add("정기배포", work, day(firstTue + 1, 15), day(firstTue + 1, 16), weekly: true)
        // 여러 날 막대
        add("마이페이지 개편-LNB 포함", work, day(22), day(36), allDay: true)
        add("가족 여행", home, day(16), day(19), allDay: true)
        add("치과", home, day(13, 18), day(13, 19))
        add("저녁 약속", home, day(13, 19), day(13, 21))
        add("헬스", home, day(13, 7), day(13, 8))
        add("책 반납", home, day(13, 12), day(13, 13))
        add("스터디", home, day(13, 21), day(13, 22))
        try? store.commit()
        cs.reload()
    }
}
#endif
