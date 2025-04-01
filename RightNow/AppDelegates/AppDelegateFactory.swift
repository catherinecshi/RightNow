import Foundation

/// Factory responsible for creating and configuring the different application delegates
/// Access point to pre-configured delegate instances for specific application needs
enum AppDelegateFactory {
    /// Returns a composite delegate configured for handling:
    /// - Push Notifications
    /// - Firebase
    static var fetchDelegates: AppDelegateType {
        CompositeAppDelegate(appDelegates: [
            PushNotificationDelegate.shared,
            FirebaseDelegate.shared
        ])
    }
}
