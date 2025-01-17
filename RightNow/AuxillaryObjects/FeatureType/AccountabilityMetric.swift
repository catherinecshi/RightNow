import Foundation

enum AccountabilityMetric: String, Codable {
    case locationTracking
    case screenTime
    case photoEvidence
    case selfTracking
    
    var displayName: String {
        switch self {
        case .locationTracking: return "Track your Location"
        case .screenTime: return "Track your Screen Time Usage"
        case .photoEvidence: return "Take a Photo"
        case .selfTracking: return "Self Tracking"
        }
    }
}
