import SwiftUI

struct MessageView: View {
    let message: Message

    var body: some View {
        HStack {
            if message.role == .user {
                Spacer(minLength: 48)
            }
            Text(message.content)
                .textSelection(.enabled)
                .padding(12)
                .foregroundStyle(message.role == .user ? Color.white : Color.primary)
                .background(bubbleColor, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            if message.role != .user {
                Spacer(minLength: 48)
            }
        }
    }

    private var bubbleColor: Color {
        message.role == .user ? Color.accentColor : Color(.secondarySystemBackground)
    }
}
