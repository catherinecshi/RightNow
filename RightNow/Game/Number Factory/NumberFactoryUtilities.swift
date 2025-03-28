// Direction enum for player movement
enum PlayerDirection {
    case up, down, left, right
}

// Rules for numbers to avoid
enum AvoidRule: CaseIterable {
    case endsWithThree
    case isDivisibleByThree
    case isEven
    case isOdd
    
    // Get readable description of the rule
    var description: String {
        switch self {
        case .endsWithThree:
            return "Ending in 3"
        case .isDivisibleByThree:
            return "Multiples of 3"
        case .isEven:
            return "Even numbers"
        case .isOdd:
            return "Odd numbers"
        }
    }
    
    // Check if a number violates the rule
    func checkViolation(_ number: Int) -> Bool {
        switch self {
        case .endsWithThree:
            return number % 10 == 3
        case .isDivisibleByThree:
            return number % 3 == 0
        case .isEven:
            return number % 2 == 0
        case .isOdd:
            return number % 2 != 0
        }
    }
}
