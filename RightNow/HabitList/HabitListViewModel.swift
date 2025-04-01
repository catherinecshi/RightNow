import UIKit
import Combine

class HabitListViewModel {
    // MARK: - Properties
    private let repository: HabitRepositoryProtocol
    
    private(set) var currentDay: Date = Date() // current displayed date
    
    // MARK: - Initialisation
    
    init(repository: HabitRepositoryProtocol = HabitRepository.shared) {
        self.repository = repository
        setupObservers()
    }
    
    // publisher for habit changes
    var habitChangePublisher: AnyPublisher<HabitRepository.HabitChangeType, Never> {
        repository.habitPublisher
    }
    
    private var observers: [((HabitRepository.HabitChangeType) -> Void)] = []
    let habitWillChange = PassthroughSubject<Void, Never>()
    private var cancellables = Set<AnyCancellable>()
    
    private func setupObservers() {
        repository.habitPublisher
            .sink { [weak self] _ in
                // trigger view updates when data changes
                self?.habitWillChange.send()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - UI Methods
    
    @objc func handleSwipe(direction: UISwipeGestureRecognizer.Direction) {
        let dayInterval: TimeInterval = 24 * 60 * 60
        
        if direction == .left {
            currentDay = currentDay.addingTimeInterval(dayInterval)
        } else if direction == .right {
            currentDay = currentDay.addingTimeInterval(-dayInterval)
        }
        
        habitWillChange.send()
    }
    
    // filter habits for the current day
    var habitsForCurrentDay: [Habit] {
        let currentDayString = TimeFormatter.weekdayToString(currentDay)
        let filteredHabits = repository.habits.filter { $0.daysOfTheWeek[currentDayString] == true }
        
        return sortHabits(filteredHabits)
    }
    
    // check if habit is completed for the current day the screen is on
    func isHabitCompletedForDay(_ habit: Habit) -> Bool {
        let currentDayString = TimeFormatter.dateToString(currentDay)
        let currentCompletions = habit.dailyCompletion[currentDayString, default: 0]
        
        return currentCompletions > 0
    }
    
    // check if a specific habit should be shown for the day the screen is on
    func isHabitForToday(_ habit: Habit) -> Bool {
        let currentDayString = TimeFormatter.getTodayWeekday()
        return habit.daysOfTheWeek[currentDayString] == true
    }
    
    func isCurrentDayToday() -> Bool {
        let calendar = Calendar.current
        return calendar.isDate(currentDay, inSameDayAs: Date())
    }
    
    // MARK: - Habit Operations (Delegates to Repository)
    func addHabit(_ habit: Habit) {
        repository.addHabit(habit)
    }
    
    func updateHabit(_ habit: Habit) async {
        await repository.updateHabit(habit)
    }
    
    func getHabits() -> [Habit] {
        return repository.habits
    }
    
    func fetchHabit(_ habitId: String) async throws -> Habit? {
        return try await repository.fetchSingleHabit(habitID: habitId)
    }
    
    func deleteHabit(_ habit: Habit) async {
        await repository.deleteHabit(habit)
    }
    
    func habitCompleted(_ habit: inout Habit) async {
        await repository.completeHabit(&habit)
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
