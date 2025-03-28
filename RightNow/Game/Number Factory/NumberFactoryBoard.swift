import Foundation

/// Model for the logic in the game board
class NumberFactoryBoard {
    // Game constants
    let gridSize = 7
    private let maxInitialNumber = 5
    
    // MARK: - Game State
    var stateDidChange: ((NumberFactoryState, NumberFactoryState) -> Void)?
    var gameDidEnd: (() -> Void)?
    var didReachGoal: (() -> Void)?
    
    private var currentState: NumberFactoryState {
        didSet {
            // notify observers whenver state changes
            stateDidChange?(currentState, oldValue)
            
            // check for specific state changes
            if currentState.isGameOver && !oldValue.isGameOver {
                gameDidEnd?()
            }
            
            if currentState.isGoalReached && !oldValue.isGoalReached {
                didReachGoal?()
            }
        }
    }
    
    // MARK: - Properties
    var playerValue: Int {
        get { return currentState.playerValue }
        set {
            // check if the new value would violate the rule
            let wouldViolateRule = currentState.avoidRule.checkViolation(newValue)
            let wouldReachGoal = newValue >= currentState.goalValue
            
            // update state with consequences of value change
            currentState = NumberFactoryState(
                goalValue: wouldReachGoal ? newValue + Int.random(in: 5...15) : currentState.goalValue,
                isGoalReached: wouldReachGoal,
                isGameOver: wouldViolateRule || currentState.isGameOver,
                avoidRule: currentState.avoidRule,
                playerValue: newValue,
                playerPosition: currentState.playerPosition,
                grid: updateGrid(with: newValue)
            )
        }
    }
    
    var grid: [[Int]] { return currentState.grid }
    var playerRow: Int { return currentState.playerPosition.row }
    var playerCol: Int { return currentState.playerPosition.col }
    var isGameOver: Bool { return currentState.isGameOver }
    var isGameWon: Bool { return currentState.isGoalReached }
    var goalValue: Int { return currentState.goalValue }
    var avoidRule: AvoidRule { return currentState.avoidRule }
    
    // MARK: - Initialization
    init() {
        currentState = NumberFactoryState.initialState(gridSize: gridSize)
        fillGridWithRandomNumbers()
    }
    
    // MARK: - Grid Management
    private func updateGrid(with newPlayerValue: Int) -> [[Int]] {
        var newGrid = currentState.grid
        let (row, col) = currentState.playerPosition
        newGrid[row][col] = newPlayerValue
        return newGrid
    }
    
    // Fill the grid with random numbers 1-5
    private func fillGridWithRandomNumbers() {
        var newGrid = currentState.grid
        
        for row in 0..<gridSize {
            for col in 0..<gridSize {
                if row == playerRow && col == playerCol {
                    continue // Skip player position
                }
                newGrid[row][col] = Int.random(in: 1...maxInitialNumber)
            }
        }
        
        currentState = NumberFactoryState(
            goalValue: currentState.goalValue,
            isGoalReached: currentState.isGoalReached,
            isGameOver: currentState.isGameOver,
            avoidRule: currentState.avoidRule,
            playerValue: currentState.playerValue,
            playerPosition: currentState.playerPosition,
            grid: newGrid
        )
    }
    
    // Generate a new row at the top of the grid
    func generateNewTopRow() -> [Int] {
        return (0..<gridSize).map { _ in
            Int.random(in: 1...maxInitialNumber)
        }
    }
    
    // MARK: - Game Actions
    // Scroll the grid down by one row
    func scrollDown() -> Bool {
        // get current grid and player position
        var newGrid = currentState.grid
        let (oldRow, oldCol) = currentState.playerPosition
        
        // player position after scroll
        let newRow = oldRow + 1
        
        // check if player falls of the grid
        if newRow >= gridSize {
            currentState = NumberFactoryState(
                goalValue: currentState.goalValue,
                isGoalReached: currentState.isGoalReached,
                isGameOver: true,
                avoidRule: currentState.avoidRule,
                playerValue: currentState.playerValue,
                playerPosition: (row: oldRow, col: oldCol),
                grid: newGrid
            )
            
            return false
        }
        
        // remove bottom row and add new top row
        newGrid.removeLast()
        newGrid.insert(generateNewTopRow(), at: 0)
        
        newGrid[newRow][oldCol] = currentState.playerValue // reset player position
        
        // update state
        currentState = NumberFactoryState(
            goalValue: currentState.goalValue,
            isGoalReached: currentState.isGoalReached,
            isGameOver: currentState.isGameOver,
            avoidRule: currentState.avoidRule,
            playerValue: currentState.playerValue,
            playerPosition: (row: newRow, col: oldCol),
            grid: newGrid
        )
        
        return true
    }
    
