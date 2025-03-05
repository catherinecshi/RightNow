import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    private lazy var appDelegate = AppDelegateFactory.fetchDelegates
    
    var firebaseManager: FirebaseConfigurable = FirebaseManager.shared
    
    //called when app is opened from a state of not running at all
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        //firebase
        firebaseManager.configure()
        
        // initialise LocationManager
        let _ = LocationManager.shared
        
        // forward call to composite delegate
        _ = appDelegate.application?(application, didFinishLaunchingWithOptions: launchOptions) ?? false
        
        // set push notifications delegate as notifications delegate
        UNUserNotificationCenter.current().delegate = PushNotificationDelegate.shared
        
        return true
    }

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
        /*
        if let eventIdentifier = userInfo["eventIdentifier"] as? String {
            return
            //store this for later use in the future
        }
         */
        
        print("Notification received with userInfo: \(userInfo)")

        
        //call completion handler
        completionHandler(.newData)
    }
    
    //for notification tokens
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        //this is for storing specific tokens for specific users, incase i would want to send notifications to specific users
        
        appDelegate.application?(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        //handle error
        appDelegate.application?(application, didFailToRegisterForRemoteNotificationsWithError: error)
    }
}

// MARK: - Application Lifecycle Methods
extension AppDelegate {
    func applicationWillResignActive(_ application: UIApplication) {
        appDelegate.applicationWillResignActive?(application)
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        appDelegate.applicationDidEnterBackground?(application)
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        appDelegate.applicationWillEnterForeground?(application)
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        appDelegate.applicationDidBecomeActive?(application)
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        appDelegate.applicationWillTerminate?(application)
    }
}

// MARK: - Background fetch delegate
extension AppDelegate {
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        appDelegate.application?(app, open: url, options: options) ?? false
    }
}

extension AppDelegate {
    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        //fetch data in background
        appDelegate.application?(application, performFetchWithCompletionHandler: completionHandler)
    }
}
