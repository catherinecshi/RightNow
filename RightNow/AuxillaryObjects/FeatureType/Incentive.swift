import Foundation

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
