import Foundation
import Combine

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
    let errorOccurred = PassthroughSubject<Error, Never>()
    
    init(dataService: GameDataServiceProtocol = DataService.shared) {
        self.dataService = dataService
        self.gameState = CentralGameState()
        
        Task {
            await loadGameState()
        }
    }
    
    // MARK: - Game Actions
    func addNumbers(_ amount: Double) {
        gameState.numbers += amount
        gameState.totalNumbersEarned += amount
        gameState.lastUpdateTime = Date()
        
        Task {
            await saveGameState()
        }
    }
    
    func addCoupons(_ amount: Int) {
        gameState.coupons += amount
        gameState.totalCouponsEarned += amount
        gameState.lastUpdateTime = Date()
        print("coupons being added")
        
        Task {
            await saveGameState()
        }
    }
    
    func canPurchaseUpgrade(_ upgradeType: UpgradeType) -> Bool {
        return gameState.numbers >= calculateUpgradeCost(upgradeType)
    }
    
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
    
    // MARK: - Helper Methods
    
    func calculateUpgradeCost(_ upgradeType: UpgradeType) -> Double {
        let level = gameState.level(for: upgradeType)
        return upgradeType.baseCost * pow(1.15, Double(level))
    }
    
    // MARK: - Persistence
    
    func saveGameState() async {
        do {
            // first save locally
            try await dataService.saveGameStateLocally(gameState)
            
            // then try to save to firestore
            try await dataService.saveGameStateToFirestore(gameState)
        } catch {
            print("error saving game state: \(error.localizedDescription)")
        }
    }
    
    private func loadGameState() async {
        // first try to load local data
        do {
            if let localGameState = try await dataService.loadGameStateLocally() {
                gameState = localGameState
            } else {
                print("local game state inaccessible")
            }
            
            saveGameCompleted.send()
        } catch {
            print("problem getting local game state: \(error.localizedDescription)")
            errorOccurred.send(error)
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
            print("problem getting firestore game state - \(error.localizedDescription)")
            errorOccurred.send(error)
        }
    }
}
