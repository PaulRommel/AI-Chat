import Foundation
import SwiftData

/// Хранилище диалогов на SwiftData.
@MainActor
final class SwiftDataChatRepository: ChatRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchChats() throws -> [Chat] {
        let descriptor = FetchDescriptor<Chat>(
            sortBy: [SortDescriptor(\Chat.updatedAt, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    func insert(_ chat: Chat) {
        context.insert(chat)
    }

    func delete(_ chat: Chat) {
        context.delete(chat)
    }

    func save() throws {
        try context.save()
    }
}
