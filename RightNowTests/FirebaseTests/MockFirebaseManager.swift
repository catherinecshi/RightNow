import XCTest
@testable import RightNow

class MockFirebaseManager: FirebaseConfigurable {
    var isConfigured = false
    var configureCallCount = 0
    
    func configure() {
        configureCallCount += 1
        isConfigured = true
    }
}
