import UIKit
import Combine
@testable import RightNow

// MARK: - Mock AuthenticationManager
class MockAuthenticationManager: AuthenticationServiceProtocol {
    @Published private(set) var currentUser: User?
    @Published private(set) var isLoading: Bool = false
    private var cancellables = Set<AnyCancellable>()
    
    var isUserAuthenticated: Bool {
        return MockFirebaseAuth.shared.currentUser != nil
    }
    
    var isAnonymous: Bool {
        return MockFirebaseAuth.shared.currentUser?.isAnonymous ?? false
    }
    
    // Add a Firebase auth state listener
    init() {
        MockFirebaseAuth.shared.addStateDidChangeListener { [weak self] user in
            guard let self = self else { return }
            
            if let mockUser = user {
                let loginType: User.LoginType
                
                if mockUser.isAnonymous {
                    loginType = .guest
                } else if mockUser.providers.contains("google.com") {
                    loginType = .google
                } else if mockUser.providers.contains("password") {
                    loginType = .email
                } else {
                    loginType = .guest
                }
                
                self.currentUser = User(
                    id: mockUser.uid,
                    email: mockUser.email,
                    loginType: loginType,
                    isAnonymous: mockUser.isAnonymous
                )
            } else {
                self.currentUser = nil
            }
        }
    }
    
    func login(email: String, password: String) -> Future<User?, Error> {
        isLoading = true
        return Future { [weak self] promise in
            MockFirebaseAuth.shared.signIn(withEmail: email, password: password) { result in
                self?.isLoading = false
                
                switch result {
                case .success(let mockUser):
                    let user = User(
                        id: mockUser.uid,
                        email: mockUser.email,
                        loginType: .email,
                        isAnonymous: false
                    )
                    promise(.success(user))
                    
                case .failure(let error):
                    promise(.failure(error))
                }
            }
        }
    }
    
    func signUp(email: String, password: String) -> Future<User?, Error> {
        isLoading = true
        return Future { [weak self] promise in
            MockFirebaseAuth.shared.createUser(withEmail: email, password: password) { result in
                self?.isLoading = false
                
                switch result {
                case .success(let mockUser):
                    let user = User(
                        id: mockUser.uid,
                        email: mockUser.email,
                        loginType: .email,
                        isAnonymous: false
                    )
                    promise(.success(user))
                    
                case .failure(let error):
                    promise(.failure(error))
                }
            }
        }
    }
    
    func googleSignIn(presentingViewController: UIViewController) -> Future<User?, Error> {
        isLoading = true
        return Future { [weak self] promise in
            MockGoogleSignIn.shared.signIn(withPresenting: presentingViewController) { result in
                switch result {
                case .success(let googleResult):
                    // Mock the Firebase credential process
                    MockFirebaseAuth.shared.signIn(with: "google-credential") { result in
                        self?.isLoading = false
                        
                        switch result {
                        case .success(let mockUser):
                            let user = User(
                                id: mockUser.uid,
                                email: mockUser.email,
                                loginType: .google,
                                isAnonymous: false
                            )
                            promise(.success(user))
                            
                        case .failure(let error):
                            promise(.failure(error))
                        }
                    }
                    
                case .failure(let error):
                    self?.isLoading = false
                    promise(.failure(error))
                }
            }
        }
    }
    
    func signInAnonymously() -> Future<User?, Error> {
        isLoading = true
        return Future { [weak self] promise in
            MockFirebaseAuth.shared.signInAnonymously { result in
                self?.isLoading = false
                
                switch result {
                case .success(let mockUser):
                    let user = User(
                        id: mockUser.uid,
                        email: mockUser.email,
                        loginType: .guest,
                        isAnonymous: true
                    )
                    promise(.success(user))
                    
                case .failure(let error):
                    promise(.failure(error))
                }
            }
        }
    }
    
    func convertAnonymousUserWithEmail(email: String, password: String) -> Future<User?, Error> {
        isLoading = true
        return Future { [weak self] promise in
            guard let currentUser = MockFirebaseAuth.shared.currentUser, currentUser.isAnonymous else {
                self?.isLoading = false
                promise(.failure(AuthError.notAnonymous))
                return
            }
            
            // Mock credential creation
            currentUser.link(with: "email-credential") { result in
                self?.isLoading = false
                
                switch result {
                case .success(let mockUser):
                    let user = User(
                        id: mockUser.uid,
                        email: mockUser.email,
                        loginType: .email,
                        isAnonymous: false
                    )
                    promise(.success(user))
                    
                case .failure(let error):
                    promise(.failure(error))
                }
            }
        }
    }
    
    @MainActor
    func convertAnonymousUserWithGoogle(presentingViewController: UIViewController) async throws -> User {
        guard let currentUser = MockFirebaseAuth.shared.currentUser, currentUser.isAnonymous else {
            throw AuthError.notAnonymous
        }
        
        isLoading = true
        
        do {
            // Mock Google sign-in
            let result = try await MockGoogleSignIn.shared.signIn(withPresenting: presentingViewController)
            
            // Mock credential linking
            let mockUser = try await currentUser.link(with: "google-credential")
            
            isLoading = false
            
            return User(
                id: mockUser.uid,
                email: mockUser.email,
                loginType: .google,
                isAnonymous: false
            )
        } catch {
            isLoading = false
            throw error
        }
    }
    
    func signOut() -> Future<Void, Error> {
        return Future { promise in
            do {
                try MockFirebaseAuth.shared.signOut()
                promise(.success(()))
            } catch {
                promise(.failure(error))
            }
        }
    }
}
