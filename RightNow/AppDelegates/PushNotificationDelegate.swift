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
        //getPendingNotifications()
        
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
            case "Snooze_5":
                handleSnooze5Minutes(notification: response.notification)
                completionHandler()
            case "Snooze_Next_Cue":
                setDefaultRootViewController()
                print("snooze next cue")
                completionHandler()
            case "Snooze_Idle":
                setDefaultRootViewController()
                print("Snooze idle")
                completionHandler()
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
    
    private func handleSnooze5Minutes(notification: UNNotification) {
        retrieveHabit(from: notification) { habit in
            guard let habit = habit else { return }
            
            let content = notification.request.content.mutableCopy() as! UNMutableNotificationContent
            content.categoryIdentifier = "HabitReminder"
            
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5 * 60, repeats: false)
            let request = UNNotificationRequest(
                identifier: "\(habit.id.uuidString)_snoozed",
                content: content,
                trigger: trigger
            )
            
            self.notificationCenter.add(request) { error in
                if let error = error {
                    print("Error scheduling snoozed notification: \(error)")
                }
            }
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
    
// MARK: - Common Methods to Reference Externally
extension PushNotificationDelegate {
    // request push notification access
    func registerForPushNotifications() {
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
                    //self.setupNotificationCategories()
                    print("User granted push notifications")
                }
            } else {
                print("User denied push notifications")
                // handle cases when permission is not granted
            }
        }
    }
    
    func requestAccessToNotifications() {
        notificationCenter.requestAuthorization(options: [.alert, .sound]) { (granted, error) in
            if granted {
                print("Notification permission granted!")
            } else {
                print("Notification permission denied because: \(error?.localizedDescription ?? " no error")")
                //maybe make this an alert in the future
            }
        }
    }
    
    func scheduleNotificationsForHabit(_ habit: Habit) {
        for (day, isActive) in habit.daysOfTheWeek {
            guard isActive else { continue }
            
            let content = UNMutableNotificationContent()
            content.title = "Right Now"
            //content.categoryIdentifier = "HabitReminder"
            
            if let _ = habit.time { // for time based habits
                content.body = "Are you starting to \(habit.name) now?"
            } else if let cue = habit.cue { // for cue based habits
                content.body = "Did you \(habit.name) after \(cue)?"
            } else {
                print("something weird going on - no time for habit and no cue either")
            }
            
            content.sound = UNNotificationSound.default
            
            // information that can be fetched in notification
            let uuidString = habit.id.uuidString
            let metric = habit.accountabilityMetric.displayName
            content.userInfo = ["habitID": uuidString, "metric": metric]
            
            // debug printing
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .long
            dateFormatter.timeStyle = .medium
            dateFormatter.timeZone = TimeZone.current
            
            // getting days of week
            let daysOfWeek = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
            let calendar = Calendar.current
            var components: DateComponents
            
            if let habitTime = habit.time {
                print("Scheduling notification for \(day) at \(dateFormatter.string(from: habitTime))")
                components = calendar.dateComponents([.hour, .minute], from: habitTime)
            } else {
                var standardTime = DateComponents()
                standardTime.hour = 20 // 8 PM
                standardTime.minute = 0
                
                print("Scheduling notification for \(day) at standard time")
                components = standardTime
            }
            
            components.weekday = daysOfWeek.firstIndex(of: day)! + 1 // + 1 bc Sunday starts at 1
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            let request = UNNotificationRequest(identifier: "\(uuidString)_\(day)", content: content, trigger: trigger)
            
            notificationCenter.add(request) { (error) in
                if let error = error {
                    print("Error scheduling notification for \(day): \(error)")
                } else {
                    print("Notification scheduled!")
                }
            }
        }
    }
    
    func cancelNotifications(for habit: Habit) {
        for day in habit.daysOfTheWeek.keys {
            let identifier = "\(habit.id)_\(day)"
            notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
        }
    }
    
    private func setupNotificationCategories() {
        // create actions
        let snooze5Action = UNNotificationAction(
            identifier: "Snooze_5",
            title: "Snooze for 5 mins",
            options: .foreground
        )
        
        let snoozeNextCueAction = UNNotificationAction(
            identifier: "Snooze_Next_Cue",
            title: "Reschedule habit for today",
            options: .foreground
        )
        
        let snoozeIdleAction = UNNotificationAction(
            identifier: "Snooze_Idle",
            title: "Snooze until next idle moment",
            options: .foreground
        )
        
        // create the category with all the actions
        let category = UNNotificationCategory(
            identifier: "HabitReminder",
            actions: [snooze5Action, snoozeNextCueAction, snoozeIdleAction],
            intentIdentifiers: [],
            options: []
        )
        
        // register the category
        notificationCenter.setNotificationCategories([category])
    }
}

