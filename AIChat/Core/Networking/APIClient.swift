import Foundation

/// Низкоуровневый HTTP-клиент: отправляет запрос и отдаёт строки ответа по мере поступления.
struct APIClient: Sendable {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    /// Строки потока. Отмена потребителя отменяет сетевой запрос.
    func lines(for request: URLRequest) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    let (bytes, response) = try await session.bytes(for: request)
                    guard let http = response as? HTTPURLResponse else {
                        throw AIError.unknown
                    }
                    guard (200..<300).contains(http.statusCode) else {
                        throw APIClient.error(forStatus: http.statusCode)
                    }
                    for try await line in bytes.lines {
                        continuation.yield(line)
                    }
                    continuation.finish()
                } catch is CancellationError {
                    continuation.finish()
                } catch let error as URLError where error.code == .cancelled {
                    continuation.finish()
                } catch let error as AIError {
                    continuation.finish(throwing: error)
                } catch let error as URLError {
                    continuation.finish(throwing: APIClient.error(for: error))
                } catch {
                    continuation.finish(throwing: AIError.unknown)
                }
            }
            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }

    static func error(forStatus code: Int) -> AIError {
        switch code {
        case 401, 403:
            .invalidAPIKey
        case 429:
            .rateLimited
        default:
            .server(statusCode: code)
        }
    }

    static func error(for urlError: URLError) -> AIError {
        switch urlError.code {
        case .notConnectedToInternet, .networkConnectionLost, .dataNotAllowed:
            .offline
        case .timedOut:
            .timeout
        default:
            .unknown
        }
    }
}
