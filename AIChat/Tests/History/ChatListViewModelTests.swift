import XCTest
@testable import AI_Chat

@MainActor
final class ChatListViewModelTests: XCTestCase {
    func testCreateChatInsertsAtTopAndPersists() throws {
        let store = try TestStore()
        let list = ChatListViewModel(repository: store.repository)

        let first = try list.createChat()
        let second = try list.createChat()

        XCTAssertEqual(list.chats.map { $0.id }, [second.id, first.id])
        XCTAssertEqual(try store.repository.fetchChats().count, 2)
    }

    func testLoadSortsByUpdatedAtDescending() throws {
        let store = try TestStore()
        let older = store.makeChat()
        older.updatedAt = Date(timeIntervalSinceNow: -100)
        let newer = store.makeChat()
        newer.updatedAt = .now
        let list = ChatListViewModel(repository: store.repository)

        list.load()

        XCTAssertEqual(list.chats.map { $0.id }, [newer.id, older.id])
        XCTAssertNil(list.loadError)
    }

    func testDeleteRemovesChatFromListAndStore() throws {
        let store = try TestStore()
        let list = ChatListViewModel(repository: store.repository)
        let chat = try list.createChat()

        try list.delete(chat)

        XCTAssertTrue(list.chats.isEmpty)
        XCTAssertTrue(try store.repository.fetchChats().isEmpty)
    }
}
