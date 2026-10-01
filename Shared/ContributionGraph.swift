import SwiftUI

/// 습관 데이터를 잔디 계산에 쓰는 형태로 스냅샷 (SwiftData 객체를 반복 조회하지 않도록)
struct HabitSnapshot: Identifiable {
    let id: UUID
    let name: String
    let icon: String
    let colorHex: String
    let created: Date
    let done: Set<Date>

    init(_ h: Habit) {
        id = h.id
        name = h.name
        icon = h.icon
        colorHex = h.colorHex
        created = h.createdAt
        done = h.doneDays
    }

    var color: Color { Color(hex: colorHex) }
}

/// 잔디 농도 계산: 습관 하나면 완료 = 4, 여러 개면 완료 비율
struct ContributionSource {
    let habits: [HabitSnapshot]
    let calendar: Calendar

    func level(on day: Date) -> Int {
        if habits.count == 1 { return habits[0].done.contains(calendar.startOfDay(for: day)) ? 4 : 0 }
        let r = DayRatio.ratio(on: day, habits: habits.map { ($0.created, $0.done) }, calendar: calendar)
        return Contribution.level(r)
    }
}

/// GitHub 스타일 잔디 (FR-4.1, 4.2)
struct ContributionGraph: View {
    let source: ContributionSource
    let weeks: Int
    let today: Date
    let tint: Color
    var dot: CGFloat = 11
    var gap: CGFloat = 3
    var showMonths = true

    var body: some View {
        let grid = Contribution.grid(weeks: weeks, today: today, calendar: source.calendar)
        let todayStart = source.calendar.startOfDay(for: today)
        VStack(alignment: .leading, spacing: 4) {
            if showMonths {
                HStack(spacing: gap) {
                    ForEach(grid.indices, id: \.self) { w in
                        Text(monthLabel(grid, w))
                            .font(.system(size: 9, weight: .semibold, design: .monospaced))
                            .foregroundStyle(Ink.faint)
                            .fixedSize()
                            .frame(width: dot, alignment: .leading)
                    }
                }
            }
            HStack(alignment: .top, spacing: gap) {
                ForEach(grid.indices, id: \.self) { w in
                    VStack(spacing: gap) {
                        ForEach(grid[w], id: \.self) { day in
                            if day > todayStart {
                                Color.clear.frame(width: dot, height: dot)
                            } else if day == todayStart {
                                let l = source.level(on: day)
                                Dot(state: l > 0 ? .level(l) : .today, tint: tint, size: dot)
                            } else {
                                Dot(state: .level(source.level(on: day)), tint: tint, size: dot)
                            }
                        }
                    }
                }
            }
        }
    }

    /// 그 주에 달의 1일이 들어 있으면 월 표시
    private func monthLabel(_ grid: [[Date]], _ w: Int) -> String {
        guard let first = grid[w].first(where: { source.calendar.component(.day, from: $0) == 1 }) ?? (w == 0 ? grid[w].first : nil)
        else { return "" }
        return "\(source.calendar.component(.month, from: first))월"
    }
}

/// 적음 → 많음 범례
struct LevelLegend: View {
    let tint: Color
    var body: some View {
        HStack(spacing: 4) {
            Text("적음").font(.caption2).foregroundStyle(Ink.faint)
            ForEach(0..<5) { Dot(state: .level($0), tint: tint, size: 9) }
            Text("많음").font(.caption2).foregroundStyle(Ink.faint)
        }
    }
}
