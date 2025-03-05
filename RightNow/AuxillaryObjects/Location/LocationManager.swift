import Foundation
import MapKit
import CoreLocation

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = LocationManager() // instantiates as singleton instance
    
    private var locationManager = CLLocationManager()
    @Published var userLocation: CLLocationCoordinate2D? // broadcasts user location updates
    var onLocationUpdate: ((CLLocationCoordinate2D) -> Void)?
    let habitListModel = HabitListViewModel()
    let repo = HabitRepository.shared
    
    var monitoredGeofences: [String: GeofenceData] = [:]
    
    override private init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        setupHabitObserver()
    }
    
    func requestAuthorization() {
        locationManager.requestAlwaysAuthorization()
    }
    
    func requestCurrentLocation() -> CLLocationCoordinate2D? { // returns user's coordinates when available
        return locationManager.location?.coordinate
    }
    
    func startLocationUpdates() { // starts continuous background location updates
        locationManager.startUpdatingLocation()
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
    }
    
    func stopLocationUpdates() {
        locationManager.stopUpdatingLocation()
        locationManager.allowsBackgroundLocationUpdates = false
    }
    
    // MARK: - Geofence
    func startMonitoringGeofence(for habit: Habit) { // called when location habit first made
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
        print("monitoring latitude: \(location.latitude) longitude: \(location.longitude) for \(habit.name)")
    }
    
    func stopMonitoringGeofence(for location: Location) {
        let geofenceRegion = CLCircularRegion(
            center: CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude),
            radius: 20,
            identifier: location.name
        )
        
        // remove from storage by going through all available geofence regions adn deleting the corresponding one
        let monitoredRegions = locationManager.monitoredRegions
        
        if let regionToRemove = monitoredRegions.first(where: {$0.identifier == location.name}) {
            // stop monitoring for that region object
            locationManager.stopMonitoring(for: regionToRemove)
            
            // remove from local storage
            monitoredGeofences.removeValue(forKey: location.name)
            
            print("successfully removed geofence for: \(location.name)")
        } else {
            print("no matching geofence found for: \(location.name)")
        }
    }
    
    // MARK: - Delegates to Handle Geofence Events
    // handles incoming location updates & updates userLocation
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        self.userLocation = location.coordinate
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        if let circularRegion = region as? CLCircularRegion {
            print("Entered region: \(circularRegion.identifier)")
            sendEnteringNotification(for: circularRegion.identifier)
            
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
                    } else {
                        print("entered location on wrong day - \(day)")
                    }
                }
                
                // check if the time is within the margin of error
                if let time = geofenceData.time {
                    let timeDifference = calendar.dateComponents([.minute], from: currentTime, to: time).minute ?? 0
                    
                    // send notification and count habit if both add up
                    if correctDay && abs(timeDifference) <= 30 {
                        var habit = geofenceData.habit
                        repo.completeHabit(&habit)
                        sendProximityNotification(for: circularRegion.identifier)
                    } else {
                        print("Notification skipped - not the time yet")
                        print("\(correctDay) expected, but today is \(weekdayString)")
                        print("geofence time \(geofenceData.time) and time difference is \(timeDifference)")
                    }
                } else {
                    var habit = geofenceData.habit
                    repo.completeHabit(&habit)
                    sendProximityNotification(for: circularRegion.identifier)
                }
            }
        }
    }
    
    func locationManager(_ manger: CLLocationManager, didExitRegion region: CLRegion) {
        if let circularRegion = region as? CLCircularRegion {
            print("Exited region: \(circularRegion.identifier)")
        }
    }
    
    // MARK: - Auxillary Functions
    func sendProximityNotification(for locationName: String) {
        print("trying to send notification")
        Task {
            do {
                try await PushNotificationDelegate.shared.scheduleNow(title: "Right Now", body: "\(locationName) in progress")
            } catch {
                print("Failed send proximity notification: \(error)")
            }
        }
    }
    
    func sendEnteringNotification(for locationName: String) {
        print("trying to send entering notification")
        Task {
            do {
                try await PushNotificationDelegate.shared.scheduleNow(title: "Right Now", body: "\(locationName) entered!")
            }
        }
    }
    
    func printActiveGeofences() {
        print("Currently monitored regions: ")
        for region in locationManager.monitoredRegions {
            print("- \(region.identifier)")
        }
        
        print("\nLocally stored geofences: ")
        for (name, _) in monitoredGeofences {
            print("- \(name)")
        }
    }
    
    // iOS has a limit of 20 geofences per app
    func canAddNewGeofence() -> Bool {
        let maxRegions = 20
        return locationManager.monitoredRegions.count < maxRegions
    }
    
    func removeAllGeofences() {
        for region in locationManager.monitoredRegions {
            locationManager.stopMonitoring(for: region)
        }
        
        monitoredGeofences.removeAll()
        print("Cleared all geofences")
    }
    
    func synchronizeGeofencesWithHabits() {
        let currentHabits = repo.getHabits().filter { $0.location != nil }
        
        // set of habit names that should have geofences
        let validHabitNames = Set(currentHabits.map { $0.name })
        
        // ios monitored regions
        let monitoredRegions = locationManager.monitoredRegions
        
        GeofenceLogger.shared.log("----- Starting Geofence Synchronization --------")
        GeofenceLogger.shared.log("Found \(currentHabits.count) habits with locations")
        GeofenceLogger.shared.log("Currently monitoring \(monitoredRegions.count) regions in iOS")
        GeofenceLogger.shared.log("Locally storing \(monitoredGeofences.count) geofences")
        
        GeofenceLogger.shared.log("\nCurrent monitored regions:")
        monitoredRegions.forEach { region in
            GeofenceLogger.shared.log("- \(region.identifier)")
        }
        
        // remove ios monitored regions
        for region in monitoredRegions {
            if !validHabitNames.contains(region.identifier) {
                GeofenceLogger.shared.log("Removing outdated iOS region: \(region.identifier)")
                locationManager.stopMonitoring(for: region)
                
                //verify removals
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                    guard let self = self else { return }
                    if self.locationManager.monitoredRegions.contains(where: { $0.identifier == region.identifier }) {
                        print("⚠️ Region \(region.identifier) still present after removal attempt")
                    } else {
                        print("✅ Region \(region.identifier) successfully removed")
                    }
                }
            }
        }
        
        // remove local regions
        let outdatedGeofences = monitoredGeofences.keys.filter { !validHabitNames.contains($0) }
        for geofenceName in outdatedGeofences {
            GeofenceLogger.shared.log("Removing outdated local geofence: \(geofenceName)")
            monitoredGeofences.removeValue(forKey: geofenceName)
        }
        
        // add any missing geofences for current habits
        for habit in currentHabits {
            let habitName = habit.name
            let isMonitored = monitoredRegions.contains { $0.identifier == habitName }
            
            if !isMonitored {
                GeofenceLogger.shared.log("Adding missing geofence for habit: \(habitName)")
                startMonitoringGeofence(for: habit)
            }
        }
        
        // print final status
        GeofenceLogger.shared.log("\nFinal state - iOS monitored regions:") // THIS PROBABLY WORKS BUT THERE IS A LAG SO IF SOMETHING GETS DELETED IT MIGHT TAKE A WHILE SO THIS MAY BE WRONG SOMETIMES
        locationManager.monitoredRegions.forEach { region in
            GeofenceLogger.shared.log("- \(region.identifier)")
        }
        
        GeofenceLogger.shared.log("Now storing \(monitoredGeofences.count) local geofences")
        GeofenceLogger.shared.log("------- Synchronization Complete---------")
    }
}

// MARK: - Checking Authorization Status and Displaying Appropriate Alerts
extension Notification.Name {
    static let locationAuthorizationDidChange = Notification.Name("locationAuthorizationDidChange")
}

extension LocationManager {
    var authorizationStatus: CLAuthorizationStatus {
        return locationManager.authorizationStatus
    }
    
    var hasShownWhenInUseAlert: Bool {
        get {
            return UserDefaults.standard.bool(forKey: "hasShownWhenInUseAlert")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "hasShownWhenInUseAlert")
        }
    }
    
    // 
}

// MARK: - Observe Habits
extension LocationManager {
    func setupHabitObserver() {
        habitListModel.addObserver { [weak self] changeType in
            guard let self = self else { return }
            
            switch changeType {
            case .habitCRUD:
                self.synchronizeGeofencesWithHabits()
            default:
                break
            }
        }
    }
}
