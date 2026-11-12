import Foundation
import Observation

@MainActor
@Observable
final class ChatViewModel {
    let chat: Chat
    var draft: String = ""
    private(set) var state: GenerationState = .idle

    /// Как часто ответ сохраняется во время потока. Меньше — надёжнее, больше — дешевле по записи.
    private static let saveInterval: TimeInterval = 1
    private static let saveFailedMessage = "Не удалось сохранить сообщение."

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
            state = .failed(message: Self.saveFailedMessage)
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
        var lastSave = Date.now
        var outcome: GenerationState = .idle
        do {
            for try await fragment in stream {
                message.content += fragment
                if Date.now.timeIntervalSince(lastSave) >= Self.saveInterval {
                    // Ошибка промежуточного сохранения не прерывает поток: финальное сохранение повторит запись и сообщит об ошибке.
                    _ = saveChanges()
                    lastSave = .now
                }
            }
            message.status = .completed
        } catch is CancellationError {
            message.status = .partial
        } catch {
            message.status = .failed
            outcome = .failed(message: Self.userMessage(for: error))
        }
        chat.updatedAt = .now
        if !saveChanges() {
            outcome = .failed(message: Self.saveFailedMessage)
        }
        state = outcome
        generationTask = nil
    }

    private func saveChanges() -> Bool {
        do {
            try repository.save()
            return true
        } catch {
            return false
        }
    }

    private static func userMessage(for error: Error) -> String {
        (error as? AIError)?.userMessage ?? AIError.unknown.userMessage
    }
}
