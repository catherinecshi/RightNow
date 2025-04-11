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
        print("trying to configure")
        firebaseManager.configure()
        
        return true
    }
}
