import Foundation

/// Represents the state of the game at any point in time
struct GameState {
    let score: Int
    let goalValue: Int
    let isGoalReached: Bool
    let isGameOver: Bool
    let avoidRule: AvoidRule
    let playerValue: Int
    let playerPosition: (row: Int, col: Int)
    let grid: [[Int]]
    
    /// Create a new game state with default starting values
    static func initialState(gridSize: Int) -> GameState {
        let grid = Array(repeating: Array(repeating: 0, count: gridSize), count: gridSize)
        return GameState(
            score: 0,
            goalValue: 10,
            isGoalReached: false,
            isGameOver: false,
            avoidRule: AvoidRule.allCases.randomElement() ?? .endsWithThree,
            playerValue: 1,
            playerPosition: (row: gridSize - 2, col: gridSize / 2),
            grid: grid
        )
    }
}
