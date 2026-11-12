import Foundation

extension Chat {
    static let defaultTitle = "Новый чат"

    /// Название по первому сообщению пользователя. Применяется только к чату с названием по умолчанию.
    func adoptTitleIfNeeded(fromFirstMessage text: String) {
        guard title == Chat.defaultTitle else { return }
        let normalized = text
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
        guard !normalized.isEmpty else { return }
        title = normalized.count > 40 ? String(normalized.prefix(40)) + "…" : normalized
    }
}
