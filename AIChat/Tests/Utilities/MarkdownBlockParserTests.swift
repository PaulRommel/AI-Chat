import XCTest
@testable import AI_Chat

final class MarkdownBlockParserTests: XCTestCase {
    func testHorizontalRuleBecomesDivider() {
        XCTAssertEqual(MarkdownBlockParser.parse("---"), [.divider])
        XCTAssertEqual(MarkdownBlockParser.parse("***"), [.divider])
        XCTAssertEqual(MarkdownBlockParser.parse("* * *"), [.divider])
    }

    func testEmptyHeadingIsSkipped() {
        XCTAssertEqual(MarkdownBlockParser.parse("####"), [])
    }

    func testHeadingWithTextIsKept() {
        XCTAssertEqual(
            MarkdownBlockParser.parse("## Заголовок"),
            [.heading(level: 2, text: "Заголовок")]
        )
    }

    func testBulletAndNumberedLists() {
        XCTAssertEqual(
            MarkdownBlockParser.parse("- первый\n2. второй"),
            [.bullet("первый"), .numbered(number: "2", text: "второй")]
        )
    }

    func testParagraphLinesAreJoined() {
        XCTAssertEqual(
            MarkdownBlockParser.parse("строка один\nстрока два"),
            [.paragraph("строка один\nстрока два")]
        )
    }

    func testUnclosedCodeFenceRunsToEnd() {
        XCTAssertEqual(
            MarkdownBlockParser.parse("```swift\nlet a = 1"),
            [.code(language: "swift", text: "let a = 1")]
        )
    }
}
