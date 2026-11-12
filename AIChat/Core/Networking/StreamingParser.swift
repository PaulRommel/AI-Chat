import Foundation

/// Разбор потока Server-Sent Events от OpenRouter (формат Chat Completions).
enum StreamingParser {
    enum Event: Equatable, Sendable {
        case delta(String)
        case done
    }

    /// Возвращает событие для строки потока или nil, если строка не несёт содержимого (пустая строка, комментарий, служебный кадр).
    static func parse(line: String) throws -> Event? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, !trimmed.hasPrefix(":"), trimmed.hasPrefix("data:") else {
            return nil
        }
        let payload = trimmed.dropFirst("data:".count).trimmingCharacters(in: .whitespaces)
        if payload == "[DONE]" {
            return .done
        }
        guard let data = payload.data(using: .utf8) else {
            throw AIError.decoding
        }
        let chunk: Chunk
        do {
            chunk = try JSONDecoder().decode(Chunk.self, from: data)
        } catch {
            throw AIError.decoding
        }
        if chunk.error != nil {
            throw AIError.streamInterrupted
        }
        guard let content = chunk.choices?.first?.delta?.content, !content.isEmpty else {
            return nil
        }
        return .delta(content)
    }

    private struct Chunk: Decodable {
        let choices: [Choice]?
        let error: ErrorBody?
    }

    private struct Choice: Decodable {
        let delta: Delta?
    }

    private struct Delta: Decodable {
        let content: String?
    }

    private struct ErrorBody: Decodable {
        let message: String?
    }
}
