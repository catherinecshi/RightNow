/// # DataService
/// Provides data persistence for the app with dual storage capabilities:
/// - Firestore cloud storage for syncing across devices
/// - Local JSON file storage for offline functionality
///
/// The service handles two main data types:
/// - User habits (creation, updating, reading, deletion)
/// - Game state (saving and loading)

import UIKit

/// Error Types for data service operations
enum DataServiceError: Error, LocalizedError {
    // General errors
    case networkUnavailable
    case authenticationRequired
    
    // Firestore errors
    case firestoreWriteFailure(underlying: Error?)
    case firestoreReadFailure(underlying: Error?)
    case firestoreDeleteFailure(underlying: Error?)
    
    // Local storage errors
    case fileNotFound(fileName: String)
    case fileReadError(fileName: String, underlying: Error?)
    case fileWriteError(fileName: String, underlying: Error?)
    case encodingError(underlying: Error?)
    case decodingError(underlying: Error?)
    
    // Data errors
    case habitNotFound(id: String)
    case invalidData(details: String)
    
    // Sync errors
    case syncConflict(details: String)
    
    /// User-friendly error descriptions
    var errorDescription: String? {
        switch self {
        case .networkUnavailable:
            return "Network connection unavailable. Please check your internet connection and try again."
        case .authenticationRequired:
            return "You need to be signed in to perform this action."
        case .firestoreWriteFailure:
            return "Failed to save data to cloud storage."
        case .firestoreReadFailure:
            return "Failed to read data from cloud storage."
        case .firestoreDeleteFailure:
            return "Failed to delete data from cloud storage."
        case .fileNotFound(let fileName):
            return "Could not find local file: \(fileName)."
        case .fileReadError(let fileName, _):
            return "Failed to read local file: \(fileName)."
        case .fileWriteError(let fileName, _):
            return "Failed to save data to local file: \(fileName)."
        case .encodingError:
            return "Failed to process data for saving."
        case .decodingError:
            return "Failed to read saved data. The file might be corrupted."
        case .habitNotFound(let id):
            return "Habit with ID \(id) was not found."
        case .invalidData(let details):
            return "Invalid data: \(details)"
        case .syncConflict(let details):
            return "Data conflict during synchronization: \(details)"
        }
    }
    
    /// Technical details for debugging
    var recoverySuggestion: String? {
        switch self {
        case .networkUnavailable:
            return "Check device connectivity or try again later."
        case .authenticationRequired:
            return "Sign in to continue."
        case .firestoreWriteFailure(let error):
            return error?.localizedDescription ?? "Unknown Firestore write error."
        case .firestoreReadFailure(let error):
            return error?.localizedDescription ?? "Unknown Firestore read error."
        case .firestoreDeleteFailure(let error):
            return error?.localizedDescription ?? "Unknown Firestore delete error."
        case .fileNotFound:
            return "The file may have been deleted or not yet created."
        case .fileReadError(_, let error):
            return error?.localizedDescription ?? "Unknown file read error."
        case .fileWriteError(_, let error):
            return error?.localizedDescription ?? "Unknown file write error."
        case .encodingError(let error):
            return error?.localizedDescription ?? "Unknown encoding error."
        case .decodingError(let error):
            return error?.localizedDescription ?? "Unknown decoding error."
        case .habitNotFound:
            return "The habit may have been deleted."
        case .invalidData:
            return "Please check the data format and try again."
        case .syncConflict:
            return "A conflict occurred during synchronization. The most recent version was kept."
        }
    }
}

/// Protocol defining operations for habit data persistence
/// Allows for testing
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
    
    func clearLocalHabitData() async throws
}

/// Protocol defining operations for game data persistence
/// Allows for testing
protocol GameDataServiceProtocol {
    func saveGameStateToFirestore(_ gameState: CentralGameState) async throws
    func loadGameStateFromFirestore() async throws -> CentralGameState?
    
    func saveGameStateLocally(_ gameState: CentralGameState) async throws
    func loadGameStateLocally() async throws -> CentralGameState?
    
    func clearLocalGameState() async throws
}

// MARK: - Habit Data Persistence

/// Data persistence for habits & game data via Firestore & local JSON files
class DataService: HabitDataServiceProtocol {
    static let shared = DataService()
    
