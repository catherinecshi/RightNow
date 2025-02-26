//
//  RightNowTests.swift
//  RightNowTests
//
//  Created by Shi Catherine on 2/26/25.
//

import XCTest
@testable import RightNow

final class RightNowTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        // Any test you write for XCTest can be annotated as throws and async.
        // Mark your test throws to produce an unexpected failure when your test encounters an uncaught error.
        // Mark your test async to allow awaiting for asynchronous code to complete. Check the results with assertions afterwards.
    }
    
    func testStreakBreaking() {
        // some issues with thinking 3 days ago and today are the same day
        let calendar = Calendar.current
        let today = Date()
        let threeDaysAgo = calendar.date(byAdding: .day, value: -3, to: today)!
        
        print("today: \(today)")
        print("three days ago \(threeDaysAgo)")
        print("same day \(TimeFormatter.isSameDay(today, threeDaysAgo))")
        
        // createa a habit with a streak and a old lastupdatedate
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
            numberOfRepetitions: 1,
            dailyCompletion: [:],
            lastUpdateDate: threeDaysAgo // set 3 days prior
        )
        
        habit.updateStats() // this should break the streak
        
        print("After updateStats, streak is \(habit.streaks)")
        
        // streak should be broken
        XCTAssertEqual(habit.streaks, 0, "Streak should be broken after missing a day")
    }
    
    func testStreakMaintenance() {
        // Setup: Create a habit with today's date as lastUpdateDate
        var habit = Habit(
            id: UUID(),
            name: "Test Habit",
            description: "Test habit description",
            time: Date(),
            daysOfTheWeek: ["Mon": true, "Tue": true, "Wed": true, "Thu": true, "Fri": true],
            accountabilityMetric: .selfTracking,
            incentive: .none,
            notificationEnabled: true,
            totalDone: 10,
            totalFailed: 0,
            streaks: 5, // Starting with a streak of 5
            numberOfRepetitions: 1,
            dailyCompletion: [:],
            lastUpdateDate: Date() // Today
        )
        
        // Act: Update stats which should maintain the streak
        habit.updateStats()
        
        // Assert: Streak should remain at 5
        XCTAssertEqual(habit.streaks, 5, "Streak should be maintained when updated same day")
        }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        measure {
            // Put the code you want to measure the time of here.
        }
    }

}
