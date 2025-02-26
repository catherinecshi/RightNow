import Foundation

struct HabitData {
    // basic required info
    var name: String?
    var hour: Int?
    var minute: Int?
    var selectedDays: [String: Bool]?
    var cue: String?
    
    //  progression
    var currentLevel: String?
    var currentLength: Int?
    var goalLength: Int?
    
    // accountability
    var accountabilityMetric: AccountabilityMetric?
    var location: Location?
    var stayOffPhoneDuration: TimeInterval?
    
    // incentive
    var incentive: Incentive?
}
