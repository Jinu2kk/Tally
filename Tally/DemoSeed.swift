#if DEBUG
import Foundation
import SwiftData

/// 디버그 전용 시드 데이터. 실행 인자 `-seedDemo YES` (기존 데이터를 지우고 채움)
/// `-seedDemo 50`이면 습관 50개 × 365일 성능 점검용 (NFR-3)
enum DemoSeed {
    @MainActor
    static func runIfRequested(_ container: ModelContainer) {
        guard let arg = UserDefaults.standard.string(forKey: "seedDemo") else { return }
        let context = container.mainContext
        try? context.delete(model: HabitLog.self)
        try? context.delete(model: Habit.self)
        try? context.delete(model: TaskItem.self)
        try? context.delete(model: DDay.self)

        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        let samples: [(String, String, Double)] = [
            ("물 2L 마시기", "💧", 0.9), ("30분 걷기", "🚶", 0.7), ("책 20쪽", "📚", 0.55),
            ("명상 10분", "🧘", 0.4), ("일기 쓰기", "✍️", 0.65),
        ]
        let count = Int(arg) ?? samples.count
        var rng = SystemRandomNumberGenerator()
        for i in 0..<count {
            let s = samples[i % samples.count]
            let h = Habit(name: count > samples.count ? "\(s.0) \(i + 1)" : s.0, icon: s.1,
                          colorHex: HabitPalette.hexes[i % HabitPalette.hexes.count], sortOrder: i,
                          createdAt: cal.addingDays(-364, to: today))
            if i == 0 { h.targetMinutes = 5 }
            context.insert(h)
            var logs: [HabitLog] = []
            for d in 1..<365 where Double.random(in: 0...1, using: &rng) < s.2 {
                let log = HabitLog(day: cal.addingDays(-d, to: today), habit: h)
                context.insert(log)
                logs.append(log)
            }
            h.logs = logs
        }
        let tasks: [(String, Quadrant, Bool)] = [
            ("분기 보고서 제출", .doFirst, false), ("치과 예약", .doFirst, true),
            ("운동 루틴 짜기", .schedule, false), ("영어 공부 계획", .schedule, false),
            ("회의록 정리 부탁", .delegate, false), ("SNS 둘러보기", .eliminate, false),
        ]
        for (i, t) in tasks.enumerated() {
            let item = TaskItem(title: t.0, quadrant: t.1, sortOrder: i)
            item.isDone = t.2
            if i == 0 { item.dueDate = cal.addingDays(2, to: today) }
            context.insert(item)
        }
        context.insert(DDay(title: "제주 여행", date: cal.addingDays(3, to: today)))
        context.insert(DDay(title: "새해", date: cal.date(from: DateComponents(year: cal.component(.year, from: today) + 1, month: 1, day: 1))!))
        try? context.save()

        if AppSettings.birthDate == nil {
            let birth = cal.date(from: DateComponents(year: 1992, month: 5, day: 14))!
            AppSettings.store.set(birth.timeIntervalSinceReferenceDate, forKey: SettingsKey.birthDate)
        }
    }
}
#endif
