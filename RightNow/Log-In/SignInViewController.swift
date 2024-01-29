import Combine
import UIKit
//import FBSDKCoreKit
//import FBSDKLoginKit
import FirebaseAuth

class SignInViewController: UIViewController {

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
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Sign In"
        label.font = UIConfiguration.titleFont
        label.textColor = UIConfiguration.tintColor
        label.textAlignment = .center
        return label
    }()

    init(state: AppState) {
        self.viewModel = SignInViewModel(authAPI: AuthService(), state: state)
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
        let stackView = UIStackView(arrangedSubviews: [titleLabel, emailTextField, passwordTextField, loginButton])
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
    
    @objc func loginButtonTapped() {
        emailChanged()
        passwordChanged()
        viewModel.login()
    }
    
    @objc private func emailChanged() {
        viewModel.email = emailTextField.text ?? ""
    }

    @objc private func passwordChanged() {
        viewModel.password = passwordTextField.text ?? ""
    }
    
    /*
    @objc func facebookLoginTapped() {
        viewModel.facebookLogin()
    }
     */
    
    lazy private var loginButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Log In", for: .normal)
        button.backgroundColor = UIColor(hexString: "#ff5a66")
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.addTarget(self, action: #selector(loginButtonTapped), for: .touchUpInside)
        return button
    }()


    
    private func bindViewModel() {
        viewModel.$statusViewModel
            .compactMap { $0 } //filters out nil values
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] status in
                if let status = status, status.title == "Successful" {
                    // This means the login was successful
                    if let sceneDelegate = UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate {
                        let habitVC = HabitListViewController()
                        self?.navigationController?.pushViewController(habitVC, animated: true)
                    }
                } else {
                    let alert = UIAlertController(title: status?.title, message: status?.message, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    self?.present(alert, animated: true, completion: nil)
                }
            })
            .store(in: &cancellableBag)
    }

}

