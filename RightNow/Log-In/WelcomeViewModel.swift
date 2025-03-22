import UIKit
import Combine

class WelcomeViewModel: ObservableObject {
    @Published var state: AppState
    @Published var statusViewModel: StatusViewModel?
    
    private var cancellableBag = Set<AnyCancellable>()
    private let authManager: AuthenticationManager
    
    init(state: AppState, authManager: AuthenticationManager = .shared) {
        self.state = state
        self.authManager = authManager
    }
    
    func continueAsGuest() {
        print("continuing as guest")
        authManager.signInAnonymously()
            .receive(on: RunLoop.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    print("received completion: \(completion)")
                    if case .failure(let error) = completion {
                        print("error: \(error.localizedDescription)")
                        self?.statusViewModel = StatusViewModel(
                            title: "Error",
                            message: error.localizedDescription
                        )
                    }
                },
                receiveValue: { [weak self] user in
                    print("value received")
                    if let user = user {
                        print("user is user")
                        self?.state.currentUser = user
                        self?.statusViewModel = StatusViewModel.logInSuccessStatus
                    } else {
                        self?.statusViewModel = StatusViewModel.errorStatus
                    }
                }
            )
            .store(in: &cancellableBag)
    }
    
    func signInWithGoogle(from viewController: UIViewController) {
        authManager.googleSignIn(presentingViewController: viewController)
            .receive(on: RunLoop.main)
            .sink(receiveCompletion: { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.statusViewModel = StatusViewModel(
                        title: "Google Sign-In Failed",
                        message: error.localizedDescription
                    )
                }
            }, receiveValue: { [weak self] user in
                if let user = user {
                    self?.state.currentUser = user
                    self?.statusViewModel = StatusViewModel.logInSuccessStatus
                } else {
                    self?.statusViewModel = StatusViewModel.errorStatus
                }
            })
            .store(in: &cancellableBag)
    }
}
