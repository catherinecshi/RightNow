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
            tier = .none
        case 15..<30:
            tier = .I
        case 30..<45:
            tier = .II
        case 45..<60:
            tier = .III
        case 60..<75:
            tier = .IV
        case 75..<90:
            tier = .V
        case 90..<105:
            tier = .VI
        default:
            tier = .VII
        }
        
        return calculateReward(for: tier)
    }
    
    private func calculateReward(for tier: RewardTier) -> Int {
        // calculate some random chance of receiving an extra coupon
        let baseReward: Int
        
        let baseChance = 0.05
        let tierMultiplier = 0.05 // 5% additional chance per tier
        var tierValue = 0
        
        switch tier {
        case .none:
            baseReward = 0
            tierValue = 0
        case .I:
            baseReward = 1
            tierValue = 1
        case .II:
            baseReward = 2
            tierValue = 2
        case .III:
            baseReward = 3
            tierValue = 3
        case .IV:
            baseReward = 4
            tierValue = 4
        case .V:
            baseReward = 5
            tierValue = 5
        case .VI:
            baseReward = 6
            tierValue = 6
        case .VII:
            baseReward = 7
            tierValue = 7
        case .VIII:
            baseReward = 8
            tierValue = 8
        }
        
        // Calculate chance of extra coupon based on tier
        let extraCouponChance = baseChance + (Double(tierValue) * tierMultiplier)
        
        // Cap the chance at 90% to always maintain some randomness
        let cappedChance = min(extraCouponChance, 0.9)
        
        // Generate random number between 0 and 1
        let randomValue = Double.random(in: 0..<1)
        
        // Check if user gets an extra coupon
        if randomValue < cappedChance {
            return baseReward + 1 // Award an extra coupon
        } else {
            return baseReward // No extra coupon
        }
    }
    
    private func addCoupons(_ amount: Int) {
        gameModel.addCoupons(amount)
        print("rewards adding coupons")
    }
    
    private enum RewardTier {
        case none
        case I
        case II
        case III
        case IV
        case V
        case VI
        case VII
        case VIII
    }
}
