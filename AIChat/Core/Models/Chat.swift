import Foundation
import SwiftData

@Model
final class Chat {
    var id: UUID
    var title: String
    var createdAt: Date
    var updatedAt: Date

    @Relationship(deleteRule: .cascade, inverse: \Message.chat)
    var messages: [Message]

    init(
        id: UUID = UUID(),
        title: String = Chat.defaultTitle,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        messages: [Message] = []
    ) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.messages = messages
    }

    var sortedMessages: [Message] {
        messages.sorted { $0.createdAt < $1.createdAt }
    }
}