// MARK: - Create Custom Notification
extension PushNotificationDelegate {
    struct NotificationConfig {
        let title: String
        let body: String
        let identifier: String
        let userInfo: [AnyHashable: Any]?
        let timeInterval: TimeInterval
        let sound: UNNotificationSound?
        let categoryIdentifier: String?
        
        // default values
        init(
            title: String,
            body: String,
            identifier: String,
            userInfo: [AnyHashable: Any]? = nil,
            timeInterval: TimeInterval = 1,
            sound: UNNotificationSound? = .default,
            categoryIdentifier: String? = nil
        ) {
            self.title = title
            self.body = body
            self.identifier = identifier
            self.userInfo = userInfo
            self.timeInterval = timeInterval
            self.sound = sound
            self.categoryIdentifier = categoryIdentifier
        }
    }
    
    func sendImmediateNotification(
        config: NotificationConfig,
        completion: ((Error?) -> Void)? = nil
    ) {
        let content = UNMutableNotificationContent()
        content.title = config.title
        content.body = config.body
        
        // optional configuration
        if let sound = config.sound {
            content.sound = sound
        }
        
        if let userInfo = config.userInfo {
            content.userInfo = userInfo
        }
        
        if let categoryIdentifier = config.categoryIdentifier {
            content.categoryIdentifier = categoryIdentifier
        }
        
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: config.timeInterval,
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: config.identifier,
            content: content,
            trigger: trigger
        )
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("Error sending notification: \(error.localizedDescription)")
            }
            completion?(error)
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
    
    // check that the pending notifications matches the habits available
    func auditNotifications() {
        let notificationCenter = UNUserNotificationCenter.current()
        
        notificationCenter.getPendingNotificationRequests { [weak self] requests in
            guard let self = self else { return }
            
            // set of existing notification IDs
            var existingNotificationIds = Set<String>()
            for request in requests {
                existingNotificationIds.insert(request.identifier)
            }
            
            // set of expected notification IDs based on local habits
            var expectedNotificationIds = Set<String>()
            for habit in HabitListViewModel.shared.habits {
                let habitId = habit.id.uuidString
                
                for (day, isEnabled) in habit.daysOfTheWeek where isEnabled {
                    expectedNotificationIds.insert("\(habitId)_\(day)")
                }
            }
            
            // for notifications that shouldn't exist based on expectation
            let notificationsToRemove = existingNotificationIds.subtracting(expectedNotificationIds)
            if !notificationsToRemove.isEmpty {
                print("Removing \(notificationsToRemove.count) unexpected notifications")
                notificationCenter.removePendingNotificationRequests(withIdentifiers: Array(notificationsToRemove))
            }
            
            // find missing notifications that should exist based on expectation
            let missingNotifications = expectedNotificationIds.subtracting(existingNotificationIds)
            if !missingNotifications.isEmpty {
                print("Found \(missingNotifications.count) missing notifications")
                // schedule notifications
                for notificationId in missingNotifications {
                    if let habit = findHabitForNotificationId(notificationId) {
                        scheduleNotificationsForHabit(habit)
                    }
                }
            }
            
            print("----------------")
            print("Notification audit complete:")
            print("- Total existing notifications: \(existingNotificationIds.count)")
            print("- Expected notifications: \(expectedNotificationIds.count)")
            print("- Removed unexpected notifications: \(notificationsToRemove.count)")
            print("- Recreated missing notifications: \(missingNotifications.count)")
            
            //getPendingNotifications()
            print("---------------")
        }
    }
    
    private func findHabitForNotificationId(_ notificationId: String) -> Habit? {
        // Check if it's a day-specific notification
        if notificationId.contains("_") {
            let components = notificationId.split(separator: "_")
            if let habitId = components.first {
                return HabitListViewModel.shared.habits.first { $0.id.uuidString == String(habitId) }
            }
        }
        // Check if it's a basic habit notification
        return HabitListViewModel.shared.habits.first { $0.id.uuidString == notificationId }
    }
}
