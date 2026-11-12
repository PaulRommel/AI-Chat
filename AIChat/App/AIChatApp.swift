import SwiftUI
import SwiftData

@main
struct AIChatApp: App {
    private let container: ModelContainer

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
        }
        .modelContainer(container)
    }
}
