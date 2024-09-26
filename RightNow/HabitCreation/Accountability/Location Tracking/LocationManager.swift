import Foundation
import MapKit
import CoreLocation

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = LocationManager() // instantiates as singleton instance
    private var locationManager = CLLocationManager()
    @Published var userLocation: CLLocationCoordinate2D?
    
    var onLocationUpdate: ((CLLocationCoordinate2D) -> Void)?
    
    override private init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }
    
    func requestAuthorization() {
        locationManager.requestAlwaysAuthorization()
    }
    
    func requestCurrentLocation() -> CLLocationCoordinate2D? {
        return locationManager.location?.coordinate
    }
    
    func startLocationUpdates() {
        locationManager.startUpdatingLocation()
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
    }
    
    func stopLocationUpdates() {
        locationManager.stopUpdatingLocation()
        locationManager.allowsBackgroundLocationUpdates = false
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        self.userLocation = location.coordinate
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedAlways:
            startLocationUpdates()
        case .authorizedWhenInUse:
            locationManager.startUpdatingLocation()
        case .notDetermined:
            requestAuthorization()
            break
        default:
            stopLocationUpdates()
        }
    }
    
    // geofencing
    func startMonitoringGeofence(for location: Location) {
        let geofenceRegion = CLCircularRegion(
            center: CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude),
            radius: 20,
            identifier: location.name
        )
        geofenceRegion.notifyOnEntry = true
        geofenceRegion.notifyOnExit = true
        
        locationManager.startMonitoring(for: geofenceRegion)
        print("monitoring latitude: \(location.latitude) longitude: \(location.longitude)")
    }
    
    func stopMonitoringGeofence(for location: Location) {
        let geofenceRegion = CLCircularRegion(
            center: CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude),
            radius: 20,
            identifier: location.name
        )
        
        locationManager.stopMonitoring(for: geofenceRegion)
        print("Stopped monitoring latitude \(location.latitude), longitude: \(location.longitude)")
    }
    
    // delegates for handling geofence events
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        if let circularRegion = region as? CLCircularRegion {
            print("Entered region: \(circularRegion.identifier)")
            sendProximityNotification(for: circularRegion.identifier)
        }
    }
    
    func locationManager(_ manger: CLLocationManager, didExitRegion region: CLRegion) {
        if let circularRegion = region as? CLCircularRegion {
            print("Exited region: \(circularRegion.identifier)")
        }
    }
    
    // notification
    func sendProximityNotification(for locationName: String) {
        print("trying to send notification")
        let content = UNMutableNotificationContent()
        content.title = "You're near \(locationName)"
        content.body = "You are within the vicinity of one of your saved locations."
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
}
