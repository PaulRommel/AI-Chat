import Foundation

/// Временное хранилище в памяти. Заменяется на SwiftData на этапе 08.
@MainActor
final class InMemoryChatRepository: ChatRepository {
    private var chats: [Chat] = []

    func fetchChats() throws -> [Chat] {
        chats
    }

    func insert(_ chat: Chat) {
        chats.append(chat)
    }

    func delete(_ chat: Chat) {
        chats.removeAll { $0.id == chat.id }
    }

    func save() throws {}
}
