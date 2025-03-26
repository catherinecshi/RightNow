import UIKit
import Firebase

/// Delegate responsible for firebase configuration and lifecycle management
final class FirebaseDelegate: AppDelegateType {
    static let shared = FirebaseDelegate()
    
    private var firebaseManager: FirebaseConfigurable // responsible for the actual operations
    
    /// Initializes with the specified firebase manager
    init(firebaseManager: FirebaseConfigurable = FirebaseManager.shared) {
        self.firebaseManager = firebaseManager
        super.init()
    }
    
    /// Configures firebase on app startup
    ///
    /// - Parameters:
    ///     - application : singleton app object
    ///     - launchOptions: dictionary indicating the reason the app was launched
    ///
    /// - Returns: Returns true to allow app launch to continue
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        firebaseManager.configure()
        swizzleFirebaseAnalytics()
        
        return true
    }
    
    /// Controls which Firebase Analytics calls are sent
    /// Connects the analytics calls with the in-house analytics controller
    /// Such that original method only called if analytics controller is enabled
    private func swizzleFirebaseAnalytics() {
        guard let analyticsClass = NSClassFromString("FIRAnalytics") else { return }
        
        // get the original logEvent method
        let originalSelector = NSSelectorFromString("logEventWithName:parameters:")
        guard let originalMethod = class_getClassMethod(analyticsClass, originalSelector) else { return }
        
        // create replacement method
        let replacementSelector = #selector(self.swizzled_logEventWithName(_:parameters:))
        let replacementMethod = class_getInstanceMethod(FirebaseDelegate.self, replacementSelector)!
        
        // swap the implementations
        method_exchangeImplementations(originalMethod, replacementMethod)
    }
    
    /// Replacement method that checks if analytics should be disabled
    ///
    /// - Parameters;
    ///     - name : event name
    ///     - parameters : optional dictionary of event parameters
    @objc func swizzled_logEventWithName(_ name: String, parameters: [String: Any]?) {
        // only proceed if analytics is enabled
        if AnalyticsController.shared.isEnabled {
            // call original implementation
            self.swizzled_logEventWithName(name, parameters: parameters)
        }
    }
}
