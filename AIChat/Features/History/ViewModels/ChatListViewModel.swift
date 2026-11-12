import Foundation
import Observation

@MainActor
@Observable
final class ChatListViewModel {
    private(set) var chats: [Chat] = []
    private(set) var loadError: String?

    private let repository: ChatRepository

    init(repository: ChatRepository) {
        self.repository = repository
    }

    func load() {
        do {
            chats = try repository.fetchChats().sorted { $0.updatedAt > $1.updatedAt }
            loadError = nil
        } catch {
            loadError = "Не удалось загрузить историю чатов."
        }
    }

    @discardableResult
    func createChat() throws -> Chat {
        let chat = Chat()
        repository.insert(chat)
        try repository.save()
        chats.insert(chat, at: 0)
        return chat
    }

    func delete(_ chat: Chat) throws {
        repository.delete(chat)
        try repository.save()
        chats.removeAll { $0.id == chat.id }
    }
}
