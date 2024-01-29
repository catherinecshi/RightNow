import UIKit
import FirebaseAuth

class SceneDelegate: UIResponder, UIWindowSceneDelegate, UNUserNotificationCenterDelegate {

    var window: UIWindow?


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        guard let windowScene = (scene as? UIWindowScene) else { return }
        window = UIWindow(windowScene: windowScene)
        window?.backgroundColor = .white
        
        //notifications
        UNUserNotificationCenter.current().delegate = self

        //check if timer was running
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
        
    }
    
    //handle notification response
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
        print("Received notification content: \(response.notification.request.content.userInfo)")
        
        /*
        if Auth.auth().currentUser != nil {
            //shows habitlistvc if the user is signed in
            if let navigationController = window?.rootViewController as? UINavigationController {
                let habitVC = HabitListViewController()
                navigationController.pushViewController(habitVC, animated: true)
            }
        } else {
            //user is not signed in
            print("User is not signed in")
        }
         */
        
        //get the navigation controller from the window's root
        guard let navigationController = window?.rootViewController as? UINavigationController else {
            completionHandler()
            return
        }
        
        //checks if the habitlistvc is already in the navigation stack
        if navigationController.viewControllers.contains(where: { $0 is HabitListViewController }) == false {
            let habitVC = HabitListViewController()
            navigationController.pushViewController(habitVC, animated: true)
        }
        
        // checks if root is UINavController
        if let navigationController = window?.rootViewController as? UINavigationController {
            //initialise habitVC and pushes it
            let habitVC = HabitListViewController()
            navigationController.pushViewController(habitVC, animated: true)
        }
        
        //handling notification when app is in foreground
        
        
        // MARK: Handling Action Taps
        let habitListViewModel = HabitListViewModel()
        
        //setting rootviewcontroller (habits)
        //right now it's assuming root is habitlistvc
        guard let rootViewController = window?.rootViewController as? HabitListViewController else {
            completionHandler()
            return
        }
        
        if let habitID = response.notification.request.content.userInfo["habitID"] as? String {
            habitListViewModel.fetchHabitFromFirestore(habitID: habitID) { habit in
                guard let habit = habit else {
                    completionHandler()
                    return
                }
                
                //add if more in the future
                switch response.actionIdentifier {
                case "Record_Action":
                    let recordVC = CameraController()
                    recordVC.habit = habit
                    recordVC.modalPresentationStyle = .fullScreen
                    rootViewController.present(recordVC, animated: true, completion: nil)
                case "Track_Action":
                    let trackVC = TimerController()
                    trackVC.habit = habit
                    trackVC.modalPresentationStyle = .fullScreen
                    rootViewController.present(trackVC, animated: true, completion: nil)
                default:
                    break
                }
            }
        } else {
            print("Habit was not fetched correctly")
            completionHandler()
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
    
    // MARK: My own methods
    
    private func presentTimerViewController(withElapsedTime elapsedTime: TimeInterval) {
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
}
