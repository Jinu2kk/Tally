import Foundation
import SwiftData
import WidgetKit

/// 앱과 위젯이 함께 쓰는 습관 토글 로직 (IC-6, IC-7)
enum HabitActions {
    static func isDone(_ habit: Habit, on day: Date, calendar: Calendar = .current) -> Bool {
        let d = calendar.startOfDay(for: day)
        return (habit.logs ?? []).contains { $0.day == d }
    }

    /// 완료 ↔ 취소. 결과가 완료 상태면 true
    @discardableResult
    static func toggle(_ habit: Habit, on day: Date, in context: ModelContext, calendar: Calendar = .current) -> Bool {
        let d = calendar.startOfDay(for: day)
        let existing = (habit.logs ?? []).filter { $0.day == d }
        if existing.isEmpty {
            let log = HabitLog(day: d, habit: habit)
            context.insert(log)
            habit.logs = (habit.logs ?? []) + [log]
        } else {
            habit.logs = (habit.logs ?? []).filter { $0.day != d }
            existing.forEach { context.delete($0) }
        }
        try? context.save()
        WidgetCenter.shared.reloadAllTimelines()
        return existing.isEmpty
    }

    static func activeHabits(in context: ModelContext) -> [Habit] {
        let descriptor = FetchDescriptor<Habit>(
            predicate: #Predicate { !$0.isArchived },
            sortBy: [SortDescriptor(\.sortOrder), SortDescriptor(\.createdAt)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }
}
