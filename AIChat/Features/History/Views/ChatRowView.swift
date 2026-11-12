import SwiftUI

struct ChatRowView: View {
    let chat: Chat
    let isSelected: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(chat.title)
                    .font(.body.weight(.medium))
                    .lineLimit(1)
                Text(chat.updatedAt, format: .dateTime.day().month().hour().minute())
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if isSelected {
                Image(systemName: "checkmark")
                    .foregroundStyle(.tint)
            }
        }
        .contentShape(Rectangle())
    }
}