    func movePlayer(direction: PlayerDirection) -> Bool {
        // Calculate the new position
        let newPosition = calculateNewPosition(from: currentState.playerPosition, direction: direction)
        
        // If position hasn't changed, return true and do nothing
        if newPosition == currentState.playerPosition {
            return true
        }
        
        // Create a new grid with player's old position cleared
        let clearedGrid = createClearedGrid(from: currentState.grid, at: currentState.playerPosition)
        
        // value of cell moved to
        let targetValue = clearedGrid[newPosition.row][newPosition.col]
        
        // Determine the result of the move
        if targetValue == 0 {
            // Empty cell move
            applyEmptyMove(to: clearedGrid, at: newPosition)
            return true
        } else {
            // Merge move
            return applyMergeMove(to: clearedGrid, at: newPosition, targetValue: targetValue)
        }
    }
    
    private func calculateNewPosition(from currentPosition: (row: Int, col: Int), direction: PlayerDirection) -> (row: Int, col: Int) {
        let (oldRow, oldCol) = currentPosition
        var newRow = oldRow
        var newCol = oldCol
        
        switch direction {
        case .up:
            newRow = max(0, oldRow - 1)
        case .down:
            newRow = min(gridSize - 1, oldRow + 1)
        case .left:
            newCol = max(0, oldCol - 1)
        case .right:
            newCol = min(gridSize - 1, oldCol + 1)
        }
        
        return (row: newRow, col: newCol)
    }
    
    // Create a grid with the player's position cleared
    private func createClearedGrid(from grid: [[Int]], at position: (row: Int, col: Int)) -> [[Int]] {
        var newGrid = grid
        newGrid[position.row][position.col] = 0
        return newGrid
    }
    
    // Apply a move to an empty cell
    private func applyEmptyMove(to grid: [[Int]], at position: (row: Int, col: Int)) {
        var newGrid = grid
        newGrid[position.row][position.col] = currentState.playerValue
        
        // Update state
        currentState = NumberFactoryState(
            goalValue: currentState.goalValue,
            isGoalReached: currentState.isGoalReached,
            isGameOver: currentState.isGameOver,
            avoidRule: currentState.avoidRule,
            playerValue: currentState.playerValue,
            playerPosition: position,
            grid: newGrid
        )
    }
    
    // Apply a merge move
    private func applyMergeMove(to grid: [[Int]], at position: (row: Int, col: Int), targetValue: Int) -> Bool {
        var newGrid = grid
        let newValue = currentState.playerValue + targetValue
        
        // Check if merge violates the avoid rule
        if currentState.avoidRule.checkViolation(newValue) {
            newGrid[position.row][position.col] = currentState.playerValue
            
            // Game over due to rule violation
            currentState = NumberFactoryState(
                goalValue: currentState.goalValue,
                isGoalReached: currentState.isGoalReached,
                isGameOver: true,
                avoidRule: currentState.avoidRule,
                playerValue: currentState.playerValue,
                playerPosition: position,
                grid: newGrid
            )
            
            return false
        }
        
        // Check if goal was reached
        newGrid[position.row][position.col] = newValue
        let goalReached = newValue >= currentState.goalValue
        let newGoalValue = goalReached ? newValue + Int.random(in: 5...15) : currentState.goalValue
        
        currentState = NumberFactoryState(
            goalValue: newGoalValue,
            isGoalReached: goalReached,
            isGameOver: currentState.isGameOver,
            avoidRule: currentState.avoidRule,
            playerValue: newValue,
            playerPosition: position,
            grid: newGrid
        )
        
        return true
    }
    
    // MARK: - Game Reset
    func startNewGame() {
        // reset to initial conditions wiht random rule
        currentState = NumberFactoryState.initialState(gridSize: gridSize)
        fillGridWithRandomNumbers()
    }
}
