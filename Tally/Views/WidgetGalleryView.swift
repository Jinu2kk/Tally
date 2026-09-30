#if DEBUG
import SwiftUI
import WidgetKit

/// 디버그 전용: 실행 인자 `-widgetGallery YES`로 위젯 화면을 실제 크기로 미리 본다
struct WidgetGalleryView: View {
    @State private var entry = TallyEntry.load()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top, spacing: 16) {
                    frame(158, 158) { YearWidgetView(entry: entry, familyOverride: .systemSmall) }
                    frame(158, 158) { MementoWidgetView(entry: entry, familyOverride: .systemSmall) }
                }
                frame(338, 158) { HabitsWidgetView(entry: entry, familyOverride: .systemMedium) }
                frame(338, 158) { ContributionWidgetView(entry: entry) }
                frame(338, 158) { YearWidgetView(entry: entry, familyOverride: .systemMedium) }
                frame(338, 354) { HabitsWidgetView(entry: entry, familyOverride: .systemLarge) }
            }
            .padding()
        }
        .background(Color.gray.opacity(0.35))
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in entry = .load() }
    }

    private func frame<V: View>(_ w: CGFloat, _ h: CGFloat, @ViewBuilder _ v: () -> V) -> some View {
        v().padding(16)
            .frame(width: w, height: h)
            .background(Ink.paper)
            .clipShape(RoundedRectangle(cornerRadius: 22))
    }
}
#endif
