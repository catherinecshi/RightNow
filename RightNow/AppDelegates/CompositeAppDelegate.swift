import UIKit

/// Type definition representing objects that can act as app delegates
typealias AppDelegateType = UIResponder & UIApplicationDelegate

/// Forwards lifecycle events to app delegates
///
/// This class separates concerns in app initialization and lifecycle management
/// Maintains a collection of the different delegates - ensure each gets appropriate lifecycle callbacks
final class CompositeAppDelegate: AppDelegateType {
    private let appDelegates: [AppDelegateType]
    
    internal init(appDelegates: [AppDelegateType]) {
        self.appDelegates = appDelegates
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // indicates whether app launch was successful
        // handles cases where it was not successful (like jailbroken device)
        
        var shouldAppLaunch = true
        
        appDelegates.forEach { specificAppDelegate in
            guard specificAppDelegate.application?(application, didFinishLaunchingWithOptions: launchOptions) ?? false else {
                // disable app launch bc delegate returned false
                shouldAppLaunch = false
                return
            }
        }
        
        return shouldAppLaunch
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        appDelegates.forEach { $0.application?(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken) }
        print("registered for remote notifications")
    }
}

extension CompositeAppDelegate {
    func applicationWillResignActive(_ application: UIApplication) {
        appDelegates.forEach { $0.applicationWillResignActive?(application) }
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        appDelegates.forEach { $0.applicationDidEnterBackground?(application) }
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        appDelegates.forEach { $0.applicationWillEnterForeground?(application) }
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        appDelegates.forEach { $0.applicationDidBecomeActive?(application) }
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        appDelegates.forEach { $0.applicationWillTerminate?(application) }
    }
}
