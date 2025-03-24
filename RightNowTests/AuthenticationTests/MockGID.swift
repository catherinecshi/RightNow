import UIKit

/// Mock Google Sign In
class MockGoogleSignIn {
    static let shared = MockGoogleSignIn()
    private init() {}
    
    var shouldFailSignIn = false
    var configuration: Any?
    
    func reset() {
        shouldFailSignIn = false
    }
    
    func signIn(withPresenting viewController: UIViewController, completion: @escaping (Result<MockGoogleSignInResult, Error>) -> Void) {
        if shouldFailSignIn {
            completion(.failure(NSError(domain: "GIDSignIn", code: -1, userInfo: [NSLocalizedDescriptionKey: "Sign in canceled"])))
            return
        }
        
        let user = MockGoogleUser(idToken: "mock-id-token", accessToken: "mock-access-token")
        let result = MockGoogleSignInResult(user: user)
        completion(.success(result))
    }
    
    func signIn(withPresenting viewController: UIViewController) async throws -> MockGoogleSignInResult {
        if shouldFailSignIn {
            throw NSError(domain: "GIDSignIn", code: -1, userInfo: [NSLocalizedDescriptionKey: "Sign in canceled"])
        }
        
        let user = MockGoogleUser(idToken: "mock-id-token", accessToken: "mock-access-token")
        return MockGoogleSignInResult(user: user)
    }
}

/// Mock Google User
class MockGoogleUser {
    let idToken: String?
    let accessToken: String
    
    init(idToken: String?, accessToken: String) {
        self.idToken = idToken
        self.accessToken = accessToken
    }
}

/// Mock Google Sign In Result
class MockGoogleSignInResult {
    let user: MockGoogleUser
    
    init(user: MockGoogleUser) {
        self.user = user
    }
}
