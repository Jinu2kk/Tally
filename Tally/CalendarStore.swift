import EventKit
import SwiftUI

/// 기본 캘린더(EventKit) 연동 (DC-6, FR-7.1, 7.4, 7.6, 7.9). 일정은 Tally에 복사하지 않는다 (NFR-6)
@Observable
@MainActor
final class CalendarStore {
    static let shared = CalendarStore()

    let eventStore = EKEventStore()
    private(set) var status: EKAuthorizationStatus = EKEventStore.authorizationStatus(for: .event)
    private(set) var calendars: [EKCalendar] = []
    /// 일정이 바뀔 때마다 올라가는 값. 화면은 이 값으로 다시 읽는다 (FR-7.9)
    private(set) var revision = 0

    var hiddenIDs: Set<String> {
        get { Set(AppSettings.store.stringArray(forKey: SettingsKey.hiddenCalendars) ?? []) }
        set {
            AppSettings.store.set(Array(newValue), forKey: SettingsKey.hiddenCalendars)
            revision += 1
        }
    }

    var hasAccess: Bool { status == .fullAccess }

    private init() {
        NotificationCenter.default.addObserver(forName: .EKEventStoreChanged, object: eventStore, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.reload() }
        }
        if hasAccess { reload() }
    }

    func requestAccess() async {
        _ = try? await eventStore.requestFullAccessToEvents()
        status = EKEventStore.authorizationStatus(for: .event)
        reload()
    }

    func reload() {
        status = EKEventStore.authorizationStatus(for: .event)
        guard hasAccess else { calendars = []; return }
        eventStore.refreshSourcesIfNecessary()
        calendars = eventStore.calendars(for: .event)
        revision += 1
    }

    // MARK: 조회

    var visibleCalendars: [EKCalendar] { calendars.filter { !hiddenIDs.contains($0.calendarIdentifier) } }

    var holidayCalendarIDs: Set<String> {
        Set(calendars.filter { CalendarMath.isHolidayCalendar(title: $0.title) }.map(\.calendarIdentifier))
    }

    func events(in interval: DateInterval) -> [DayEvent] {
        let visible = visibleCalendars
        guard hasAccess, !visible.isEmpty else { return [] }
        let predicate = eventStore.predicateForEvents(withStart: interval.start, end: interval.end, calendars: visible)
        return eventStore.events(matching: predicate).map(DayEvent.init)
    }

    func event(id: String) -> EKEvent? { eventStore.event(withIdentifier: id) }

    /// 계정(소스)별로 묶은 캘린더 (FR-7.6)
    var groupedCalendars: [(source: String, calendars: [EKCalendar])] {
        let groups = Dictionary(grouping: calendars) { $0.source.title }
        return groups.keys.sorted(by: Self.sourceOrder).map { key in
            (key, groups[key]!.sorted { $0.title.localizedStandardCompare($1.title) == .orderedAscending })
        }
    }

    private static func sourceOrder(_ a: String, _ b: String) -> Bool {
        // 계정 → iCloud → 기타(구독·생일)
        func rank(_ s: String) -> Int {
            switch s.lowercased() {
            case "icloud": 1
            case "other", "기타", "subscribed calendars", "구독한 캘린더", "birthdays": 2
            default: 0
            }
        }
        return (rank(a), a) < (rank(b), b)
    }

    func toggle(_ calendar: EKCalendar) {
        var h = hiddenIDs
        if h.contains(calendar.calendarIdentifier) { h.remove(calendar.calendarIdentifier) } else { h.insert(calendar.calendarIdentifier) }
        hiddenIDs = h
    }

    // MARK: 쓰기

    /// 새 캘린더 (FR-7.6 캘린더 추가). 기본 일정 캘린더와 같은 계정에 만든다
    func addCalendar(title: String, colorHex: String) throws {
        let cal = EKCalendar(for: .event, eventStore: eventStore)
        cal.title = title
        cal.cgColor = UIColor(Color(hex: colorHex)).cgColor
        guard let source = eventStore.defaultCalendarForNewEvents?.source
                ?? eventStore.sources.first(where: { $0.sourceType == .local }) else {
            throw CocoaError(.featureUnsupported)
        }
        cal.source = source
        try eventStore.saveCalendar(cal, commit: true)
        reload()
    }
}

extension DayEvent {
    init(_ e: EKEvent) {
        self.init(eventID: e.eventIdentifier ?? UUID().uuidString,
                  title: e.title?.isEmpty == false ? e.title! : String(localized: "(제목 없음)"),
                  start: e.startDate, end: e.endDate, isAllDay: e.isAllDay,
                  colorHex: e.calendar.map { Self.hex($0.cgColor) } ?? "8E8E93",
                  calendarID: e.calendar?.calendarIdentifier ?? "")
    }

    static func hex(_ c: CGColor?) -> String {
        guard let c, let rgb = c.converted(to: CGColorSpace(name: CGColorSpace.sRGB)!, intent: .defaultIntent, options: nil),
              let comps = rgb.components, comps.count >= 3 else { return "8E8E93" }
        return String(format: "%02X%02X%02X", Int(comps[0] * 255), Int(comps[1] * 255), Int(comps[2] * 255))
    }
}
