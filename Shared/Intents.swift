import AppIntents
import SwiftData
import WidgetKit

// 앱과 위젯이 함께 쓰는 App Intents (IC-7)

struct HabitEntity: AppEntity, Identifiable {
    let id: String
    let name: String
    let icon: String

    static var typeDisplayRepresentation: TypeDisplayRepresentation { "습관" }
    static var defaultQuery = HabitEntityQuery()

    var displayRepresentation: DisplayRepresentation { DisplayRepresentation(title: "\(icon) \(name)") }

    init(_ h: Habit) {
        id = h.id.uuidString
        name = h.name
        icon = h.icon
    }
}

struct HabitEntityQuery: EntityQuery {
    /// 보관하지 않은 습관만 (T-5.1)
    static func all(in context: ModelContext) -> [HabitEntity] {
        HabitActions.activeHabits(in: context).map(HabitEntity.init)
    }

    @MainActor
    func entities(for identifiers: [String]) async throws -> [HabitEntity] {
        Self.all(in: ModelContext(SharedStore.container)).filter { identifiers.contains($0.id) }
    }

    @MainActor
    func suggestedEntities() async throws -> [HabitEntity] {
        Self.all(in: ModelContext(SharedStore.container))
    }
}

/// 위젯의 체크 버튼 (FR-5.2)
struct ToggleHabitIntent: AppIntent {
    static var title: LocalizedStringResource = "습관 체크"
    static var description = IntentDescription("오늘 습관을 완료로 표시하거나 취소합니다.")
    static var isDiscoverable = false

    @Parameter(title: "습관 ID")
    var habitID: String

    init() {}
    init(habitID: String) { self.habitID = habitID }

    @MainActor
    func perform() async throws -> some IntentResult {
        let context = ModelContext(SharedStore.container)
        if let habit = HabitActions.activeHabits(in: context).first(where: { $0.id.uuidString == habitID }) {
            HabitActions.toggle(habit, on: .now, in: context)
        }
        return .result()
    }
}

/// 잔디 위젯 설정: 습관 하나 또는 전체 (FR-5.3)
struct ContributionConfigIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "잔디 설정"
    static var description = IntentDescription("표시할 습관을 고르세요. 비워 두면 전체를 보여 줍니다.")

    @Parameter(title: "습관")
    var habit: HabitEntity?
}
