import Foundation

/// Ошибки AI-слоя. Каждая ошибка переводится в понятное состояние интерфейса.
enum AIError: Error, Equatable, Sendable {
    case missingAPIKey
    case invalidAPIKey
    case rateLimited
    case offline
    case timeout
    case server(statusCode: Int)
    case decoding
    case streamInterrupted
    case unknown

    var userMessage: String {
        switch self {
        case .missingAPIKey:
            "API-ключ не настроен."
        case .invalidAPIKey:
            "API-ключ недействителен."
        case .rateLimited:
            "Исчерпан лимит запросов. Попробуйте позже."
        case .offline:
            "Нет подключения к интернету."
        case .timeout:
            "Превышено время ожидания ответа."
        case .server(let statusCode):
            "Ошибка сервера (код \(statusCode))."
        case .decoding:
            "Не удалось разобрать ответ сервера."
        case .streamInterrupted:
            "Соединение прервано."
        case .unknown:
            "Неизвестная ошибка."
        }
    }
}
