import Foundation

struct Habit: Codable {
    // basic required information
    let id: UUID
    var name: String
    var description: String
    var time: Date
    var daysOfTheWeek: [String: Bool]
    
    // accountability
    var accountabilityMetric: String
    var location: Location?
    
    // incentive
    var incentive: String
    
    // notification
    var notificationEnabled: Bool
}
