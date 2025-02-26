import Foundation

enum AccountabilityMetric: String, Codable {
    case locationTracking
    case screenTime
    case photoEvidence
    case selfTracking
    case objectDetection
    case stayStill
    case stepCount
    case stayOffPhone
    
    var displayName: String {
        switch self {
        case .locationTracking: return "Track your Location"
        case .screenTime: return "Track your Screen Time Usage"
        case .photoEvidence: return "Take a Photo"
        case .selfTracking: return "Self Tracking"
        case .objectDetection: return "Object Detection"
        case .stayStill: return "Stay Still"
        case .stepCount: return "Track your Steps"
        case .stayOffPhone: return "Stay Off your Phone"
        }
    }
}
