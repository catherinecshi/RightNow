import UIKit

// Upgrade model
class Upgrade {
    let name: String
    let baseCost: Double
    let range: Int
    let description: String
    var level: Int = 0
    
    var currentCost: Double {
        return baseCost * pow(1.15, Double(level))
    }
    
    init(name: String, baseCost: Double, range: Int, description: String) {
        self.name = name
        self.baseCost = baseCost
        self.range = range
        self.description = description
    }
}

enum UpgradeType: String, CaseIterable {
    case d6 = "Dice roll"
    case cards = "Playing Cards"
    case roulette = "Roulette"
    case bingo = "Bingo Ball"
    case lottery = "Lottery Card"
    
    var baseCost: Double {
        switch self {
        case .d6: return 15
        case .cards: return 100
        case .roulette: return 1100
        case .bingo: return 12000
        case .lottery: return 130000
        }
    }
    
    var range: Double {
        switch self {
        case .d6: return 6
        case .cards: return 13
        case .roulette: return 36
        case .bingo: return 75
        case .lottery: return 200
        }
    }
    
    var description: String {
        switch self {
        case .d6: return "Adds 1-6 to your total in the number factory"
        case .cards: return "Adds 1-13 to your total in the number factory"
        case .roulette: return "Adds 1-36 to your total in the number factory"
        case .bingo: return "Adds 1-75 to your total in the number factory"
        case .lottery: return "Adds 1-150 to your total in the number factory"
        }
    }
}
