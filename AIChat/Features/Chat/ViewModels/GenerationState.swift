/// Состояние генерации ответа в текущем чате.
enum GenerationState: Equatable {
    case idle
    case sending
    case streaming
    case failed(message: String)

    var isBusy: Bool {
        switch self {
        case .sending, .streaming:
            true
        case .idle, .failed:
            false
        }
    }
}
