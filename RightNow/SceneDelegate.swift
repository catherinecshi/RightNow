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
            // show habitlistvc if the user is signed in
            let habitVC = HabitListViewController()
            window?.rootViewController = UINavigationController(rootViewController: habitVC)
            window?.makeKeyAndVisible()
        } else {
            // user is not signed in
            print("User is not signed in")
            let welcomeVC = WelcomeViewController(state: AppState.shared)
            window?.rootViewController = UINavigationController(rootViewController: welcomeVC)
            window?.makeKeyAndVisible()
        }
        
        //check if timer was running
        /*
        if UserDefaults.standard.bool(forKey: "timerIsRunning") {
            let habitListVC = HabitListViewController()
            let navigationController = UINavigationController(rootViewController: habitListVC)
            window?.rootViewController = navigationController
            window?.makeKeyAndVisible()
            
            let elapsedTime = UserDefaults.standard.object(forKey: "timerElapsedTime") as! TimeInterval
            presentTimerViewController(withElapsedTime: elapsedTime)
        } else {
            let splashVC = SplashViewController(state: AppState())
            let navigationController = UINavigationController(rootViewController: splashVC)
            window?.rootViewController = navigationController
            window?.makeKeyAndVisible()
        }
         */
        
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
    
    /*
    func presentTimerViewController(withElapsedTime elapsedTime: TimeInterval) {
        //instantiate timer view controller
        let timerVC = TimerController()
        
        // present timer vc
        timerVC.modalPresentationStyle = .popover
        if let popOverController = timerVC.popoverPresentationController {
            popOverController.permittedArrowDirections = []
            popOverController.sourceView = self.window?.rootViewController?.view //anchor to root view
            popOverController.sourceRect = CGRect(x: self.window!.bounds.midX, y: self.window!.bounds.midY, width: 0, height: 0)
            popOverController.canOverlapSourceViewRect = true
        }
        
        //present timer vc
        self.window?.rootViewController?.present(timerVC, animated: true, completion: {
            timerVC.showTimeAlert(elapsedTime: elapsedTime)
        })
    }
     */
}
        
