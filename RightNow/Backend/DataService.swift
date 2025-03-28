/// Handles habit data storage
/// Includes local storage via JSON files and cloud storage with Firestore
import UIKit

enum LocalStorageError: Error {
    case noFileFound
}

protocol HabitDataServiceProtocol {
    func saveHabitsToFirestore(habits: [Habit]) async throws
    func updateHabitInFirestore(_ habit: Habit) async throws
    func loadHabitsFromFirestore() async throws -> [Habit]
    func fetchHabitFromFirestore(habitID: String) async throws -> Habit?
    func deleteHabitFromFirestore(habitId: UUID) async throws
    
    func saveHabitsLocally(_ habits: [Habit]) async throws
    func updateHabitLocally(_ habit: Habit) async throws
    func loadHabitsLocally() async throws -> [Habit]
    func fetchHabitLocally(habitID: String) async throws -> Habit?
    func deleteHabitLocally(habitID: UUID) async throws
    
    func clearLocalStorage() async throws
}

protocol GameDataServiceProtocol {
    func saveGameStateToFirestore(_ gameState: CentralGameState) async throws
    func loadGameStateFromFirestore() async throws -> CentralGameState?
    
    func saveGameStateLocally(_ gameState: CentralGameState) async throws
    func loadGameStateLocally() async throws -> CentralGameState?
}

class DataService: HabitDataServiceProtocol {
    static let shared = DataService()
    
    // MARK: - Firestore Operations
    // reference to the firebase manager
    var firebaseManager: FirebaseConfigurable
    
    init(firebaseManager: FirebaseConfigurable = FirebaseManager.shared) {
        self.firebaseManager = firebaseManager
    }
    
    private func getUserId() throws -> String {
        guard let userId = firebaseManager.currentUserId else {
            throw FirebaseError.userNotAuthenticated
        }
        
        return userId
    }
    
    func saveHabitsToFirestore(habits: [Habit]) async throws {
        for habit in habits {
            try await saveHabitToFirestore(habit)
        }
    }

    private func saveHabitToFirestore(_ habit: Habit, userId: String? = nil) async throws {
        try await firebaseManager.setDocument(
            data: habit,
            collection: "users",
            subcollection: "habits",
            subdocument: habit.id.uuidString
        )
    }

    func updateHabitInFirestore(_ habit: Habit) async throws {
        try await firebaseManager.updateDocument(
            data: habit,
            collection: "users",
            subcollection: "habits",
            subdocument: habit.id.uuidString
        )
    }

    func loadHabitsFromFirestore() async throws -> [Habit] {
        return try await firebaseManager.getDocuments(
            collection: "users",
            subcollection: "habits"
        )
    }

    func fetchHabitFromFirestore(habitID: String) async throws -> Habit? {
        return try await firebaseManager.getDocument(
            collection: "users",
            subcollection: "habits",
            subdocument: habitID
        )
    }

    func deleteHabitFromFirestore(habitId: UUID) async throws {
        try await firebaseManager.deleteDocument(
            collection: "users",
            subcollection: "habits",
            subdocument: habitId.uuidString
        )
    }
    // MARK: - Local Storage Operations
    private func getHabitsFileURL() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0].appendingPathComponent("habits.json")
    }
    
    func saveHabitsLocally(_ habits: [Habit]) async throws {
        let fileURL = getHabitsFileURL()
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(habits)
        try data.write(to: fileURL)
    }
    
    func updateHabitLocally(_ habit: Habit) async throws {
        var habits = try await loadHabitsLocally()
        
        if let index = habits.firstIndex(where: { $0.id == habit.id }) {
            habits[index] = habit
        } else {
            throw LocalStorageError.noFileFound
        }
        
        try await saveHabitsLocally(habits)
    }
    
    func loadHabitsLocally() async throws -> [Habit] {
        let fileURL = getHabitsFileURL()
        
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return []
        }
        
        let data = try Data(contentsOf: fileURL)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([Habit].self, from: data)
    }
    
    func fetchHabitLocally(habitID: String) async throws -> Habit? {
        let habits = try await loadHabitsLocally()
        return habits.first(where: { $0.id.uuidString == habitID })
    }
    
    func deleteHabitLocally(habitID: UUID) async throws {
        var habits = try await loadHabitsLocally()
        habits.removeAll(where: {$0.id == habitID })
        try await saveHabitsLocally(habits)
    }
    
    // MARK: - Careful!! Clear Local storage for when the user logs out
    func clearLocalStorage() async throws {
        // clear for current user
        let fileURL = getHabitsFileURL()
        
        if FileManager.default.fileExists(atPath: fileURL.path) {
            try FileManager.default.removeItem(at: fileURL)
        }
    }
}

extension DataService: GameDataServiceProtocol {
    // MARK: - Game State Firestore Operations
    func saveGameStateToFirestore(_ gameState: CentralGameState) async throws {
        try await firebaseManager.setDocument(
            data: gameState,
            collection: "users",
            subcollection: "gameData",
            subdocument: "centralGame"
        )
    }
    
    func loadGameStateFromFirestore() async throws -> CentralGameState? {
        return try await firebaseManager.getDocument(
            collection: "users",
            subcollection: "gameData",
            subdocument: "centralGame"
        )
    }
    
    // MARK: - Game State Local Operations
    private func getGameStateFileURL() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0].appendingPathComponent("central_game_state.json")
    }
    
    func saveGameStateLocally(_ gameState: CentralGameState) async throws {
        let fileURL = getGameStateFileURL()
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(gameState)
        try data.write(to: fileURL)
    }
    
    func loadGameStateLocally() async throws -> CentralGameState? {
        let fileURL = getGameStateFileURL()
        
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return nil // Return nil instead of empty array since we're dealing with a single object
        }
        
        let data = try Data(contentsOf: fileURL)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(CentralGameState.self, from: data)
    }
    
    // MARK: - Clear game state
    func clearGameStateLocally() async throws {
        let fileURL = getGameStateFileURL()
        
        if FileManager.default.fileExists(atPath: fileURL.path) {
            try FileManager.default.removeItem(at: fileURL)
        }
    }
}
