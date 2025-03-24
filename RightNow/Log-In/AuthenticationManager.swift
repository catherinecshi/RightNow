import Combine
import FirebaseCore
import FirebaseAuth
import GoogleSignIn

/// Types of Errors Authentication Manager can throw
enum AuthError: Error {
    case missingClientID
    case signInCancelled
    case missingCredentials
    case unknown(message: String)
    case notAuthenticated
    case notAnonymous
}

/// Defining AuthenticationManager behaviors for testing purposes
protocol AuthenticationServiceProtocol {
    var isUserAuthenticated: Bool { get }
    var isAnonymous: Bool { get }
    var isLoading: Bool { get }
    var currentUser: User? { get }
    
    func login(email: String, password: String) -> Future<User?, Error>
    func signUp(email: String, password: String) -> Future<User?, Error>
    func googleSignIn(presentingViewController: UIViewController) -> Future<User?, Error>
    func signInAnonymously() -> Future<User?, Error>
    func convertAnonymousUserWithEmail(email: String, password: String) -> Future<User?, Error>
    func convertAnonymousUserWithGoogle(presentingViewController: UIViewController) async throws -> User
    func signOut() -> Future<Void, Error>
}

/// Handles all interaction with FirebaseAuth from authentication models
class AuthenticationManager: AuthenticationServiceProtocol {
    static let shared = AuthenticationManager()
    
    @Published private(set) var currentUser: User?
    @Published private(set) var isLoading: Bool = false // flag for when an operation is processing
    private var cancellables = Set<AnyCancellable>()

    /// Returns true when user is logged in
    var isUserAuthenticated: Bool {
        return Auth.auth().currentUser != nil
    }
    
    /// Returns true when the current user is anonymously logged in
    var isAnonymous: Bool {
        return Auth.auth().currentUser?.isAnonymous ?? false
    }
    
    /// Initializes Authentication Manager
    /// - Establishes Firebase authentication state listener for
    ///     - Sign-ins
    ///     - Sign-outs
    ///     - Session expirations
    ///     - Authentication revocations
    /// - Updates currentUser accordingly
    private init() {
        Auth.auth().addStateDidChangeListener { [weak self] (_, firebaseUser) in
            guard let self = self else { return }
            
            if let firebaseUser = firebaseUser {
                let loginType = self.determineLoginType(from: firebaseUser)
                
                let user = User(
                    id: firebaseUser.uid,
                    email: firebaseUser.email,
                    loginType: loginType,
                    isAnonymous: firebaseUser.isAnonymous
                )
                self.currentUser = user
            } else {
                self.currentUser = nil
            }
        }
    }
    
    /// Determines login type using Firebase authentication provider data
    ///
    /// Parameter
    /// - firebaseUser : Firebase user object
    ///     - contains authentication data
    ///
    /// Returns
    /// - User.LoginType
    ///     - logintype for user
    private func determineLoginType(from firebaseUser: FirebaseAuth.User) -> User.LoginType {
        if firebaseUser.isAnonymous {
            return .guest
        }
        
        // If user has provider data, check the first provider
        if !firebaseUser.providerData.isEmpty {
            let providerId = firebaseUser.providerData[0].providerID
            
            switch providerId {
            case "google.com":
                return .google
            case "password":
                return .email
            default:
                return .guest
            }
        }
        
        return .guest
    }
    
