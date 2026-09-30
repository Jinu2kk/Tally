import SwiftUI
import SwiftData

/// 탭 「오늘」 — 습관 체크 (FR-1)
struct TodayView: View {
    @Environment(\.modelContext) private var context
    @Query(filter: #Predicate<Habit> { !$0.isArchived },
           sort: [SortDescriptor(\Habit.sortOrder), SortDescriptor(\Habit.createdAt)])
    private var habits: [Habit]
    @AppStorage(SettingsKey.weekStartsOnMonday, store: AppSettings.store) private var mondayFirst = false

    @State private var selectedDay = Calendar.current.startOfDay(for: .now)
    @State private var editing: Habit?
    @State private var showNew = false
    @State private var showReorder = false

    private var calendar: Calendar { AppSettings.calendar(mondayFirst: mondayFirst) }
    private var isToday: Bool { calendar.isDateInToday(selectedDay) }

    var body: some View {
        PaperScreen(isToday ? String(localized: "오늘") : selectedDay.formatted(.dateTime.locale(.app).month().day()),
                    subtitle: selectedDay.formatted(.dateTime.locale(.app).year().month().day().weekday(.wide))) {
            if habits.count > 1 {
                Button { showReorder = true } label: { Image(systemName: "arrow.up.arrow.down") }
                    .accessibilityLabel("순서 변경")
            }
            Button { showNew = true } label: { Image(systemName: "plus") }
                .accessibilityLabel("습관 추가")
        } content: {
            WeekStrip(selected: $selectedDay, calendar: calendar)
            if habits.isEmpty {
                emptyState
            } else {
                summary
                VStack(spacing: 14) {
                    ForEach(habits) { habit in
                        HabitRow(habit: habit, day: selectedDay, calendar: calendar) {
                            HabitActions.toggle(habit, on: selectedDay, in: context)
                        } onEdit: {
                            editing = habit
                        }
                    }
                }
                Text("행을 탭하거나 오른쪽으로 밀면 체크돼요 · 길게 누르면 편집")
                    .font(.caption2)
                    .foregroundStyle(Ink.faint)
                    .frame(maxWidth: .infinity)
            }
        }
        .sheet(isPresented: $showNew) { HabitEditorView(habit: nil, nextOrder: (habits.map(\.sortOrder).max() ?? -1) + 1) }
        .sheet(item: $editing) { HabitEditorView(habit: $0, nextOrder: 0) }
        .sheet(isPresented: $showReorder) { HabitReorderView() }
        .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged)) { _ in
            selectedDay = Calendar.current.startOfDay(for: .now)
        }
    }

    private var summary: some View {
        let done = habits.filter { HabitActions.isDone($0, on: selectedDay) }.count
        return HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text("\(done)")
                .font(.number(56))
                .contentTransition(.numericText())
            Text("/ \(habits.count)")
                .font(.number(24))
                .foregroundStyle(Ink.faint)
            Spacer()
            VStack(alignment: .trailing, spacing: 6) {
                Text(done == habits.count ? "모두 완료" : "완료").labelStyle()
                HStack(spacing: 4) {
                    ForEach(habits) { h in
                        Dot(state: HabitActions.isDone(h, on: selectedDay) ? .accent : .empty,
                            tint: Color(hex: h.colorHex), size: 10)
                    }
                }
            }
        }
        .foregroundStyle(Ink.ink)
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: done)
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                ForEach(0..<4) { i in Dot(state: i == 3 ? .accent : .empty, tint: .accentColor, size: 14) }
            }
            Text("첫 습관을 적어 보세요")
                .font(.title3.weight(.bold))
                .foregroundStyle(Ink.ink)
            Text("매일 하나씩 체크하면 점이 채워지고, 연속 기록이 쌓여요.")
                .font(.subheadline)
                .foregroundStyle(Ink.faint)
            Button { showNew = true } label: {
                Label("습관 추가", systemImage: "plus")
                    .font(.subheadline.weight(.bold))
                    .padding(.horizontal, 14).padding(.vertical, 8)
                    .background(Capsule().fill(Color.accentColor))
                    .foregroundStyle(.white)
            }
        }
        .inkCard(padding: 20)
    }
}

// MARK: - 주간 스트립 (FR-1.4)

struct WeekStrip: View {
    @Binding var selected: Date
    let calendar: Calendar

    private var weekStart: Date {
        let wd = calendar.component(.weekday, from: selected)
        return calendar.addingDays(-((wd - calendar.firstWeekday + 7) % 7), to: selected)
    }

