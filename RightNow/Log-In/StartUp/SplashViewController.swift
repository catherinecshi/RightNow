import UIKit
import FirebaseAuth

class SplashViewController: UIViewController {

    //var isActive: Bool = false
    var state: AppState // Assuming AppState is some model or ViewModel you have
    
    let logoImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "AppIcon"))
        imageView.layer.borderWidth = 3  // Adjust the width as per your requirement
        imageView.layer.borderColor = UIColor.white.cgColor
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 15  // Adjust the radius as per your requirement
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()
    
    init(state: AppState) {
        self.state = state
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupViews()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.transitionToAppropriateView()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    
    func setupViews() {
        view.backgroundColor = UIConfiguration.tintColor
        
        view.addSubview(logoImageView)
        
        NSLayoutConstraint.activate([
            logoImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            logoImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            logoImageView.widthAnchor.constraint(equalToConstant: 200),
            logoImageView.heightAnchor.constraint(equalToConstant: 200)
        ])
    }
    
    func transitionToAppropriateView() {
        // Check if the user is already authenticated.
        if let _ = Auth.auth().currentUser {
            // User is signed in.
            transitionToMainApp()
        } else {
            // User is NOT signed in.
            transitionToWelcomeView()
        }
    }

    func transitionToMainApp() {
        // Assuming that you've refactored the logic that sets up the main interface into a function called `setupMainTabBarController()` in SceneDelegate.
        if let sceneDelegate = UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate {
            let habitVC = HabitListViewController()
            navigationController?.pushViewController(habitVC, animated: true)
        }
    }
    
    func transitionToWelcomeView() {
        let welcomeVC = WelcomeViewController(state: state)
        self.navigationController?.pushViewController(welcomeVC, animated: true)
    }
}
