import Foundation

/// The types of incentives the user can choose
enum Incentive: String, Codable {
    case none
    case money
    case blockApps
    
    /// Returns string for corresponding incentive
    var displayName: String {
        switch self {
        case .none: return "None"
        case .money: return "Stake Money"
        case .blockApps: return "Block Apps"
        }
    }
}
