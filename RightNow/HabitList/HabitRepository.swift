/// Manages habit collection and synchronization. Handles network connectivity with Firebase

import UIKit
import Network
import Combine

protocol HabitRepositoryProtocol {
    var habits: [Habit] { get }
    var habitPublisher: AnyPublisher<HabitRepository.HabitChangeType, Never> { get }
    
    func addHabit(_ habit: Habit)
    func updateHabit(_ habit: Habit) async
    func getHabits() -> [Habit]
    func fetchSingleHabit(habitID: String) async throws -> Habit?
    func deleteHabit(_ habit: Habit) async
    func completeHabit(_ habit: inout Habit) async
    
    func clearLocalData() async
}

/// Handles synchronization, network monitoring, and publishing of habit changes
class HabitRepository: HabitRepositoryProtocol {
    static let shared = HabitRepository()
    
    // MARK: - Properties
    private let dataService: HabitDataServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    private(set) var habits: [Habit] = []
    private var isNetworkAvailable = true
    private var monitor: NWPathMonitor? // observes connectivity changes
    private var needsSync = false
    
    /// Subject and publisher for publishing habit changes
    private let habitSubject = PassthroughSubject<HabitChangeType, Never>()
    var habitPublisher: AnyPublisher<HabitChangeType, Never> {
        habitSubject.eraseToAnyPublisher()
    }
    
