import EventKit
import SwiftUI

// MARK: - 날짜별 일정 (FR-7.3)

struct DayEventsSheet: View {
    let day: Date
    let onEdit: (EditorTarget) -> Void
    @Environment(CalendarStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        let cal = Calendar.current
        let interval = DateInterval(start: cal.startOfDay(for: day), end: cal.addingDays(1, to: day))
        let events = CalendarMath.sorted(store.events(in: interval).filter {
            !CalendarMath.events(on: day, from: [$0], calendar: cal).isEmpty
        })
        let _ = store.revision
        NavigationStack {
            List {
                if events.isEmpty {
                    Text("일정이 없어요").foregroundStyle(Ink.faint).listRowBackground(Ink.card)
                }
                ForEach(events) { e in
                    Button { onEdit(EditorTarget(eventID: e.eventID)) } label: { EventRow(event: e, day: day) }
                        .listRowBackground(Ink.card)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Ink.paper)
            .navigationTitle(day.formatted(.dateTime.locale(.app).month().day().weekday(.wide)))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("닫기") { dismiss() } }
                ToolbarItem(placement: .primaryAction) {
                    Button { onEdit(EditorTarget(start: day)) } label: { Image(systemName: "plus") }
                        .accessibilityLabel("이 날에 일정 추가")
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

struct EventRow: View {
    let event: DayEvent
    var day: Date?

    var body: some View {
        HStack(spacing: 10) {
            Capsule().fill(Color(hex: event.colorHex)).frame(width: 4, height: 34)
            VStack(alignment: .leading, spacing: 2) {
                Text(event.title).font(.headline).foregroundStyle(Ink.ink).lineLimit(2)
                Text(timeText).font(.label).foregroundStyle(Ink.faint)
            }
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
    }

    private var timeText: String {
        if event.isAllDay { return String(localized: "종일") }
        let t = Date.FormatStyle.dateTime.locale(.app).hour().minute()
        return "\(event.start.formatted(t)) – \(event.end.formatted(t))"
    }
}

// MARK: - 다가오는 일정 (FR-7.14 왼쪽 위 버튼)

struct AgendaSheet: View {
    let onEdit: (EditorTarget) -> Void
    @Environment(CalendarStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        let cal = Calendar.current
        let start = cal.startOfDay(for: .now)
        let events = CalendarMath.sorted(store.events(in: DateInterval(start: start, end: cal.addingDays(30, to: start))))
        let days = Array(Set(events.map { max(cal.startOfDay(for: $0.start), start) })).sorted()
        let _ = store.revision
        NavigationStack {
            List {
                if events.isEmpty {
                    Text("앞으로 30일 동안 일정이 없어요").foregroundStyle(Ink.faint).listRowBackground(Ink.card)
                }
                ForEach(days, id: \.self) { d in
                    Section(d.formatted(.dateTime.locale(.app).month().day().weekday()) + " · " + DDayMath.label(d, now: .now, calendar: cal)) {
                        ForEach(events.filter { max(cal.startOfDay(for: $0.start), start) == d }) { e in
                            Button { onEdit(EditorTarget(eventID: e.eventID)) } label: { EventRow(event: e) }
                                .listRowBackground(Ink.card)
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Ink.paper)
            .navigationTitle("다가오는 일정")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("닫기") { dismiss() } } }
        }
    }
}

// MARK: - 캘린더 선택 (FR-7.6)

struct CalendarPickerSheet: View {
    @Environment(CalendarStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var showAdd = false

    var body: some View {
        let _ = store.revision
        NavigationStack {
            List {
                ForEach(store.groupedCalendars, id: \.source) { group in
                    Section(group.source) {
                        ForEach(group.calendars, id: \.calendarIdentifier) { c in
                            let on = !store.hiddenIDs.contains(c.calendarIdentifier)
                            Button { store.toggle(c) } label: {
                                HStack(spacing: 12) {
                                    ZStack {
                                        Circle().fill(Color(cgColor: c.cgColor).opacity(on ? 1 : 0.25))
                                        if on { Image(systemName: "checkmark").font(.caption.weight(.black)).foregroundStyle(.white) }
                                    }
                                    .frame(width: 24, height: 24)
                                    VStack(alignment: .leading, spacing: 1) {
                                        Text(c.title).foregroundStyle(Ink.ink)
                                        if let sub = subtitle(c) { Text(sub).font(.caption).foregroundStyle(Ink.faint) }
                                    }
                                }
                            }
                            .listRowBackground(Ink.card)
                            .accessibilityValue(on ? "표시" : "숨김")
                        }
                    }
                }
                Section {
                    Button { showAdd = true } label: { Label("캘린더 추가", systemImage: "calendar.badge.plus") }
                        .listRowBackground(Ink.card)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Ink.paper)
            .navigationTitle("캘린더")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("완료") { dismiss() } } }
            .sheet(isPresented: $showAdd) { AddCalendarSheet() }
        }
    }

    private func subtitle(_ c: EKCalendar) -> String? {
        if c.type == .subscription { return String(localized: "구독") }
        if c.type == .birthday { return String(localized: "생일") }
        if !c.allowsContentModifications { return String(localized: "읽기 전용") }
        return nil
    }
}

struct AddCalendarSheet: View {
    @Environment(CalendarStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var hex = HabitPalette.hexes[1]
    @State private var error: String?

    var body: some View {
        NavigationStack {
            Form {
                TextField("이름", text: $title)
                HStack {
                    ForEach(HabitPalette.hexes, id: \.self) { h in
                        Button { hex = h } label: {
                            Circle().fill(Color(hex: h)).frame(width: 28, height: 28)
                                .overlay(Circle().strokeBorder(Ink.ink, lineWidth: hex == h ? 2.5 : 0).padding(-4))
                        }
                        .buttonStyle(.plain).frame(maxWidth: .infinity)
                    }
                }
                if let error { Text(error).font(.footnote).foregroundStyle(.red) }
            }
            .scrollContentBackground(.hidden)
            .background(Ink.paper)
            .navigationTitle("캘린더 추가")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("취소") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("저장") {
                        do { try store.addCalendar(title: title, colorHex: hex); dismiss() }
                        catch { self.error = String(localized: "캘린더를 만들 수 없어요: \(error.localizedDescription)") }
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }
}
