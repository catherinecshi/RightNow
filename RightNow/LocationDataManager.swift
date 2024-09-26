import CoreLocation

class LocationDataManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var authorizationStatus: CLAuthorizationStatus?
    var locationManager = CLLocationManager()
    
    override init() {
        super.init()
        locationManager.delegate = self
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse: // location services are available
            authorizationStatus = .authorizedWhenInUse
            manager.requestLocation()
            break
        
        case .restricted: // location services unavailable currently
            authorizationStatus = .restricted
            break
            
        case .denied: // Location services unavailable currently
            authorizationStatus = .denied
            break
            
        case .notDetermined: // authorization not determined yet
            authorizationStatus = .notDetermined
            manager.requestWhenInUseAuthorization()
            break
            
        default:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("error :\(error.localizedDescription)")
    }
}
