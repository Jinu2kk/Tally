import EventKit
import EventKitUI
import SwiftUI

/// 시스템 일정 편집기 (IC-13). 새 일정이면 event를 nil로
struct EventEditor: UIViewControllerRepresentable {
    let store: EKEventStore
    var event: EKEvent?
    var start: Date?
    let onDone: () -> Void

    func makeUIViewController(context: Context) -> EKEventEditViewController {
        let vc = EKEventEditViewController()
        vc.eventStore = store
        if let event {
            vc.event = event
        } else {
            let e = EKEvent(eventStore: store)
            let base = start ?? .now
            let cal = Calendar.current
            // 오늘이면 다음 정각, 다른 날이면 오전 9시
            let begin = cal.isDateInToday(base)
                ? cal.nextDate(after: .now, matching: DateComponents(minute: 0), matchingPolicy: .nextTime) ?? .now
                : cal.date(bySettingHour: 9, minute: 0, second: 0, of: base) ?? base
            e.startDate = begin
            e.endDate = begin.addingTimeInterval(3600)
            e.calendar = store.defaultCalendarForNewEvents
            vc.event = e
        }
        vc.editViewDelegate = context.coordinator
        return vc
    }

    func updateUIViewController(_ vc: EKEventEditViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onDone: onDone) }

    final class Coordinator: NSObject, EKEventEditViewDelegate {
        let onDone: () -> Void
        init(onDone: @escaping () -> Void) { self.onDone = onDone }
        func eventEditViewController(_ controller: EKEventEditViewController, didCompleteWith action: EKEventEditViewAction) {
            onDone()
        }
    }
}

/// 편집기에 넘길 대상 (sheet(item:)용)
struct EditorTarget: Identifiable {
    let id = UUID()
    var eventID: String?
    var start: Date?
}
