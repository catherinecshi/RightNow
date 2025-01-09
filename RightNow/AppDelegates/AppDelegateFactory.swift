/*
 puts all the different delegates together
 */

import Foundation

enum AppDelegateFactory {
    static var fetchDelegates: AppDelegateType {
        CompositeAppDelegate(appDelegates: [
            PushNotificationDelegate.shared
        ])
    }
}