    /// Authenticates user with email and password credentials
    /// Updates currentUser upon successful authentication
    ///
    /// Parameters:
    /// - email : String
    ///     - User's email address
    /// - password : String
    ///     - User's password
    ///
    /// Returns:
    /// - User object
    func login(email: String, password: String) -> Future<User?, Error> {
        isLoading = true
        return Future { [weak self] promise in
            Auth.auth().signIn(withEmail: email, password: password) { (result, error) in
                self?.isLoading = false // finished processing
                
                if let error = error {
                    promise(.failure(error))
                    return
                }
                
                guard let result = result else {
                    promise(.failure(NSError(domain: "AuthError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unknown error occurred"])))
                    return
                }
                
                let user = User(
                    id: result.user.uid,
                    email: result.user.email,
                    loginType: User.LoginType.email,
                    isAnonymous: false
                )
                promise(.success(user))
            }
        }
    }
    
    /// Creates new user with provided email and password
    /// Updates currentUser upon successful creation
    ///
    /// Parameters:
    /// - email : String
    ///     - email address for new account
    /// - password : String
    ///     - password for new account
    ///
    /// Returns:
    /// - User object
    func signUp(email: String, password: String) -> Future<User?, Error> {
        isLoading = true
        return Future { [weak self] promise in
            Auth.auth().createUser(withEmail: email, password: password) { (result, error) in
                self?.isLoading = false // finished processing
                
                if let error = error {
                    promise(.failure(error))
                    return
                }
                
                guard let result = result else {
                    promise(.failure(NSError(domain: "AuthError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unknown error occurred"])))
                    return
                }
                
                let user = User(
                    id: result.user.uid,
                    email: result.user.email,
                    loginType: User.LoginType.email,
                    isAnonymous: false
                )
                promise(.success(user))
            }
        }
    }
    
    /// Authenticates user with Google Sign-In
    /// Updates currentUser upon successful authentication
    ///
    /// Parameters:
    /// - presentingViewController : UIViewController
    ///     - viewcontroller upon which to present google sign in UI
    ///
    /// Returns:
    /// - User Object
    ///
    /// Throws:
    /// - AuthError.missingClientID
    ///     - if the firebase configuration lacks google client id
    /// - AuthError.missingCrendentials
    ///     - if authentication succeeds but required tokens are missing
    func googleSignIn(presentingViewController: UIViewController) -> Future<User?, Error> {
        isLoading = true
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(AuthError.unknown(message: "Self is deallocated")))
                return
            }
            
            print("🔍 Starting Google Sign-In flow")
            
            guard let clientID = FirebaseApp.app()?.options.clientID else {
                self.isLoading = false
                print("❌ Missing Firebase client ID")
                promise(.failure(AuthError.missingClientID))
                return
            }
            
            // create google sgin in configuration object
            let config = GIDConfiguration(clientID: clientID)
            GIDSignIn.sharedInstance.configuration = config
            
            // sign in flow
            GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController) { result, error in
                print("🔍 Google Sign-In attempt completed")
                self.isLoading = false
                if let error = error {
                    print("❌ Google Sign-In error: \(error.localizedDescription)")
                    promise(.failure(error))
                    return
                }
                
                guard let user = result?.user,
                      let idToken = user.idToken?.tokenString else {
                    print("❌ Missing Google credentials")
                    promise(.failure(AuthError.missingCredentials))
                    return
                }
                
                let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                               accessToken: user.accessToken.tokenString)
                print("✅ Google Sign-In successful, proceeding to Firebase auth")
                
                Auth.auth().signIn(with: credential) { authResult, error in
                    if let error = error {
                        promise(.failure(error))
                        print("❌ Firebase auth error: \(error.localizedDescription)")
                        return
                    }
                    
                    guard let authResult = authResult else {
                        print("❌ Firebase auth result is nil")
                        promise(.failure(AuthError.unknown(message: "Firebase auth result is nil")))
                        return
                    }
                    
                    print("✅ Firebase auth successful")
                    
                    let user = User(
                        id: authResult.user.uid,
                        email: authResult.user.email,
                        loginType: User.LoginType.google,
                        isAnonymous: false
                    )
                    
                    print("✅ User created: \(user.id), email: \(user.email ?? "no email")")
                    promise(.success(user))
                }
            }
        }
    }
    
    /// Anonymous sign in using Firebase
    /// Updates currentUser upon successful authentication
    ///
    /// Returns:
    /// - User Object
    func signInAnonymously() -> Future<User?, Error> {
        isLoading = true
        return Future { [weak self] promise in
            Auth.auth().signInAnonymously { (result, error) in
                self?.isLoading = false
                
                if let error = error {
                    promise(.failure(error))
                    return
                }
                
                guard let result = result else {
                    promise(.failure(NSError(domain: "AuthError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unknown error occurred"])))
                    return
                }
                
                let user = User(
                    id: result.user.uid,
                    email: result.user.email,
                    loginType: User.LoginType.guest,
                    isAnonymous: true
                )
                promise(.success(user))
            }
        }
    }
    
    /// Links an anonymous to a permanent email/password account
    /// Updates currentUser upon successful authentication
    ///
    /// Parameters:
    /// - email : String
    ///     - email address to be linked
    /// - password : String
    ///     - password to be linked
    ///
    /// Returns:
    /// - User Object
    func convertAnonymousUserWithEmail(email: String, password: String) -> Future<User?, Error> {
        isLoading = true
        return Future { [weak self] promise in
            guard let currentUser = Auth.auth().currentUser, currentUser.isAnonymous else {
                self?.isLoading = false
                promise(.failure(NSError(domain: "AuthError", code: -1, userInfo: [NSLocalizedDescriptionKey: "User is not anonymous"])))
                return
            }
            
            let credential = EmailAuthProvider.credential(withEmail: email, password: password)
            
            currentUser.link(with: credential) { (result, error) in
                self?.isLoading = false
                
                if let error = error {
                    promise(.failure(error))
                    return
                }
                
                guard let result = result else {
                    promise(.failure(NSError(domain: "AuthError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unknown error occurred"])))
                    return
                }
                
                let user = User(
                    id: result.user.uid,
                    email: result.user.email,
                    loginType: User.LoginType.email,
                    isAnonymous: false
                )
                promise(.success(user))
            }
        }
    }
    
    /// Links an anonymous to a permanent account with Google credentials
    /// Updates currentUser upon successful authentication
    ///
    /// Parameters:
    /// - presentingViewController : UIViewController
    ///     - view controller to present the google sign in UI upon
    ///
    /// Returns:
    /// - User Object
    ///
    /// Throws:
    /// - AuthError.notAnonymous
    ///     - user didn't start as anonymous user
    /// - AuthError.missingClientID
    ///     - if firebase configuration lacks a google client ID
    /// - AuthError.missingCredentials
    ///     - google authentication succeeds but required tokens are missing
    @MainActor
    func convertAnonymousUserWithGoogle(presentingViewController: UIViewController) async throws -> User {
        guard let currentUser = Auth.auth().currentUser, currentUser.isAnonymous else {
            throw AuthError.notAnonymous
        }
        
        isLoading = true
        
        do {
            // Get Google sign-in configuration
            guard let clientID = FirebaseApp.app()?.options.clientID else {
                isLoading = false
                throw AuthError.missingClientID
            }
            
            // Create Google sign-in configuration
            let config = GIDConfiguration(clientID: clientID)
            GIDSignIn.sharedInstance.configuration = config
            
            // Start Google sign-in flow
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController)
            let user = result.user
            
            guard let idToken = user.idToken?.tokenString else {
                isLoading = false
                throw AuthError.missingCredentials
            }
            
            // Create Google credential
            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: user.accessToken.tokenString
            )
            
            // Link the anonymous account with Google credential
            let authResult = try await currentUser.link(with: credential)
            
            isLoading = false
            
            // Return updated user
            return User(
                id: authResult.user.uid,
                email: authResult.user.email,
                loginType: User.LoginType.google,
                isAnonymous: false
            )
        } catch {
            isLoading = false
            throw error
        }
    }
    
    /// Signs out current user out of firebase and session
    /// Throws firebase authentication error if sign out fails
    func signOut() -> Future<Void, Error> {
        return Future { promise in
            do {
                if let uid = Auth.auth().currentUser?.uid {
                    print("Current user UID \(uid)")
                }
                Task { // clear local storage so it won't appear when the log into another account
                    await HabitRepository.shared.clearLocalData()
                }
                try Auth.auth().signOut()
                AppState.shared.currentUser = nil
                promise(.success(()))
            } catch let error {
                promise(.failure(error))
            }
        }
    }
}
