import Combine
import UIKit
import FirebaseAuth

/// View controller for email/password sign up screen
class SignUpViewController: UIViewController {
    // MARK: - Properties
    weak var sceneDelegate: SceneDelegate?
    private var viewModel: SignUpViewModel!
    private var cancellableBag: Set<AnyCancellable> = []
    
    // in the navigation bar
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Sign Up"
        label.font = UIConfiguration.titleFont
        label.textColor = UIConfiguration.tintColor
        label.textAlignment = .center
        return label
    }()
    
    private let emailTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "E-mail Address"
        tf.borderStyle = .roundedRect
        return tf
    }()
    
    private let passwordTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Password"
        tf.borderStyle = .roundedRect
        tf.isSecureTextEntry = true
        tf.textContentType = .password
        return tf
    }()
    
    private let confirmPasswordTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Confirm Password"
        tf.borderStyle = .roundedRect
        tf.isSecureTextEntry = true
        tf.textContentType = .newPassword
        return tf
    }()
    
    // if passwords don't match
    private let passwordMismatchLabel: UILabel = {
        let label = UILabel()
        label.text = "Passwords do not match"
        label.textColor = .red
        label.font = UIFont.systemFont(ofSize: 12)
        label.isHidden = true
        label.textAlignment = .center
        return label
    }()
    
    lazy private var signUpButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Create Account", for: .normal)
        button.backgroundColor = UIConfiguration.tintColor
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.addTarget(self, action: #selector(signUpButtonTapped), for: .touchUpInside)
        return button
    }()
    
    // MARK: - Lifcycle
    /// Initializes Screen with application state
    /// Takes AppState, which contains information about currentUser
    init(state: AppState) {
        self.viewModel = SignUpViewModel(state: state)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.sceneDelegate = getSceneDelegate()
        setupUI()
        bindViewModel()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    private func getSceneDelegate() -> SceneDelegate? {
        guard let windowScene = self.view.window?.windowScene,
              let sceneDelegate = windowScene.delegate as? SceneDelegate else {
            return nil
        }
        return sceneDelegate
    }
    
    // MARK: - Setup UI
    /// Sets up stack of relevant UI elements
    private func setupUI() {
        view.backgroundColor = .white
        let stackView = UIStackView(arrangedSubviews: [
            titleLabel,
            emailTextField,
            passwordTextField,
            confirmPasswordTextField,
            signUpButton
        ])
        
        stackView.axis = .vertical
        stackView.spacing = 20
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        emailTextField.addTarget(self, action: #selector(emailChanged), for: .editingChanged)
        passwordTextField.addTarget(self, action: #selector(passwordChanged), for: .editingChanged)
        confirmPasswordTextField.addTarget(self, action: #selector(confirmPasswordChanged), for: .editingChanged)
        
        view.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    // MARK: - Actions
    /// Calls publisher methods and initiates sign up process
    @objc private func signUpButtonTapped() {
        emailChanged()
        passwordChanged()
        confirmPasswordChanged()
        
        viewModel.signUp()
    }
    
    /// Updates model with changed email value
    @objc private func emailChanged() {
        viewModel.email = emailTextField.text ?? ""
    }
    
    /// Updates model with changed password value
    @objc private func passwordChanged() {
        viewModel.password = passwordTextField.text ?? ""
    }
    
    /// Updates model with changed confirm password value
    @objc private func confirmPasswordChanged() {
        viewModel.passwordConfirmation = confirmPasswordTextField.text ?? ""
    }
    
    /// Establishes Combine bindings to view model
    /// Observes authentication status changes and handles navigation
    /// Checks and make sure the password and confirm password fields have the same values
    private func bindViewModel() {
        viewModel.$statusViewModel
            .compactMap { $0 } // Filters out nil values
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] status in
                if status.title == "Successful" {
                    // This means the signup was successful
                    self?.transitionToMainApp()
                } else {
                    let alert = UIAlertController(title: status.title, message: status.message, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    self?.present(alert, animated: true, completion: nil)
                }
            })
            // Store the cancellable reference to avoid memory leaks
            .store(in: &cancellableBag)
        
        // binding for password matching validation
        viewModel.$passwordsMatch
            .receive(on: DispatchQueue.main)
            .sink { [weak self] match in
                self?.passwordMismatchLabel.isHidden = match
                
                // Optional: Disable the button when passwords don't match
                if !match && !(self?.confirmPasswordTextField.text?.isEmpty ?? true) {
                    self?.signUpButton.isEnabled = false
                    self?.signUpButton.alpha = 0.5
                } else {
                    self?.signUpButton.isEnabled = true
                    self?.signUpButton.alpha = 1.0
                }
            }
            .store(in: &cancellableBag)
    }
    
    /// Handles navigation to the main tab bar for the app
    /// Uses custom transition to present main tab bar
    func transitionToMainApp() {
        DispatchQueue.main.async { [weak self] in
            if let sceneDelegate = self?.sceneDelegate, let appCoordinator = sceneDelegate.appCoordinator {
                // Use the existing app coordinator
                appCoordinator.start()
            }
        }
    }
}
