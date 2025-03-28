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
        //notifyObservers(of: .habitCRUD)
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
        
        return currentCompletions >= habit.numberOfRepetitions
    }
    
    // check if a specific habit should be shown for the day the screen is on
    func isHabitForToday(_ habit: Habit) -> Bool {
        let currentDayString = TimeFormatter.getTodayWeekday()
        return habit.daysOfTheWeek[currentDayString] == true
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
    
    /*
    func locationBasedHabits() -> [Habit] {
        return repository.locationBasedHabits()
    }
    
    func changeLocationToSelfTrack(habits: [Habit]? = nil) {
        repository.changeLocationToSelfTrack(habits: habits)
    }
     */
    
    // MARK: - Helper Methods
    
    /// Sorts habits based on time, chains, and name
    /// - Parameter habits: The habits to sort
    /// - Returns: Sorted array of habits
    private func sortHabits(_ habits: [Habit]) -> [Habit] {
        return habits.sorted { habit1, habit2 in
            // Check if habits are chained to other habits
            if let cue1 = habit1.cue, let matchingHabit1 = habits.first(where: { $0.name == cue1 }) {
                if habit2.name == matchingHabit1.name {
                    return false
                }
                
                if let time2 = habit2.time, let matchingTime = matchingHabit1.time {
                    return matchingTime < time2
                }
            }
            
            if let cue2 = habit2.cue, let matchingHabit2 = habits.first(where: { $0.name == cue2 }) {
                if habit1.name == matchingHabit2.name {
                    return true
                }
                
                if let time1 = habit1.time, let matchingTime = matchingHabit2.time {
                    return time1 < matchingTime
                }
            }
            
            // Both habits are chained
            if let cue1 = habit1.cue, let cue2 = habit2.cue {
                let ultimateTime1 = findUltimateTimeHabit(habit1, in: habits)
                let ultimateTime2 = findUltimateTimeHabit(habit2, in: habits)
                
                if let time1 = ultimateTime1, let time2 = ultimateTime2 {
                    return time1 < time2
                }
                
                if ultimateTime1 != nil {
                    return true
                }
                
                if ultimateTime2 != nil {
                    return false
                }
            }
            
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
    
    /// Finds the ultimate time-based habit in a chain
    /// - Parameters:
    ///   - habit: The habit to check
    ///   - habits: All available habits
    ///   - visited: Set of already visited habit names
    /// - Returns: Time of the root habit in the chain
    private func findUltimateTimeHabit(_ habit: Habit, in habits: [Habit], visited: Set<String> = []) -> Date? {
        if let time = habit.time {
            return time
        }
        
        guard let cue = habit.cue, !visited.contains(cue) else {
            return nil
        }
        
        guard let chainedHabit = habits.first(where: { $0.name == cue }) else {
            return nil
        }
        
        return findUltimateTimeHabit(chainedHabit, in: habits, visited: visited.union([cue]))
    }
}
