import UIKit
import Combine

class AccountConversionViewController: UIViewController {
    var viewModel: AccountConversionViewModel
    private var cancellableBag: Set<AnyCancellable> = []
    
    // UI elements
    private var logoImageView: UIImageView!
    private var titleLabel: UILabel!
    private var subtitleLabel: UILabel!
    private var emailTextField: UITextField!
    private var passwordTextField: UITextField!
    private var confirmPasswordTextField: UITextField!
    private var passwordMismatchLabel: UILabel!
    private var convertButton: UIButton!
    private var googleSignInButton: UIButton!
    
    init(viewModel: AccountConversionViewModel) {
        self.viewModel = viewModel
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
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    private func setupUI() {
        // Logo ImageView
        logoImageView = UIImageView(image: UIImage(named: "AppIcon"))
        logoImageView.contentMode = .scaleAspectFit
        logoImageView.tintColor = UIConfiguration.tintColor
        
        // Title Label
        titleLabel = UILabel()
        titleLabel.text = "Create Your Account"
        titleLabel.font = UIConfiguration.titleFont
        titleLabel.textColor = UIConfiguration.tintColor
        titleLabel.textAlignment = .center
        
        // Subtitle Label
        subtitleLabel = UILabel()
        subtitleLabel.text = "Save your progress and access your data on any device"
        subtitleLabel.font = UIConfiguration.subtitleFont
        subtitleLabel.numberOfLines = 0 // to allow wrapping
        subtitleLabel.textAlignment = .center
        
        // Email TextField
        emailTextField = UITextField()
        emailTextField.placeholder = "E-mail Address"
        emailTextField.borderStyle = .roundedRect
        emailTextField.autocapitalizationType = .none
        emailTextField.keyboardType = .emailAddress
        emailTextField.addTarget(self, action: #selector(emailChanged), for: .editingChanged)
        
        // Password TextField
        passwordTextField = UITextField()
        passwordTextField.placeholder = "Password"
        passwordTextField.borderStyle = .roundedRect
        passwordTextField.isSecureTextEntry = true
        passwordTextField.textContentType = .newPassword
        passwordTextField.addTarget(self, action: #selector(passwordChanged), for: .editingChanged)
        
        // Confirm Password TextField
        confirmPasswordTextField = UITextField()
        confirmPasswordTextField.placeholder = "Confirm Password"
        confirmPasswordTextField.borderStyle = .roundedRect
        confirmPasswordTextField.isSecureTextEntry = true
        confirmPasswordTextField.textContentType = .newPassword
        confirmPasswordTextField.addTarget(self, action: #selector(confirmPasswordChanged), for: .editingChanged)
        
        // Password Mismatch Label
        passwordMismatchLabel = UILabel()
        passwordMismatchLabel.text = "Passwords do not match"
        passwordMismatchLabel.textColor = .red
        passwordMismatchLabel.font = UIFont.systemFont(ofSize: 12)
        passwordMismatchLabel.isHidden = true
        passwordMismatchLabel.textAlignment = .center
        
        // Convert Button
        convertButton = UIButton()
        convertButton.setTitle("Create Account", for: .normal)
        convertButton.titleLabel?.font = UIConfiguration.buttonFont
        convertButton.backgroundColor = UIConfiguration.tintColor
        convertButton.setTitleColor(.white, for: .normal)
        convertButton.layer.cornerRadius = 8
        convertButton.addTarget(self, action: #selector(convertButtonTapped), for: .touchUpInside)
        
        // Later Button
        googleSignInButton = UIButton()
        googleSignInButton.setTitle("Sign In with Google", for: .normal)
        googleSignInButton.titleLabel?.font = UIConfiguration.buttonFont
        googleSignInButton.backgroundColor = .white
        googleSignInButton.setTitleColor(.black, for: .normal)
        googleSignInButton.layer.borderWidth = 1.0
        googleSignInButton.layer.borderColor = UIColor.gray.cgColor
        googleSignInButton.layer.cornerRadius = 8
        googleSignInButton.addTarget(self, action: #selector(googleSignInButtonTapped), for: .touchUpInside)
        
        // Adding subviews
        view.addSubview(logoImageView)
        view.addSubview(titleLabel)
        view.addSubview(subtitleLabel)
        view.addSubview(emailTextField)
        view.addSubview(passwordTextField)
        view.addSubview(confirmPasswordTextField)
        view.addSubview(passwordMismatchLabel)
        view.addSubview(convertButton)
        view.addSubview(googleSignInButton)
        
        // Setting frames
        logoImageView.frame = CGRect(x: (view.bounds.width - 100) / 2, y: 80, width: 100, height: 100)
        titleLabel.frame = CGRect(x: 20, y: logoImageView.frame.maxY + 20, width: view.bounds.width - 40, height: 30)
        subtitleLabel.frame = CGRect(x: 20, y: titleLabel.frame.maxY + 10, width: view.bounds.width - 40, height: 40)
        emailTextField.frame = CGRect(x: 20, y: subtitleLabel.frame.maxY + 20, width: view.bounds.width - 40, height: 50)
        passwordTextField.frame = CGRect(x: 20, y: emailTextField.frame.maxY + 10, width: view.bounds.width - 40, height: 50)
        confirmPasswordTextField.frame = CGRect(x: 20, y: passwordTextField.frame.maxY + 10, width: view.bounds.width - 40, height: 50)
        passwordMismatchLabel.frame = CGRect(x: 20, y: confirmPasswordTextField.frame.maxY + 5, width: view.bounds.width - 40, height: 20)
        convertButton.frame = CGRect(x: 20, y: passwordMismatchLabel.frame.maxY + 20, width: view.bounds.width - 40, height: 50)
        googleSignInButton.frame = CGRect(x: 20, y: convertButton.frame.maxY + 10, width: view.bounds.width - 40, height: 30)
    }
    
    private func bindViewModel() {
        viewModel.$statusViewModel
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                if status.title == "Successful" {
                    // Account conversion successful
                    self?.showSuccessAndDismiss()
                } else {
                    // Show error
                    let alert = CustomAlertViewController(title: status.title, message: status.message)
                    self?.present(alert, animated: true)
                }
            }
            .store(in: &cancellableBag)
        
        viewModel.$passwordsMatch
            .receive(on: DispatchQueue.main)
            .sink { [weak self] match in
                self?.passwordMismatchLabel.isHidden = match
                
                // Disable the button when passwords don't match
                if !match && !(self?.confirmPasswordTextField.text?.isEmpty ?? true) {
                    self?.convertButton.isEnabled = false
                    self?.convertButton.alpha = 0.5
                } else {
                    self?.convertButton.isEnabled = true
                    self?.convertButton.alpha = 1.0
                }
            }
            .store(in: &cancellableBag)
    }
    
    private func showSuccessAndDismiss() {
        let alert = UIAlertController(
            title: "Account Created",
            message: "Your account has been created successfully!",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            // Go back to home screen
            self?.navigationController?.popViewController(animated: true)
        })
        present(alert, animated: true)
    }
    
    @objc func convertButtonTapped() {
        // vlidate fields first
        emailChanged()
        passwordChanged()
        confirmPasswordChanged()
        
        // convert account
        viewModel.convertAccount()
    }
    
    @objc func googleSignInButtonTapped() {
        viewModel.convertWithGoogle(from: self)
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
}
