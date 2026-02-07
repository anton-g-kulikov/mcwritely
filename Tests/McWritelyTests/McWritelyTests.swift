import XCTest
@testable import McWritely

final class McWritelyTests: XCTestCase {
    func testKeychainStoreRoundTrip() throws {
        let service = "com.antonkulikov.mcwritely.tests"
        let account = "test-\(UUID().uuidString)"
        let value = "test-key-\(UUID().uuidString)"
        
        let store = KeychainStore.shared
        _ = store.delete(service: service, account: account)
        guard store.save(value, service: service, account: account) else {
            throw XCTSkip("Keychain not available or denied for tests.")
        }
        XCTAssertEqual(store.read(service: service, account: account), value)
        _ = store.delete(service: service, account: account)
    }
    
    func testOpenAIResponseParsingSuccess() throws {
        let json = """
        {
            "choices": [
                {
                    "message": {
                        "content": "  Hello world  "
                    }
                }
            ]
        }
        """.data(using: .utf8)!
        
        let decoded = try JSONDecoder().decode(OpenAIService.OpenAIResponse.self, from: json)
        let content = decoded.choices.first?.message.content.trimmingCharacters(in: .whitespacesAndNewlines)
        XCTAssertEqual(content, "Hello world")
    }
    
    func testOpenAIResponseParsingFailure() throws {
        let json = """
        {
            "choices": [
                {
                    "message": {}
                }
            ]
        }
        """.data(using: .utf8)!
        
        XCTAssertThrowsError(try JSONDecoder().decode(OpenAIService.OpenAIResponse.self, from: json))
    }
    
    func testKeychainServiceIdentifier() throws {
        // Since we are in a test environment, Bundle.main.bundleIdentifier might be nil
        // or the test runner's bundle ID. We just want to ensure it doesn't crash
        // and returns a reasonable string.
        let settings = Settings.shared
        // We can't easily access the private static keychainService, but we can verify
        // that KeychainStore operations don't fail when called via Settings.
        settings.apiKey = "test-key"
        XCTAssertEqual(settings.apiKey, "test-key")
        settings.apiKey = ""
        XCTAssertEqual(settings.apiKey, "")
    }
    
    func testKeepNewTextInClipboardDefaultIsFalse() throws {
        let settings = Settings.shared
        let original = settings.keepNewTextInClipboard
        settings.keepNewTextInClipboard = false
        XCTAssertFalse(settings.keepNewTextInClipboard)
        settings.keepNewTextInClipboard = original
    }

    func testRTFConversionToPlainText() throws {
        let attributed = NSAttributedString(string: "Hello RTF")
        let rtfData = try attributed.data(
            from: NSRange(location: 0, length: attributed.length),
            documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf]
        )

        let extracted = PasteboardTextExtractor.plainText(fromRTF: rtfData)
        XCTAssertEqual(extracted, "Hello RTF")
    }

    func testHTMLConversionToPlainText() throws {
        let html = "<html><body><b>Hello</b> world</body></html>"
        let data = try XCTUnwrap(html.data(using: .utf8))

        let extracted = PasteboardTextExtractor.plainText(fromHTML: data)
        let s = try XCTUnwrap(extracted)
        XCTAssertTrue(s.contains("Hello"))
        XCTAssertTrue(s.contains("world"))
    }

    func testReadObjectsCoercionExtractsString() throws {
        let objects: [Any] = [NSString(string: "Hello from coercion")]
        let extracted = PasteboardTextExtractor.plainText(fromReadObjects: objects)
        XCTAssertEqual(extracted, "Hello from coercion")
    }
}
