import SwiftUI
import SwiftData
import WidgetKit

// 위젯 화면. 앱의 디버그 미리보기에서도 쓰기 위해 Shared에 둔다

// MARK: - 공통 스냅샷

/// 위젯 한 장에 필요한 데이터. 자정마다 새로 만든다 (FR-5.5)
struct TallyEntry: TimelineEntry {
    let date: Date
    let tintHex: String
    let habits: [HabitSnapshot]
    let doneToday: Set<UUID>
    let birth: Date?
    let expectancy: Int
    let mondayFirst: Bool
    var focusID: UUID?

    var tint: Color { Color(hex: tintHex) }
    var calendar: Calendar { AppSettings.calendar(mondayFirst: mondayFirst) }

    static func load(at date: Date = .now, focus: String? = nil) -> TallyEntry {
        let context = ModelContext(SharedStore.container)
        let habits = HabitActions.activeHabits(in: context)
        let today = Calendar.current.startOfDay(for: date)
        return TallyEntry(
            date: date,
            tintHex: AppSettings.tint.hex,
            habits: habits.map(HabitSnapshot.init),
            doneToday: Set(habits.filter { $0.doneDays.contains(today) }.map(\.id)),
            birth: AppSettings.birthDate,
            expectancy: AppSettings.lifeExpectancy,
            mondayFirst: AppSettings.weekStartsOnMonday,
            focusID: focus.flatMap(UUID.init(uuidString:))
        )
    }

    static let sample = TallyEntry(
        date: .now, tintHex: ThemeTint.tomato.hex,
        habits: [], doneToday: [], birth: Calendar.current.date(byAdding: .year, value: -30, to: .now),
        expectancy: 80, mondayFirst: false
    )

    static var nextMidnight: Date {
        Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: 1, to: .now) ?? .now)
    }
}

extension View {
    func paperBackground() -> some View { containerBackground(Ink.paper, for: .widget) }
}

// MARK: - 1. 오늘의 습관 (FR-5.2)
struct HabitsWidgetView: View {
    @Environment(\.widgetFamily) private var envFamily
    let entry: TallyEntry
    /// 앱 안 미리보기에서 크기를 지정할 때
    var familyOverride: WidgetFamily?
    private var family: WidgetFamily { familyOverride ?? envFamily }

    var body: some View {
        let limit = family == .systemLarge ? 7 : 3
        let shown = Array(entry.habits.prefix(limit))
        VStack(alignment: .leading, spacing: family == .systemLarge ? 10 : 6) {
            HStack(alignment: .firstTextBaseline) {
                Text("오늘").font(.label).tracking(1.2).foregroundStyle(Ink.faint)
                Spacer()
                Text("\(entry.doneToday.count)").font(.number(20)).foregroundStyle(Ink.ink)
                    + Text(" / \(entry.habits.count)").font(.number(13)).foregroundStyle(Ink.faint)
            }
            if shown.isEmpty {
                Spacer()
                Text("앱에서 습관을 추가하세요").font(.footnote).foregroundStyle(Ink.faint)
                    .frame(maxWidth: .infinity)
                Spacer()
            } else {
                ForEach(shown) { h in
                    let done = entry.doneToday.contains(h.id)
                    Button(intent: ToggleHabitIntent(habitID: h.id.uuidString)) {
                        HStack(spacing: 10) {
                            Text(h.icon).font(.system(size: 17))
                                .frame(width: 30, height: 30)
                                .background(Circle().fill(h.color.opacity(0.18)))
                            Text(h.name)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(done ? Ink.faint : Ink.ink)
                                .strikethrough(done)
                                .lineLimit(1)
                            Spacer(minLength: 4)
                            ZStack {
                                Circle().strokeBorder(Ink.ink, lineWidth: 1.4)
                                if done {
                                    Circle().fill(h.color)
                                    Image(systemName: "checkmark").font(.system(size: 11, weight: .black)).foregroundStyle(.white)
                                }
                            }
                            .frame(width: 24, height: 24)
                        }
                    }
                    .buttonStyle(.plain)
                }
                if entry.habits.count > shown.count {
                    Text("+\(entry.habits.count - shown.count)개 더").font(.caption2).foregroundStyle(Ink.faint)
                }
                Spacer(minLength: 0)
            }
        }
        .paperBackground()
    }
}

// MARK: - 2. 올해 진행률 (FR-5.1)
struct YearWidgetView: View {
    @Environment(\.widgetFamily) private var envFamily
    let entry: TallyEntry
    /// 앱 안 미리보기에서 크기를 지정할 때
    var familyOverride: WidgetFamily?
    private var family: WidgetFamily { familyOverride ?? envFamily }

