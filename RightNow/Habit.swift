import Foundation

struct Habit: Codable {
    let id: UUID
    var name: String
    var description: String
    var time: Date
    var daysOfTheWeek: [String: Bool]
    var notificationEnabled: Bool
}
