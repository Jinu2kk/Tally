import WidgetKit
import SwiftUI
import SwiftData

@main
struct TallyWidgetBundle: WidgetBundle {
    var body: some Widget {
        HabitsWidget()
        YearProgressWidget()
        ContributionWidget()
        MementoWidget()
    }
}

struct TallyProvider: TimelineProvider {
    func placeholder(in context: Context) -> TallyEntry { .sample }
    func getSnapshot(in context: Context, completion: @escaping (TallyEntry) -> Void) {
        completion(context.isPreview ? .sample : .load())
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<TallyEntry>) -> Void) {
        completion(Timeline(entries: [.load()], policy: .after(TallyEntry.nextMidnight)))
    }
}

struct ContributionProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> TallyEntry { .sample }
    func snapshot(for configuration: ContributionConfigIntent, in context: Context) async -> TallyEntry {
        .load(focus: configuration.habit?.id)
    }
    func timeline(for configuration: ContributionConfigIntent, in context: Context) async -> Timeline<TallyEntry> {
        Timeline(entries: [.load(focus: configuration.habit?.id)], policy: .after(TallyEntry.nextMidnight))
    }
}

// MARK: - 1. 오늘의 습관 (FR-5.2)

struct HabitsWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "Habits", provider: TallyProvider()) { HabitsWidgetView(entry: $0) }
            .configurationDisplayName("오늘의 습관")
            .description("위젯에서 바로 체크하세요.")
            .supportedFamilies([.systemMedium, .systemLarge])
    }
}

// MARK: - 2. 올해 진행률 (FR-5.1)

struct YearProgressWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "YearProgress", provider: TallyProvider()) { YearWidgetView(entry: $0) }
            .configurationDisplayName("올해 진행률")
            .description("올해가 얼마나 지났는지 점으로 보여 줍니다.")
            .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular, .accessoryRectangular])
    }
}

// MARK: - 3. 잔디 (FR-5.3)

struct ContributionWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: "Contribution", intent: ContributionConfigIntent.self, provider: ContributionProvider()) {
            ContributionWidgetView(entry: $0)
        }
        .configurationDisplayName("잔디")
        .description("최근 기록을 잔디로 보여 줍니다. 길게 눌러 습관을 고를 수 있어요.")
        .supportedFamilies([.systemMedium])
    }
}

// MARK: - 4. Memento Mori (FR-5.4)

struct MementoWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "Memento", provider: TallyProvider()) { MementoWidgetView(entry: $0) }
            .configurationDisplayName("Memento Mori")
            .description("살아온 주와 남은 주")
            .supportedFamilies([.systemSmall, .accessoryRectangular])
    }
}