    var body: some View {
        let y = YearProgress(now: entry.date, calendar: entry.calendar)
        switch family {
        case .accessoryCircular:
            Gauge(value: y.fraction) { Text(String(y.year)) } currentValueLabel: { Text("\(y.percent)") }
                .gaugeStyle(.accessoryCircularCapacity)
                .containerBackground(.clear, for: .widget)
        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 2) {
                Text("\(String(y.year)) · \(y.percent)%").font(.headline)
                ProgressView(value: y.fraction)
                Text("남은 \(y.daysLeft)일").font(.caption)
            }
            .containerBackground(.clear, for: .widget)
        case .systemMedium:
            HStack(spacing: 14) {
                numbers(y)
                grid(y, columns: 28)
            }
            .paperBackground()
        default:
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline) {
                    Text("\(y.percent)").font(.number(30)) + Text("%").font(.number(14)).foregroundStyle(Ink.faint)
                    Spacer()
                    Text(String(y.year)).font(.label).foregroundStyle(Ink.faint)
                }
                .foregroundStyle(Ink.ink)
                grid(y, columns: 19)
            }
            .paperBackground()
        }
    }

    private func numbers(_ y: YearProgress) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(String(y.year)).font(.label).foregroundStyle(Ink.faint)
            Text("\(y.percent)%").font(.number(32)).foregroundStyle(Ink.ink)
            Spacer()
            Text("\(y.daysLeft)").font(.number(20)).foregroundStyle(entry.tint)
            Text("일 남음").font(.label).foregroundStyle(Ink.faint)
        }
    }

    private func grid(_ y: YearProgress, columns: Int) -> some View {
        DotCanvas(count: y.daysInYear, columns: columns, spacingRatio: 0.3, tint: entry.tint) { i in
            i < y.dayOfYear - 1 ? .filled : (i == y.dayOfYear - 1 ? .today : .empty)
        }
    }
}

// MARK: - 3. 잔디 (FR-5.3)
struct ContributionWidgetView: View {
    let entry: TallyEntry

    var body: some View {
        let focus = entry.habits.first { $0.id == entry.focusID }
        let scope = focus.map { [$0] } ?? entry.habits
        let tint = focus?.color ?? entry.tint
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(focus.map { "\($0.icon) \($0.name)" } ?? String(localized: "전체 습관"))
                    .font(.caption.weight(.bold)).foregroundStyle(Ink.ink).lineLimit(1)
                Spacer()
                if let f = focus {
                    Text("연속 \(Streaks.current(f.done, today: entry.date, calendar: entry.calendar))일")
                        .font(.label).foregroundStyle(Ink.faint)
                }
            }
            ContributionGraph(source: ContributionSource(habits: scope, calendar: entry.calendar),
                              weeks: 21, today: entry.date, tint: tint, dot: 11, gap: 3, showMonths: false)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .paperBackground()
    }
}

// MARK: - 4. Memento Mori (FR-5.4)
struct MementoWidgetView: View {
    @Environment(\.widgetFamily) private var envFamily
    let entry: TallyEntry
    /// 앱 안 미리보기에서 크기를 지정할 때
    var familyOverride: WidgetFamily?
    private var family: WidgetFamily { familyOverride ?? envFamily }

    var body: some View {
        if let birth = entry.birth {
            let l = LifeProgress(birth: birth, expectancy: entry.expectancy, now: entry.date, calendar: entry.calendar)
            if family == .accessoryRectangular {
                VStack(alignment: .leading, spacing: 2) {
                    Text("MEMENTO MORI").font(.caption2.weight(.bold))
                    Text("남은 \(l.weeksLeft.formatted())주").font(.headline)
                    ProgressView(value: l.fraction)
                }
                .containerBackground(.clear, for: .widget)
            } else {
                let years = entry.expectancy
                let lived = min(years, l.livedWeeks / LifeProgress.weeksPerYear)
                VStack(alignment: .leading, spacing: 6) {
                    Text("MEMENTO MORI").font(.label).tracking(1).foregroundStyle(Ink.faint)
                    Text(l.weeksLeft.formatted()).font(.number(28)).foregroundStyle(entry.tint)
                        .minimumScaleFactor(0.6).lineLimit(1)
                    Text("주 남음").font(.label).foregroundStyle(Ink.faint)
                    Spacer(minLength: 0)
                    // 점 하나 = 1년
                    DotCanvas(count: years, columns: 10, spacingRatio: 0.4, tint: entry.tint) { i in
                        i < lived ? .filled : (i == lived ? .today : .empty)
                    }
                }
                .paperBackground()
            }
        } else {
            Text("앱에서 생년월일을 입력하세요")
                .font(.caption).foregroundStyle(Ink.faint)
                .paperBackground()
        }
    }
}
