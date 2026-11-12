import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: ChatViewModel?
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            if let viewModel {
                ChatView(viewModel: viewModel)
            } else if let errorMessage {
                ContentUnavailableView(
                    "Не удалось открыть чат",
                    systemImage: "exclamationmark.triangle",
                    description: Text(errorMessage)
                )
            } else {
                ProgressView()
            }
        }
        .task {
            guard viewModel == nil else { return }
            openLatestChat()
        }
    }

    /// Открывает последний сохранённый чат. Если чатов ещё нет, создаёт первый.
    private func openLatestChat() {
        let repository = SwiftDataChatRepository(context: modelContext)
        do {
            let chat = try repository.fetchChats().first ?? createChat(in: repository)
            viewModel = ChatViewModel(
                chat: chat,
                provider: UnconfiguredAIProvider(),
                repository: repository
            )
        } catch {
            errorMessage = "Попробуйте перезапустить приложение."
        }
    }

    private func createChat(in repository: ChatRepository) throws -> Chat {
        let chat = Chat()
        repository.insert(chat)
        try repository.save()
        return chat
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Chat.self, Message.self], inMemory: true)
}
