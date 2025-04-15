import UIKit
import Combine
import FirebaseAuth

/// View Controller for Settings
/// Currently contains buttons for account state management
/// - Permanent Account
///     - Sign out button
/// - Guest Account
///     - Sign out button
///     - Conversion button
class SettingsViewController: UIViewController {
    // MARK: - Properties
    private let state: AppState // persistent storage
    private let authManager: AuthenticationManager
    private var cancellableBag: Set<AnyCancellable> = []
    weak var sceneDelegate: SceneDelegate?
    
    private lazy var signOutButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = UIConfiguration.tintColor
        button.setTitle("Sign Out", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.addTarget(self, action: #selector(signOutButtonTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isHidden = true
        return button
    }()
    
    private lazy var linkAccountButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = UIConfiguration.tintColor
        button.setTitle("Link Account", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.addTarget(self, action: #selector(linkAccountButtonTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isHidden = true
        return button
    }()
    
    private lazy var logIntoAnotherAccountButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = UIConfiguration.tintColor
        button.setTitle("Log Into Another Account", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.addTarget(self, action: #selector(logIntoAnotherAccountButtonTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isHidden = true
        return button
    }()
    
    private lazy var deleteAccountButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = .systemRed
        button.setTitle("Delete Account", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.addTarget(self, action: #selector(deleteAccountTapped), for: .touchUpInside)
        button.isHidden = false
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // MARK: - Lifecycle
    /// Initializes settings with current app state
    init(state: AppState = .shared, authManager: AuthenticationManager = .shared) {
        self.state = state
        self.authManager = authManager
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Settings"
        navigationController?.navigationBar.isHidden = false
        setupButton()
        setupBackButton()
        self.sceneDelegate = getSceneDelegate()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateUIForAuthState()
    }
    
    private func getSceneDelegate() -> SceneDelegate? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let sceneDelegate = windowScene.delegate as? SceneDelegate else {
            return nil
        }
        return sceneDelegate
    }
    
    // MARK: - UI Setup
    /// Changes which buttons are visible depending on whether the user is anonymous or not
    /// - Permanently logged in
    ///     - display sign out button
    /// - Anonymously logged in
    ///     - display sign out button
    ///     - display conversion button
    private func updateUIForAuthState() {
        guard let currentUser = Auth.auth().currentUser else {
            // no user logged in (this shouldn't happen??)
            navigateToWelcome()
            return
        }
        
        if currentUser.isAnonymous {
            // ananoymous user
            signOutButton.isHidden = true
            linkAccountButton.isHidden = false
            logIntoAnotherAccountButton.isHidden = false
            deleteAccountButton.isHidden = false
        } else {
            // signed in user
            signOutButton.isHidden = false
            linkAccountButton.isHidden = true
            logIntoAnotherAccountButton.isHidden = true
            deleteAccountButton.isHidden = false
        }
    }
    
    /// Sets up UI for all buttons
    private func setupButton() {
        view.backgroundColor = .white
        
        view.addSubview(signOutButton)
        view.addSubview(linkAccountButton)
        view.addSubview(logIntoAnotherAccountButton)
        view.addSubview(deleteAccountButton)
        
        NSLayoutConstraint.activate([
            signOutButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            signOutButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            signOutButton.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            signOutButton.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        NSLayoutConstraint.activate([
            // Link Account button positioned above the center
            linkAccountButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            linkAccountButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            linkAccountButton.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -40),
            linkAccountButton.heightAnchor.constraint(equalToConstant: 50),
            
            // Log Into Another Account button positioned below the center
            logIntoAnotherAccountButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            logIntoAnotherAccountButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            logIntoAnotherAccountButton.topAnchor.constraint(equalTo: linkAccountButton.bottomAnchor, constant: 20),
            logIntoAnotherAccountButton.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        NSLayoutConstraint.activate([
            deleteAccountButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            deleteAccountButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            deleteAccountButton.topAnchor.constraint(equalTo: signOutButton.bottomAnchor, constant: 20),
            deleteAccountButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    /// Sets up button to dismiss view
    private func setupBackButton() {
        let backButton = UIBarButtonItem(
            image: UIImage(systemName: "xmark"),
            style: .plain,
            target: self,
            action: #selector(backButtonTapped)
        )
        backButton.tintColor = UIColor.lightGray
        navigationItem.rightBarButtonItem = backButton
    }
    
    // MARK: - Actions
    /// Signed in user tapped sign out button
    @objc func signOutButtonTapped() {
        signOut()
    }
    
    /// Anonymous user tapped conversion button
    @objc func linkAccountButtonTapped() {
        navigateToConversion()
    }
    
    /// Anonymous user tapped sign out button
    /// Warns user that they're about to lose all of their progress
    ///     (since guest users don't have a way of signing back in)
    /// Sends user to conversion if they ask to link account instead
    /// Logs user out if asked
    @objc func logIntoAnotherAccountButtonTapped() {
        // warn users that they're about to lose all of their progress
        let alert = CustomAlertViewController(
            title: "Warning!",
            message: "You'll lose all of your progress with the anonymous account if you log out! You can keep the progress by linking it to an account",
            okButtonTitle: "Link Account",
            cancelButtonTitle: "Log Out",
            completionOk: { [weak self] in
                self?.navigateToConversion()
            },
            completionCancel: { [weak self] in
                self?.signOut()
            }
        )
        present(alert, animated: true)
    }
    
    /// User decides to delete their account
    /// Prompt the user for confirmation before deletion
    @objc func deleteAccountTapped() {
        // Show confirmation alert using your custom alert controller
        let alert = CustomAlertViewController(
            title: "Delete Account?",
            message: "This action cannot be undone. All your data will be permanently deleted.",
            okButtonTitle: "Delete",
            cancelButtonTitle: "Cancel",
            completionOk: { [weak self] in
                self?.deleteAccount()
            },
            completionCancel: nil
        )
        present(alert, animated: true)
    }
    
    /// Back button tapped and exits out of the settings
    var customTransitionDelegate: CustomSlideInTransition?
    @objc private func backButtonTapped() {
        if let navController = navigationController {
            navController.transitioningDelegate = customTransitionDelegate
        }
        dismiss(animated: true)
    }
    
    private func deleteAccount() {
        authManager.deleteCurrentAccount()
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                guard let self = self else { return }
                
                switch completion {
                case .failure(let error):
                    let alert = CustomAlertViewController(
                        title: "Account Deletion Failed",
                        message: "There was a problem deleting your account: \(error.localizedDescription)"
                    )
                    self.present(alert, animated: true)
                case .finished:
                    break
                }
            }, receiveValue: { [weak self] _ in
                // Account was successfully deleted
                let alert = CustomAlertViewController(
                    title: "Account Deleted",
                    message: "Your account has been successfully deleted.",
                    completionOk: { [weak self] in
                        self?.navigateToWelcome()
                    }
                )
                self?.present(alert, animated: true)
            })
            .store(in: &cancellableBag)
    }
    
    /// Signs the user out of Firebase and AppState
    /// Throws alert if failure
    private func signOut() {
        authManager.signOut()
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                guard let self = self else { return }
                
                switch completion {
                case .failure:
                    let alert = CustomAlertViewController(title: "Sign Out Failed",
                                                          message: "There was a problem signing out")
                    self.present(alert, animated: true)
                case .finished:
                    break
                }
            }, receiveValue: { [weak self] _ in
                self?.navigateToWelcome()
            })
            .store(in: &cancellableBag)
    }
    
    /// Handles navigation for sending the user to initial welcome view
    /// Uses custom transition to present WelcomeViewController
    /// Removes current view from root view controller
    private func navigateToWelcome() {
        if let sceneDelegate = self.sceneDelegate, let window = sceneDelegate.window {
            let welcomeVC = WelcomeViewController(state: state)
            
            // Create a navigation controller with the sign-in VC as the root
            let navigationController = UINavigationController(rootViewController: welcomeVC)
            
            // Create a transition animation
            let transition = CATransition()
            transition.duration = 0.3
            transition.type = CATransitionType.push
            transition.subtype = CATransitionSubtype.fromLeft
            transition.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
            
            // Set the window's root view controller to the navigation controller
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                window.layer.add(transition, forKey: nil)
                window.rootViewController = navigationController
            }
        }
    }
}

// MARK: - Account Conversion
/// Handle interactions with AccountConversionViewController
extension SettingsViewController: AccountConversionDelegate {
    /// Handles navigation to account conversion view
    private func navigateToConversion() {
        let conversionVC = AccountConversionViewController()
        let navigationController = UINavigationController(rootViewController: conversionVC)
        navigationController.modalPresentationStyle = .fullScreen
        present(navigationController, animated: true)
    }
    
    /// Update settings UI if user successfully linked anonymous account
    /// Takes successfully - true if user successfully linked anonymous account
    func conversionDidComplete(successfully: Bool) {
        if successfully {
            updateUIForAuthState()
            
            // present success message for the user
            let alert = CustomAlertViewController(title: "Account Linked",
                                                  message: "Your progress has been saved to your new account!")
            present(alert, animated: true)
        }
    }
}
