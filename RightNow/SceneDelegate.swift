import UIKit
import FirebaseAuth

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        guard let windowScene = (scene as? UIWindowScene) else { return }
        window = UIWindow(windowScene: windowScene)
        window?.backgroundColor = .white
        
        if #available(iOS 13.0, *) { // force light mode for UI
            window?.overrideUserInterfaceStyle = .light
        }
        
        // if from notification, send information to PushNotificationDelegate
        PushNotificationDelegate.shared.window = window
        
        if Auth.auth().currentUser != nil {
            //let onboardingVC = OnboardingViewController()
            //window?.rootViewController = onboardingVC
            //window?.makeKeyAndVisible()
            
            // show tabs if the user is signed in
            let tabBarController = TabBarController()
            tabBarController.selectedIndex = 1
            window?.rootViewController = tabBarController
            window?.makeKeyAndVisible()
        } else {
            // user is not signed in
            print("User is not signed in")
            let welcomeVC = WelcomeViewController(state: AppState.shared)
            window?.rootViewController = UINavigationController(rootViewController: welcomeVC)
            window?.makeKeyAndVisible()
        }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }
}
        
