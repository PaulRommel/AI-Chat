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
            if message.content.isEmpty && message.status == .pending {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                MarkdownView(source: message.content)
                    .textSelection(.enabled)
            }
        }
    }
}
