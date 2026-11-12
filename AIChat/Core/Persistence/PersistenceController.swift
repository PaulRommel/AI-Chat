import Foundation
import SwiftData

/// Создание контейнера SwiftData для чатов и сообщений.
enum PersistenceController {
    static let schema = Schema([Chat.self, Message.self])

    static func makeContainer(inMemory: Bool = false) throws -> ModelContainer {
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: inMemory)
        return try ModelContainer(for: schema, configurations: configuration)
    }
}
