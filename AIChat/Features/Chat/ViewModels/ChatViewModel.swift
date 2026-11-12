import Foundation
import Observation

@MainActor
@Observable
final class ChatViewModel {
    let chat: Chat
    var draft: String = ""
    private(set) var state: GenerationState = .idle

    private let provider: AIProvider
    private let repository: ChatRepository

    init(chat: Chat, provider: AIProvider, repository: ChatRepository) {
        self.chat = chat
        self.provider = provider
        self.repository = repository
    }

    var canSend: Bool {
        !state.isBusy && !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
