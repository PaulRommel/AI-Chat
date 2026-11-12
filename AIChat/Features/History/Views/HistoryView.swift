import SwiftUI

struct HistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel: ChatListViewModel
    let selectedChatID: UUID?
    let onSelect: (Chat) -> Void
    let onDelete: (Chat) -> Void

    @State private var chatPendingDeletion: Chat?

    private let cardWidth: CGFloat = 280
    private let gap: CGFloat = 8
    private let minimumSpaceAboveRow: CGFloat = 220

    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.chats) { chat in
                    Button {
                        onSelect(chat)
                        dismiss()
                    } label: {
                        ChatRowView(chat: chat, isSelected: chat.id == selectedChatID)
                    }
                    .buttonStyle(.plain)
                    .anchorPreference(key: RowAnchorKey.self, value: .bounds) { [chat.id: $0] }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            chatPendingDeletion = chat
                        } label: {
                            Label("Удалить", systemImage: "trash")
                        }
                    }
                }
            }
            .overlayPreferenceValue(RowAnchorKey.self) { anchors in
                deletionOverlay(anchors: anchors)
            }
            .overlay {
                if viewModel.chats.isEmpty {
                    ContentUnavailableView(
                        "Чатов пока нет",
                        systemImage: "bubble.left.and.bubble.right"
                    )
                }
            }
            .navigationTitle("История")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Готово") { dismiss() }
                }
            }
            .onAppear {
                viewModel.load()
            }
        }
    }

    /// Карточка удаления: центрируется по горизонтали и располагается над строкой (или под ней, если сверху нет места).
    @ViewBuilder
    private func deletionOverlay(anchors: [UUID: Anchor<CGRect>]) -> some View {
        if let chat = chatPendingDeletion, let anchor = anchors[chat.id] {
            GeometryReader { proxy in
                let rowFrame = proxy[anchor]
                let fitsAbove = rowFrame.minY > minimumSpaceAboveRow

                ZStack(alignment: .topLeading) {
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture { chatPendingDeletion = nil }

                    if fitsAbove {
                        VStack(spacing: 0) {
                            Spacer(minLength: 0)
                            card(for: chat)
                        }
                        .frame(width: proxy.size.width, height: max(rowFrame.minY - gap, 0))
                    } else {
                        VStack(spacing: 0) {
                            card(for: chat)
                            Spacer(minLength: 0)
                        }
                        .frame(width: proxy.size.width, height: proxy.size.height)
                        .offset(y: rowFrame.maxY + gap)
                    }
                }
            }
        }
    }

    private func card(for chat: Chat) -> some View {
        DeleteChatCard(
            onConfirm: {
                onDelete(chat)
                chatPendingDeletion = nil
            },
            onCancel: {
                chatPendingDeletion = nil
            }
        )
    }
}

/// Передаёт границы строк чатов наверх, чтобы карточка удаления знала, где строка.
private struct RowAnchorKey: PreferenceKey {
    static let defaultValue: [UUID: Anchor<CGRect>] = [:]

    static func reduce(value: inout [UUID: Anchor<CGRect>], nextValue: () -> [UUID: Anchor<CGRect>]) {
        value.merge(nextValue()) { $1 }
    }
}
