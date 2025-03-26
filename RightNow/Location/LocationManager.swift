import Foundation
import Combine
import MapKit
import CoreLocation

/// Central Manager for all things related to location
///
/// Features:
/// - Location authorization management
/// - User location tracking
/// - Geofence creation and monitoring of habits
/// - Automatic habit completion based on geofenced locations
/// - Notification delivery for location-based events
///
/// # Important:
/// - iOS limits apps to tracking a maximum of 20 geofences at once
/// - Requires "Always" location authorization for background tracking
///
/// # Requirements:
/// - Info.plist entries:
///     - NSLocationAlwaysAndWhenInUseUsageDescription
///     - NSLocationWhenInUseUsageDescription
///     - NSLocationAlwaysUsageDescription
/// - Background modes:
///     - Location updates
///     - Background fetch
///     - Remote notifications
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = LocationManager() // singleton instance
    
    private var locationManager = CLLocationManager() // underlying core location manager
    @Published var userLocation: CLLocationCoordinate2D? // broadcasts user location updates
    var onLocationUpdate: ((CLLocationCoordinate2D) -> Void)? // callback when user's location updates
    let repo = HabitRepository.shared // manages habit data
    private var cancellables = Set<AnyCancellable>()
    
    /// Dictionary mapping geofence identifiers to its associated data
    /// Allows for quick lookup
    var monitoredGeofences: [String: GeofenceData] = [:]
    
    /// Sets up location manager with the appropriate accuracy
    /// Sets up observers for habit changes in repo
    override private init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        setupHabitObserver()
    }
    
    /// Requests "Always" authorization for location services
    /// Prompts user with system permission dialogue
    func requestAuthorization() {
        locationManager.requestAlwaysAuthorization()
    }
    
    /// Returns user's current location coordinates when available
    /// Returns nil when location is unavailable
    func requestCurrentLocation() -> CLLocationCoordinate2D? {
        return locationManager.location?.coordinate
    }
    
    /// Starts continuous background location updates of user
    func startLocationUpdates() {
        locationManager.startUpdatingLocation()
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
    }
    
    /// Stops background location updates of user
    func stopLocationUpdates() {
        locationManager.stopUpdatingLocation()
        locationManager.allowsBackgroundLocationUpdates = false
    }
    
    // MARK: - Geofence
    /// Starts monitoring geofence for a specific habit
    ///
    /// Creates circular region around habit location and monitors for entry and exit events
    /// Habit marked complete when geofence entered at appropraite time
    /// Stores geofence data in local dictionary
    /// Called when location habit is first made
    ///
    /// Parameters:
    /// - habit : Habit
    ///     - habit whose geofence will start being monitored
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
        print("monitoring latitude: \(location.latitude) longitude: \(location.longitude) for \(habit.name)")
    }
    
    /// Stops monitoring geofence for specified location
    ///
    /// Removes geofence from both iOS monitoring system and local dictionary
    ///
    /// Parameters:
    /// - location : Location
    ///     - the location to stop monitoring
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
    
    /// Checks if a new geofence can be added with exceeding limit
    /// Returns true if new geofence can be added
    ///
    /// iOS has a limit of 20 geofences per app at a single time
    func canAddNewGeofence() -> Bool {
        let maxRegions = 20
        return locationManager.monitoredRegions.count < maxRegions
    }
    
    /// Removes all geofences from iOS and local dictionary
    func removeAllGeofences() {
        for region in locationManager.monitoredRegions {
            locationManager.stopMonitoring(for: region)
        }
        
        monitoredGeofences.removeAll()
        print("Cleared all geofences")
    }
    
    // MARK: - Delegates to Handle Geofence Events
    /// Handles location updates from the iOS system
    ///
    /// Updates local variable userLocation with most recent location
    /// Calls onLocationUpdate callback if set
    ///
    /// Parameters:
    /// - manager : CLLocationManager
    ///     - location manager providing the update
    ///     - typically just the manager currently monitoring location updates
    /// - locations : [CLLocation]
    ///     - array of location objects in chronological order
    ///     - so last one is the most recent
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        self.userLocation = location.coordinate
    }
    
    /// Handles geofence region entry events
    ///
    /// When the user enters a monitored region,
    /// 1. Send an entry notification to user
    /// 2. Verifies if current day and time matches the habit's time and date
    /// 3. Completes habit if appropriate, and sends a completion notification
    ///
    /// Parameters:
    /// - manager : CLLocationManager
    ///     - location manager providing the update
    ///     - typically just the manager currently monitoring location updates
    /// - region : CLRegion
    ///     - the region that was entered
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
                
                Task {
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
                            await repo.completeHabit(&habit)
                            sendProximityNotification(for: circularRegion.identifier)
                        } else {
                            print("Notification skipped - not the time yet")
                            print("\(correctDay) expected, but today is \(weekdayString)")
                            print("geofence time \(geofenceData.time) and time difference is \(timeDifference)")
                        }
                    } else {
                        var habit = geofenceData.habit
                        await repo.completeHabit(&habit)
                        sendProximityNotification(for: circularRegion.identifier)
                    }
                }
            }
        }
    }
    
    /// Handles geofence region exit events
    ///
    /// Currently just logs it
    ///
    /// Parameters:
    /// - manager : CLLocationManager
    ///     - location manager tracking the updates
    ///     - typically just the manager that's currently monitoring the locations
    /// - region : CLRegion
    ///     - the region that was exited
    func locationManager(_ manger: CLLocationManager, didExitRegion region: CLRegion) {
        if let circularRegion = region as? CLCircularRegion {
            print("Exited region: \(circularRegion.identifier)")
        }
    }
    
    // MARK: - Auxillary Functions
    /// Sends notification that habit is in progress to the user
    ///
    /// Parameters:
    /// - locationName : String
    ///     - name of the location to be displayed in notification
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
    
    /// Sends notification that the user has entered a geofence
    ///
    /// Parameters:
    /// - locationName : String
    ///     - name of the location to be displayed in notification
    func sendEnteringNotification(for locationName: String) {
        print("trying to send entering notification")
        Task {
            do {
                try await PushNotificationDelegate.shared.scheduleNow(title: "Right Now", body: "\(locationName) entered!")
            }
        }
    }
    
    /// Prints all monitored geofences in iOS and local dictionary
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
    
    /// Synchronizes the iOS monitored geofences with the local dictionary
    ///
    /// This method:
    /// 1. Identifies the habits that should have locations from habit repository
    /// 2. Removes outdated geofences from iOS and local dicttionary
    /// 3. Adds missing geofences for current habits
    /// 4. Logs the synchronization process
    ///
    /// Called during startup and habit CRUD operations
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
    /// notification sent when location authorization status changed
    static let locationAuthorizationDidChange = Notification.Name("locationAuthorizationDidChange")
}

extension LocationManager {
    /// current location authorization status
    var authorizationStatus: CLAuthorizationStatus {
        return locationManager.authorizationStatus
    }
    
    /// Indicates whether "When In Use" alert has already been shown
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
    /// Sets up obsever for habit changes to update geofences
    ///
    /// When habits CRUD, this observer automatically calls synchronizesGeofencesWithHabits
    func setupHabitObserver() {
        var cancellables = Set<AnyCancellable>()
        
        // Subscribe directly to the repository's publisher
        repo.habitPublisher
            .receive(on: RunLoop.main) // Ensure updates happen on main thread
            .sink { [weak self] changeType in
                guard let self = self else { return }
                
                switch changeType {
                case .habitCRUD:
                    self.synchronizeGeofencesWithHabits()
                case .levelChanged, .streakChanged:
                    // These changes don't affect geofencing, so we ignore them
                    break
                }
            }
            .store(in: &cancellables)
        
        // Store the cancellables as a property to prevent them from being deallocated
        self.cancellables = cancellables
    }
}
