import SwiftUI
import SwiftData

@main
struct AIChatApp: App {
    private let container: ModelContainer
    @State private var themeManager = ThemeManager()

    init() {
        do {
            container = try PersistenceController.makeContainer()
        } catch {
            fatalError("Не удалось открыть хранилище чатов: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(themeManager)
        }
        .modelContainer(container)
    }
}
