import UIKit
import Combine

/// View model for WelcomeViewController
class WelcomeViewModel: ObservableObject {
    @Published var state: AppState
    @Published var statusViewModel: AuthenticationStatus?
    
    private var cancellableBag = Set<AnyCancellable>()
    private let authManager: AuthenticationManager
    
    /// Initializes with app state and authentication manager
    init(state: AppState, authManager: AuthenticationManager = .shared) {
        self.state = state
        self.authManager = authManager
    }
    
    /// Anonymous authentication for guest log-in
    /// Updates publisher with success or failure
    func continueAsGuest() {
        authManager.signInAnonymously()
            .receive(on: RunLoop.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.statusViewModel = AuthenticationStatus(
                            title: "Error",
                            message: error.localizedDescription
                        )
                    }
                },
                receiveValue: { [weak self] user in
                    if let user = user {
                        self?.state.currentUser = user
                        self?.statusViewModel = AuthenticationStatus.logInSuccessStatus
                    } else {
                        self?.statusViewModel = AuthenticationStatus.errorStatus
                    }
                }
            )
            .store(in: &cancellableBag)
    }
    
    /// Initiates Google-SignIn authentication flow
    /// Takes viewController - view controller the google sign in UI will be presented upon
    /// Updates publisher with success or failure
    func signInWithGoogle(from viewController: UIViewController) {
        authManager.googleSignIn(presentingViewController: viewController)
            .receive(on: RunLoop.main)
            .sink(receiveCompletion: { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.statusViewModel = AuthenticationStatus(
                        title: "Google Sign-In Failed",
                        message: error.localizedDescription
                    )
                }
            }, receiveValue: { [weak self] user in
                if let user = user {
                    self?.state.currentUser = user
                    self?.statusViewModel = AuthenticationStatus.logInSuccessStatus
                } else {
                    self?.statusViewModel = AuthenticationStatus.errorStatus
                }
            })
            .store(in: &cancellableBag)
    }
    
    func signInWithApple(from viewController: UIViewController) {
        authManager.appleSignIn(presentingViewController: viewController)
            .receive(on: RunLoop.main)
            .sink(receiveCompletion: { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.statusViewModel = AuthenticationStatus(
                        title: "Apple Sign-In Failed",
                        message: error.localizedDescription
                    )
                }
            }, receiveValue: { [weak self] user in
                if let user = user {
                    self?.state.currentUser = user
                    self?.statusViewModel = AuthenticationStatus.logInSuccessStatus
                } else {
                    self?.statusViewModel = AuthenticationStatus.errorStatus
                }
            })
            .store(in: &cancellableBag)
    }
}
