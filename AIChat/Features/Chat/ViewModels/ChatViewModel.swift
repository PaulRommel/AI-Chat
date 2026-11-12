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
    private var generationTask: Task<Void, Never>?

    init(chat: Chat, provider: AIProvider, repository: ChatRepository) {
        self.chat = chat
        self.provider = provider
        self.repository = repository
    }

    var canSend: Bool {
        !state.isBusy && !trimmedDraft.isEmpty
    }

    private var trimmedDraft: String {
        draft.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Сохраняет сообщение пользователя и пустой ответ ассистента, затем запрашивает ответ у провайдера.
    func send() {
        guard canSend else { return }
        let text = trimmedDraft
        draft = ""

        let userMessage = Message(role: .user, content: text, createdAt: .now)
        let assistantMessage = Message(
            role: .assistant,
            content: "",
            createdAt: .now,
            status: .pending
        )
        chat.messages.append(userMessage)
        chat.messages.append(assistantMessage)
        chat.adoptTitleIfNeeded(fromFirstMessage: text)
        chat.updatedAt = .now

        // История берётся до ответа: в неё входят только завершённые сообщения, без пустого ответа.
        let history = chat.sortedMessages
            .filter { $0.id != assistantMessage.id && $0.status == .completed }
            .map { ChatRequestMessage(role: $0.role, content: $0.content) }

        guard saveChanges() else {
            draft = text
            return
        }

        state = .sending
        let stream = provider.streamReply(to: history)
        generationTask = Task {
            await consume(stream, into: assistantMessage)
        }
    }

    private func consume(_ stream: AsyncThrowingStream<String, Error>, into message: Message) async {
        message.status = .streaming
        state = .streaming
        do {
            for try await fragment in stream {
                message.content += fragment
            }
            message.status = .completed
            state = .idle
        } catch is CancellationError {
            message.status = .partial
            state = .idle
        } catch {
            message.status = .failed
            state = .failed(message: Self.userMessage(for: error))
        }
        chat.updatedAt = .now
        saveChanges()
        generationTask = nil
    }

    @discardableResult
    private func saveChanges() -> Bool {
        do {
            try repository.save()
            return true
        } catch {
            state = .failed(message: "Не удалось сохранить сообщение.")
            return false
        }
    }

    private static func userMessage(for error: Error) -> String {
        (error as? AIError)?.userMessage ?? AIError.unknown.userMessage
    }
}
