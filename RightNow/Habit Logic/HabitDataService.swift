/// Handles habit data storage. Includes local storage via JSON files and cloud storage with Firestore
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
}

class HabitDataService: HabitDataServiceProtocol {
    static let shared = HabitDataService()
    
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
            collection: "habits",
            subcollection: "userHabits",
            subdocument: habit.id.uuidString
        )
    }

    func updateHabitInFirestore(_ habit: Habit) async throws {
        try await firebaseManager.updateDocument(
            data: habit,
            collection: "habits",
            subcollection: "userHabits",
            subdocument: habit.id.uuidString
        )
    }

    func loadHabitsFromFirestore() async throws -> [Habit] {
        return try await firebaseManager.getDocuments(
            collection: "habits",
            subcollection: "userHabits"
        )
    }

    func fetchHabitFromFirestore(habitID: String) async throws -> Habit? {
        return try await firebaseManager.getDocument(
            collection: "habits",
            subcollection: "userHabits",
            subdocument: habitID
        )
    }

    func deleteHabitFromFirestore(habitId: UUID) async throws {
        try await firebaseManager.deleteDocument(
            collection: "habits",
            subcollection: "userHabits",
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
}
