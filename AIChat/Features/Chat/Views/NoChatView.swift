import SwiftUI

/// Экран, когда ни один чат не открыт: чатов нет или открытый чат удалён.
struct NoChatView: View {
    let onNewChat: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label("Нет открытого чата", systemImage: "bubble.left.and.bubble.right")
        } description: {
            Text("Создайте новый чат или выберите существующий в истории.")
        } actions: {
            Button("Новый чат", action: onNewChat)
                .buttonStyle(.borderedProminent)
        }
    }
}
