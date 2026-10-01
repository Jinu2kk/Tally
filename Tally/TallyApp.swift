import SwiftUI
import SwiftData
import WidgetKit

@main
struct TallyApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage(SettingsKey.appearance, store: AppSettings.store) private var appearance = AppearanceMode.system.rawValue
    @AppStorage(SettingsKey.tint, store: AppSettings.store) private var tintRaw = ThemeTint.tomato.rawValue

    /// 위젯이 다른 프로세스에서 기록을 바꾸므로, 앱이 다시 활성화될 때 새 컨텍스트로 갈아 끼워 최신 데이터를 읽는다
    @State private var context: ModelContext

    init() {
        #if DEBUG
        if UserDefaults.standard.bool(forKey: "uiTesting") {
            // UI 테스트마다 설정을 비운다
            AppSettings.store.removePersistentDomain(forName: SharedStore.appGroupID)
        }
        DemoSeed.runIfRequested(SharedStore.container)
        #endif
        _context = State(initialValue: Self.freshContext())
    }

    var body: some Scene {
        WindowGroup {
            root
                .task {
                    #if DEBUG
                    await DemoEvents.runHooks()
                    #endif
                }
                .tint((ThemeTint(rawValue: tintRaw) ?? .tomato).color)
                .preferredColorScheme(colorScheme)
        }
        .modelContainer(SharedStore.container)
        .modelContext(context)
        .environment(CalendarStore.shared)
        .onChange(of: scenePhase) { old, new in
            if new == .active, old == .background {
                context = Self.freshContext()
            }
            if new == .background {
                WidgetCenter.shared.reloadAllTimelines()
            }
        }
    }

    @ViewBuilder private var root: some View {
        #if DEBUG
        if UserDefaults.standard.bool(forKey: "widgetGallery") {
            WidgetGalleryView()
        } else {
            RootTabView()
        }
        #else
        RootTabView()
        #endif
    }

    private static func freshContext() -> ModelContext {
        let c = ModelContext(SharedStore.container)
        c.autosaveEnabled = true
        return c
    }

    private var colorScheme: ColorScheme? {
        switch AppearanceMode(rawValue: appearance) ?? .system {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}
