import Foundation
import UIKit
import FirebaseAuth

/// Central manager for all things notification-related
///
/// This class is responsible for:
/// - Requesting and handling notification permissions
/// - Registering for remote notifications
/// - Scheduling habit reminder notifications
/// - Managing notification categories and actions
/// - Handling notification interactions (taps, action buttons)
///
/// Usage example:
/// ```
/// // Request notification permissions
/// await PushNotificationDelegate.shared.registerForPushNotifications()
///
/// // Schedule notifications for a habit
/// let habit = Habit(...)
/// PushNotificationDelegate.shared.scheduleNotificationsForHabit(habit)
/// ```
final class PushNotificationDelegate: AppDelegateType, UNUserNotificationCenterDelegate, Resettable {
    static let shared = PushNotificationDelegate()
    let repo = HabitRepository.shared
    
    // avoid unnecessary initialisation
    private override init() {
        super.init()
        SingletonRegistry.shared.register(self)
    }
    
    /// Errors that can occur when scheduling notifications
    enum NotificationError: LocalizedError {
        case pastDate
        case schedulingFailed(Error) // system error
        
        /// Human readable descriptions of errors
        var errorDescription: String? {
            switch self {
            case .pastDate:
                return "Cannot schedule notification for past date"
            case .schedulingFailed(let error):
                return "Failed to schedule notification: \(error)"
            }
        }
    }
    
    private let notificationCenter = UNUserNotificationCenter.current() // system's notif center
    weak var window: UIWindow?
    
    // for checking notification settings
    private var _cachedPermissionStatus: UNAuthorizationStatus = .notDetermined // last known status
    public var cachedPermissionStatus: UNAuthorizationStatus { // cache - returns last known status
        _cachedPermissionStatus
    }
    
    // resetting
    func reset() {
        removePendingNotifications()
    }
    
    // MARK: - UIApplicationDelegate Methods
    /// Called when the app finishes launching.
    /// - Parameters:
    ///   - application: The singleton app object.
    ///   - launchOptions: A dictionary indicating the reason the app was launched.
    /// - Returns: `true` if the delegate handled the launch successfully.
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        //registerForPushNotifications()
        //removePendingNotifications()
        //getPendingNotifications()
        
        return true
    }
    
    /// Called when the app successfully registers for remote notifications.
    /// - Parameters:
    ///   - application: The singleton app object.
    ///   - deviceToken: A token that identifies the device to APNs.
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let deviceToken: String = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("Device token is: \(deviceToken)")
    }
    
    /// Called when the app fails to register for remote notifications.
    /// - Parameters:
    ///   - application: The singleton app object.
    ///   - error: The error that occurred during registration.
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for remote notifications: \(error)")
    }
    
    // MARK: - UNUserNotificationCenterDelegate Methods
    /// Called when a notification is about to be presented while the app is in the foreground.
    /// - Parameters:
    ///   - center: The notification center object.
    ///   - notification: The notification to be presented.
    ///   - completionHandler: A block to execute with the presentation options.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions
    ) -> Void) {
        // called when app is in foreground for notification
        print("Notification will present: \(notification.request.identifier)")
        completionHandler([.banner, .list, .sound])
    }
    
    // MARK: - Private Notification Handling Methods
    
    /// Retrieves the habit associated with a notification.
    /// - Parameter notification: The notification containing the habit ID.
    /// - Returns: The habit if found, nil otherwise.
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
    
// MARK: - Push Notification Management API
extension PushNotificationDelegate {
    /// Requests permission to send notifications with a completion handler
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
    
