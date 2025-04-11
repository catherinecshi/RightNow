import Foundation

struct UserSettings: Codable {
    var hasCompletedOnboarding: Bool
    
    enum CodingKeys: String, CodingKey {
        case hasCompletedOnboarding = "has_completed_onboarding"
    }
}
