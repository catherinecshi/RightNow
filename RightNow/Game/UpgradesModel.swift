import UIKit

/// Cases for different upgrade types
enum UpgradeType: String, CaseIterable {
    case d6 = "Dice roll"
    case cards = "Playing Cards"
    case roulette = "Roulette"
    case bingo = "Bingo Ball"
    case lottery = "Lottery Card"
    
    var baseCost: Double {
        switch self {
        case .d6: return 150
        case .cards: return 2_500
        case .roulette: return 50_000
        case .bingo: return 1_000_000
        case .lottery: return 20_000_000
        }
    }
    
    /// range of what the random number could draw from
    var range: Double {
        switch self {
        case .d6: return 6
        case .cards: return 13
        case .roulette: return 24
        case .bingo: return 44
        case .lottery: return 90
        }
    }
    
    var description: String {
        switch self {
        case .d6: return "Multiplies your total by 1-6 in the number factory"
        case .cards: return "Multiplies your total by 1-13 in the number factory"
        case .roulette: return "Multiplies your total by 1-24 in the number factory"
        case .bingo: return "Multiplies your total by 1-44 in the number factory"
        case .lottery: return "Multiplies your total by 1-90 in the number factory"
        }
    }
}
