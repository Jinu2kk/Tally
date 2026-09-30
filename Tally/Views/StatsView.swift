import SwiftUI
import SwiftData

/// 탭 「기록」 — 잔디, 요약, 월별 달성률 (FR-4)
struct StatsView: View {
    @Query(filter: #Predicate<Habit> { !$0.isArchived },
           sort: [SortDescriptor(\Habit.sortOrder), SortDescriptor(\Habit.createdAt)])
    private var habits: [Habit]
    @AppStorage(SettingsKey.weekStartsOnMonday, store: AppSettings.store) private var mondayFirst = false
    @AppStorage(SettingsKey.tint, store: AppSettings.store) private var tintRaw = ThemeTint.tomato.rawValue

    /// nil = 전체
    @State private var selectedID: UUID?
    @State private var month = Date.now

    private var calendar: Calendar { AppSettings.calendar(mondayFirst: mondayFirst) }

    var body: some View {
        let all = habits.map(HabitSnapshot.init)
        let selected = all.first { $0.id == selectedID }
        let scope = selected.map { [$0] } ?? all
        let tint = selected?.color ?? (ThemeTint(rawValue: tintRaw) ?? .tomato).color
        let source = ContributionSource(habits: scope, calendar: calendar)

        PaperScreen(String(localized: "기록"), subtitle: String(localized: "쌓인 점을 돌아보기")) {
            EmptyView()
        } content: {
            if all.isEmpty {
                Text("습관을 추가하고 체크하면 여기에 기록이 쌓여요.")
                    .font(.subheadline).foregroundStyle(Ink.faint)
                    .inkCard(padding: 18)
            } else {
                picker(all)
                summary(scope)
                graphCard(source: source, tint: tint)
                MonthCard(month: $month, scope: scope, source: source, tint: tint, calendar: calendar)
            }
        }
    }

    private func picker(_ all: [HabitSnapshot]) -> some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                chip(title: String(localized: "전체"), icon: nil, isOn: selectedID == nil) { selectedID = nil }
                ForEach(all) { h in
                    chip(title: h.name, icon: h.icon, isOn: selectedID == h.id) { selectedID = h.id }
                }
            }
            .padding(.vertical, 2)
            .padding(.trailing, 4)
        }
        .scrollIndicators(.hidden)
    }

    private func chip(title: String, icon: String?, isOn: Bool, action: @escaping () -> Void) -> some View {
        Button { withAnimation(.snappy) { action() } } label: {
            HStack(spacing: 4) {
                if let icon { Text(icon) }
                Text(title).lineLimit(1)
            }
            .font(.subheadline.weight(.semibold))
            .padding(.horizontal, 12).padding(.vertical, 7)
            .foregroundStyle(isOn ? Ink.paper : Ink.ink)
            .background(Capsule().fill(isOn ? Ink.ink : Color.clear))
            .overlay(Capsule().strokeBorder(Ink.ink, lineWidth: Metrics.border))
        }
        .buttonStyle(.plain)
    }

    // MARK: 요약 (FR-4.3)

    private func summary(_ scope: [HabitSnapshot]) -> some View {
        let current = scope.map { Streaks.current($0.done, today: .now, calendar: calendar) }.max() ?? 0
        let longest = scope.map { Streaks.longest($0.done, calendar: calendar) }.max() ?? 0
        let total = scope.reduce(0) { $0 + $1.done.count }
        return HStack(spacing: 12) {
            tile(value: current, unit: String(localized: "일"), label: String(localized: "현재 연속"))
            tile(value: longest, unit: String(localized: "일"), label: String(localized: "최장 연속"))
            tile(value: total, unit: String(localized: "회"), label: String(localized: "전체 완료"))
        }
    }

    private func tile(value: Int, unit: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).labelStyle().lineLimit(1).minimumScaleFactor(0.8)
            HStack(alignment: .firstTextBaseline, spacing: 1) {
                Text(value.formatted()).font(.number(26)).minimumScaleFactor(0.6).lineLimit(1)
                Text(unit).font(.caption.weight(.bold)).foregroundStyle(Ink.faint)
            }
            .foregroundStyle(Ink.ink)
        }
        .inkCard(padding: 12)
        .accessibilityElement(children: .combine)
    }

    // MARK: 잔디 (FR-4.1, 4.2)

    private func graphCard(source: ContributionSource, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(String(localized: "최근 1년")) { LevelLegend(tint: tint) }
            ScrollView(.horizontal) {
                ContributionGraph(source: source, weeks: 53, today: .now, tint: tint)
                    .padding(.trailing, 14)
            }
            .defaultScrollAnchor(.trailing)
            .scrollIndicators(.hidden)
        }
        .inkCard(padding: 16)
    }
}

