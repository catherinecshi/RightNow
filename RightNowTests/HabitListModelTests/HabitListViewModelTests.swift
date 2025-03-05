import XCTest
import Combine
import Firebase
@testable import RightNow

class HabitListViewModelTests: XCTestCase {
    var viewModel: HabitListViewModel!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        
        // initialise fireabse
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
            print("configuring firebase")
        }
        
        viewModel = HabitListViewModel()
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        cancellables = nil
        super.tearDown()
    }
    
    // MARK: - Tests for currentDay and swipe handling
        
    func testHandleSwipeChangesCurrentDay() {
        // Save initial date
        let initialDate = viewModel.currentDay
        
        // Simulate swipe left (forward in time)
        viewModel.handleSwipe(direction: .left)
        
        // Verify date increased by 1 day
        XCTAssertEqual(
            Calendar.current.dateComponents([.day], from: initialDate, to: viewModel.currentDay).day,
            1,
            "Swiping left should move forward by one day"
        )
        
        // Simulate swipe right (backward in time)
        viewModel.handleSwipe(direction: .right)
        
        // Verify we're back to the initial date
        XCTAssertEqual(
            Calendar.current.dateComponents([.day], from: initialDate, to: viewModel.currentDay).day,
            0,
            "Swiping right after left should return to initial day"
        )
    }
    
    func testIsHabitForToday() {
        // Create a habit specifically for today
        let todayWeekday = TimeFormatter.getTodayWeekday()
        var todayHabit = Habit(
            id: UUID(),
            name: "Test Habit",
            description: "Test habit description",
            time: Date(),
            daysOfTheWeek: ["Mon": true, "Tue": true, "Wed": true, "Thu": true, "Fri": true, "Sat": true, "Sun": true],
            accountabilityMetric: .selfTracking,
            incentive: .none,
            notificationEnabled: true,
            totalDone: 10,
            totalFailed: 0,
            streaks: 5,
            numberOfRepetitions: 2,
            dailyCompletion: [:],
            lastUpdateDate: Date()
        )
        todayHabit.daysOfTheWeek = [todayWeekday: true]
        
        // Create a habit for a different day
        let otherWeekdays = TimeFormatter.allDays.filter { $0 != todayWeekday }
        var otherDayHabit = Habit(
            id: UUID(),
            name: "Test Habit",
            description: "Test habit description",
            time: Date(),
            daysOfTheWeek: ["Mon": true, "Tue": true, "Wed": true, "Thu": true, "Fri": true, "Sat": true, "Sun": true],
            accountabilityMetric: .selfTracking,
            incentive: .none,
            notificationEnabled: true,
            totalDone: 10,
            totalFailed: 0,
            streaks: 5,
            numberOfRepetitions: 2,
            dailyCompletion: [:],
            lastUpdateDate: Date()
        )
        if let firstOtherDay = otherWeekdays.first {
            otherDayHabit.daysOfTheWeek = [firstOtherDay: true]
        }
        
        // Test the function
        XCTAssertTrue(viewModel.isHabitForToday(todayHabit), "Habit set for today should return true")
        XCTAssertFalse(viewModel.isHabitForToday(otherDayHabit), "Habit not set for today should return false")
    }
    
    // MARK: - Tests for habit filtering
        
    func testHabitsForCurrentDay() {
        // Setup test habits that we'll check for
        let repository = HabitRepository.shared
        let mondayHabit = Habit(name: "Monday Habit",
                                description: "",
                                time: Date(),
                                daysOfTheWeek: ["Mon": true, "Tue": false, "Wed": false, "Thu": false, "Fri": false, "Sat": false, "Sun": false],
                                accountabilityMetric: .selfTracking,
                                incentive: .none,
                                notificationEnabled: true)
        let tuesdayHabit = Habit(name: "Tuesday Habit",
                                description: "",
                                time: Date(),
                                daysOfTheWeek: ["Mon": false, "Tue": true, "Wed": false, "Thu": false, "Fri": false, "Sat": false, "Sun": false],
                                accountabilityMetric: .selfTracking,
                                incentive: .none,
                                notificationEnabled: true)
        let everydayHabit = Habit(name: "Everyday Habit",
                                  description: "",
                                  time: Date(),
                                  daysOfTheWeek: ["Mon": true, "Tue": true, "Wed": true, "Thu": true, "Fri": true, "Sat": true, "Sun": true],
                                  accountabilityMetric: .selfTracking,
                                  incentive: .none,
                                  notificationEnabled: true)
        
        // Add test habits to repository
        repository.addHabit(mondayHabit)
        repository.addHabit(tuesdayHabit)
        repository.addHabit(everydayHabit)
        
        // Get the current day of week (1 = Sunday, 2 = Monday, etc.)
        let calendar = Calendar.current
        let currentWeekday = calendar.component(.weekday, from: Date())
        
        // Calculate swipes needed to get to Monday (weekday 2)
        var swipesToMonday = 0
        var swipeDirection: UISwipeGestureRecognizer.Direction = .right
        
        if currentWeekday == 2 {
            // Already Monday, no swipes needed
            swipesToMonday = 0
        } else if currentWeekday == 1 {
            // It's Sunday, swipe left once to get to Monday
            swipesToMonday = 1
            swipeDirection = .left
        } else {
            // For any other day, swipe right to go backward to reach Monday
            swipesToMonday = currentWeekday - 2
            swipeDirection = .right
        }
        
        // Execute swipes to reach Monday
        for _ in 0..<swipesToMonday {
            viewModel.handleSwipe(direction: swipeDirection)
        }
        
        // Create expectation for day change
        let mondayExpectation = XCTestExpectation(description: "Should reach Monday")
        let tuesdayExpectation = XCTestExpectation(description: "Should reach Tuesday")
        
        // Wait briefly for UI to update after swipes
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Now we should be on Monday - verify the habits
            let filteredHabits = self.viewModel.habitsForCurrentDay
            XCTAssertTrue(filteredHabits.contains(where: { $0.name == "Monday Habit" }), "Monday habit should be visible")
            XCTAssertTrue(filteredHabits.contains(where: { $0.name == "Everyday Habit" }), "Everyday habit should be visible")
            XCTAssertFalse(filteredHabits.contains(where: { $0.name == "Tuesday Habit" }), "Tuesday habit should not be visible")
            
            // Swipe left to get to Tuesday
            self.viewModel.handleSwipe(direction: .left)
            
            // Wait briefly for UI to update again
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                // Now we should be on Tuesday - verify the habits
                let tuesdayHabits = self.viewModel.habitsForCurrentDay
                XCTAssertTrue(tuesdayHabits.contains(where: { $0.name == "Tuesday Habit" }), "Tuesday habit should be visible")
                XCTAssertTrue(tuesdayHabits.contains(where: { $0.name == "Everyday Habit" }), "Everyday habit should be visible")
                XCTAssertFalse(tuesdayHabits.contains(where: { $0.name == "Monday Habit" }), "Monday habit should not be visible")
                
                // Clean up - remove the test habits after test completes
                repository.deleteHabit(mondayHabit)
                repository.deleteHabit(tuesdayHabit)
                repository.deleteHabit(everydayHabit)
                
                tuesdayExpectation.fulfill()
            }
            
            mondayExpectation.fulfill()
        }
        
        // Wait for both checks to complete
        wait(for: [mondayExpectation, tuesdayExpectation], timeout: 2.0)
    }
    
    // MARK: - Tests for habit completion
        
    func testIsHabitCompletedForDay() {
        // Create a habit with completion data
        var habit = Habit(
            id: UUID(),
            name: "Test Habit",
            description: "Test habit description",
            time: Date(),
            daysOfTheWeek: ["Mon": true, "Tue": true, "Wed": true, "Thu": true, "Fri": true, "Sat": true, "Sun": true],
            accountabilityMetric: .selfTracking,
            incentive: .none,
            notificationEnabled: true,
            totalDone: 0,
            totalFailed: 0,
            streaks: 0,
            numberOfRepetitions: 2,
            dailyCompletion: [:],
            lastUpdateDate: Date()
        )
        
        // Set current day to today
        let todayString = TimeFormatter.dateToString(Date())
        
        // Test when not completed
        XCTAssertFalse(viewModel.isHabitCompletedForDay(habit), "New habit should not be completed")
        
        // Add one completion (still not fully completed)
        habit.dailyCompletion[todayString] = 1
        XCTAssertFalse(viewModel.isHabitCompletedForDay(habit), "Habit with 1/2 completions should not be considered completed")
        
        // Add second completion (now fully completed)
        habit.dailyCompletion[todayString] = 2
        XCTAssertTrue(viewModel.isHabitCompletedForDay(habit), "Habit with 2/2 completions should be considered completed")
    }
    
    func testIsHabitCompletedLogic() {
        // Testing can be done through a test habit without modifying repository
        var habit = Habit(
            id: UUID(),
            name: "Test Habit",
            description: "Test habit description",
            time: Date(),
            daysOfTheWeek: ["Mon": true, "Tue": true, "Wed": true, "Thu": true, "Fri": true, "Sat": true, "Sun": true],
            accountabilityMetric: .selfTracking,
            incentive: .none,
            notificationEnabled: true,
            totalDone: 0,
            totalFailed: 0,
            streaks: 0,
            numberOfRepetitions: 1,
            dailyCompletion: [:],
            lastUpdateDate: Date()
        )
        
        let completed = viewModel.isHabitCompletedForDay(habit)
        // Assert based on the test habit's completion status
        XCTAssertEqual(completed, false, "New habit should not be completed")
    }
    
    // MARK: - Tests for Observer Patterns
    
    func testObserverPatternTriggersUpdate() {
        // Create expectation
        let expectation = XCTestExpectation(description: "Observer callback should be triggered")
        
        // Add observer
        viewModel.addObserver { _ in
            expectation.fulfill()
        }
        
        // Trigger a change
        var habit = Habit(
            id: UUID(),
            name: "Test Habit",
            description: "Test habit description",
            time: Date(),
            daysOfTheWeek: ["Mon": true, "Tue": true, "Wed": true, "Thu": true, "Fri": true, "Sat": true, "Sun": true],
            accountabilityMetric: .selfTracking,
            incentive: .none,
            notificationEnabled: true,
            totalDone: 10,
            totalFailed: 0,
            streaks: 5,
            numberOfRepetitions: 2,
            dailyCompletion: [:],
            lastUpdateDate: Date()
        )
        let repository = HabitRepository.shared
        repository.addHabit(habit)
        
        // Wait for expectation
        wait(for: [expectation], timeout: 2.0)
    }
    
    func testHabitWillChangePublisher() {
        // Create expectation
        let expectation = XCTestExpectation(description: "habitWillChange should emit when habits change")
        
        // Subscribe to publisher
        viewModel.habitWillChange
            .sink {
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // Trigger a change
        var habit = Habit(
            id: UUID(),
            name: "Test Habit",
            description: "Test habit description",
            time: Date(),
            daysOfTheWeek: ["Mon": true, "Tue": true, "Wed": true, "Thu": true, "Fri": true, "Sat": true, "Sun": true],
            accountabilityMetric: .selfTracking,
            incentive: .none,
            notificationEnabled: true,
            totalDone: 10,
            totalFailed: 0,
            streaks: 5,
            numberOfRepetitions: 2,
            dailyCompletion: [:],
            lastUpdateDate: Date()
        )
        let repository = HabitRepository.shared
        repository.addHabit(habit)
        
        // Wait for expectation
        wait(for: [expectation], timeout: 2.0)
    }
    
    // MARK: - Helper Methods
        
    private func findNextWeekday(for weekday: Int) -> Date {
        let calendar = Calendar.current
        var components = DateComponents()
        components.weekday = weekday
        
        // Find next occurrence of this weekday
        return calendar.nextDate(
            after: Date(),
            matching: components,
            matchingPolicy: .nextTime
        ) ?? Date()
    }
}