    /// Subject and publisher for publishing errors
    private let errorSubject = PassthroughSubject<DataServiceError, Never>()
    var errorPublisher: AnyPublisher<DataServiceError, Never> {
        errorSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Initialization
    
    /// Initiates with reference to dataservice, habits, and network monitoring
    private init(dataService: HabitDataServiceProtocol = DataService.shared) {
        self.dataService = dataService
        
        Task {
            await loadInitialHabits()
        }
        setupNetworkMonitoring()
    }
    
    /// Clean up resources when instance is deallocated
    deinit {
        monitor?.cancel()
    }
    
    /// Loads local habits and tries to synchronize with firebase
    private func loadInitialHabits() async {
        // load from local storage
        do {
            let localHabits = try await dataService.loadHabitsLocally()
            habits = localHabits
        } catch {
            print("Error loading habits locally: \(error)")
        }
        
        // then try to load from firestore
        await syncWithFirestore()
        
        notifyChange(.habitCRUD)
    }
    
    // MARK: - Network Monitoring
    
    /// Sets up network monitoring
    /// Triggers synchronization after connectivity is restored after being unavailable
    private func setupNetworkMonitoring() {
        let monitor = NWPathMonitor()
        self.monitor = monitor
        monitor.pathUpdateHandler = { [weak self] path in
            let isConnected = path.status == .satisfied
            
            guard let self = self else { return }
            
            Task { @MainActor in
                let wasDisconnected = !(self.isNetworkAvailable)
                self.isNetworkAvailable = isConnected
                
                if isConnected && wasDisconnected {
                    Task {
                        await self.syncWithFirestore()
                    }
                }
            }
        }
        
        let queue = DispatchQueue(label: "HabitRepositoryNetworkMonitor")
        monitor.start(queue: queue)
    }
    
    /// Synchronizes local data with Firestore
    ///
    /// This method:
    /// 1. Fetches habits from Firestore
    /// 2. Merges them with local habits, keeping the most recently updated version
    /// 3. Updates streaks and other time-dependent data
    /// 4. Saves the merged data locally
    /// 5. Updates notifications
    private func syncWithFirestore() async {
        guard isNetworkAvailable else { return }
        
        do {
            // load from firestore
            let firestoreHabits = try await dataService.loadHabitsFromFirestore()
            
            // dict for quick loookup
            let existingHabits = Dictionary(uniqueKeysWithValues: habits.map { ($0.id.uuidString, $0 )})
            var updatedHabits: [Habit] = []
            
            // merge with local - keep most recent
            for var habit in firestoreHabits {
                if let existingHabits = existingHabits[habit.id.uuidString] {
                    if existingHabits.lastUpdateDate >= habit.lastUpdateDate {
                        // local version is more or equally recent
                        habit = existingHabits
                    }
                }
                
                habit.updateStats() // check if streak was broken
                updatedHabits.append(habit)
            }
            
            // update repos and local storage
            let finalUpdatedHabits = updatedHabits
            
            self.habits = finalUpdatedHabits
            try? await self.dataService.saveHabitsLocally(finalUpdatedHabits)
            self.notifyChange(.habitCRUD)
            
            // update notification and geofences
            await PushNotificationDelegate.shared.auditNotifications()
        } catch {
            print("Error syncing with Firestore: \(error)")
        }
    }
    
    // MARK: - CRUD Operations
    
    /// Adds a new habit to the repository
    /// - Parameter habit: The habit to add
    ///
    /// This method:
    /// 1. Adds the habit to the local collection
    /// 2. Saves the habit to local storage and Firestore
    /// 3. Schedules notifications for the habit
    /// 4. Notifies subscribers of the change
    func addHabit(_ habit: Habit) {
        habits.append(habit)
        
        // save to firestore
        Task {
            await performOperation {
                try await dataService.saveHabitsLocally(habits)
                try await dataService.saveHabitsToFirestore(habits: [habit])
            }
        }
        
        // add notificaitons
        PushNotificationDelegate.shared.scheduleNotificationsForHabit(habit)
        
        notifyChange(.habitCRUD)
    }
    
    /// Updates an existing habit with new data
    /// - Parameter habit: The habit with updated information
    ///
    /// This method:
    /// 1. Updates the habit in the local collection
    /// 2. Saves changes to local storage and Firestore
    /// 3. Detects and notifies about level and streak changes
    func updateHabit(_ habit: Habit) async {
        var levelChanged = false
        var oldLevel: Level?
        var streakChanged = false
        
        // update locally
        if let index = habits.firstIndex(where: { $0.id == habit.id }) {
            let oldHabit = habits[index] // used to check if anything changed
            oldLevel = oldHabit.currentLevel
            levelChanged = oldHabit.currentLevel != habit.currentLevel
            streakChanged = oldHabit.streaks != habit.streaks
            
            habits[index] = habit // update list
            
            // save locally
            await performOperation {
                try? await dataService.saveHabitsLocally(habits)
            }
        }
        
        // stupid fucking concurrency domain issues
        let newLevelChanged = levelChanged
        let newOldLevel = oldLevel
        let newStreakChanged = streakChanged
        
        // update firestore
        Task {
            await performOperation {
                try await dataService.updateHabitInFirestore(habit)
            }
            
            // notify after local and remote updates
            await MainActor.run {
                // check for level change
                if newLevelChanged, let oldLevel = newOldLevel {
                    self.notifyChange(.levelChanged(habitId: habit.id,
                                               oldLevel: oldLevel,
                                               newLevel: habit.currentLevel))
                }
                
                // check for streak change
                if newStreakChanged {
                    self.notifyChange(.streakChanged(habitId: habit.id, newStreak: habit.streaks))
                }
            }
        }
        
        notifyChange(.habitCRUD)
    }
    
    /// Returns an array of all habits
    func getHabits() -> [Habit] {
        return habits
    }
    
    /// Fetches a single habit by its ID from the remote data source
    ///
    /// - Parameter habitID: The string representation of the habit's UUID
    /// - Returns: The habit if found, nil otherwise
    /// - Throws: An error if the fetch operation fails
    func fetchSingleHabit(habitID: String) async throws -> Habit? {
        var habit: Habit?
        await performOperation {
            habit = try await dataService.fetchHabitFromFirestore(habitID: habitID)
        }
        return habit
    }
    
    /// Removes a habit from the repository
    /// - Parameter habit: The habit to delete
    ///
    /// This method:
    /// 1. Removes the habit from the local collection
    /// 2. Updates local storage
    /// 3. Cancels any scheduled notifications for the habit
    /// 4. Deletes the habit from Firestore
    func deleteHabit(_ habit: Habit) async {
        // delete locally
        habits.removeAll(where: { $0.id == habit.id })
        
        await performOperation {
            try? await dataService.saveHabitsLocally(habits)
        }
        
        // delete notifications
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [habit.id.uuidString])
        
        let weekdays = TimeFormatter.allDays
        let dayIdentifiers = weekdays.map { "\(habit.id.uuidString)_\($0)" }
        center.removePendingNotificationRequests(withIdentifiers: dayIdentifiers)
        
        // delete from firestore
        Task {
            await performOperation {
                try await dataService.deleteHabitFromFirestore(habitId: habit.id)
            }
        }
    }
    
