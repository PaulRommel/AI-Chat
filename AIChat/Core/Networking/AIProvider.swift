import Foundation

/// Сообщение, которое передаётся провайдеру AI как часть истории диалога.
struct ChatRequestMessage: Codable, Equatable, Sendable {
    let role: MessageRole
    let content: String
}

/// Провайдер AI. Реализация (OpenRouter и др.) подбирается конфигурацией.
protocol AIProvider: Sendable {
    /// Возвращает поток фрагментов ответа. Отмена задачи, которая читает поток, прекращает запрос.
    func streamReply(to messages: [ChatRequestMessage]) -> AsyncThrowingStream<String, Error>
}
