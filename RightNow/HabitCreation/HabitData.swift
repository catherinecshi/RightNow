import Foundation

/// Habit Data Storage Utilitythat is being added to when the user creates a habit
struct HabitData {
    var name: String?
    var hour: Int?
    var minute: Int?
    var selectedDays: [String: Bool]?
}
