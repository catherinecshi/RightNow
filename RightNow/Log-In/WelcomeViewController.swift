import UIKit
import Combine
import GoogleSignIn

/// Presents Welcome Screen when the user is not logged in
class WelcomeViewController: UIViewController {
    // MARK: - Properties
    var viewModel: WelcomeViewModel
    var state: AppState
    private var cancellableBag: Set<AnyCancellable> = []
    
    // UI elements
    private var logoImageView: UIImageView!
    private var titleLabel: UILabel!
    private var subtitleLabel: UILabel!
    private var loginButton: UIButton!
    private var signUpButton: UIButton!
    private var googleSignInButton: UIButton!
    private var guestButton: UIButton!
    
    // MARK: - Lifecycle
    /// Initializes Screen with application state
    /// Takes AppState, which contains information about currentUser
    init(state: AppState) {
        self.state = state
        self.viewModel = WelcomeViewModel(state: state)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupUI()
        bindViewModel()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    // MARK: - Setup UI
    /// Creates and configures all UI elements
    /// Arranges elements based on a frame-based layout
    func setupUI() {
        // Logo ImageView
        let logoImageView = UIImageView(image: UIImage(named: "AppIcon"))
        logoImageView.contentMode = .scaleAspectFit
        logoImageView.tintColor = UIConfiguration.tintColor
        
        // Title Label
        titleLabel = UILabel()
        titleLabel.text = "Right Now"
        titleLabel.font = UIConfiguration.titleFont
        titleLabel.textColor = UIConfiguration.tintColor
        titleLabel.textAlignment = .center
        
        // Subtitle Label
        subtitleLabel = UILabel()
        subtitleLabel.text = "What should you be doing right now?"
        subtitleLabel.font = UIConfiguration.subtitleFont
        subtitleLabel.numberOfLines = 0 // to allow wrapping
        subtitleLabel.textAlignment = .center
        
        // Login Button
        loginButton = UIButton()
        loginButton.setTitle("Sign In with Email", for: .normal)
        loginButton.titleLabel?.font = UIConfiguration.buttonFont
        loginButton.backgroundColor = UIConfiguration.tintColor
        loginButton.setTitleColor(.white, for: .normal)
        loginButton.addTarget(self, action: #selector(loginButtonTapped), for: .touchUpInside)
        
        // Sign Up Button
        signUpButton = UIButton()
        signUpButton.setTitle("Sign Up with Email", for: .normal)
        signUpButton.titleLabel?.font = UIConfiguration.buttonFont
        signUpButton.backgroundColor = .clear
        signUpButton.setTitleColor(.black, for: .normal)
        signUpButton.layer.borderWidth = 1.0
        signUpButton.layer.borderColor = UIColor.gray.cgColor
        signUpButton.addTarget(self, action: #selector(signUpButtonTapped), for: .touchUpInside)
        
        // Google Sign In Button
        googleSignInButton = UIButton()
        googleSignInButton.setTitle("Sign In with Google", for: .normal)
        googleSignInButton.titleLabel?.font = UIConfiguration.buttonFont
        googleSignInButton.backgroundColor = .white
        googleSignInButton.setTitleColor(.black, for: .normal)
        googleSignInButton.layer.borderWidth = 1.0
        googleSignInButton.layer.borderColor = UIColor.gray.cgColor
        googleSignInButton.layer.cornerRadius = 4
        googleSignInButton.addTarget(self, action: #selector(googleSignInButtonTapped), for: .touchUpInside)
        
        // continue as guest button
        guestButton = UIButton(type: .system)
        guestButton.setTitle("Continue as Guest", for: .normal)
        guestButton.setTitleColor(.gray, for: .normal)
        guestButton.titleLabel?.font = UIConfiguration.buttonFont
        guestButton.layer.borderWidth = 1.0
        guestButton.layer.borderColor = UIColor.gray.cgColor
        guestButton.addTarget(self, action: #selector(guestButtonTapped), for: .touchUpInside)

        // Adding subviews
        view.addSubview(logoImageView)
        view.addSubview(titleLabel)
        view.addSubview(subtitleLabel)
        view.addSubview(loginButton)
        view.addSubview(signUpButton)
        view.addSubview(googleSignInButton)
        view.addSubview(guestButton)
        
        // Setting frames
        logoImageView.frame = CGRect(x: (view.bounds.width - 200) / 2, y: 100, width: 200, height: 200)
        titleLabel.frame = CGRect(x: 20, y: logoImageView.frame.maxY + 20, width: view.bounds.width - 40, height: 30)
        subtitleLabel.frame = CGRect(x: 20, y: titleLabel.frame.maxY + 10, width: view.bounds.width - 40, height: 60)
        loginButton.frame = CGRect(x: 20, y: subtitleLabel.frame.maxY + 20, width: view.bounds.width - 40, height: 50)
        signUpButton.frame = CGRect(x: 20, y: loginButton.frame.maxY + 10, width: view.bounds.width - 40, height: 50)
        googleSignInButton.frame = CGRect(x: 20, y: signUpButton.frame.maxY + 10, width: view.bounds.width - 40, height: 50)
        guestButton.frame = CGRect(x: 20, y: googleSignInButton.frame.maxY + 10, width: view.bounds.width - 40, height: 50)
    }
    
    // MARK: - Actions
    /// Establishes Combine bindings to view model
    /// Observes authentication status changes and handles navigation
    private func bindViewModel() {
        viewModel.$statusViewModel
            .compactMap { $0 } // filters out nil values
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in // creates subscriber that executes closure whenever new published value
                if status.title == "Successful" {
                    // Navigate to the app's main interface
                    self?.navigateToDestination(index: 3)
                } else {
                    // Show error
                    let alert = CustomAlertViewController(
                        title: status.title,
                        message: status.message
                    )
                    self?.present(alert, animated: true)
                }
            }
            .store(in: &cancellableBag)
    }
    
    @objc func loginButtonTapped() {
        navigateToDestination(index: 1)
    }
    
    @objc func signUpButtonTapped() {
        navigateToDestination(index: 2)
    }
    
    @objc func googleSignInButtonTapped() {
        viewModel.signInWithGoogle(from: self)
    }
    
    @objc func guestButtonTapped() {
        viewModel.continueAsGuest()
    }
    
    /// Handles navigation to different screens depending on user input
    /// Takes index - indicator of where to navigate to
    private func navigateToDestination(index: Int) {
        let viewController: UIViewController
        switch index {
        case 1:
            viewController = SignInViewController(state: state)
        case 2:
            viewController = SignUpViewController(state: state)
        case 3:
            viewController = TabBarController()
        default:
            viewController = TabBarController()
        }
        self.navigationController?.pushViewController(viewController, animated: true)
    }
}
