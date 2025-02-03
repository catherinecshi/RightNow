import Foundation

struct GeofenceData {
    var location: Location
    var time: Date?
    var daysOfWeek: [String: Bool]
    var habit: Habit
}
