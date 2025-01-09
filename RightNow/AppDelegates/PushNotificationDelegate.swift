import Foundation
import UIKit
import FirebaseAuth

final class PushNotificationDelegate: AppDelegateType, UNUserNotificationCenterDelegate {
    static let shared = PushNotificationDelegate()
    
    // avoid unnecessary initialisation
    private override init() { }
    
    private let notificationCenter = UNUserNotificationCenter.current()
    weak var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        registerForPushNotifications()
        //removePendingNotifications()
        getPendingNotifications()
        
        return true
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // possible use case
        // receive requested device token
        // save device token to local storage
        // register device token with FCM
        let deviceToken: String = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("Device token is: \(deviceToken)")
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        // some error occurred while registering for device token
        print("Failed to register for remote notifications: \(error)")
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // called when app is in foreground for notification
        print("Notification will present: \(notification.request.identifier)")
        completionHandler([.banner, .list, .sound])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        // called when user interacts with notification
        let actionIdentifier = response.actionIdentifier
        print("Notification response received with action identifier: \(actionIdentifier)")
        
        if let _ = Auth.auth().currentUser {
            switch actionIdentifier {
            case "Track_Action":
                retrieveHabit(from: response.notification) { habit in
                    if let habit = habit {
                        self.presentTimerController(habit: habit)
                        print("record action timer vc presented")
                    } else {
                        self.setDefaultRootViewController()
                        print("track action default root vc presented")
                    }
                    completionHandler()
                }
            case "Record_Action":
                retrieveHabit(from: response.notification) { habit in
                    if let habit = habit {
                        self.presentCameraController(habit: habit)
                        print("track action camera vc presented")
                    } else {
                        self.setDefaultRootViewController()
                        print("record action default root vc presented")
                    }
                    completionHandler()
                }
            default:
                setDefaultRootViewController()
                print("default vc presented")
                completionHandler()
            }
        } else {
            print("not logged in")
            setWelcomeViewController()
        }
    }
    
    private func presentCameraController(habit: Habit) {
        DispatchQueue.main.async {
            if let window = self.window {
                let rootVC = HabitListViewController()
                window.rootViewController = rootVC
                window.makeKeyAndVisible()
                
                let cameraVC = CameraController(habit: habit)
                cameraVC.modalPresentationStyle = .fullScreen
                rootVC.present(cameraVC, animated: true, completion: nil)
            } else {
                print("Window is nil")
            }
        }
    }
    
    private func presentTimerController(habit: Habit) {
        DispatchQueue.main.async {
            if let window = self.window {
                let rootVC = HabitListViewController()
                window.rootViewController = rootVC
                window.makeKeyAndVisible()
                
                let timerVC = TimerController(habit: habit)
                timerVC.modalPresentationStyle = .fullScreen
                rootVC.present(timerVC, animated: true, completion: nil)
            } else {
                print("Window is nil")
            }
        }
    }
    
    func setDefaultRootViewController() {
        DispatchQueue.main.async {
            if let window = self.window {
                let splashVC = SplashViewController(state: AppState())
                window.rootViewController = UINavigationController(rootViewController: splashVC)
                window.makeKeyAndVisible()
            }
        }
    }
    
    func setWelcomeViewController() {
        DispatchQueue.main.async {
            if let window = self.window {
                let welcomeVC = WelcomeViewController(state: AppState.shared)
                window.rootViewController = UINavigationController(rootViewController: welcomeVC)
                window.makeKeyAndVisible()
            }
        }
    }
    
    func retrieveHabit(from notification: UNNotification, completion: @escaping (Habit?) -> Void) {
        if let habitID = notification.request.content.userInfo["habitID"] as? String {
            HabitListViewModel.shared.fetchHabitFromFirestore(habitID: habitID) { habit in
                if let habit = habit {
                    completion(habit)
                } else {
                    print("Failed to fetch habit with ID: \(habitID)")
                    completion(nil)
                }
            }
        } else {
            print("No habit id found in notification")
            completion(nil)
        }
    }
}
    

extension PushNotificationDelegate {
    // request push notification access
    private func registerForPushNotifications() {
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        notificationCenter.requestAuthorization(options: authOptions) { granted, error in
            if let error = error {
                print("Failed to request authorization: \(error)")
                return
            }
            
            if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                    UNUserNotificationCenter.current().delegate = self
                print("User granted push notifications")
                }
            } else {
                print("User denied push notifications")
                // handle cases when permission is not granted
            }
        }
    }
}

// MARK: - Debugging Purposes
extension PushNotificationDelegate {
    private func getPendingNotifications() {
        notificationCenter.getPendingNotificationRequests { requests in
            for request in requests {
                print("Pending notification request: \(request.identifier)")
                
                let content = request.content
                print("Title: \(content.title)")
                print("Body: \(content.body)")
                print("User info: \(content.userInfo)")
                
                if let trigger = request.trigger as? UNCalendarNotificationTrigger {
                    print("Trigger repeats: \(trigger.repeats)")
                    
                    if let triggerDate = trigger.nextTriggerDate() {
                        let dateFormatter = DateFormatter()
                        dateFormatter.dateStyle = .long
                        dateFormatter.timeStyle = .medium
                        print("Next trigger date: \(dateFormatter.string(from: triggerDate))")
                    } else {
                        print("No next trigger date")
                    }
                } else if let trigger = request.trigger as? UNTimeIntervalNotificationTrigger {
                    print("Time interval: \(trigger.timeInterval)")
                    print("Repeats: \(trigger.repeats)")
                } else {
                    print("Unknown trigger type")
                }
                
                print("-----")
            }
        }
    }
    
    private func removePendingNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
    }
}
