import UIKit

class WelcomeViewController: UIViewController {

    var state: AppState
    
    private var index: Int = 1
    
    // UI elements
    private var logoImageView: UIImageView!
    private var titleLabel: UILabel!
    private var subtitleLabel: UILabel!
    private var loginButton: UIButton!
    private var signUpButton: UIButton!

    init(state: AppState) {
        self.state = state
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupViews()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    func setupViews() {
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
        loginButton.setTitle("Log In", for: .normal)
        loginButton.titleLabel?.font = UIConfiguration.buttonFont
        loginButton.backgroundColor = UIConfiguration.tintColor
        loginButton.setTitleColor(.white, for: .normal)
        loginButton.addTarget(self, action: #selector(loginButtonTapped), for: .touchUpInside)
        
        // Sign Up Button
        signUpButton = UIButton()
        signUpButton.setTitle("Sign Up", for: .normal)
        signUpButton.titleLabel?.font = UIConfiguration.buttonFont
        signUpButton.backgroundColor = .clear
        signUpButton.setTitleColor(.black, for: .normal)
        signUpButton.layer.borderWidth = 1.0
        signUpButton.layer.borderColor = UIColor.gray.cgColor
        signUpButton.addTarget(self, action: #selector(signUpButtonTapped), for: .touchUpInside)

        // Adding subviews
        view.addSubview(logoImageView)
        view.addSubview(titleLabel)
        view.addSubview(subtitleLabel)
        view.addSubview(loginButton)
        view.addSubview(signUpButton)
        
        // Setting frames
        logoImageView.frame = CGRect(x: (view.bounds.width - 200) / 2, y: 100, width: 200, height: 200)
        titleLabel.frame = CGRect(x: 20, y: logoImageView.frame.maxY + 20, width: view.bounds.width - 40, height: 30)
        subtitleLabel.frame = CGRect(x: 20, y: titleLabel.frame.maxY + 10, width: view.bounds.width - 40, height: 60)
        loginButton.frame = CGRect(x: 20, y: subtitleLabel.frame.maxY + 20, width: view.bounds.width - 40, height: 50)
        signUpButton.frame = CGRect(x: 20, y: loginButton.frame.maxY + 10, width: view.bounds.width - 40, height: 50)

    }
    
    @objc func loginButtonTapped() {
        index = 1
        navigateToDestination()
    }
    
    @objc func signUpButtonTapped() {
        index = 2
        navigateToDestination()
    }
    
    private func navigateToDestination() {
        let viewController: UIViewController
        switch index {
        case 1:
            viewController = SignInViewController(state: state)
        default:
            viewController = SignUpViewController(state: state)
        }
        self.navigationController?.pushViewController(viewController, animated: true)
    }
}
