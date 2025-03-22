import UIKit
import FirebaseAuth

class SettingsViewController: UIViewController {
    private let state: AppState
    
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
    
    init(state: AppState = .shared) {
        self.state = state
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
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateUIForAuthState()
    }
    
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
        } else {
            // signed in user
            signOutButton.isHidden = false
            linkAccountButton.isHidden = true
            logIntoAnotherAccountButton.isHidden = true
        }
    }
    
    private func setupButton() {
        view.backgroundColor = .white
        
        view.addSubview(signOutButton)
        view.addSubview(linkAccountButton)
        view.addSubview(logIntoAnotherAccountButton)
        
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
    }
    
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
    
    // MARK: - switch
    @objc func signOutButtonTapped() {
        guard let currentUser = Auth.auth().currentUser else { return }
        signOut()
    }
    
    @objc func linkAccountButtonTapped() {
        convertAccountInWelcome()
    }
    
    @objc func logIntoAnotherAccountButtonTapped() {
        // warn users that they're about to lose all of their progress
        let alert = CustomAlertViewController(
            title: "Warning!",
            message: "You'll lose all of your progress with the anonymous account if you log out! You can keep the progress by linking it to an account",
            okButtonTitle: "Link Account",
            cancelButtonTitle: "Log Out",
            completionOk: { [weak self] in
                self?.convertAccountInWelcome()
            },
            completionCancel: { [weak self] in
                self?.signOut()
            }
        )
        present(alert, animated: true)
    }
    
    var customTransitionDelegate: CustomSlideInTransition?
    @objc private func backButtonTapped() {
        if let navController = navigationController {
            navController.transitioningDelegate = customTransitionDelegate
        }
        dismiss(animated: true)
    }
    
    private func signOut() {
        do {
            try Auth.auth().signOut()
            state.currentUser = nil // update local state
            navigateToWelcome()
        } catch {
            let alert = CustomAlertViewController(title: "Sign Out Failed", message: " There was a problem signing out. Please try again later.")
            present(alert, animated: true)
        }
    }
    
    private func navigateToWelcome() {
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
    
    private func convertAccountInWelcome() {
        let welcomeVC = WelcomeViewController(state: state)
        let navigationController = UINavigationController(rootViewController: welcomeVC)
        
        let transition = CATransition()
        transition.duration = 0.3
        transition.type = CATransitionType.push
        transition.subtype = CATransitionSubtype.fromLeft
        transition.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.layer.add(transition, forKey: nil)
            window.rootViewController = navigationController
        }
    }
}
