import SwiftUI

struct ChatView: View {
    @Bindable var viewModel: ChatViewModel

    var body: some View {
        VStack(spacing: 0) {
            if viewModel.chat.sortedMessages.isEmpty {
                EmptyChatView()
            } else {
                messageList
            }
            MessageInputView(text: $viewModel.draft, onSend: nil)
        }
        .navigationTitle(viewModel.chat.title)
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemBackground))
    }

    private var messageList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.chat.sortedMessages) { message in
                    MessageView(message: message)
                }
            }
            .padding()
        }
    }
}
