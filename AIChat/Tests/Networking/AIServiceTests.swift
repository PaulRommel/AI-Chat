import XCTest
@testable import AI_Chat

final class AIServiceTests: XCTestCase {
    private let endpoint = URL(string: "https://example.test/chat")
    private let question = [ChatRequestMessage(role: .user, content: "Привет")]

    override func tearDown() {
        MockURLProtocol.handler = nil
        MockURLProtocol.capturedRequest = nil
        super.tearDown()
    }

    func testStreamsFragmentsFromSSEBody() async throws {
        MockURLProtocol.handler = { request in
            let body = """
            data: {"choices":[{"delta":{"content":"Прив"}}]}

            : OPENROUTER PROCESSING
            data: {"choices":[{"delta":{"content":"ет"}}]}

            data: [DONE]

            """
            return (try makeResponse(for: request, status: 200), Data(body.utf8))
        }

        let text = try await collect(makeService().streamReply(to: question))

        XCTAssertEqual(text, "Привет")
    }

    func testRequestCarriesKeyModelAndStreamFlag() async throws {
        MockURLProtocol.handler = { request in
            (try makeResponse(for: request, status: 200), Data("data: [DONE]\n".utf8))
        }

        _ = try await collect(makeService().streamReply(to: question))

        let request = try XCTUnwrap(MockURLProtocol.capturedRequest)
        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer test-key")
        let body = try XCTUnwrap(requestBody(request))
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Any])
        XCTAssertEqual(json["model"] as? String, "test/model")
        XCTAssertEqual(json["stream"] as? Bool, true)
    }

    func testHTTPStatusesMapToErrors() async throws {
        let cases: [(status: Int, expected: AIError)] = [
            (401, .invalidAPIKey),
            (429, .rateLimited),
            (500, .server(statusCode: 500))
        ]
        for testCase in cases {
            let status = testCase.status
            MockURLProtocol.handler = { request in
                (try makeResponse(for: request, status: status), Data())
            }
            do {
                _ = try await collect(makeService().streamReply(to: question))
                XCTFail("Ожидалась ошибка для статуса \(status)")
            } catch {
                XCTAssertEqual(error as? AIError, testCase.expected)
            }
        }
    }

    func testMissingKeyFailsBeforeRequest() async throws {
        do {
            _ = try await collect(makeService(apiKey: nil).streamReply(to: question))
            XCTFail("Ожидалась ошибка без ключа")
        } catch {
            XCTAssertEqual(error as? AIError, .missingAPIKey)
        }
        XCTAssertNil(MockURLProtocol.capturedRequest)
    }

    func testNetworkFailureMapsToOffline() async throws {
        MockURLProtocol.handler = { _ in
            throw URLError(.notConnectedToInternet)
        }
        do {
            _ = try await collect(makeService().streamReply(to: question))
            XCTFail("Ожидалась ошибка сети")
        } catch {
            XCTAssertEqual(error as? AIError, .offline)
        }
    }

    func testErrorInsideStreamIsReported() async throws {
        MockURLProtocol.handler = { request in
            (try makeResponse(for: request, status: 200), Data("data: {\"error\":{\"message\":\"boom\"}}\n".utf8))
        }
        do {
            _ = try await collect(makeService().streamReply(to: question))
            XCTFail("Ожидалась ошибка потока")
        } catch {
            XCTAssertEqual(error as? AIError, .streamInterrupted)
        }
    }

    private func makeService(apiKey: String? = "test-key") -> AIService {
        let configuration = APIConfiguration(apiKey: apiKey, model: "test/model", endpoint: endpoint)
        let sessionConfiguration = URLSessionConfiguration.ephemeral
        sessionConfiguration.protocolClasses = [MockURLProtocol.self]
        let client = APIClient(session: URLSession(configuration: sessionConfiguration))
        return AIService(configuration: configuration, client: client)
    }

    private func collect(_ stream: AsyncThrowingStream<String, Error>) async throws -> String {
        var text = ""
        for try await fragment in stream {
            text += fragment
        }
        return text
    }

    /// Тело запроса: иногда URLSession передаёт его потоком, а не в `httpBody`.
    private func requestBody(_ request: URLRequest) -> Data? {
        if let body = request.httpBody {
            return body
        }
        guard let stream = request.httpBodyStream else { return nil }
        stream.open()
        defer { stream.close() }
        var data = Data()
        var buffer = [UInt8](repeating: 0, count: 1024)
        while stream.hasBytesAvailable {
            let read = stream.read(&buffer, maxLength: buffer.count)
            if read <= 0 { break }
            data.append(buffer, count: read)
        }
        return data
    }
}

private func makeResponse(for request: URLRequest, status: Int) throws -> HTTPURLResponse {
    guard let response = HTTPURLResponse(
        url: request.url ?? URL(fileURLWithPath: "/"),
        statusCode: status,
        httpVersion: nil,
        headerFields: nil
    ) else {
        throw URLError(.badServerResponse)
    }
    return response
}

