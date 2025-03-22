import Combine
import UIKit
import FirebaseAuth

class SignUpViewController: UIViewController {
    
    private var viewModel: SignUpViewModel!
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
        button.backgroundColor = UIColor(hexString: "#ff5a66")
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.addTarget(self, action: #selector(signUpButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Sign Up"
        label.font = UIConfiguration.titleFont
        label.textColor = UIConfiguration.tintColor
        label.textAlignment = .center
        return label
    }()
    
    init(state: AppState) {
        self.viewModel = SignUpViewModel(state: state)
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
    
    @objc private func signUpButtonTapped() {
        emailChanged()
        passwordChanged()
        confirmPasswordChanged()
        viewModel.signUp()
    }
    
    @objc private func emailChanged() {
        viewModel.email = emailTextField.text ?? ""
    }

    @objc private func passwordChanged() {
        viewModel.password = passwordTextField.text ?? ""
    }
    
    @objc private func confirmPasswordChanged() {
        viewModel.passwordConfirmation = confirmPasswordTextField.text ?? ""
    }
    
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
    
    func transitionToMainApp() {
        // Create our tab bar controller
        let tabBarController = TabBarController()
        
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

extension UIColor {
    convenience init?(hexString: String) {
        let chars = Array(hexString.dropFirst())
        self.init(red: CGFloat(strtoul(String(chars[0...1]), nil, 16)) / 255,
                  green: CGFloat(strtoul(String(chars[2...3]), nil, 16)) / 255,
                  blue: CGFloat(strtoul(String(chars[4...5]), nil, 16)) / 255,
                  alpha: 1.0)
    }
}
