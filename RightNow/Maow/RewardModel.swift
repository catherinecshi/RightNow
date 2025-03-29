import Foundation

class RewardModel {
    private let gameModel = CentralGameModel.shared
    
    // the big boy to call
    public func timeToCoupons(minutes: Int) -> Int {
        let noCoupons = getRewardForSession(minutes: minutes)
        addCoupons(noCoupons)
        print("big boy making coupons")
        
        return noCoupons
    }
    
    // Get reward based on session duration
    private func getRewardForSession(minutes: Int) -> Int {
        // Base probability tiers based on session duration
        let tier: RewardTier
        
        switch minutes {
        case 0..<15:
            tier = .low
        case 15..<30:
            tier = .medium
        case 30..<45:
            tier = .high
        case 45..<60:
            tier = .epic
        case 60..<75:
            tier = .omega
        case 75..<90:
            tier = .beta
        case 90..<105:
            tier = .alpha
        default:
            tier = .sigma
        }
        
        return calculateReward(for: tier)
    }
    
    private func calculateReward(for tier: RewardTier) -> Int {
        switch tier {
        case .low:
            return 1
        case .medium:
            return 2
        case .high:
            return 3
        case .epic:
            return 4
        case .omega:
            return 5
        case .beta:
            return 6
        case .alpha:
            return 7
        case .sigma:
            return 8
        }
    }
    
    private func addCoupons(_ amount: Int) {
        gameModel.addCoupons(amount)
        print("rewards adding coupons")
    }
    
    private enum RewardTier {
        case low
        case medium
        case high
        case epic
        case omega
        case beta
        case alpha
        case sigma
    }
}
