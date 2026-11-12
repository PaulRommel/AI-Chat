import XCTest
@testable import AI_Chat

@MainActor
final class ChatViewModelTests: XCTestCase {
    func testSendStoresMessagesAndStreamsReply() async throws {
        let store = try TestStore()
        let chat = store.makeChat()
        let provider = FakeProvider(scripts: [.fragments(["Привет", ", мир"])])
        let viewModel = ChatViewModel(chat: chat, provider: provider, repository: store.repository)

        viewModel.draft = "  Привет  "
        viewModel.send()
        XCTAssertEqual(viewModel.draft, "")

        try await waitUntil { viewModel.state == .idle }

        let messages = chat.sortedMessages
        XCTAssertEqual(messages.map { $0.role }, [.user, .assistant])
        XCTAssertEqual(messages[0].content, "Привет")
        XCTAssertEqual(messages[1].content, "Привет, мир")
        XCTAssertEqual(messages[1].status, .completed)
        XCTAssertEqual(chat.title, "Привет")
        XCTAssertEqual(provider.requests, [[ChatRequestMessage(role: .user, content: "Привет")]])
    }

    func testEmptyDraftCannotBeSent() throws {
        let store = try TestStore()
        let chat = store.makeChat()
        let provider = FakeProvider(scripts: [])
        let viewModel = ChatViewModel(chat: chat, provider: provider, repository: store.repository)

        viewModel.draft = "   \n  "
        XCTAssertFalse(viewModel.canSend)
        viewModel.send()

        XCTAssertTrue(chat.messages.isEmpty)
        XCTAssertTrue(provider.requests.isEmpty)
    }

    func testFailureMarksReplyAsFailedAndRetryReusesIt() async throws {
        let store = try TestStore()
        let chat = store.makeChat()
        let provider = FakeProvider(scripts: [.fail(.offline), .fragments(["Ответ"])])
        let viewModel = ChatViewModel(chat: chat, provider: provider, repository: store.repository)

        viewModel.draft = "Вопрос"
        viewModel.send()
        try await waitUntil { viewModel.errorMessage != nil }

        XCTAssertEqual(viewModel.errorMessage, AIError.offline.userMessage)
        XCTAssertTrue(viewModel.canRetry)
        let failedReply = try XCTUnwrap(chat.sortedMessages.last)
        XCTAssertEqual(failedReply.status, .failed)

        viewModel.retry()
        try await waitUntil { viewModel.state == .idle }

        let messages = chat.sortedMessages
        XCTAssertEqual(messages.count, 2, "Повтор не должен создавать новых сообщений")
        XCTAssertEqual(messages.last?.id, failedReply.id)
        XCTAssertEqual(messages.last?.content, "Ответ")
        XCTAssertEqual(messages.last?.status, .completed)
        XCTAssertFalse(viewModel.canRetry)
        XCTAssertEqual(provider.requests.last, [ChatRequestMessage(role: .user, content: "Вопрос")])
    }

    func testServerErrorShowsStatusCode() async throws {
        let store = try TestStore()
        let chat = store.makeChat()
        let provider = FakeProvider(scripts: [.fail(.server(statusCode: 500))])
        let viewModel = ChatViewModel(chat: chat, provider: provider, repository: store.repository)

        viewModel.draft = "Вопрос"
        viewModel.send()
        try await waitUntil { viewModel.errorMessage != nil }

        XCTAssertEqual(viewModel.errorMessage, AIError.server(statusCode: 500).userMessage)
    }

    func testStopKeepsPartialReplyWithPartialStatus() async throws {
        let store = try TestStore()
        let chat = store.makeChat()
        let provider = FakeProvider(scripts: [.hangAfter("Часть")])
        let viewModel = ChatViewModel(chat: chat, provider: provider, repository: store.repository)

        viewModel.draft = "Расскажи подробно"
        viewModel.send()
        try await waitUntil { chat.sortedMessages.last?.content == "Часть" }

        viewModel.stop()
        try await waitUntil { viewModel.state == .idle }

        let reply = try XCTUnwrap(chat.sortedMessages.last)
        XCTAssertEqual(reply.status, .partial)
        XCTAssertEqual(reply.content, "Часть")
        XCTAssertNil(viewModel.errorMessage)
    }
}