    // MARK: - Firestore Operations
    // reference to the firebase manager
    var firebaseManager: FirebaseConfigurable
    
    /// Initializes DataService with Firebase manager
    init(firebaseManager: FirebaseConfigurable = FirebaseManager.shared) {
        self.firebaseManager = firebaseManager
    }
    
    /// Gets current user ID from firebase
    /// - Returns: User ID String
    /// - Throws: FirebaseError.userNotAuthenticated
    private func getUserId() throws -> String {
        guard let userId = firebaseManager.currentUserId else {
            throw DataServiceError.authenticationRequired
        }
        
        return userId
    }
    
    /// Saves multiple habits to Firestore
    /// - Parameter habits: Array of habits to save
    /// - Throws: FirebaseError if saving any habits fail
    func saveHabitsToFirestore(habits: [Habit]) async throws {
        for habit in habits {
            try await saveHabitToFirestore(habit)
        }
    }

    /// Saves a single habit to Firestore
    /// - Parameters:
    ///     - habit: The habit to save
    ///     - userId: Optional user Id (defaults to current user)
    /// - Throws: FirebaseError if saving fails
    private func saveHabitToFirestore(_ habit: Habit, userId: String? = nil) async throws {
        try await firebaseManager.setDocument(
            data: habit,
            collection: "users",
            subcollection: "habits",
            subdocument: habit.id.uuidString
        )
    }
    
    /// Updates a single habit in Firestore
    /// - Parameter habit: The habit to update
    /// - Throws: FirebaseError if updating fails
    func updateHabitInFirestore(_ habit: Habit) async throws {
        try await firebaseManager.updateDocument(
            data: habit,
            collection: "users",
            subcollection: "habits",
            subdocument: habit.id.uuidString
        )
    }
    
    /// Loads all habits from Firestore for the current user
    /// - Returns: Array of habits
    /// - Throws: FirebaseError if loading fails
    func loadHabitsFromFirestore() async throws -> [Habit] {
        return try await firebaseManager.getDocuments(
            collection: "users",
            subcollection: "habits"
        )
    }
    
    /// Fetches a single habit from Firestore by ID
    /// - Parameter habitID: String UUID of habit to fetch
    /// - Returns: The habit if found (defaults to nil)
    /// - Throws: FirebaseError if fetching fails
    func fetchHabitFromFirestore(habitID: String) async throws -> Habit? {
        return try await firebaseManager.getDocument(
            collection: "users",
            subcollection: "habits",
            subdocument: habitID
        )
    }
    
    /// Deletes a habit from Firestore
    /// - Parameter habitId: UUID of habit to delete
    /// - Throws: FirebaseError if deletion fails
    func deleteHabitFromFirestore(habitId: UUID) async throws {
        try await firebaseManager.deleteDocument(
            collection: "users",
            subcollection: "habits",
            subdocument: habitId.uuidString
        )
    }
    
    // MARK: - Local Storage Operations
    
