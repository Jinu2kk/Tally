import Foundation
import SwiftData

// 모든 속성은 기본값 또는 옵셔널, unique 제약 없음 — 추후 CloudKit 동기화를 켤 수 있게 (DESIGN §4)

@Model
final class Habit {
    var id: UUID = UUID()
    var name: String = ""
    var icon: String = "✏️"
    var colorHex: String = "E4572E"
    var targetMinutes: Int? = nil
    var reminderHour: Int? = nil
    var reminderMinute: Int? = nil
    var sortOrder: Int = 0
    var isArchived: Bool = false
    var createdAt: Date = Date()
    @Relationship(deleteRule: .cascade, inverse: \HabitLog.habit)
    var logs: [HabitLog]? = []

    init(name: String, icon: String, colorHex: String, sortOrder: Int, createdAt: Date = .now) {
        self.name = name
        self.icon = icon
        self.colorHex = colorHex
        self.sortOrder = sortOrder
        self.createdAt = createdAt
    }

    var hasReminder: Bool { reminderHour != nil && reminderMinute != nil }

    /// 완료한 날짜(자정 기준) 집합
    var doneDays: Set<Date> { Set((logs ?? []).map(\.day)) }
}

@Model
final class HabitLog {
    /// 해당 날짜의 00:00 (Calendar.startOfDay) — IC-6
    var day: Date = Date()
    var habit: Habit?

    init(day: Date, habit: Habit) {
        self.day = day
        self.habit = habit
    }
}

enum Quadrant: Int, CaseIterable, Identifiable, Codable {
    case doFirst = 0, schedule, delegate, eliminate

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .doFirst: String(localized: "지금 하기")
        case .schedule: String(localized: "일정 잡기")
        case .delegate: String(localized: "위임하기")
        case .eliminate: String(localized: "버리기")
        }
    }

    var subtitle: String {
        switch self {
        case .doFirst: String(localized: "긴급 · 중요")
        case .schedule: String(localized: "중요 · 긴급하지 않음")
        case .delegate: String(localized: "긴급 · 중요하지 않음")
        case .eliminate: String(localized: "긴급하지도 중요하지도 않음")
        }
    }

    var code: String {
        switch self {
        case .doFirst: "Q1"
        case .schedule: "Q2"
        case .delegate: "Q3"
        case .eliminate: "Q4"
        }
    }
}

@Model
final class TaskItem {
    var id: UUID = UUID()
    var title: String = ""
    var note: String = ""
    var quadrantRaw: Int = 0
    var isDone: Bool = false
    var dueDate: Date? = nil
    var createdAt: Date = Date()
    var sortOrder: Int = 0

    init(title: String, note: String = "", quadrant: Quadrant, dueDate: Date? = nil, sortOrder: Int = 0) {
        self.title = title
        self.note = note
        self.quadrantRaw = quadrant.rawValue
        self.dueDate = dueDate
        self.sortOrder = sortOrder
    }

    var quadrant: Quadrant {
        get { Quadrant(rawValue: quadrantRaw) ?? .doFirst }
        set { quadrantRaw = newValue.rawValue }
    }
}

@Model
final class DDay {
    var id: UUID = UUID()
    var title: String = ""
    var date: Date = Date()
    var createdAt: Date = Date()

    init(title: String, date: Date) {
        self.title = title
        self.date = date
    }
}
