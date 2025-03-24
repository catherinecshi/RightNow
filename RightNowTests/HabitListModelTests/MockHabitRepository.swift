import XCTest
import Combine
@testable import RightNow

class MockHabitRepository: HabitRepositoryProtocol {
    func clearLocalData() async {
        print("hi")
    }
    
    var habits: [Habit] = []
    private let habitSubject = PassthroughSubject<HabitRepository.HabitChangeType, Never>()
    
    var habitPublisher: AnyPublisher<HabitRepository.HabitChangeType, Never> {
        habitSubject.eraseToAnyPublisher()
    }
    
    func addHabit(_ habit: Habit) {
        habits.append(habit)
        notifyChange(.habitCRUD)
    }
    
    func updateHabit(_ habit: Habit) {
        if let index = habits.firstIndex(where: { $0.id == habit.id }) {
            habits[index] = habit
        }
        notifyChange(.habitCRUD)
    }
    
    func getHabits() -> [Habit] {
        return habits
    }
    
    func fetchSingleHabit(habitID: String) async throws -> Habit? {
        return habits.first(where: { $0.id.uuidString == habitID })
    }
    
    func deleteHabit(_ habit: Habit) {
        habits.removeAll(where: { $0.id == habit.id })
        notifyChange(.habitCRUD)
    }
    
    func completeHabit(_ habit: inout Habit) {
        let currentDayString = TimeFormatter.dateToString(Date())
        let oldLevel = habit.currentLevel
        
        habit.streaks += 1
        habit.totalDone += 1
        habit.dailyCompletion[currentDayString, default: 0] += 1
        
        let newLevel = habit.currentLevel
        
        updateHabit(habit)
        
        if oldLevel != newLevel {
            notifyChange(.levelChanged(habitId: habit.id,
                                      oldLevel: oldLevel,
                                      newLevel: newLevel))
        }
        
        notifyChange(.streakChanged(habitId: habit.id, newStreak: habit.streaks))
    }
    
    // Additional methods to match the full protocol
    func locationBasedHabits() -> [Habit] {
        return habits.filter { $0.location != nil }
    }
    
    func changeLocationToSelfTrack(habits: [Habit]? = nil) {
        let habitsToModify = habits ?? locationBasedHabits()
        
        for var habit in habitsToModify {
            habit.accountabilityMetric = .selfTracking
            habit.location = nil
            
            updateHabit(habit)
        }
    }
    
    private func notifyChange(_ changeType: HabitRepository.HabitChangeType) {
        DispatchQueue.main.async {
            self.habitSubject.send(changeType)
        }
    }
}
