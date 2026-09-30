import WidgetKit
import SwiftUI

@main
struct TallyWidgetBundle: WidgetBundle {
    var body: some Widget {
        YearProgressWidget()
    }
}

struct YearProgressWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "YearProgress", provider: MidnightProvider()) { entry in
            Text(entry.date, style: .date)
                .containerBackground(Ink.paper, for: .widget)
        }
        .configurationDisplayName("올해 진행률")
    }
}

struct DayEntry: TimelineEntry { let date: Date }

struct MidnightProvider: TimelineProvider {
    func placeholder(in context: Context) -> DayEntry { DayEntry(date: .now) }
    func getSnapshot(in context: Context, completion: @escaping (DayEntry) -> Void) { completion(DayEntry(date: .now)) }
    func getTimeline(in context: Context, completion: @escaping (Timeline<DayEntry>) -> Void) {
        let midnight = Calendar.current.startOfDay(for: .now.addingTimeInterval(86_400))
        completion(Timeline(entries: [DayEntry(date: .now)], policy: .after(midnight)))
    }
}
