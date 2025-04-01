// Direction enum for player movement
enum PlayerDirection {
    case up, down, left, right
}

// Rules for numbers to avoid
enum AvoidRule: CaseIterable {
    case endsWithThree
    case endsWithFour
    case endsWithFive
    case endsWithSix
    case endsWithSeven
    case endsWithEight
    case endsWithNine
    
    // Get readable description of the rule
    var description: String {
        switch self {
        case .endsWithThree:
            return "Ending in 3"
        case .endsWithFour:
            return "Ending in 4"
        case .endsWithFive:
            return "Ending in 5"
        case .endsWithSix:
            return "Ending in 6"
        case .endsWithSeven:
            return "Ending in 7"
        case .endsWithEight:
            return "Ending in 8"
        case .endsWithNine:
            return "Ending in 9"
        }
    }
    
    // Check if a number violates the rule
    func checkViolation(_ number: Int) -> Bool {
        switch self {
        case .endsWithThree:
            return number % 10 == 3
        case .endsWithFour:
            return number % 10 == 4
        case .endsWithFive:
            return number % 10 == 5
        case .endsWithSix:
            return number % 10 == 6
        case .endsWithSeven:
            return number % 10 == 7
        case .endsWithEight:
            return number % 10 == 8
        case .endsWithNine:
            return number % 10 == 9
        }
    }
}
