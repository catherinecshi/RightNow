import Foundation
import Combine

/// The core model class for the game that manages game state, game logic, and persistence.
///
/// ## Features
/// - Maintains the current game state
/// - Provides methods to modify the game state (numbers, coupons, upgrades)
/// - Handles saving and loading game state from local storage and Firestore
/// - Publishes events related to game state changes and errors
/// - Calculates upgrade costs and purchase eligibility
class CentralGameModel {
    static let shared = CentralGameModel()
    
    // data service reference
    private let dataService: GameDataServiceProtocol
    
    // current game state
    @Published private(set) var gameState: CentralGameState
    private var isNetworkAvailable = true
    private var isSyncing = false
    
    // Publishers
    let saveGameCompleted = PassthroughSubject<Void, Never>()
    let loadGameCompleted = PassthroughSubject<Void, Never>()
    let errorOccurred = PassthroughSubject<DataServiceError, Never>()
    
    init(dataService: GameDataServiceProtocol = DataService.shared) {
        self.dataService = dataService
        self.gameState = CentralGameState()
        
        Task {
            await loadGameState()
        }
    }
    
    // MARK: - Game State Modification
    
    /// Adds numbers to player's total
    /// - Parameter amount: amount of numbers to add
    ///
    /// save triggered afterwwards
    func addNumbers(_ amount: Double) {
        gameState.numbers += amount
        gameState.totalNumbersEarned += amount
        gameState.lastUpdateTime = Date()
        
        Task {
            await saveGameState()
        }
    }
    
    /// Adds coupons to player's total
    /// - Parameter amount: the amount of coupons to add
    ///
    /// save triggered afterwards
    func addCoupons(_ amount: Int) {
        gameState.coupons += amount
        gameState.totalCouponsEarned += amount
        gameState.lastUpdateTime = Date()
        
        Task {
            await saveGameState()
        }
    }
    
    /// uses a coupon from the player's total
    /// - Parameter amount: the amount of coupons to use
    func useCoupons(_ amount: Int) {
        gameState.coupons -= amount
        gameState.lastUpdateTime = Date()
        
        Task {
            await saveGameState()
        }
    }
    
    /// purchases upgrade if enough numbers
    /// - Parameter upgradeType: type of upgrade to purchase
    /// - Returns: true if purchase was successful
    ///
    /// calculates cost of upgrades, checks if player can afford it
    /// if so, deduct cost from player's numbers and icnrease upgarde count
    func purchaseUpgrade(_ upgradeType: UpgradeType) -> Bool {
        let cost = calculateUpgradeCost(upgradeType)
        
        if gameState.numbers >= cost {
            gameState.numbers -= cost
            
            let currentLevel = gameState.level(for: upgradeType)
            gameState.upgradeLevels[upgradeType.rawValue] = currentLevel + 1
            gameState.lastUpdateTime = Date()
            
            Task {
                await saveGameState()
            }
            return true
        }
        return false
    }
    
    // MARK: - Fetch Stored Variables
    
    /// returns all upgrade types and # upgrades
    ///
    /// Converts raw string keys in game state to strongly typed UpgradeType
    func getUpgrades() -> [UpgradeType: Int] {
        var typedUpgrades: [UpgradeType: Int] = [:]
        
        for (upgradeTypeRawValues, level) in gameState.upgradeLevels {
            // try to create upgradetype from raw value
            if let upgradeType = UpgradeType(rawValue: upgradeTypeRawValues) {
                typedUpgrades[upgradeType] = level
            }
        }
        
        return typedUpgrades
    }
    
    // MARK: - Helper Methods
    
    /// calculates cost of upgrade based on type and current levle
    /// - Parameter upgradeType: type of upgrade to calculate cost for
    /// - Returns: cost of upgarde
    func calculateUpgradeCost(_ upgradeType: UpgradeType) -> Double {
        let level = gameState.level(for: upgradeType)
        return upgradeType.baseCost * pow(1.15, Double(level))
    }
    
    /// Determines whether player can afford to purchase upgrade
    /// - Parameter upgradeType: type of upgrade to chekc
    /// - Returns: true if player can afford it
    func canPurchaseUpgrade(_ upgradeType: UpgradeType) -> Bool {
        return gameState.numbers >= calculateUpgradeCost(upgradeType)
    }
    
    // MARK: - Persistence
    
    /// Saves the current game state both locally and to Firestore
    ///
    /// This method attempts to save the game state to both local storage and Firestore.
    /// If the Firestore save fails, it will still attempt to save locally.
    func saveGameState() async {
        do {
            // first save locally
            try await dataService.saveGameStateLocally(gameState)
            
            // then try to save to firestore
            try await dataService.saveGameStateToFirestore(gameState)
            saveGameCompleted.send()
        } catch {
            handleError(error)
            
            // try to save locally even if firestore failed
            if let _ = error as? DataServiceError {
                do {
                    try await dataService.saveGameStateLocally(gameState)
                } catch {
                    handleError(error)
                }
            }
        }
    }
    
    /// Loads the game state from local storage and Firestore
    ///
    /// This method first attempts to load from local storage, then checks Firestore.
    /// If both sources have data, it uses the one with the most recent update time.
    /// It then syncs the most recent state to both storages.
    private func loadGameState() async {
        // first try to load local data
        do {
            if let localGameState = try await dataService.loadGameStateLocally() {
                gameState = localGameState
            } else {
                throw DataServiceError.invalidData(details: "local game state couldn't be loaded")
            }
            
            saveGameCompleted.send()
        } catch {
            handleError(error)
        }
        
        // then check firestore and see if it is up to date
        do {
            if let firebaseGameState = try await dataService.loadGameStateFromFirestore() {
                if firebaseGameState.lastUpdateTime > gameState.lastUpdateTime {
                    gameState = firebaseGameState
                    
                    // save the more recent state locally
                    try await dataService.saveGameStateLocally(gameState)
                } else if gameState.lastUpdateTime > firebaseGameState.lastUpdateTime {
                    // local state is newer - update Firestore
                    try await dataService.saveGameStateToFirestore(gameState)
                }
            } else {
                // no state in firestore - save the current state
                try await dataService.saveGameStateToFirestore(gameState)
            }
            
            loadGameCompleted.send()
        } catch {
            // check if the problem is because no local but yes firestore
            do {
                if let firebaseGameState = try await dataService.loadGameStateFromFirestore() {
                    gameState = firebaseGameState
                }
            } catch {
                handleError(error)
            }
            
            handleError(error)
        }
    }
    
    /// Clears all locally stored game data
    func clearLocalData() async {
        do {
            try await dataService.clearLocalGameState()
        } catch {
            print("Error clearing local storage: \(error)")
        }
    }
    
    // MARK: - Error Handling
    
    /// Handles errors that occur during data operations
    /// - Parameter error: The error that occurred
    ///
    /// This method converts any error into a `DataServiceError` and publishes it
    /// to the `errorOccurred` publisher.
    private func handleError(_ error: Error) {
        // Convert to DataServiceError if needed
        let dataError: DataServiceError
        
        if let error = error as? DataServiceError {
            dataError = error
        } else {
            dataError = .invalidData(details: error.localizedDescription)
        }
        
        // Publish the error
        errorOccurred.send(dataError)
    }
}