    var body: some View {
        let days = (0..<7).map { calendar.addingDays($0, to: weekStart) }
        let today = calendar.startOfDay(for: .now)
        HStack(spacing: 4) {
            Button { shift(-7) } label: { Image(systemName: "chevron.left") }
                .accessibilityLabel("이전 주")
            ForEach(days, id: \.self) { day in
                let isSelected = day == calendar.startOfDay(for: selected)
                let isFuture = day > today
                Button {
                    withAnimation(.snappy) { selected = day }
                } label: {
                    VStack(spacing: 4) {
                        Text(day.formatted(.dateTime.locale(.app).weekday(.narrow)))
                            .font(.label)
                        Text("\(calendar.component(.day, from: day))")
                            .font(.system(.callout, design: .rounded).weight(.bold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .foregroundStyle(isSelected ? Ink.paper : Ink.ink)
                    .background {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(isSelected ? Ink.ink : .clear)
                        if day == today && !isSelected {
                            RoundedRectangle(cornerRadius: 10)
                                .strokeBorder(Color.accentColor, lineWidth: 1.5)
                        }
                    }
                }
                .disabled(isFuture)
                .opacity(isFuture ? 0.3 : 1)
            }
            Button { shift(7) } label: { Image(systemName: "chevron.right") }
                .disabled(days.last! >= today)
                .accessibilityLabel("다음 주")
        }
        .buttonStyle(.plain)
        .font(.footnote.weight(.bold))
        .foregroundStyle(Ink.ink)
    }

    private func shift(_ n: Int) {
        let today = calendar.startOfDay(for: .now)
        withAnimation(.snappy) { selected = min(calendar.addingDays(n, to: selected), today) }
    }
}

// MARK: - 습관 행

struct HabitRow: View {
    let habit: Habit
    let day: Date
    let calendar: Calendar
    let onToggle: () -> Void
    let onEdit: () -> Void

    @State private var dragX: CGFloat = 0
    @State private var bump = 0

    private var color: Color { Color(hex: habit.colorHex) }

    var body: some View {
        let done = HabitActions.isDone(habit, on: day)
        let doneDays = habit.doneDays
        let streak = Streaks.current(doneDays, today: .now, calendar: calendar)
        let best = Streaks.longest(doneDays, calendar: calendar)

        HStack(spacing: 14) {
            Text(habit.icon)
                .font(.system(size: 26))
                .frame(width: 48, height: 48)
                .background(Circle().fill(color.opacity(0.18)))
                .overlay(Circle().strokeBorder(Ink.ink, lineWidth: Metrics.border))

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Text(habit.name)
                        .font(.headline)
                        .foregroundStyle(Ink.ink)
                        .strikethrough(done, color: Ink.faint)
                        .lineLimit(1)
                    if let m = habit.targetMinutes {
                        Text("\(m)분")
                            .font(.label)
                            .padding(.horizontal, 5).padding(.vertical, 1)
                            .overlay(Capsule().strokeBorder(Ink.faint, lineWidth: 1))
                            .foregroundStyle(Ink.faint)
                    }
                }
                HStack(spacing: 8) {
                    lastSevenDots(doneDays)
                    ViewThatFits {
                        Text("연속 \(streak)일 · 최장 \(best)일")
                        Text("연속 \(streak) · 최장 \(best)")
                        Text("\(streak)일 연속")
                    }
                    .font(.label)
                    .foregroundStyle(Ink.faint)
                    .lineLimit(1)
                }
            }
            Spacer(minLength: 0)
            ZStack {
                Circle().strokeBorder(Ink.ink, lineWidth: 1.5)
                Circle().fill(color).padding(done ? 0 : 20).opacity(done ? 1 : 0)
                if done {
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .black))
                        .foregroundStyle(.white)
                }
            }
            .frame(width: 40, height: 40)
            .animation(.spring(response: 0.35, dampingFraction: 0.6), value: done)
        }
        .inkCard(padding: 14)
        .background(alignment: .leading) {
            // 스와이프 중 뒤에 보이는 힌트
            Image(systemName: done ? "arrow.uturn.backward" : "checkmark")
                .font(.headline.weight(.black))
                .foregroundStyle(color)
                .padding(.leading, 14)
                .opacity(Double(min(1, dragX / 80)))
        }
        .offset(x: dragX)
        .contentShape(Rectangle())
        .onTapGesture { fire() }
        .simultaneousGesture(
            DragGesture(minimumDistance: 24)
                .onChanged { v in
                    guard abs(v.translation.width) > abs(v.translation.height), v.translation.width > 0 else { return }
                    dragX = min(v.translation.width, 110)
                }
                .onEnded { _ in
                    if dragX > 80 { fire() }
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { dragX = 0 }
                }
        )
        .contextMenu {
            Button { onEdit() } label: { Label("편집", systemImage: "pencil") }
            Button { fire() } label: {
                Label(done ? "체크 취소" : "체크", systemImage: done ? "arrow.uturn.backward" : "checkmark")
            }
        }
        .sensoryFeedback(.success, trigger: bump)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
        .accessibilityValue(done ? "완료" : "미완료")
    }

    private func fire() {
        onToggle()
        bump += 1
    }

    private func lastSevenDots(_ doneDays: Set<Date>) -> some View {
        let today = calendar.startOfDay(for: .now)
        return HStack(spacing: 3) {
            ForEach((0..<7).reversed(), id: \.self) { i in
                let d = calendar.addingDays(-i, to: today)
                Dot(state: doneDays.contains(d) ? .accent : .empty, tint: color, size: 7)
            }
        }
    }
}

// MARK: - 순서 변경 (FR-1.5)

struct HabitReorderView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query(filter: #Predicate<Habit> { !$0.isArchived },
           sort: [SortDescriptor(\Habit.sortOrder), SortDescriptor(\Habit.createdAt)])
    private var habits: [Habit]

    var body: some View {
        NavigationStack {
            List {
                ForEach(habits) { h in
                    Label { Text(h.name) } icon: { Text(h.icon) }
                        .listRowBackground(Ink.card)
                }
                .onMove(perform: move)
            }
            .environment(\.editMode, .constant(.active))
            .scrollContentBackground(.hidden)
            .background(Ink.paper)
            .navigationTitle("순서 변경")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("완료") { dismiss() } }
            }
        }
    }

    private func move(from: IndexSet, to: Int) {
        var list = habits
        list.move(fromOffsets: from, toOffset: to)
        for (i, h) in list.enumerated() { h.sortOrder = i }
        try? context.save()
    }
}
