import Foundation

/// Mock User for Firebase
class MockFirebaseUser {
    let uid: String
    let email: String?
    let isAnonymous: Bool
    let providers: [String]
    
    init(uid: String, email: String?, isAnonymous: Bool, providers: [String]) {
        self.uid = uid
        self.email = email
        self.isAnonymous = isAnonymous
        self.providers = providers
    }
    
    func link(with credential: Any, completion: @escaping (Result<MockFirebaseUser, Error>) -> Void) {
        if MockFirebaseAuth.shared.shouldFailLinking {
            completion(.failure(NSError(domain: "auth", code: -1, userInfo: [NSLocalizedDescriptionKey: "Linking failed"])))
            return
        }
        
        let updatedUser = MockFirebaseUser(
            uid: self.uid,
            email: "linked@example.com",
            isAnonymous: false,
            providers: self.providers + ["password"]
        )
        
        MockFirebaseAuth.shared.currentUser = updatedUser
        MockFirebaseAuth.shared.notifyStateChange()
        completion(.success(updatedUser))
    }
    
    func link(with credential: Any) async throws -> MockFirebaseUser {
        if MockFirebaseAuth.shared.shouldFailLinking {
            throw NSError(domain: "auth", code: -1, userInfo: [NSLocalizedDescriptionKey: "Linking failed"])
        }
        
        let updatedUser = MockFirebaseUser(
            uid: self.uid,
            email: "linked@example.com",
            isAnonymous: false,
            providers: self.providers + ["google.com"]
        )
        
        MockFirebaseAuth.shared.currentUser = updatedUser
        MockFirebaseAuth.shared.notifyStateChange()
        return updatedUser
    }
}
