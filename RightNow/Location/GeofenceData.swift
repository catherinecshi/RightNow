import Foundation

/// Object storing data for each location being tracked with geofence
struct GeofenceData {
    var location: Location
    var time: Date?
    var daysOfWeek: [String: Bool]
    var habit: Habit
}
