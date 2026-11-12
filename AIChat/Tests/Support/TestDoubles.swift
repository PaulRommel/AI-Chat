import Foundation
import SwiftData
@testable import AI_Chat

/// Провайдер для тестов: по очереди выполняет заранее заданные сценарии и запоминает историю запросов.
final class FakeProvider: AIProvider, @unchecked Sendable {
    enum Script: Sendable {
        /// Отдаёт фрагменты и завершает поток.
        case fragments([String])
        /// Завершает поток ошибкой.
        case fail(AIError)
        /// Отдаёт фрагмент и ждёт отмены (имитирует длинный ответ).
        case hangAfter(String)
    }

    private let lock = NSLock()
    private var scripts: [Script]
    private var recorded: [[ChatRequestMessage]] = []

    init(scripts: [Script]) {
        self.scripts = scripts
    }

    var requests: [[ChatRequestMessage]] {
        lock.withLock { recorded }
    }

    func streamReply(to messages: [ChatRequestMessage]) -> AsyncThrowingStream<String, Error> {
        let script: Script = lock.withLock {
            recorded.append(messages)
            return scripts.isEmpty ? .fragments([]) : scripts.removeFirst()
        }
        return AsyncThrowingStream { continuation in
            switch script {
            case .fragments(let parts):
                parts.forEach { continuation.yield($0) }
                continuation.finish()
            case .fail(let error):
                continuation.finish(throwing: error)
            case .hangAfter(let part):
                continuation.yield(part)
                let task = Task {
                    try? await Task.sleep(for: .seconds(30))
                    continuation.finish()
                }
                continuation.onTermination = { _ in
                    task.cancel()
                }
            }
        }
    }
}

/// Хранилище в памяти на SwiftData для тестов репозитория и ViewModel.
@MainActor
final class TestStore {
    let container: ModelContainer
    let context: ModelContext
    let repository: SwiftDataChatRepository

    init() throws {
        container = try PersistenceController.makeContainer(inMemory: true)
        context = ModelContext(container)
        repository = SwiftDataChatRepository(context: context)
    }

    func makeChat() -> Chat {
        let chat = Chat()
        context.insert(chat)
        return chat
    }
}

struct TestTimeout: Error {}

/// Ждёт выполнения условия, проверяя его раз в несколько миллисекунд.
@MainActor
func waitUntil(timeout: Duration = .seconds(3), _ condition: () -> Bool) async throws {
    let deadline = ContinuousClock.now.advanced(by: timeout)
    while !condition() {
        guard ContinuousClock.now < deadline else { throw TestTimeout() }
        try await Task.sleep(for: .milliseconds(5))
    }
}
