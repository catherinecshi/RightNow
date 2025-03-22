import Combine
import Foundation
import UIKit

/// Corresponding model for AccountConversionViewController
class AccountConversionViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var passwordConfirmation: String = ""
    @Published var passwordsMatch: Bool = true
    @Published var statusViewModel: AuthenticationStatus?
    
    private var cancellableBag = Set<AnyCancellable>()
    private let authManager: AuthenticationManager
    
    /// Initializes model with link to central authentication manager
    init(authManager: AuthenticationManager = .shared) {
        self.authManager = authManager
        setupValidation()
    }
    
    /// Checks if password and confirm password values match
    /// Take values from publishers in view controller and checks if they match
    private func setupValidation() {
        // Set up publisher to check if passwords match
        Publishers.CombineLatest($password, $passwordConfirmation)
            .map { password, confirmation in
                // If confirmation is empty, don't show mismatch yet
                if confirmation.isEmpty { return true }
                return password == confirmation
            }
            .assign(to: &$passwordsMatch)
    }
    
    /// Initializes account conversion process with email/password credentials
    /// Prevents account from being created with certain errors
    /// - if any fields are empty
    /// - if password is less than 6 characters long
    /// - if user is somehow not anonymous
    func convertAccount() {
        // Basic validation
        guard !email.isEmpty else {
            statusViewModel = AuthenticationStatus(title: "Error", message: "Please enter your email address")
            return
        }
        
        guard !password.isEmpty else {
            statusViewModel = AuthenticationStatus(title: "Error", message: "Please enter a password")
            return
        }
        
        guard passwordsMatch else {
            statusViewModel = AuthenticationStatus(title: "Error", message: "Passwords do not match")
            return
        }
        
        guard password.count >= 6 else {
            statusViewModel = AuthenticationStatus(title: "Error", message: "Password must be at least 6 characters")
            return
        }
        
        // Check if the user is anonymous
        if !authManager.isAnonymous {
            statusViewModel = AuthenticationStatus(title: "Error", message: "You're already signed in with an account")
            return
        }
        
        // Attempt to convert the anonymous account
        authManager.convertAnonymousUserWithEmail(email: email, password: password)
            .receive(on: RunLoop.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.statusViewModel = AuthenticationStatus(
                            title: "Account Creation Failed",
                            message: error.localizedDescription
                        )
                    }
                },
                receiveValue: { [weak self] user in
                    if user != nil {
                        self?.statusViewModel = AuthenticationStatus(
                            title: "Successful",
                            message: "Your account has been created successfully"
                        )
                    } else {
                        self?.statusViewModel = AuthenticationStatus(
                            title: "Error",
                            message: "Failed to create account"
                        )
                    }
                }
            )
            .store(in: &cancellableBag)
    }
    
    
    /// Converts user with google credentials
    /// Takes viewController - view controller the google sign in UI will appear upon
    func convertWithGoogle(from viewController: UIViewController) {
        // Check if the user is anonymous
        if !authManager.isAnonymous {
            statusViewModel = AuthenticationStatus(title: "Error", message: "You're already signed in with an account")
            return
        }
        
        Task {
            do {
                let user = try await authManager.convertAnonymousUserWithGoogle(presentingViewController: viewController)
                DispatchQueue.main.async { [weak self] in
                    self?.statusViewModel = AuthenticationStatus(
                        title: "Successful",
                        message: "Your account has been created successfully"
                    )
                }
            } catch {
                DispatchQueue.main.async { [weak self] in
                    self?.statusViewModel = AuthenticationStatus(
                        title: "Google Sign-In Failed",
                        message: error.localizedDescription
                    )
                }
            }
        }
    }
}
