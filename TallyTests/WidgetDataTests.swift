import XCTest
import SwiftData

final class WidgetDataTests: XCTestCase {
    // T-5.1 위젯 설정 목록에서 보관된 습관 제외, 순서 유지
    func testHabitEntityQueryExcludesArchived() throws {
        let context = ModelContext(SharedStore.makeContainer(inMemory: true))
        let a = Habit(name: "A", icon: "🅰️", colorHex: "000000", sortOrder: 1)
        let b = Habit(name: "B", icon: "🅱️", colorHex: "000000", sortOrder: 0)
        let c = Habit(name: "C", icon: "©️", colorHex: "000000", sortOrder: 2)
        c.isArchived = true
        [a, b, c].forEach(context.insert)
        try context.save()
        XCTAssertEqual(HabitEntityQuery.all(in: context).map(\.name), ["B", "A"])
    }

    func testSnapshotCarriesDoneDays() throws {
        let context = ModelContext(SharedStore.makeContainer(inMemory: true))
        let h = Habit(name: "A", icon: "🅰️", colorHex: "000000", sortOrder: 0)
        context.insert(h)
        HabitActions.toggle(h, on: .now, in: context)
        let snap = HabitSnapshot(h)
        XCTAssertTrue(snap.done.contains(Calendar.current.startOfDay(for: .now)))
        XCTAssertEqual(ContributionSource(habits: [snap], calendar: .current).level(on: .now), 4)
    }
}

final class ToggleIntentTests: XCTestCase {
    @MainActor
    func testToggleIntentPerform() async throws {
        let context = ModelContext(SharedStore.container)
        let h = Habit(name: "intent-test", icon: "🧪", colorHex: "000000", sortOrder: 999)
        context.insert(h)
        try context.save()
        defer { context.delete(h); try? context.save() }

        _ = try await ToggleHabitIntent(habitID: h.id.uuidString).perform()
        let fresh = ModelContext(SharedStore.container)
        let again = HabitActions.activeHabits(in: fresh).first { $0.id == h.id }
        XCTAssertNotNil(again)
        XCTAssertTrue(HabitActions.isDone(again!, on: .now), "인텐트 실행 후 새 컨텍스트에서 완료로 보여야 함")
    }
}
