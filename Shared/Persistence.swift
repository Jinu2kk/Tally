import Foundation
import SwiftData

enum SharedStore {
    static let appGroupID = "group.com.jinu2kk.tally"
    static let schema = Schema([Habit.self, HabitLog.self, TaskItem.self, DDay.self])

    /// 앱과 위젯이 함께 쓰는 컨테이너 (IC-3)
    /// UI 테스트는 실행 인자 `-uiTesting YES`로 메모리 저장소를 쓴다
    static let container: ModelContainer = makeContainer(inMemory: UserDefaults.standard.bool(forKey: "uiTesting"))

    /// App Group 컨테이너 안의 저장소 위치. 사용할 수 없으면 nil (서명 없는 빌드 등)
    static var groupStoreURL: URL? {
        guard let base = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) else {
            return nil
        }
        let dir = base.appending(path: "Library/Application Support", directoryHint: .isDirectory)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appending(path: "Tally.store")
    }

    static func makeContainer(inMemory: Bool = false) -> ModelContainer {
        let config: ModelConfiguration
        if inMemory {
            config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        } else if let url = groupStoreURL {
            config = ModelConfiguration(schema: schema, url: url)
        } else {
            config = ModelConfiguration(schema: schema) // NFR-5: 앱 전용 저장소로 대체
        }
        do {
            return try ModelContainer(for: schema, configurations: config)
        } catch {
            fatalError("ModelContainer 생성 실패: \(error)")
        }
    }
}
