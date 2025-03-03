/// Handles habit data storage. Includes local storage via JSON files and cloud storage with Firestore
import UIKit
import FirebaseAuth
import FirebaseFirestore

enum HabitServiceError: Error {
    case userNotLoggedIn
    case networkUnavailable
    case saveFailed
    case loadFailed
}

class HabitDataService {
    static let shared = HabitDataService()
    private let db = Firestore.firestore()
    
    // MARK: - Firestore Operations
    func saveHabitsToFirestore(habits: [Habit]) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw HabitServiceError.userNotLoggedIn
        }
        
        for habit in habits {
            let habitData = try JSONEncoder().encode(habit)
            var habitDict = try JSONSerialization.jsonObject(with: habitData, options: []) as! [String: Any]
            
            // nil is invisible when inputting into firestore -> turn into null instead
            if habit.location == nil {
                habitDict["location"] = NSNull()
            }
            
            try await db.collection("habits")
                .document(userId)
                .collection("userHabits")
                .document(habit.id.uuidString)
                .setData(habitDict)
        }
    }
    
    func updateHabitInFirestore(_ habit: Habit) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw HabitServiceError.userNotLoggedIn
        }
        
        let habitData = try JSONEncoder().encode(habit)
        var habitDict = try JSONSerialization.jsonObject(with: habitData, options: []) as! [String: Any]
        
        if habit.location == nil {
            habitDict["location"] = NSNull()
        }
        
        try await db.collection("habits")
            .document(userId)
            .collection("userHabits")
            .document(habit.id.uuidString)
            .updateData(habitDict)
    }
    
    // loads all habits
    func loadHabitsFromFirestore() async throws -> [Habit] {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw HabitServiceError.userNotLoggedIn
        }
        
        let snapshot = try await db.collection("habits")
            .document(userId)
            .collection("userHabits")
            .getDocuments()
        
        var habits: [Habit] = []
        
        for document in snapshot.documents {
            let jsonData = try JSONSerialization.data(withJSONObject: document.data(), options: [])
            let habit = try JSONDecoder().decode(Habit.self, from: jsonData)
            habits.append(habit)
        }
        
        return habits
    }
    
    // load one habit
    func fetchHabitFromFirestore(habitID: String, maxRetries: Int = 3) async throws -> Habit? {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw HabitServiceError.userNotLoggedIn
        }
        
        var currentRetry = 0
        var lastError: Error? = nil
        
        while currentRetry <= maxRetries {
            do {
                let document = try await db.collection("habits")
                    .document(userId)
                    .collection("userHabits")
                    .document(habitID)
                    .getDocument()
                
                if document.exists, let data = document.data() {
                    let jsonData = try JSONSerialization.data(withJSONObject: data, options: [])
                    let habit = try JSONDecoder().decode(Habit.self, from: jsonData)
                    return habit
                } else {
                    return nil
                }
            } catch {
                lastError = error
                currentRetry += 1
                
                if currentRetry <= maxRetries {
                    // exponential backoff delay
                    let delay = TimeInterval(pow(2.0, Double(currentRetry)))
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
            }
        }
        
        if let error = lastError {
            throw error
        }
        
        return nil
    }
    
    func deleteHabitFromFirestore(habitId: UUID) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw HabitServiceError.userNotLoggedIn
        }
        
        try await db.collection("habits")
            .document(userId)
            .collection("userHabits")
            .document(habitId.uuidString)
            .delete()
    }
    
    // MARK: - Local Storage Operations
    private func getHabitsFileURL() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0].appendingPathComponent("habits.json")
    }
    
    func saveHabitsLocally(_ habits: [Habit]) throws {
        let fileURL = getHabitsFileURL()
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(habits)
        try data.write(to: fileURL)
    }
    
    func loadHabitsLocally() -> [Habit]? {
        let fileURL = getHabitsFileURL()
        
        do {
            if FileManager.default.fileExists(atPath: fileURL.path) {
                let data = try Data(contentsOf: fileURL)
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let localHabits = try decoder.decode([Habit].self, from: data)
                return localHabits
            }
        } catch {
            print("Error laoding habits locally: \(error)")
        }
        
        return nil
    }
}
