import Combine
import FirebaseCore
import FirebaseAuth
import GoogleSignIn

class SignInViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var statusViewModel: StatusViewModel?
    @Published var state: AppState
    
    private var cancellableBag = Set<AnyCancellable>()
    private let authManager: AuthenticationManager
    
    init(state: AppState, authManager: AuthenticationManager = .shared) {
        self.state = state
        self.authManager = authManager
    }
    
    func login() {
        authManager.login(email: email, password: password)
            .receive(on: RunLoop.main)
            .sink(receiveCompletion: { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.statusViewModel = StatusViewModel(
                        title: "Error",
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
