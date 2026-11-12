import SwiftUI

struct MessageView: View {
    let message: Message

    var body: some View {
        switch message.role {
        case .user:
            HStack {
                Spacer(minLength: 48)
                Text(message.content)
                    .textSelection(.enabled)
                    .foregroundStyle(.white)
                    .padding(12)
                    .background(
                        Color.accentColor,
                        in: RoundedRectangle(cornerRadius: 18, style: .continuous)
                    )
            }
        case .assistant, .system:
            if message.content.isEmpty {
                switch message.status {
                case .pending, .streaming:
                    ProgressView()
                        .frame(maxWidth: .infinity, alignment: .leading)
                case .failed:
                    Text("Ответ не получен.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                case .completed, .partial:
                    EmptyView()
                }
            } else {
                MarkdownView(source: message.content)
                    .textSelection(.enabled)
            }
        }
    }
}
