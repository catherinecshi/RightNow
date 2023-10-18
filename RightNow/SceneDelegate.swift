import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate, UNUserNotificationCenterDelegate {

    var window: UIWindow?


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        guard let windowScene = (scene as? UIWindowScene) else { return }
        window = UIWindow(windowScene: windowScene)
        
        //checks for the launch option
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate, appDelegate.launchedFromNotification {
            //go into the notificiation view
            
            let clockVC = TimerController()
            let navigationController = UINavigationController(rootViewController: clockVC)
            window?.rootViewController = clockVC
            window?.makeKeyAndVisible()
        } else {
            //goes into the splash view
            //should fix this at some point so it always start from splash
            let splashVC = SplashViewController(state: AppState())
            let navigationController = UINavigationController(rootViewController: splashVC)
            window?.rootViewController = navigationController
            window?.makeKeyAndVisible()
        }
        
        //set up notification
        //UNUserNotificationCenter.current().delegate = self
        
    }
    
    func setupMainTabBarController() -> UITabBarController {
        //create instances of view controller for each tab
        let calendarVC = CalendarViewController()
        calendarVC.tabBarItem = UITabBarItem(title: "Calendar", image: UIImage(systemName: "calendar"), selectedImage: nil)
        calendarVC.title = "RightNow"
        
        let navigationControllerForCalendar = UINavigationController(rootViewController: calendarVC)
        //navigationControllerForCalendar.tabBarItem = UITabBarItem(title:"Calendar", image: UIImage(systemName: "calendar"), selectedImage: nil)
        
        //create instance of camera view controller
        let cameraVC = CameraController()
        cameraVC.tabBarItem = UITabBarItem(title: "Camera", image: UIImage(systemName: "camera"), selectedImage: nil)
        cameraVC.title = "RightNow"
        let navigationControllerForCamera = UINavigationController(rootViewController: cameraVC)
        
        //create instance of clock in & out view controller
        let clockInOutVC = TimerController()
        clockInOutVC.tabBarItem = UITabBarItem(title: "Timer", image: UIImage(systemName: "clock"), selectedImage: nil)
        clockInOutVC.title = "RightNow"
        let navigationControllerForTimer = UINavigationController(rootViewController: clockInOutVC)
        
        //make more view controllers here
        //to do list stuff
        //instructions in chatgpt "startup view verifica"
        
        //tab bar controller
        let tabBarController = UITabBarController()
        tabBarController.tabBar.barTintColor = .white
        tabBarController.viewControllers = [navigationControllerForCalendar, navigationControllerForCamera, navigationControllerForTimer]
        navigationControllerForCalendar.tabBarItem.title = "Calendar"
        navigationControllerForCamera.tabBarItem.title = "Camera"
        navigationControllerForTimer.tabBarItem.title = "Timer"
        
        //window
        window?.backgroundColor = .white
        window?.rootViewController = tabBarController
        window?.makeKeyAndVisible()
        
        return tabBarController
    }
    
    //handle notification response
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
        // gives the payload of data associated with notif
        if let tabIndex = response.notification.request.content.userInfo["tabIndex"] as? Int, let tabBarController = window?.rootViewController as? UITabBarController {
            
            tabBarController.selectedIndex = tabIndex
        }
        
        completionHandler()
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

    func navigateToViewController<T: UIViewController>(ofType type: T.Type) {
        print("in navigateToViewController() (scenedelegate)")
        if let tabBarController = window?.rootViewController as? UITabBarController, let viewControllers = tabBarController.viewControllers {
            print("root view is UITabBarController and has view controllers (navigateToViewController)")
            for (index, navigationController) in viewControllers.enumerated() {
                if let nc = navigationController as? UINavigationController {
                    if let firstChild = nc.children.first {
                        print("First child type: \(String(describing: nc.children.first.self))")
                        print("Target type: \(String(describing: type.self))")
                        print("Navigation stack: \(nc.viewControllers)")
                        if firstChild is T {
                            tabBarController.selectedIndex = index
                            print("in inner if statement")
                            break
                        }
                    }
                }
            }
        }
    }
}
