import Combine
import FirebaseCore
import FirebaseAuth
import GoogleSignIn

enum AuthError: Error {
    case missingClientID
    case signInCancelled
    case missingCredentials
    case unknown(message: String)
    case notAuthenticated
    case notAnonymous
}

class AuthenticationManager {
    static let shared = AuthenticationManager()
    
    @Published private(set) var currentUser: User?
    @Published private(set) var isLoading: Bool = false
    private var cancellables = Set<AnyCancellable>()

    var isUserAuthenticated: Bool {
        return Auth.auth().currentUser != nil
    }
    
    var isAnonymous: Bool {
        return Auth.auth().currentUser?.isAnonymous ?? false
    }
    
    private init() {
        // set up auth state observer
        Auth.auth().addStateDidChangeListener { [weak self] (_, firebaseUser) in
            if let firebaseUser = firebaseUser {
                // User signed in
                let user = User(
                    id: firebaseUser.uid,
                    email: firebaseUser.email,
                    isAnonymous: firebaseUser.isAnonymous
                )
                self?.currentUser = user
            } else {
                // User signed out
                self?.currentUser = nil
            }
        }
    }
    
    // Login with email
    func login(email: String, password: String) -> Future<User?, Error> {
        isLoading = true
        return Future { [weak self] promise in
            Auth.auth().signIn(withEmail: email, password: password) { (result, error) in
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
    
    // Sign up with email
    func signUp(email: String, password: String) -> Future<User?, Error> {
        isLoading = true
        return Future { [weak self] promise in
            Auth.auth().createUser(withEmail: email, password: password) { (result, error) in
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
    
    // sign in with google
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
    
    // Sign in anonymously
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
    
    // Convert anonymous user to permanent account
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
    
    // Convert anonymous user to Google account
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
    
    // Sign out
    func signOut() -> Future<Void, Error> {
        return Future { promise in
            do {
                try Auth.auth().signOut()
                promise(.success(()))
            } catch let error {
                promise(.failure(error))
            }
        }
    }
}
