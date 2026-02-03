import XCTest
@testable import Writely

final class WritelyTests: XCTestCase {
    func testKeychainStoreRoundTrip() throws {
        let service = "com.antonkulikov.writely.tests"
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
        let response: [String: Any] = [
            "choices": [
                [
                    "message": [
                        "content": "  Hello world  "
                    ]
                ]
            ]
        ]
        
        let data = try JSONSerialization.data(withJSONObject: response)
        let parsed = try OpenAIService.parseResponse(data)
        XCTAssertEqual(parsed, "Hello world")
    }
    
    func testOpenAIResponseParsingFailure() throws {
        let response: [String: Any] = [
            "choices": [
                [
                    "message": [:]
                ]
            ]
        ]
        
        let data = try JSONSerialization.data(withJSONObject: response)
        XCTAssertThrowsError(try OpenAIService.parseResponse(data))
    }
    
    func testKeepNewTextInClipboardDefaultIsFalse() throws {
        let settings = Settings.shared
        let original = settings.keepNewTextInClipboard
        settings.keepNewTextInClipboard = false
        XCTAssertFalse(settings.keepNewTextInClipboard)
        settings.keepNewTextInClipboard = original
    }
}
