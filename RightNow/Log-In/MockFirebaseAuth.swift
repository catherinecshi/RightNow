import XCTest
import Combine
import FirebaseAuth
@testable import RightNow

// MARK: - Mock Firebase Auth
class MockFirebaseAuth {
    static let shared = MockFirebaseAuth()
    private init() {}
    
    var currentUser: MockFirebaseUser?
    var shouldFailSignIn = false
    var shouldFailSignUp = false
    var shouldFailAnonymousSignIn = false
    var shouldFailSignOut = false
    var shouldFailLinking = false
    var stateChangeListeners: [(MockFirebaseUser?) -> Void] = []
    
    func reset() {
        currentUser = nil
        shouldFailSignIn = false
        shouldFailSignUp = false
        shouldFailAnonymousSignIn = false
        shouldFailSignOut = false
        shouldFailLinking = false
        stateChangeListeners = []
    }
    
    func notifyStateChange() {
        stateChangeListeners.forEach { $0(currentUser) }
    }
    
    func addStateDidChangeListener(_ listener: @escaping (MockFirebaseUser?) -> Void) {
        stateChangeListeners.append(listener)
        // Initial notification
        listener(currentUser)
    }
    
    func signIn(withEmail email: String, password: String, completion: @escaping (Result<MockFirebaseUser, Error>) -> Void) {
        if shouldFailSignIn {
            completion(.failure(NSError(domain: "auth", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid credentials"])))
            return
        }
        
        let user = MockFirebaseUser(uid: "test-uid", email: email, isAnonymous: false, providers: ["password"])
        self.currentUser = user
        notifyStateChange()
        completion(.success(user))
    }
    
    func createUser(withEmail email: String, password: String, completion: @escaping (Result<MockFirebaseUser, Error>) -> Void) {
        if shouldFailSignUp {
            completion(.failure(NSError(domain: "auth", code: -1, userInfo: [NSLocalizedDescriptionKey: "Email already in use"])))
            return
        }
        
        let user = MockFirebaseUser(uid: "new-user-uid", email: email, isAnonymous: false, providers: ["password"])
        self.currentUser = user
        notifyStateChange()
        completion(.success(user))
    }
    
    func signInAnonymously(completion: @escaping (Result<MockFirebaseUser, Error>) -> Void) {
        if shouldFailAnonymousSignIn {
            completion(.failure(NSError(domain: "auth", code: -1, userInfo: [NSLocalizedDescriptionKey: "Network error"])))
            return
        }
        
        let user = MockFirebaseUser(uid: "anon-uid", email: nil, isAnonymous: true, providers: [])
        self.currentUser = user
        notifyStateChange()
        completion(.success(user))
    }
    
    func signOut() throws {
        if shouldFailSignOut {
            throw NSError(domain: "auth", code: -1, userInfo: [NSLocalizedDescriptionKey: "Network error"])
        }
        
        currentUser = nil
        notifyStateChange()
    }
    
    func signIn(with credential: Any, completion: @escaping (Result<MockFirebaseUser, Error>) -> Void) {
        if shouldFailSignIn {
            completion(.failure(NSError(domain: "auth", code: -1, userInfo: [NSLocalizedDescriptionKey: "Authentication failed"])))
            return
        }
        
        let user = MockFirebaseUser(uid: "google-uid", email: "google@example.com", isAnonymous: false, providers: ["google.com"])
        self.currentUser = user
        notifyStateChange()
        completion(.success(user))
    }
}
