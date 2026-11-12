import XCTest
@testable import AI_Chat

final class StreamingParserTests: XCTestCase {
    func testDeltaLineReturnsContent() throws {
        let line = #"data: {"choices":[{"delta":{"content":"Привет"}}]}"#
        XCTAssertEqual(try StreamingParser.parse(line: line), .delta("Привет"))
    }

    func testDoneLineFinishesStream() throws {
        XCTAssertEqual(try StreamingParser.parse(line: "data: [DONE]"), .done)
    }

    func testEmptyAndCommentLinesAreIgnored() throws {
        XCTAssertNil(try StreamingParser.parse(line: ""))
        XCTAssertNil(try StreamingParser.parse(line: ": OPENROUTER PROCESSING"))
    }

    func testChunkWithoutContentIsIgnored() throws {
        let line = #"data: {"choices":[{"delta":{"role":"assistant"}}]}"#
        XCTAssertNil(try StreamingParser.parse(line: line))
    }

    func testErrorChunkThrowsStreamInterrupted() {
        let line = #"data: {"error":{"message":"Provider disconnected"}}"#
        XCTAssertThrowsError(try StreamingParser.parse(line: line)) { error in
            XCTAssertEqual(error as? AIError, .streamInterrupted)
        }
    }

    func testMalformedJSONThrowsDecoding() {
        XCTAssertThrowsError(try StreamingParser.parse(line: "data: {not json")) { error in
            XCTAssertEqual(error as? AIError, .decoding)
        }
    }
}
