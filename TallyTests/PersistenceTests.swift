import XCTest
import SwiftData

final class PersistenceTests: XCTestCase {
    // T-0.1
    func testInMemoryContainerStoresModels() throws {
        let context = ModelContext(SharedStore.makeContainer(inMemory: true))
        context.insert(Habit(name: "물", icon: "💧", colorHex: "1B998B", sortOrder: 0))
        context.insert(TaskItem(title: "보고서", quadrant: .schedule))
        context.insert(DDay(title: "여행", date: .now))
        try context.save()
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<Habit>()), 1)
        XCTAssertEqual(try context.fetch(FetchDescriptor<TaskItem>()).first?.quadrant, .schedule)
    }

    // T-0.2
    func testSharedContainerCreates() {
        XCTAssertNotNil(SharedStore.makeContainer())
    }
}
