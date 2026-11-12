import Foundation

/// Провайдер до подключения OpenRouter (этап 10). Сразу сообщает, что ключ не настроен.
struct UnconfiguredAIProvider: AIProvider {
    func streamReply(to messages: [ChatRequestMessage]) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            continuation.finish(throwing: AIError.missingAPIKey)
        }
    }
}
