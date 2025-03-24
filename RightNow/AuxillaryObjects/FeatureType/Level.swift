import Foundation

/// Levels representing streak length of a habit
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
    
    /// Returns string for corresponding level
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
    
    /// Returns Int (streak length) for corresponding level
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
    
    /// Returns the level before the input level
    var previousLevel: Level? {
        let levels = Level.allCases
        guard let currentIndex = levels.firstIndex(of: self), currentIndex > 0 else {
            return nil
        }
        return levels[currentIndex - 1]
    }
}
