import Foundation

// MARK: Accountaibility Metrics

// supposedly for sending these types to firebase, but i don't think it is technically necessary
class AccountabilityMetricWrapper: NSObject, NSSecureCoding {
    static var supportsSecureCoding: Bool = true
    
    let value: AccountabilityMetric
    
    init(value: AccountabilityMetric) {
        self.value = value
    }
    
    required convenience init?(coder: NSCoder) {
        guard let rawValue = coder.decodeObject(of: NSString.self, forKey: "value") as String? else {
            return nil
        }
        
        guard let value = AccountabilityMetric(rawValue: rawValue) else {
            return nil
        }
        
        self.init(value: value)
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(value.rawValue, forKey: "value")
    }
}

enum AccountabilityMetric: String, Codable {
    case locationTracking
    case screenTime
    case photoEvidence
    
    var displayName: String {
        switch self {
        case .locationTracking: return "Track your Location"
        case .screenTime: return "Track your Screen Time Usage"
        case .photoEvidence: return "Take a Photo"
        }
    }
}

// MARK: Incentives

class IncentiveWrapper: NSObject, NSSecureCoding {
    static var supportsSecureCoding: Bool = true
    
    let value: Incentive
    
    init(value: Incentive) {
        self.value = value
    }
    
    required convenience init?(coder: NSCoder) {
        guard let rawValue = coder.decodeObject(of: NSString.self, forKey: "value") as String? else {
            return nil
        }
        
        guard let value = Incentive(rawValue: rawValue) else {
            return nil
        }
        
        self.init(value: value)
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(value.rawValue, forKey: "value")
    }
}

enum Incentive: String, Codable {
    case none
    case money
    case blockApps
    
    var displayName: String {
        switch self {
        case .none: return "None"
        case .money: return "Stake Money"
        case .blockApps: return "Block Apps"
        }
    }
}

// MARK: Level

class LevelWrapper: NSObject, NSSecureCoding {
    static var supportsSecureCoding: Bool = true
    
    let value: Level
    
    init(value: Level) {
        self.value = value
    }
    
    required convenience init?(coder: NSCoder) {
        guard let rawValue = coder.decodeObject(of: NSString.self, forKey: "value") as String? else {
            return nil
        }
        
        guard let value = Level(rawValue: rawValue) else {
            return nil
        }
        
        self.init(value: value)
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(value.rawValue, forKey: "value")
    }
}

enum Level: String, Codable, CaseIterable {
    case beginner
    case novice
    case intermediate
    case competent
    case proficient
    case advanced
    case expert
    case elite
    case mastery
    
    var displayName: String {
        switch self {
        case .beginner: return "Beginner"
        case .novice: return "Novice"
        case .intermediate: return "Intermediate"
        case .competent: return "Competent"
        case .proficient: return "Proficient"
        case .advanced: return "Advanced"
        case .expert: return "Expert"
        case .elite: return "Elite"
        case .mastery: return "Mastery"
        }
    }
    
    var streakForLevel: Int {
        switch self {
        case .beginner: return 3
        case .novice: return 7
        case .intermediate: return 14
        case .competent: return 30
        case .proficient: return 60
        case .advanced: return 100
        case .expert: return 200
        case .elite: return 365
        case .mastery: return 1000
        }
    }
    
    var previousLevel: Level? {
        let levels = Level.allCases
        guard let currentIndex = levels.firstIndex(of: self), currentIndex > 0 else {
            return nil
        }
        return levels[currentIndex - 1]
    }
}
