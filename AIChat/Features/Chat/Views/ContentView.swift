import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var repository: SwiftDataChatRepository?
    @State private var listViewModel: ChatListViewModel?
    @State private var chatViewModel: ChatViewModel?
    @State private var isShowingHistory = false
    @State private var isShowingError = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationStack {
            Group {
                if let chatViewModel {
                    ChatView(viewModel: chatViewModel)
                } else if listViewModel != nil {
                    NoChatView(onNewChat: startNewChat)
                } else {
                    ProgressView()
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        isShowingHistory = true
                    } label: {
                        Image(systemName: "list.bullet")
                    }
                    .accessibilityLabel("История чатов")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        startNewChat()
                    } label: {
                        Image(systemName: "square.and.pencil")
                    }
                    .accessibilityLabel("Новый чат")
                }
            }
        }
        .sheet(isPresented: $isShowingHistory) {
            if let listViewModel {
                HistoryView(
                    viewModel: listViewModel,
                    selectedChatID: chatViewModel?.chat.id,
                    onSelect: { chat in open(chat) },
                    onDelete: { chat in delete(chat) }
                )
            }
        }
        .alert("Ошибка", isPresented: $isShowingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .task {
            guard listViewModel == nil else { return }
            setUp()
        }
    }

    /// Открывает последний чат. Если чатов нет, показывает пустой экран.
    private func setUp() {
        let repo = SwiftDataChatRepository(context: modelContext)
        let list = ChatListViewModel(repository: repo)
        repository = repo
        listViewModel = list
        list.load()
        if let latest = list.chats.first {
            open(latest)
        }
    }

    private func open(_ chat: Chat) {
        guard let repository else { return }
        chatViewModel = ChatViewModel(
            chat: chat,
            provider: UnconfiguredAIProvider(),
            repository: repository
        )
    }

    /// Каждое нажатие создаёт новый чат и открывает его.
    private func startNewChat() {
        guard let listViewModel else { return }
        do {
            let chat = try listViewModel.createChat()
            open(chat)
        } catch {
            show("Не удалось создать чат.")
        }
    }

    /// Удаляет чат. Если удалён открытый, открывается следующий; если чатов не осталось, показывается пустой экран.
    private func delete(_ chat: Chat) {
        guard let listViewModel else { return }
        let wasOpen = chatViewModel?.chat.id == chat.id
        do {
            try listViewModel.delete(chat)
        } catch {
            show("Не удалось удалить чат.")
            return
        }
        guard wasOpen else { return }
        chatViewModel = nil
        if let next = listViewModel.chats.first {
            open(next)
        }
    }

    private func show(_ message: String) {
        errorMessage = message
        isShowingError = true
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Chat.self, Message.self], inMemory: true)
}
