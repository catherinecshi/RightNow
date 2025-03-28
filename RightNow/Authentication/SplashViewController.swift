import UIKit
import FirebaseAuth

class SplashViewController: UIViewController {

    //var isActive: Bool = false
    var state: AppState
    
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
        let tabBarController = TabBarController()
        
        // transition animation
        let transition = CATransition()
        transition.duration = 0.3
        transition.type = CATransitionType.push
        transition.subtype = CATransitionSubtype.fromRight
        transition.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.layer.add(transition, forKey: nil)
            window.rootViewController = tabBarController
        }
    }
    
    func transitionToWelcomeView() {
        let welcomeVC = WelcomeViewController(state: state)
        self.navigationController?.pushViewController(welcomeVC, animated: true)
    }
}
