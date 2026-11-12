import Foundation

/// Реализация AIProvider поверх OpenRouter: собирает запрос, читает поток и отдаёт фрагменты ответа.
struct AIService: AIProvider {
    private let configuration: APIConfiguration
    private let client: APIClient

    init(configuration: APIConfiguration = .current, client: APIClient = APIClient()) {
        self.configuration = configuration
        self.client = client
    }

    func streamReply(to messages: [ChatRequestMessage]) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            guard let apiKey = configuration.apiKey else {
                continuation.finish(throwing: AIError.missingAPIKey)
                return
            }
            let request: URLRequest
            do {
                request = try makeRequest(messages: messages, apiKey: apiKey)
            } catch {
                continuation.finish(throwing: error)
                return
            }
            let task = Task {
                do {
                    for try await line in client.lines(for: request) {
                        guard let event = try StreamingParser.parse(line: line) else { continue }
                        switch event {
                        case .delta(let text):
                            continuation.yield(text)
                        case .done:
                            continuation.finish()
                            return
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }

    private func makeRequest(messages: [ChatRequestMessage], apiKey: String) throws -> URLRequest {
        guard let url = configuration.endpoint else {
            throw AIError.unknown
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 60
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("AI Chat", forHTTPHeaderField: "X-Title")
        request.httpBody = try JSONEncoder().encode(
            ChatCompletionRequest(model: configuration.model, messages: messages, stream: true)
        )
        return request
    }

    private struct ChatCompletionRequest: Encodable {
        let model: String
        let messages: [ChatRequestMessage]
        let stream: Bool
    }
}
