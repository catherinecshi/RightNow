import Foundation
import UIKit
import FirebaseAuth

final class PushNotificationDelegate: AppDelegateType, UNUserNotificationCenterDelegate {
    static let shared = PushNotificationDelegate()
    let repo = HabitRepository.shared
    
    // avoid unnecessary initialisation
    private override init() { }
    
    enum NotificationError: LocalizedError {
        case pastDate
        case schedulingFailed(Error)
        
        var errorDescription: String? {
            switch self {
            case .pastDate:
                return "Cannot schedule notification for past date"
            case .schedulingFailed(let error):
                return "Failed to schedule notification: \(error)"
            }
        }
    }
    
    private let notificationCenter = UNUserNotificationCenter.current()
    weak var window: UIWindow?
    
    // for checking notification settings
    private var _cachedPermissionStatus: UNAuthorizationStatus = .notDetermined // last known status
    public var cachedPermissionStatus: UNAuthorizationStatus {
        _cachedPermissionStatus
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        //registerForPushNotifications()
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
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions
    ) -> Void) {
        // called when app is in foreground for notification
        print("Notification will present: \(notification.request.identifier)")
        completionHandler([.banner, .list, .sound])
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) async {
        // called when user interacts with notification
        let actionIdentifier = response.actionIdentifier
        print("Notification response received with action identifier: \(actionIdentifier)")
        
        if let _ = Auth.auth().currentUser {
            switch actionIdentifier {
            case "Snooze_5":
                await handleSnooze5Minutes(notification: response.notification)
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
    
    private func handleSnooze5Minutes(notification: UNNotification) async {
        guard let habit = await retrieveHabit(from: notification) else {
            print("Could not retrieve habit from notification \(notification.description)")
            return
        }
        
        guard let content = notification.request.content.mutableCopy() as? UNMutableNotificationContent else {
            print("Failed to create mutable notification content")
            return
        }
        
        content.categoryIdentifier = "HabitReminder"
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5 * 60, repeats: false)
        let request = UNNotificationRequest(
            identifier: "\(habit.id.uuidString)_snoozed",
            content: content,
            trigger: trigger
        )
        
        try? await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            self.notificationCenter.add(request) { error in
                if let error = error {
                    print("Error scheduling snoozed notification \(error)")
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
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
    
    func retrieveHabit(from notification: UNNotification) async -> Habit? {
        guard let habitID = notification.request.content.userInfo["habitID"] as? String else {
            print("no habit id found in notification")
            return nil
        }
        
        do {
            return try await repo.fetchSingleHabit(habitID: habitID)
        } catch {
            print("Failed to fetch habit with ID: \(habitID)")
            return nil
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
            
            // update cached status after authorization
            self.getPermissionStatus { _ in }
            
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
    
    func requestAccessToNotifications(completion: @escaping (Bool) -> Void) {
        notificationCenter.getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .notDetermined:
                self.notificationCenter.requestAuthorization(options: [.alert, .sound]) { (granted, error) in
                    DispatchQueue.main.async {
                        if granted {
                            print("Notification permission granted!")
                            completion(true)
                        } else {
                            print("Notification permission denied because: \(error?.localizedDescription ?? " no error")")
                            completion(false)
                        }
                    }
                }
            default:
                completion(true)
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
            let daysOfWeek = TimeFormatter.allDays
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
    
    func cancelNotificationForHabit(for habit: Habit) {
        for day in habit.daysOfTheWeek.keys {
            let identifier = "\(habit.id)_\(day)"
            notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
        }
    }
    
    func cancelNotification(withIdentifier identifier: String) async -> Bool {
        let requests = await notificationCenter.pendingNotificationRequests()
        let exists = requests.contains { $0.identifier == identifier }
        
        await notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
        return exists
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
    
    // get authorization status
    public func getPermissionStatus(completion: @escaping (UNAuthorizationStatus) -> Void) {
        notificationCenter.getNotificationSettings { settings in
            DispatchQueue.main.async {
                self._cachedPermissionStatus = settings.authorizationStatus
                completion(settings.authorizationStatus)
            }
        }
    }
}

// MARK: - Create Custom Notification
struct NotificationRequest {
    let title: String
    let body: String
    let trigger: NotificationTrigger?
    let identifier: String
    let userInfo: [AnyHashable: Any]?
    let sound: UNNotificationSound?
    let categoryIdentifier: String?
}

enum NotificationTrigger {
    case time(Date)
    case interval(TimeInterval)
    case calendar(DateComponents)
    
    var unNotificationTrigger: UNNotificationTrigger {
        switch self {
        case .time(let date):
            let timeInterval = date.timeIntervalSinceNow
            return UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
        case .interval(let interval):
            return UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        case .calendar(let components):
            return UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        }
    }
}

extension PushNotificationDelegate {
    // main function to call for custom notifications
    func schedule(request: NotificationRequest) async throws {
        let content = UNMutableNotificationContent()
        content.title = request.title
        content.body = request.body
        content.sound = request.sound ?? .default
        
        if let userInfo = request.userInfo {
            content.userInfo = userInfo
        }
        
        if let categoryIdentifier = request.categoryIdentifier {
            content.categoryIdentifier = categoryIdentifier
        }
        
        let notificationRequest = UNNotificationRequest(
            identifier: request.identifier,
            content: content,
            trigger: request.trigger?.unNotificationTrigger
        )
        
        try await notificationCenter.add(notificationRequest)
    }
    
    // following are convenience methods for scheduling notifications
    func scheduleOneTime(
        title: String,
        body: String,
        at date: Date,
        identifier: String = UUID().uuidString
    ) async throws {
        let request = NotificationRequest(
            title: title,
            body: body,
            trigger: .time(date),
            identifier: identifier,
            userInfo: nil,
            sound: .default,
            categoryIdentifier: nil
        )
        
        try await schedule(request: request)
    }
    
    func scheduleNow(
        title: String,
        body: String,
        identifier: String = UUID().uuidString
    ) async throws {
        let request = NotificationRequest(
            title: title,
            body: body,
            trigger: nil,
            identifier: identifier,
            userInfo: nil,
            sound: .default,
            categoryIdentifier: nil
        )
        
        try await schedule(request: request)
    }
    
    func scheduleAfterDelay(
        title: String,
        body: String,
        delay: TimeInterval,
        identifier: String = UUID().uuidString
    ) async throws {
        let request = NotificationRequest(
            title: title,
            body: body,
            trigger: NotificationTrigger.interval(delay),
            identifier: identifier,
            userInfo: nil,
            sound: .default,
            categoryIdentifier: nil
        )
        
        try await schedule(request: request)
    }
    
    func scheduleTimerSuccessNotification(
        timeInterval: TimeInterval,
        title: String = "Work done!",
        body: String = "You've completed a session!",
        identifier: String? = nil,
        categoryIdentifier: String? = nil,
        userInfo: [AnyHashable: Any]? = nil,
        completion: ((Error?) -> Void)? = nil
    ) async throws {
        // don't schedule if the date is in the past
        guard timeInterval > 0 else {
            throw NotificationError.pastDate
        }
        
        // create identifier if none provided
        let notificationIdentifier = identifier ?? UUID().uuidString
        
        let request = NotificationRequest(
            title: title,
            body: body,
            trigger: .interval(timeInterval),
            identifier: notificationIdentifier,
            userInfo: userInfo,
            sound: .default,
            categoryIdentifier: categoryIdentifier
        )
        
        try await schedule(request: request)
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
            for habit in repo.getHabits() {
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
                return repo.getHabits().first { $0.id.uuidString == String(habitId) }
            }
        }
        // Check if it's a basic habit notification
        return repo.getHabits().first { $0.id.uuidString == notificationId }
    }
}
