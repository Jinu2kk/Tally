import SwiftUI
import SwiftData

@main
struct TallyApp: App {
    @AppStorage(SettingsKey.appearance, store: AppSettings.store) private var appearance = AppearanceMode.system.rawValue
    @AppStorage(SettingsKey.tint, store: AppSettings.store) private var tintRaw = ThemeTint.tomato.rawValue

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .tint((ThemeTint(rawValue: tintRaw) ?? .tomato).color)
                .preferredColorScheme(colorScheme)
        }
        .modelContainer(SharedStore.container)
    }

    private var colorScheme: ColorScheme? {
        switch AppearanceMode(rawValue: appearance) ?? .system {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}
