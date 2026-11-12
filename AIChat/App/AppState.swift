import Foundation
import Observation

/// Общее состояние приложения, не относящееся к отдельному экрану.
@MainActor
@Observable
final class AppState {
    var selectedChatID: UUID?

    func select(chatID: UUID?) {
        selectedChatID = chatID
    }
}