    /// Returns file URL for habits JSON file
    private func getHabitsFileURL() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0].appendingPathComponent("habits.json")
    }
    
    /// Saves multiple habits to local storage
    /// - Parameter habits: Array of habits to save
    /// - Throws: Error if encoding or writing to file fails
    func saveHabitsLocally(_ habits: [Habit]) async throws {
        let fileURL = getHabitsFileURL()
        let fileName = fileURL.lastPathComponent
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        do {
            let data = try encoder.encode(habits)
            try data.write(to: fileURL)
        } catch let encodingError as EncodingError {
            throw DataServiceError.encodingError(underlying: encodingError)
        } catch {
            throw DataServiceError.fileWriteError(fileName: fileName, underlying: error)
        }
    }
    
    /// Updates a single habit in local storage
    /// - Parameter habit: The habit to update
    /// - Throws: LocalStorageError.noFileFound if habit not found, or encoding/writing errors
    func updateHabitLocally(_ habit: Habit) async throws {
        do {
            var habits = try await loadHabitsLocally()
            
            if let index = habits.firstIndex(where: { $0.id == habit.id }) {
                habits[index] = habit
            } else {
                throw DataServiceError.habitNotFound(id: habit.id.uuidString)
            }
            
            try await saveHabitsLocally(habits)
        } catch {
            // only rewrap if not already a dataservice error
            if error is DataServiceError {
                throw error
            } else {
                throw DataServiceError.fileWriteError(fileName: getHabitsFileURL().lastPathComponent, underlying: error)
            }
        }
    }
    
    /// Loads all habits from local storage
    /// - Returns: Array of habits (empty if no file exists)
    /// - Throws: Error if reading or decoding file fails
    func loadHabitsLocally() async throws -> [Habit] {
        let fileURL = getHabitsFileURL()
        let fileName = fileURL.lastPathComponent
        
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return []
        }
        
        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode([Habit].self, from: data)
        } catch let decodingError as DecodingError {
            throw DataServiceError.decodingError(underlying: decodingError)
        } catch {
            throw DataServiceError.fileReadError(fileName: fileName, underlying: error)
        }
    }
    
    /// Fetches a single habit from local storage by ID
    /// - Parameter habitID: String UUID of the habit to fetch
    /// - Returns: The habit if found, nil otherwise
    /// - Throws: Error if reading or decoding file fails
    func fetchHabitLocally(habitID: String) async throws -> Habit? {
        do {
            let habits = try await loadHabitsLocally()
            return habits.first(where: { $0.id.uuidString == habitID })
        } catch {
            throw error
        }
    }
    
    /// Deletes a habit from local storage
    /// - Parameter habitID: UUID of the habit to delete
    /// - Throws: Error if reading, modifying, or writing file fails
    func deleteHabitLocally(habitID: UUID) async throws {
        do {
            var habits = try await loadHabitsLocally()
            habits.removeAll(where: {$0.id == habitID })
            try await saveHabitsLocally(habits)
        } catch {
            throw error
        }
    }
    
    // MARK: - Storage Management
    
    /// Clears all locally stored habits for current user
    /// Typically used with logging out from anonymous account
    /// - Throws: Error if file deletion fails
    /// - Warning: This permanently deletes all local habit data
    func clearLocalHabitData() async throws {
        // clear for current user
        let fileURL = getHabitsFileURL()
        
        if FileManager.default.fileExists(atPath: fileURL.path) {
            try FileManager.default.removeItem(at: fileURL)
        }
    }
}

// MARK: - Game State Persistence

/// Implements game state persistence operations
extension DataService: GameDataServiceProtocol {
    
    // MARK: - Firestore Operations
    
    /// Saves game state to Firestore
    /// - Parameter gameState: The game state to save
    /// - Throws: FirebaseError if saving fails
    func saveGameStateToFirestore(_ gameState: CentralGameState) async throws {
        try await firebaseManager.setDocument(
            data: gameState,
            collection: "users",
            subcollection: "gameData",
            subdocument: "centralGame"
        )
    }
    
    /// Loads game state from Firestore
    /// - Returns: The game state if found, nil otherwise
    /// - Throws: FirebaseError if loading fails
    func loadGameStateFromFirestore() async throws -> CentralGameState? {
        return try await firebaseManager.getDocument(
            collection: "users",
            subcollection: "gameData",
            subdocument: "centralGame"
        )
    }
    
    // MARK: - Local Operations
    
    /// Returns file URL for game state JSON file
    private func getGameStateFileURL() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0].appendingPathComponent("central_game_state.json")
    }
    
    /// Saves game state to local storage
    /// - Parameter gameState: The game state to save
    /// - Throws: Error if encoding or writing to file fails
    func saveGameStateLocally(_ gameState: CentralGameState) async throws {
        let fileURL = getGameStateFileURL()
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(gameState)
        try data.write(to: fileURL)
    }
    
    /// Loads game state from local storage
    /// - Returns: The game state if found, nil otherwise
    /// - Throws: Error if reading or decoding file fails
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
    
    // MARK: - Storage Management
    
    /// Clears locally stored game state
    /// Typically used when anonymous user logs out
    /// - Throws: Error if file deletion fails
    /// - Warning: This permanently deletes local game state data
    func clearLocalGameState() async throws {
        let fileURL = getGameStateFileURL()
        
        if FileManager.default.fileExists(atPath: fileURL.path) {
            try FileManager.default.removeItem(at: fileURL)
        }
    }
}
