import UIKit
import CoreLocation

/// Responsible for location service initialization and lifecycle management
/// Integrates with application delegates
final class LocationDelegate: AppDelegateType {
    static let shared = LocationDelegate()
    
    /// location manager responsible for operations
    private var locationManager: LocationManager
    
    /// Initializes locationdelegate with specified manager
    init(locationManager: LocationManager = LocationManager.shared) {
        self.locationManager = locationManager
        super.init()
    }
    
    /// Initializes and configures location services when application launches
    ///
    /// - Parameters:
    ///     - application: singleton app object
    ///     - launchOptions: Dictionary indicating the reason the app was launched
    ///
    /// - Returns: true to allow app launch to continue
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let _ = LocationManager.shared
        
        // request authorization if needed
        if locationManager.authorizationStatus == .notDetermined {
            locationManager.requestAuthorization()
        }
        
        // sync with geofences on startup
        locationManager.synchronizeGeofencesWithHabits()
        
        // start location updates if authorized
        if locationManager.authorizationStatus == .authorizedAlways ||
            locationManager.authorizationStatus == .authorizedWhenInUse {
            locationManager.startLocationUpdates()
        }
        
        return true
    }
    
    /// Handles application entering background mode
    /// Continues location tracking when app is in background
    func applicationDidEnterBackground(_ application: UIApplication) {
        if locationManager.authorizationStatus == .authorizedAlways {
            locationManager.startLocationUpdates()
        }
    }
    
    
    /// Handles application becoming active
    /// Updates geofence monitoring when app is active
    func applicationDidBecomeActive(_ application: UIApplication) {
        locationManager.synchronizeGeofencesWithHabits()
    }
    
    /// Handles application termination
    /// Cleans up location resources when app terminates
    func applicationWillTerminate(_ application: UIApplication) {
        // nothing for now
    }
}
