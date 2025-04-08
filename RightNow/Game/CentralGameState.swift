import Foundation

/// Game state model that's compatible with Firestore and local JSON storage
struct CentralGameState: Codable {
    // Unique identifier
    var id: UUID
    
    // Currencies
    var numbers: Double = 0
    var coupons: Int = 5
    
    // Timestamps for offline progress calculation
    var lastUpdateTime: Date = Date()
    
    // Upgrade levels stored by type identifier
    var upgradeLevels: [String: Int] = [:]
    
    // Statistics
    var totalNumbersEarned: Double = 0
    var totalCouponsEarned: Int = 0
    var totalUpgradesPurchased: Int = 0
    
    // Constructor with default values
    init(id: UUID = UUID()) {
        self.id = id
        
        // Initialize all upgrade types with level 0
        for upgradeType in UpgradeType.allCases {
            upgradeLevels[upgradeType.rawValue] = 0
        }
    }
    
    // Helper to get upgrade level
    func level(for upgradeType: UpgradeType) -> Int {
        return upgradeLevels[upgradeType.rawValue] ?? 0
    }
}
