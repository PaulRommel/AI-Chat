import SwiftUI

struct MessageInputView: View {
    @Binding var text: String
    let isSendEnabled: Bool
    let isGenerating: Bool
    let onSend: () -> Void
    let onStop: () -> Void

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            TextField("Сообщение", text: $text, axis: .vertical)
                .lineLimit(1...6)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    Color(.secondarySystemBackground),
                    in: RoundedRectangle(cornerRadius: 20, style: .continuous)
                )

            if isGenerating {
                Button(action: onStop) {
                    Image(systemName: "stop.circle.fill")
                        .font(.system(size: 32))
                }
                .accessibilityLabel("Остановить")
            } else {
                Button(action: onSend) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 32))
                }
                .disabled(!isSendEnabled)
                .accessibilityLabel("Отправить")
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.bar)
    }
}
