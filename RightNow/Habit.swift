import Foundation

struct Habit: Codable {
    // basic required information
    let id: UUID
    var name: String
    var description: String
    var time: Date
    var daysOfTheWeek: [String: Bool] // the strings are 3 letter combos
    
    // accountability
    var accountabilityMetric: AccountabilityMetric
    var location: Location?
    
    // incentive
    var incentive: Incentive
    
    // notification
    var notificationEnabled: Bool
    
    // progress thus far
    var totalDone: Int // number of times this habit has been done by the user
    var totalFailed: Int// number of times the user has failed this habit
    var streaks: Int
    
    // dynamically calculates current level based on the current streak
    var currentLevel: Level {
        let levels = Level.allCases.sorted { $0.streakForLevel < $1.streakForLevel }
        for level in levels {
            if streaks < level.streakForLevel {
                return level
            }
        }
        return .mastery
    }
    
    // if habit is made from habit creation or editing
    init(id: UUID = UUID(), name: String, description: String, time: Date, daysOfTheWeek: [String: Bool], accountabilityMetric: AccountabilityMetric, location: Location? = nil, incentive: Incentive, notificationEnabled: Bool, totalDone: Int = 0, totalFailed: Int = 0, streaks: Int = 0, currentLevel: Level = .beginner) {
            self.id = id
            self.name = name
            self.description = description
            self.time = time
            self.daysOfTheWeek = daysOfTheWeek
            self.accountabilityMetric = accountabilityMetric
            self.location = location
            self.incentive = incentive
            self.notificationEnabled = notificationEnabled
            self.totalDone = totalDone
            self.totalFailed = totalFailed
            self.streaks = streaks
        }
    
    // if loaded in from firestore - incase new variables are added, this adds default values
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decode(String.self, forKey: .description)
        time = try container.decode(Date.self, forKey: .time)
        daysOfTheWeek = try container.decode([String: Bool].self, forKey: .daysOfTheWeek)
        accountabilityMetric = try container.decode(AccountabilityMetric.self, forKey: .accountabilityMetric)
        location = try? container.decode(Location.self, forKey: .location)
        incentive = try container.decode(Incentive.self, forKey: .incentive)
        notificationEnabled = try container.decodeIfPresent(Bool.self, forKey: .notificationEnabled) ?? true
        totalDone = try container.decodeIfPresent(Int.self, forKey: .totalDone) ?? 0
        totalFailed = try container.decodeIfPresent(Int.self, forKey: .totalFailed) ?? 0
        streaks = try container.decodeIfPresent(Int.self, forKey: .streaks) ?? 0
    }
}
