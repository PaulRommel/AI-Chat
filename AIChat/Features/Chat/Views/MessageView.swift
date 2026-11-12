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
            MarkdownView(source: message.content)
                .textSelection(.enabled)
        }
    }
}
