import UIKit
import Firebase
import FirebaseCore
import FirebaseFirestoreSwift

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    //launch options
    var launchedFromNotification = false
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        //firebase
        FirebaseApp.configure()

        //let db = Firestore.firestore()
        
        // enable offline functioning bc firebase
        Database.database().isPersistenceEnabled = true
        
        //check if the app was opened from a notification
        if let notification = launchOptions?[.remoteNotification] as? [String: AnyObject] {
            launchedFromNotification = true
            print("LaunchOption = notification")
        }
        
        registerNotificationCategories()
        UNUserNotificationCenter.current().delegate = self
        
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(
            options: authOptions,
            completionHandler: {_, _ in})
        application.registerForRemoteNotifications()
        
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        if let eventIdentifier = userInfo["eventIdentifier"] as? String {
            return
            //store this for later use in the future
        }
        
        print("Notification received with userInfo: \(userInfo)")
        
        //call completion handler
        completionHandler(.newData)
    }
    
    //for notification tokens
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let deviceToken: String = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("Device token is: \(deviceToken)")
    }
    
    func registerNotificationCategories() {
        let goToTimer = UNNotificationAction(identifier: "goToTimer", title: "Clock In", options: [.foreground])
        let goToCamera = UNNotificationAction(identifier: "goToCamera", title: "Record Task", options: [.foreground])
        
        let category = UNNotificationCategory(identifier: "eventNotification", actions: [goToTimer, goToCamera], intentIdentifiers: [], options: [])
        
        UNUserNotificationCenter.current().setNotificationCategories([category])
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate{
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
        let categoryIdentifier = response.notification.request.content.categoryIdentifier
        
        print("received notification with category identifier: \(categoryIdentifier)")
        
        if categoryIdentifier == "eventNotification" {
            print("Category identifier matches!")
        } else {
            print("Category identifier does not match!")
        }
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene, let sceneDelegate = windowScene.delegate as? SceneDelegate {
            switch response.actionIdentifier {
            case "goToTimer":
                sceneDelegate.navigateToViewController(ofType: TimerController.self)
                print("Attempting to navigate to ClockInOutVC")
            case "goToCamera":
                sceneDelegate.navigateToViewController(ofType: CameraController.self)
                print("Attempting to navigate to TakePhotoVC")
            default:
                print("in default case")
                break
            }
        }

      completionHandler()
    }
}

