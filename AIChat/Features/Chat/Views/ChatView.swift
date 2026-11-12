import SwiftUI

struct ChatView: View {
    @Bindable var viewModel: ChatViewModel
    private let bottomID = "chat-bottom"

    var body: some View {
        let messages = viewModel.chat.sortedMessages
        VStack(spacing: 0) {
            if messages.isEmpty {
                EmptyChatView()
            } else {
                messageList(messages)
            }
            if viewModel.canRetry {
                HStack(spacing: 12) {
                    Text(viewModel.errorMessage ?? "Ответ не получен.")
                        .font(.footnote)
                        .foregroundStyle(.red)
                    Spacer()
                    Button("Повторить", action: viewModel.retry)
                        .font(.footnote.weight(.semibold))
                }
                .padding(.horizontal)
                .padding(.top, 4)
            } else if let message = viewModel.errorMessage {
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .padding(.horizontal)
                    .padding(.top, 4)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            MessageInputView(
                text: $viewModel.draft,
                isSendEnabled: viewModel.canSend,
                isGenerating: viewModel.state.isBusy,
                onSend: viewModel.send,
                onStop: viewModel.stop
            )
        }
        .navigationTitle(viewModel.chat.title)
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemBackground))
    }

    private func messageList(_ messages: [Message]) -> some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(messages) { message in
                        MessageView(message: message)
                    }
                    Color.clear
                        .frame(height: 1)
                        .id(bottomID)
                }
                .padding()
            }
            .defaultScrollAnchor(.bottom)
            .scrollDismissesKeyboard(.interactively)
            .onChange(of: messages.count) { _, _ in
                scrollToBottom(proxy)
            }
            .onChange(of: messages.last?.content) { _, _ in
                scrollToBottom(proxy)
            }
        }
    }

    private func scrollToBottom(_ proxy: ScrollViewProxy) {
        withAnimation(.easeOut(duration: 0.2)) {
            proxy.scrollTo(bottomID, anchor: .bottom)
        }
    }
}
