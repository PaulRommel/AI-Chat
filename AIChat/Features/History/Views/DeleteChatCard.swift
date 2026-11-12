import SwiftUI

/// Карточка подтверждения удаления чата. Выводится над строкой удаляемого чата.
struct DeleteChatCard: View {
    let onConfirm: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Text("Удалить чат?")
                .font(.headline)
            Text("Чат и все его сообщения будут удалены без возможности восстановления.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            Button("Удалить", role: .destructive, action: onConfirm)
                .buttonStyle(.borderedProminent)
                .tint(.red)
            Button("Отмена", action: onCancel)
        }
        .padding(16)
        .frame(width: 280)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.2), radius: 12, y: 4)
    }
}
