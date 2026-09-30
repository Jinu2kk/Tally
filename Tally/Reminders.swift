import Foundation
import UserNotifications

/// 습관 리마인더 로컬 알림 (FR-1.6). 식별자: habit-<uuid>
enum Reminders {
    private static var center: UNUserNotificationCenter { .current() }

    static func identifier(for habit: Habit) -> String { "habit-\(habit.id.uuidString)" }

    /// 권한이 없으면 요청한다. 허용되면 true
    static func requestAuthorization() async -> Bool {
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral: return true
        case .denied: return false
        default: return (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        }
    }

    static func authorizationStatus() async -> UNAuthorizationStatus {
        await center.notificationSettings().authorizationStatus
    }

    /// 습관 상태에 맞춰 알림을 다시 건다. 보관됐거나 시각이 없으면 제거만 한다
    static func sync(_ habit: Habit) {
        let id = identifier(for: habit)
        center.removePendingNotificationRequests(withIdentifiers: [id])
        guard !habit.isArchived, let hour = habit.reminderHour, let minute = habit.reminderMinute else { return }

        let content = UNMutableNotificationContent()
        content.title = "\(habit.icon) \(habit.name)"
        content.body = String(localized: "오늘 기록할 시간이에요.")
        content.sound = .default
        let trigger = UNCalendarNotificationTrigger(dateMatching: DateComponents(hour: hour, minute: minute), repeats: true)
        center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
    }

    static func cancel(_ habit: Habit) {
        center.removePendingNotificationRequests(withIdentifiers: [identifier(for: habit)])
    }

    static func cancelAll() {
        center.removeAllPendingNotificationRequests()
    }
}