    /// Schedules notifications for all active days of a habit
    func scheduleNotificationsForHabit(_ habit: Habit) {
        for (day, isActive) in habit.daysOfTheWeek {
            guard isActive else { continue }
            
            let content = UNMutableNotificationContent()
            content.title = "Right Now"
            //content.categoryIdentifier = "HabitReminder"
            
            if let _ = habit.time { // for time based habits
                content.body = "Are you starting to \(habit.name) now?"
            } else {
                print("something weird going on - no time for habit and no cue either")
            }
            
            content.sound = UNNotificationSound.default
            
            // information that can be fetched in notification
            let uuidString = habit.id.uuidString
            content.userInfo = ["habitID": uuidString]
            
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
    
    /// Cancels all notifications for a habit
    func cancelNotificationForHabit(for habit: Habit) {
        for day in habit.daysOfTheWeek.keys {
            let identifier = "\(habit.id)_\(day)"
            notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
        }
    }
    
    /// Cancels a specific notification by its identifier
    ///
    /// - Parameter identifier: The unique identifier of the notification
    /// - Returns: `true` if the notification existed and was cancelled
    func cancelNotification(withIdentifier identifier: String) async -> Bool {
        let requests = await notificationCenter.pendingNotificationRequests()
        let exists = requests.contains { $0.identifier == identifier }
        
        await notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
        return exists
    }
    
    /// Retrieves current notification permission status
    /// - Parameter completion: A closure to be executed with the current authorization status
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
/// Model representing notification to be scheduled
struct NotificationRequest {
    let title: String
    let body: String
    let trigger: NotificationTrigger? // determines when the notification will be delivered
    let identifier: String // unique identifier
    let userInfo: [AnyHashable: Any]? // additional data
    let sound: UNNotificationSound?
    let categoryIdentifier: String? // category identifier used for actions
}

/// Represents different ways to trigger a notification
enum NotificationTrigger {
    case time(Date) // trigger at specific date and time
    case interval(TimeInterval) // trigger after a specified time interval
    case calendar(DateComponents) // trigger when specified calendar components match
    
    /// Converts into system's notification trigger type
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
    /// Schedules a notification using the provided request configuration.
    /// - Parameter request: The notification request to schedule.
    /// - Throws: An error if scheduling fails.
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
    
    /// Schedules a one-time notification at a specific date.
    /// - Parameters:
    ///   - title: The title of the notification.
    ///   - body: The body text of the notification.
    ///   - date: The date and time when the notification should be delivered.
    ///   - identifier: A unique identifier for the notification. Defaults to a random UUID string.
    /// - Throws: An error if scheduling fails or if the date is in the past.
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
    
    /// Schedules a notification to be delivered immediately.
    /// - Parameters:
    ///   - title: The title of the notification.
    ///   - body: The body text of the notification.
    ///   - identifier: A unique identifier for the notification. Defaults to a random UUID string.
    /// - Throws: An error if scheduling fails.
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
    
    /// Schedules a notification to be delivered after a specified delay.
    /// - Parameters:
    ///   - title: The title of the notification.
    ///   - body: The body text of the notification.
    ///   - delay: The time interval to wait before delivering the notification.
    ///   - identifier: A unique identifier for the notification. Defaults to a random UUID string.
    /// - Throws: An error if scheduling fails or if the delay is negative.
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
    
    /// Schedules a notification to be delivered when a timer completes.
    /// - Parameters:
    ///   - timeInterval: The duration of the timer.
    ///   - title: The title of the notification. Defaults to "Work done!".
    ///   - body: The body text of the notification. Defaults to "You've completed a session!".
    ///   - identifier: A unique identifier for the notification. Defaults to a random UUID string.
    ///   - categoryIdentifier: The category identifier for the notification, used for action buttons.
    ///   - userInfo: Additional data to store with the notification.
    ///   - completion: A callback to execute when scheduling completes or fails.
    /// - Throws: `NotificationError.pastDate` if the time interval is negative, or another error if scheduling fails.
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
    /// Prints details of all pending notifications to the console
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
    
    /// Remove all pending notifications
    private func removePendingNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
    }
    
    /// Creates and removes unexpected scheduled notifications based on habits
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
    
    /// Finds the habit associated with a notification identifier
    /// - Parameter notificationId: The identifier of the notification
    /// - Returns: The associated habit if found, nil otherwise
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
