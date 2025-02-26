import Foundation

struct Habit: Codable {
    // basic required information
    let id: UUID
    var name: String
    var description: String
    var time: Date?
    var cue: String?
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
    var numberOfRepetitions: Int // number of times user wants to do a habit per day
    var dailyCompletion: [String: Int] // keys are date strings and values are counts
    
    // speeds up computation
    private var lastUpdateDate: Date
    
    // update stats when habit is completed/failed
    mutating func updateStats() {
        let calendar = Calendar.current
        let today = Date()
        
        print("last update \(lastUpdateDate)")
        print("today \(today)")
        print("same day check \(TimeFormatter.isSameDay(today, lastUpdateDate))")
        
        // no need to update if last update is today
        if TimeFormatter.isSameDay(lastUpdateDate, today) {
            print("checkign for the same day")
            return
        }
        
        var currentDate = lastUpdateDate
        
        // check if there's any missed days between last update and today
        while !TimeFormatter.isSameDay(currentDate, today) {
            guard let nextDay = calendar.date(byAdding: .day, value: 1, to: currentDate) else {
                break
            }
            currentDate = nextDay
            
            let dateString = TimeFormatter.dateToString(currentDate)
            let weekdayString = TimeFormatter.weekdayToString(currentDate)
            
            print("day is now \(dateString)")
            
            if daysOfTheWeek[weekdayString, default: false] {
                print("\(weekdayString) found in days of the week")
                let completionsForDay = dailyCompletion[dateString, default: 0]
                
                if !TimeFormatter.isSameDay(currentDate, today) && completionsForDay < numberOfRepetitions {
                    print("streak is broken")
                    streaks = 0
                    totalFailed += 1
                    break
                }
            }
        }
        
        totalDone = dailyCompletion.values.reduce(0, +)
        lastUpdateDate = today
    }
    
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
    init(id: UUID = UUID(), name: String, description: String, time: Date, daysOfTheWeek: [String: Bool], accountabilityMetric: AccountabilityMetric, location: Location? = nil, incentive: Incentive, notificationEnabled: Bool, totalDone: Int = 0, totalFailed: Int = 0, streaks: Int = 0, currentLevel: Level = .beginner, numberOfRepetitions: Int = 1, dailyCompletion: [String: Int] = [:], lastUpdateDate: Date = Date()) {
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
            self.numberOfRepetitions = numberOfRepetitions
            self.dailyCompletion = dailyCompletion
            self.lastUpdateDate = lastUpdateDate
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
        numberOfRepetitions = try container.decodeIfPresent(Int.self, forKey: .numberOfRepetitions) ?? 1
        dailyCompletion = try container.decodeIfPresent([String: Int].self, forKey: .dailyCompletion) ?? [:]
        lastUpdateDate = try container.decodeIfPresent(Date.self, forKey: .lastUpdateDate) ?? Date()
    }
}
