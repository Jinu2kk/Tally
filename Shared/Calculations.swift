import Foundation

// UI와 분리된 순수 계산 함수. 모두 Calendar와 now를 인자로 받아 테스트에서 고정한다 (DESIGN §3)

extension Calendar {
    func days(from a: Date, to b: Date) -> Int {
        dateComponents([.day], from: startOfDay(for: a), to: startOfDay(for: b)).day ?? 0
    }

    func addingDays(_ n: Int, to date: Date) -> Date {
        self.date(byAdding: .day, value: n, to: startOfDay(for: date)) ?? date
    }
}

// MARK: - 연속 기록 (IC-5)

enum Streaks {
    /// 오늘 완료했으면 오늘부터, 아니면 어제부터 거꾸로 센다.
    /// 오늘 미완료여도 어제까지 이어졌으면 streak은 유지된다.
    static func current(_ done: Set<Date>, today: Date, calendar: Calendar) -> Int {
        let todayStart = calendar.startOfDay(for: today)
        var day = done.contains(todayStart) ? todayStart : calendar.addingDays(-1, to: todayStart)
        var count = 0
        while done.contains(day) {
            count += 1
            day = calendar.addingDays(-1, to: day)
        }
        return count
    }

    static func longest(_ done: Set<Date>, calendar: Calendar) -> Int {
        let sorted = done.sorted()
        guard var prev = sorted.first else { return 0 }
        var best = 1, run = 1
        for day in sorted.dropFirst() {
            run = calendar.days(from: prev, to: day) == 1 ? run + 1 : 1
            best = max(best, run)
            prev = day
        }
        return best
    }
}

// MARK: - 올해 진행률 (FR-2.1)

struct YearProgress: Equatable {
    let year: Int
    /// 1부터 시작하는 오늘의 순번
    let dayOfYear: Int
    let daysInYear: Int

    init(now: Date, calendar: Calendar) {
        year = calendar.component(.year, from: now)
        dayOfYear = calendar.ordinality(of: .day, in: .year, for: now) ?? 1
        daysInYear = calendar.range(of: .day, in: .year, for: now)?.count ?? 365
    }

    var daysLeft: Int { daysInYear - dayOfYear }
    var fraction: Double { Double(dayOfYear) / Double(daysInYear) }
    var percent: Int { Int((fraction * 100).rounded(.down)) }
}

// MARK: - 라이프 캘린더 (FR-2.2)

struct LifeProgress: Equatable {
    static let weeksPerYear = 52

    let totalWeeks: Int
    let livedWeeks: Int

    init(birth: Date, expectancy: Int, now: Date, calendar: Calendar) {
        totalWeeks = max(1, expectancy) * Self.weeksPerYear
        let weeks = max(0, calendar.days(from: birth, to: now) / 7)
        livedWeeks = min(totalWeeks, weeks)
    }

    var weeksLeft: Int { totalWeeks - livedWeeks }
    var fraction: Double { Double(livedWeeks) / Double(totalWeeks) }
    var percent: Int { Int((fraction * 100).rounded(.down)) }
}

// MARK: - D-Day (FR-2.3)

enum DDayMath {
    static func daysUntil(_ target: Date, now: Date, calendar: Calendar) -> Int {
        calendar.days(from: now, to: target)
    }

    static func label(_ target: Date, now: Date, calendar: Calendar) -> String {
        let d = daysUntil(target, now: now, calendar: calendar)
        if d > 0 { return "D-\(d)" }
        if d == 0 { return "D-Day" }
        return "D+\(-d)"
    }
}

// MARK: - 잔디 (FR-4.1, 4.2)

enum Contribution {
    /// weeks × 7 격자. 각 원소는 한 주(7일, 주 시작 요일부터). 마지막 주에 오늘이 들어 있다.
    static func grid(weeks: Int, today: Date, calendar: Calendar) -> [[Date]] {
        let todayStart = calendar.startOfDay(for: today)
        let weekday = calendar.component(.weekday, from: todayStart)
        let offset = (weekday - calendar.firstWeekday + 7) % 7
        let lastWeekStart = calendar.addingDays(-offset, to: todayStart)
        let firstWeekStart = calendar.addingDays(-7 * (weeks - 1), to: lastWeekStart)
        return (0..<weeks).map { w in
            (0..<7).map { d in calendar.addingDays(w * 7 + d, to: firstWeekStart) }
        }
    }

    /// 완료 비율(0...1)을 농도 0...4로
    static func level(_ ratio: Double) -> Int {
        switch ratio {
        case ..<0.0001: 0
        case ..<0.34: 1
        case ..<0.67: 2
        case ..<1: 3
        default: 4
        }
    }
}

// MARK: - 월별 달성률 (FR-4.4)

enum MonthStats {
    /// 해당 월의 모든 날짜
    static func days(in month: Date, calendar: Calendar) -> [Date] {
        guard let interval = calendar.dateInterval(of: .month, for: month) else { return [] }
        let count = calendar.range(of: .day, in: .month, for: month)?.count ?? 30
        return (0..<count).map { calendar.addingDays($0, to: interval.start) }
    }

    /// 달력 첫 줄 앞에 비워 둘 칸 수 (주 시작 요일 반영)
    static func leadingBlanks(for month: Date, calendar: Calendar) -> Int {
        guard let first = calendar.dateInterval(of: .month, for: month)?.start else { return 0 }
        return (calendar.component(.weekday, from: first) - calendar.firstWeekday + 7) % 7
    }

    /// 대상 기간: 시작일(습관 생성일) 이후 ~ 오늘까지
    static func eligibleDays(in month: Date, since start: Date, today: Date, calendar: Calendar) -> [Date] {
        let s = calendar.startOfDay(for: start), t = calendar.startOfDay(for: today)
        return days(in: month, calendar: calendar).filter { $0 >= s && $0 <= t }
    }

    /// 0...1, 대상 날짜가 없으면 nil
    static func rate(done: Set<Date>, eligible: [Date]) -> Double? {
        guard !eligible.isEmpty else { return nil }
        return Double(eligible.filter { done.contains($0) }.count) / Double(eligible.count)
    }
}

// MARK: - 여러 습관 합산

enum DailyRatio {
    /// 그날 존재하던 습관 중 완료한 비율. 대상 습관이 없으면 0
    static func ratio(on day: Date, habits: [(created: Date, done: Set<Date>)], calendar: Calendar) -> Double {
        let d = calendar.startOfDay(for: day)
        let alive = habits.filter { calendar.startOfDay(for: $0.created) <= d }
        guard !alive.isEmpty else { return 0 }
        return Double(alive.filter { $0.done.contains(d) }.count) / Double(alive.count)
    }
}
