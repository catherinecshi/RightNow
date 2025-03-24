import Combine
import UIKit
import FirebaseAuth

/// View controller for email/password log in screen
class SignInViewController: UIViewController {
    // MARK: - Properties
    private let viewModel: SignInViewModel
    private var cancellableBag: Set<AnyCancellable> = []
    
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
        return tf
    }()
    
    // at the top of the view
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Sign In"
        label.font = UIConfiguration.titleFont
        label.textColor = UIConfiguration.tintColor
        label.textAlignment = .center
        return label
    }()
    
    private lazy var loginButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Log In", for: .normal)
        button.backgroundColor = UIConfiguration.tintColor
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.addTarget(self, action: #selector(loginButtonTapped), for: .touchUpInside)
        return button
    }()
    
    // MARK: - Lifecycle
    /// Initializes Screen with application state
    /// Takes AppState, which contains information about currentUser
    init(state: AppState) {
        self.viewModel = SignInViewModel(state: state)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
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
    
    // MARK: - Setup UI
    /// Sets up stack of relevant UI elements
    private func setupUI() {
        view.backgroundColor = .white
        
        let stackView = UIStackView(arrangedSubviews: [titleLabel, 
                                                       emailTextField,
                                                       passwordTextField,
                                                       loginButton])
        stackView.axis = .vertical
        stackView.spacing = 20
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    // MARK: - Actions
    /// Calls publisher methods and initiates login process
    @objc func loginButtonTapped() {
        emailChanged()
        passwordChanged()
        
        viewModel.login()
    }
    
    /// Updates model with changed email value
    @objc private func emailChanged() {
        viewModel.email = emailTextField.text ?? ""
    }
    
    /// Updates model with changed password value
    @objc private func passwordChanged() {
        viewModel.password = passwordTextField.text ?? ""
    }
    
    /// Establishes Combine bindings to view model
    /// Observes authentication status changes and handles navigation
    private func bindViewModel() {
        viewModel.$statusViewModel
            .compactMap { $0 } //filters out nil values
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] status in
                if status.title == "Successful" {
                    // This means the login was successful
                    self?.transitionToMainApp()
                } else {
                    let alert = CustomAlertViewController(title: status.title, message: status.message)
                    self?.present(alert, animated: true)
                }
            })
            .store(in: &cancellableBag)
    }
    
    /// Handles navigation to main app
    /// Uses custom transition swiping
    func transitionToMainApp() {
        let tabBarController = TabBarController()
        tabBarController.selectedIndex = 1
        
        // Create a transition animation
        let transition = CATransition()
        transition.duration = 0.3
        transition.type = CATransitionType.push
        transition.subtype = CATransitionSubtype.fromRight
        transition.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        
        // Get the window using the current window scene
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.layer.add(transition, forKey: nil)
            window.rootViewController = tabBarController
        }
    }
}
