import Foundation
import MapKit
import CoreLocation

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = LocationManager() // instantiates as singleton instance
    
    private var locationManager = CLLocationManager()
    @Published var userLocation: CLLocationCoordinate2D?
    var onLocationUpdate: ((CLLocationCoordinate2D) -> Void)?
    let habitListModel = HabitListViewModel.shared
    
    var monitoredGeofences: [String: GeofenceData] = [:]
    
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
    func startMonitoringGeofence(for habit: Habit) {
        let location = habit.location!
        let time = habit.time
        let daysOfWeek = habit.daysOfTheWeek
        
        let geofenceRegion = CLCircularRegion(
            center: CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude),
            radius: 20,
            identifier: location.name
        )
        geofenceRegion.notifyOnEntry = true
        geofenceRegion.notifyOnExit = true
        
        // store geofence data
        monitoredGeofences[location.name] = GeofenceData(location: location, time: time, daysOfWeek: daysOfWeek, habit: habit)
        
        locationManager.startMonitoring(for: geofenceRegion)
        print("monitoring latitude: \(location.latitude) longitude: \(location.longitude)")
    }
    
    func stopMonitoringGeofence(for location: Location) {
        let geofenceRegion = CLCircularRegion(
            center: CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude),
            radius: 20,
            identifier: location.name
        )
        
        // remove from storage
        monitoredGeofences.removeValue(forKey: location.name)
        
        locationManager.stopMonitoring(for: geofenceRegion)
        print("Stopped monitoring latitude \(location.latitude), longitude: \(location.longitude)")
    }
    
    // delegates for handling geofence events
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        if let circularRegion = region as? CLCircularRegion {
            print("Entered region: \(circularRegion.identifier)")
            
            if let geofenceData = monitoredGeofences[circularRegion.identifier] {
                print("retrieved geofence data for \(circularRegion.identifier)")
                let currentTime = Date()
                let calendar = Calendar.current
                
                // check if the current day of week matches up with daysOfWeek
                let weekday = calendar.component(.weekday, from: currentTime)
                let dateFormatter = DateFormatter()
                dateFormatter.locale = Locale(identifier: "en_US")
                dateFormatter.dateFormat = "EEE"
                let weekdayString = dateFormatter.string(from: currentTime)
                
                var correctDay = false
                for (day, isActive) in geofenceData.daysOfWeek {
                    if day == weekdayString && isActive {
                        correctDay = true
                    }
                }
                
                // check if the time is within the margin of error
                let timeDifference = calendar.dateComponents([.minute], from: currentTime, to: geofenceData.time).minute ?? 0
                
                // send notification and count habit if both add up
                if correctDay && abs(timeDifference) <= 15 {
                    var habit = geofenceData.habit
                    habitListModel.habitCompleted(&habit)
                    sendProximityNotification(for: circularRegion.identifier)
                } else {
                    print("Notification skipped - not the time yet")
                }
            }
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
        content.title = "Right Now"
        content.body = "\(locationName) in progress!"
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
}