    /// Marks a habit as completed for the current day and updates its stats
    /// - Parameter habit: The habit to mark as completed (passed as an inout parameter to allow modification)
    ///
    /// This method:
    /// 1. Increments the habit's streak and completion count
    /// 2. Records the completion for the current day
    /// 3. Updates the habit in storage
    /// 4. Notifies subscribers of level and streak changes
    func completeHabit(_ habit: inout Habit) async {
        let currentDayString = TimeFormatter.dateToString(Date())
        let oldLevel = habit.currentLevel
        
        habit.streaks += 1
        habit.totalDone += 1
        habit.dailyCompletion[currentDayString, default: 0] += 1
        
        // check if level has changed
        let newLevel = habit.currentLevel
        
        await updateHabit(habit)
        
        if oldLevel != newLevel {
            notifyChange(.levelChanged(habitId: habit.id,
                                       oldLevel: oldLevel,
                                       newLevel: newLevel))
        }
        
        notifyChange(.streakChanged(habitId: habit.id, newStreak: habit.streaks))
    }
    
    // MARK: - Change Observers
    
    /// Defines the types of changes that can happen to habits
    enum HabitChangeType {
        case levelChanged(habitId: UUID, oldLevel: Level, newLevel: Level)
        case streakChanged(habitId: UUID, newStreak: Int)
        case habitCRUD // created, updated, deleted
    }
    
    /// Notify subscribers of change to habits
    /// - Parameter changeType: The type of change that has occurred
    private func notifyChange(_ changeType: HabitChangeType) {
        DispatchQueue.main.async {
            self.habitSubject.send(changeType)
        }
    }
    
    // MARK: - Data Clearing
    
    /// Clears all locally stored habits
    func clearLocalData() async {
        // clear in memory data
        habits = []
        
        // clear persisted data
        do {
            try await dataService.clearLocalHabitData()
        } catch {
            print("Error clearing local storage: \(error)")
        }
        
        notifyChange(.habitCRUD)
    }
    
    // MARK: - Error Handling
    
    /// Reports an error through the error publisher
    /// - Parameter error: The error to report
    ///
    /// Converts multiple error types to a standardized format
    private func reportError(_ error: Error) {
        let dataError: DataServiceError
        
        if let error = error as? DataServiceError {
            dataError = error
        } else if let error = error as? FirebaseError {
            switch error {
            case .userNotAuthenticated:
                dataError = .authenticationRequired
            default:
                dataError = .firestoreReadFailure(underlying: error)
            }
        } else {
            dataError = .invalidData(details: error.localizedDescription)
        }
        
        // publish error
        DispatchQueue.main.async {
            self.errorSubject.send(dataError)
        }
    }
    
    /// Performs operation with standardized error handling
    /// - Parameter operation: The asynchronous operation to perform
    /// 
    /// This method:
    /// 1. Attempts to execute the provided operation
    /// 2. Catches and reports any errors
    /// 3. Sets the needsSync flag for network-related errors
    private func performOperation(_ operation: () async throws -> Void) async {
        do {
            try await operation()
        } catch {
            reportError(error)
            
            // set sync flag if it is a network error
            if let dataError = error as? DataServiceError {
                switch dataError {
                case .networkUnavailable, .firestoreWriteFailure, .firestoreReadFailure, .firestoreDeleteFailure:
                    needsSync = true
                default:
                    break
                }
            }
        }
    }
}
