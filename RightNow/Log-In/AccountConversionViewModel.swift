import Combine
import Foundation
import UIKit

class AccountConversionViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var passwordConfirmation: String = ""
    @Published var passwordsMatch: Bool = true
    @Published var statusViewModel: StatusViewModel?
    
    private var cancellableBag = Set<AnyCancellable>()
    private let authManager: AuthenticationManager
    
    init(authManager: AuthenticationManager = .shared) {
        self.authManager = authManager
        
        // Set up publisher to check if passwords match
        Publishers.CombineLatest($password, $passwordConfirmation)
            .map { password, confirmation in
                // If confirmation is empty, don't show mismatch yet
                if confirmation.isEmpty { return true }
                return password == confirmation
            }
            .assign(to: &$passwordsMatch)
    }
    
    func convertAccount() {
        // Basic validation
        guard !email.isEmpty else {
            statusViewModel = StatusViewModel(title: "Error", message: "Please enter your email address")
            return
        }
        
        guard !password.isEmpty else {
            statusViewModel = StatusViewModel(title: "Error", message: "Please enter a password")
            return
        }
        
        guard passwordsMatch else {
            statusViewModel = StatusViewModel(title: "Error", message: "Passwords do not match")
            return
        }
        
        guard password.count >= 6 else {
            statusViewModel = StatusViewModel(title: "Error", message: "Password must be at least 6 characters")
            return
        }
        
        // Check if the user is anonymous
        if !authManager.isAnonymous {
            statusViewModel = StatusViewModel(title: "Error", message: "You're already signed in with an account")
            return
        }
        
        // Attempt to convert the anonymous account
        authManager.convertAnonymousUserWithEmail(email: email, password: password)
            .receive(on: RunLoop.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.statusViewModel = StatusViewModel(
                            title: "Account Creation Failed",
                            message: error.localizedDescription
                        )
                    }
                },
                receiveValue: { [weak self] user in
                    if user != nil {
                        self?.statusViewModel = StatusViewModel(
                            title: "Successful",
                            message: "Your account has been created successfully"
                        )
                    } else {
                        self?.statusViewModel = StatusViewModel(
                            title: "Error",
                            message: "Failed to create account"
                        )
                    }
                }
            )
            .store(in: &cancellableBag)
    }
    
    func convertWithGoogle(from viewController: UIViewController) {
        // Check if the user is anonymous
        if !authManager.isAnonymous {
            statusViewModel = StatusViewModel(title: "Error", message: "You're already signed in with an account")
            return
        }
        
        Task {
            do {
                let user = try await authManager.convertAnonymousUserWithGoogle(presentingViewController: viewController)
                DispatchQueue.main.async { [weak self] in
                    self?.statusViewModel = StatusViewModel(
                        title: "Successful",
                        message: "Your account has been created successfully"
                    )
                }
            } catch {
                DispatchQueue.main.async { [weak self] in
                    self?.statusViewModel = StatusViewModel(
                        title: "Google Sign-In Failed",
                        message: error.localizedDescription
                    )
                }
            }
        }
    }
}
