import XCTest
@testable import Writely

final class WritelyTests: XCTestCase {
    func testKeychainStoreRoundTrip() throws {
        let service = "com.antonkulikov.writely.tests"
        let account = "test-\(UUID().uuidString)"
        let value = "test-key-\(UUID().uuidString)"
        
        let store = KeychainStore.shared
        _ = store.delete(service: service, account: account)
        XCTAssertTrue(store.save(value, service: service, account: account))
        XCTAssertEqual(store.read(service: service, account: account), value)
        _ = store.delete(service: service, account: account)
    }
}
