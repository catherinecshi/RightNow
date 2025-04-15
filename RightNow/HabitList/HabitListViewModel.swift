import UIKit
import Combine

/// A view model that manages habit data and UI state for a habit list view.
///
/// This class serves as the intermediary between the UI and the data layer,
/// providing filtered habits for the current day and handling user interactions.
class HabitListViewModel {
    // MARK: - Properties
    private let repository: HabitRepositoryProtocol
    
    private(set) var currentDay: Date = Date() // current displayed date
    
    // MARK: - Initialisation
    
    init(repository: HabitRepositoryProtocol = HabitRepository.shared) {
        self.repository = repository
        setupObservers()
    }
    
    /// Observers that are notified when habit is changed
    private var observers: [((HabitRepository.HabitChangeType) -> Void)] = []
    let habitWillChange = PassthroughSubject<Void, Never>() // publisher of habits changed for UI updates
    private var cancellables = Set<AnyCancellable>()
    
    /// Publisher that emits events when habits change in repository
    /// Subscribers do CRUD with this
    var habitChangePublisher: AnyPublisher<HabitRepository.HabitChangeType, Never> {
        repository.habitPublisher
    }
    
    /// Sets up combine subscribers to react to changes in habits - UI updates
    private func setupObservers() {
        repository.habitPublisher
            .sink { [weak self] _ in
                // trigger view updates when data changes
                self?.habitWillChange.send()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - UI Models
    
    /// Handles swipe gesture to navigate between days
    /// - Parameter direction: direction of swipe gesture
    ///     - left for next day
    ///     - right for previous day
    @objc func handleSwipe(direction: UISwipeGestureRecognizer.Direction) {
        let dayInterval: TimeInterval = 24 * 60 * 60
        
        if direction == .left {
            currentDay = currentDay.addingTimeInterval(dayInterval)
        } else if direction == .right {
            currentDay = currentDay.addingTimeInterval(-dayInterval)
        }
        
        habitWillChange.send()
    }
    
    /// Returns habits scheduled for currently displayed day (by days of week)
    var habitsForCurrentDay: [Habit] {
        let currentDayString = TimeFormatter.weekdayToString(currentDay)
        let filteredHabits = repository.habits.filter { $0.daysOfTheWeek[currentDayString] == true }
        
        return sortHabits(filteredHabits)
    }
    
    /// Returns true if habit has been completed for currently displayed day
    /// - Parameter habit: the habit to check for completion
    func isHabitCompletedForDay(_ habit: Habit) -> Bool {
        let currentDayString = TimeFormatter.dateToString(currentDay)
        let currentCompletions = habit.dailyCompletion[currentDayString, default: 0]
        
        return currentCompletions > 0
    }
    
    /// Returns true if habit is scheduled for today (in time and calendar, not display)
    /// - Parameter habit: the habit to check
    func isHabitForToday(_ habit: Habit) -> Bool {
        let currentDayString = TimeFormatter.getTodayWeekday()
        return habit.daysOfTheWeek[currentDayString] == true
    }
    
    /// Returns true if currently displayed day is today
    func isCurrentDayToday() -> Bool {
        let calendar = Calendar.current
        return calendar.isDate(currentDay, inSameDayAs: Date())
    }
    
    // MARK: - Habit Operations (Delegates to Repository)
    
    /// Adds parameter habit to repository
    func addHabit(_ habit: Habit) {
        repository.addHabit(habit)
    }
    
    /// Updates parameter habit with repository
    func updateHabit(_ habit: Habit) async {
        await repository.updateHabit(habit)
    }
    
    /// Returns all habits from repository
    func getHabits() -> [Habit] {
        return repository.habits
    }
    
    /// Fetches a specific habit by its ID
    /// - Parameter habitId: habit id
    /// - Returns: habit if found, nil otherwise
    /// - Throws: any errors that occur during operation
    func fetchHabit(_ habitId: String) async throws -> Habit? {
        return try await repository.fetchSingleHabit(habitID: habitId)
    }
    
    /// Deletes parameter habit from repository
    func deleteHabit(_ habit: Habit) async {
        await repository.deleteHabit(habit)
    }
    
    /// Marks parameter habit as complete for the day
    func habitCompleted(_ habit: inout Habit) async {
        await repository.completeHabit(&habit)
    }
    
    func reloadData() {
        repository.checkFirebaseReadiness()
    }
    
    // MARK: - Helper Methods
    
    /// Sorts habits based on time, chains, and name
    /// - Parameter habits: The habits to sort
    /// - Returns: Sorted array of habits
    private func sortHabits(_ habits: [Habit]) -> [Habit] {
        return habits.sorted { habit1, habit2 in
            // Sort by time if available
            if let time1 = habit1.time, let time2 = habit2.time {
                return time1 < time2
            }
            
            if habit1.time != nil && habit2.time == nil {
                return true
            }
            
            if habit1.time == nil && habit2.time != nil {
                return false
            }
            
            // Default to alphabetical order
            return habit1.name < habit2.name
        }
    }
}
