import SwiftUI

struct ContentView: View {
    @State private var viewModel: ChatViewModel

    init() {
        _viewModel = State(initialValue: ChatViewModel(
            chat: Chat(),
            provider: UnconfiguredAIProvider(),
            repository: InMemoryChatRepository()
        ))
    }

    var body: some View {
        NavigationStack {
            ChatView(viewModel: viewModel)
        }
    }
}

#Preview {
    ContentView()
}
