import Foundation

/// Хранилище диалогов. Реализация на SwiftData появится на этапе 08.
@MainActor
protocol ChatRepository: AnyObject {
    func fetchChats() throws -> [Chat]
    func insert(_ chat: Chat)
    func delete(_ chat: Chat)
    func save() throws
}
