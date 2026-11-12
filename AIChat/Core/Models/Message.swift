import Foundation
import SwiftData

enum MessageRole: String, Codable, Sendable {
    case user
    case assistant
    case system
}

enum MessageStatus: String, Codable, Sendable {
    case pending
    case streaming
    case completed
    case partial
    case failed
}

@Model
final class Message {
    var id: UUID
    var role: MessageRole
    var content: String
    var createdAt: Date
    var status: MessageStatus
    var chat: Chat?

    init(
        id: UUID = UUID(),
        role: MessageRole,
        content: String,
        createdAt: Date = .now,
        status: MessageStatus = .completed,
        chat: Chat? = nil
    ) {
        self.id = id
        self.role = role
        self.content = content
        self.createdAt = createdAt
        self.status = status
        self.chat = chat
    }
}
