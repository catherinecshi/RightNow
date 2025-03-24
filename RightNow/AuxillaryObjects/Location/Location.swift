import Foundation
import CoreLocation

/// Location objects constructed from longitude and latitude
struct Location: Codable, Equatable, Identifiable {
    var id: UUID
    var name: String
    var latitude: Double
    var longitude: Double
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    static func ==(lhs: Location, rhs: Location) -> Bool {
        lhs.id == rhs.id
    }
}