// MARK: - 월 달력 (FR-4.4)

private struct MonthCard: View {
    @Binding var month: Date
    let scope: [HabitSnapshot]
    let source: ContributionSource
    let tint: Color
    let calendar: Calendar

    var body: some View {
        let days = MonthStats.days(in: month, calendar: calendar)
        let blanks = MonthStats.leadingBlanks(for: month, calendar: calendar)
        let today = calendar.startOfDay(for: .now)
        let rate = monthRate(days: days, today: today)
        let isCurrentMonth = calendar.isDate(month, equalTo: .now, toGranularity: .month)

        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Button { shift(-1) } label: { Image(systemName: "chevron.left") }
                    .accessibilityLabel("이전 달")
                Text(month.formatted(.dateTime.locale(.app).year().month(.wide)))
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                Button { shift(1) } label: { Image(systemName: "chevron.right") }
                    .disabled(isCurrentMonth)
                    .opacity(isCurrentMonth ? 0.3 : 1)
                    .accessibilityLabel("다음 달")
            }
            .buttonStyle(.plain)
            .foregroundStyle(Ink.ink)

            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(rate.map { "\(Int(($0 * 100).rounded()))" } ?? "–").font(.number(40))
                Text("%").font(.number(18)).foregroundStyle(Ink.faint)
                Spacer()
                Text("이달 달성률").labelStyle()
            }
            .foregroundStyle(Ink.ink)

            let cols = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)
            LazyVGrid(columns: cols, spacing: 8) {
                ForEach(0..<7, id: \.self) { i in
                    Text(weekdaySymbol(i)).font(.label).foregroundStyle(Ink.faint)
                }
                ForEach(0..<blanks, id: \.self) { _ in Color.clear.frame(height: 30) }
                ForEach(days, id: \.self) { day in
                    let level = day > today ? 0 : source.level(on: day)
                    ZStack {
                        Circle().fill(level > 0 ? tint.opacity(Dot.opacity(for: level)) : Ink.empty.opacity(day > today ? 0.4 : 1))
                        if day == today {
                            Circle().strokeBorder(Ink.ink, lineWidth: 1.5)
                        }
                        Text("\(calendar.component(.day, from: day))")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(level >= 3 ? .white : Ink.ink.opacity(day > today ? 0.35 : 0.8))
                    }
                    .frame(height: 30)
                }
            }
        }
        .inkCard(padding: 16)
    }

    private func monthRate(days: [Date], today: Date) -> Double? {
        // 습관별 대상 날짜(생성일 ~ 오늘)의 완료율을 합산
        var eligible = 0, done = 0
        for h in scope {
            let e = MonthStats.eligibleDays(in: month, since: h.created, today: today, calendar: calendar)
            eligible += e.count
            done += e.filter { h.done.contains($0) }.count
        }
        return eligible == 0 ? nil : Double(done) / Double(eligible)
    }

    private func weekdaySymbol(_ i: Int) -> String {
        var cal = calendar
        cal.locale = .app
        let symbols = cal.veryShortWeekdaySymbols
        return symbols[(i + calendar.firstWeekday - 1) % 7]
    }

    private func shift(_ n: Int) {
        withAnimation(.snappy) { month = calendar.date(byAdding: .month, value: n, to: month) ?? month }
    }
}
