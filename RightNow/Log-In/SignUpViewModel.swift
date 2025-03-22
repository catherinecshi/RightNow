import Combine
import Foundation

class SignUpViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var passwordConfirmation: String = ""
    @Published var statusViewModel: StatusViewModel?
    @Published var state: AppState
    
    @Published private(set) var passwordsMatch: Bool = true
    
    private var cancellableBag = Set<AnyCancellable>()
    private let authManager: AuthenticationManager
    
    init(state: AppState, authManager: AuthenticationManager = .shared) {
        self.state = state
        self.authManager = authManager
    }
    
    private func setupValidation() {
        // Monitor both password fields for real-time validation
        Publishers.CombineLatest($password, $passwordConfirmation)
            .map { password, confirmation in
                // Only validate when user has entered something in confirmation field
                return password == confirmation || confirmation.isEmpty
            }
            .assign(to: \.passwordsMatch, on: self)
            .store(in: &cancellableBag)
    }
    
    func signUp() {
        // validate if the passwords match
        guard passwordsMatch && !passwordConfirmation.isEmpty else {
            statusViewModel = StatusViewModel(
                title: "Error",
                message: "Passwords do not match"
            )
            return
        }
        
        authManager.signUp(email: email, password: password)
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
                    self?.statusViewModel = StatusViewModel.signUpSuccessStatus
                } else {
                    self?.statusViewModel = StatusViewModel.errorStatus
                }
            })
            .store(in: &cancellableBag)
    }
}
