import XCTest
@testable import AI_Chat

final class APIConfigurationTests: XCTestCase {
    func testDecodeKeyRestoresOriginalText() {
        let key = "sk-or-v1-example"
        let mask: [UInt8] = [0x5A, 0x13, 0xFE, 0x07]
        let bytes = key.utf8.enumerated().map { index, byte in byte ^ mask[index % mask.count] }

        XCTAssertEqual(APIConfiguration.decodeKey(bytes, mask: mask), key)
    }

    func testEmptyInputDecodesToNil() {
        XCTAssertNil(APIConfiguration.decodeKey([], mask: [1, 2]))
        XCTAssertNil(APIConfiguration.decodeKey([1], mask: []))
    }
}
