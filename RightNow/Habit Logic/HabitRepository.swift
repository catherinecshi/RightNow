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

class HabitRepository: HabitRepositoryProtocol {
    static let shared = HabitRepository()
    
    // MARK: - Properties
    private let dataService: HabitDataServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    private(set) var habits: [Habit] = []
    private var isNetworkAvailable = true
    private var isSyncing = false
    private var needsSync = false
    
    private let habitSubject = PassthroughSubject<HabitChangeType, Never>()
    var habitPublisher: AnyPublisher<HabitChangeType, Never> {
        habitSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Initialization
    private init(dataService: HabitDataServiceProtocol = HabitDataService.shared) {
        self.dataService = dataService
        
        Task {
            await loadInitialHabits()
        }
        setupNetworkMonitoring()
    }
    
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
    private func setupNetworkMonitoring() {
        let monitor = NWPathMonitor()
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
    
    private func syncWithFirestore() async {
        guard isNetworkAvailable, !isSyncing else { return }
        
        isSyncing = true
        
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
            LocationManager.shared.synchronizeGeofencesWithHabits()
            
            self.isSyncing = false // done syncing
        } catch {
            print("Error syncing with Firestore: \(error)")
            isSyncing = false
        }
    }
    
    // MARK: - CRUD Operations
    func addHabit(_ habit: Habit) {
        habits.append(habit)
        
        // save to firestore
        Task {
            do {
                try await dataService.saveHabitsLocally(habits)
                try await dataService.saveHabitsToFirestore(habits: [habit])
            } catch {
                print("Error saving habit to firestore: \(error)")
                needsSync = true
            }
        }
        
        // add notificaitons
        PushNotificationDelegate.shared.scheduleNotificationsForHabit(habit)
        
        // monitor location if needed
        if habit.location != nil {
            LocationManager.shared.startMonitoringGeofence(for: habit)
        }
        
        notifyChange(.habitCRUD)
    }
    
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
            try? await dataService.saveHabitsLocally(habits)
        }
        
        // stupid fucking concurrency domain issues
        let newLevelChanged = levelChanged
        let newOldLevel = oldLevel
        let newStreakChanged = streakChanged
        
        // update firestore
        Task {
            do {
                try await dataService.updateHabitInFirestore(habit)
            } catch {
                print("Error updating habit in firestore: \(error)")
                needsSync = true
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
    
    func getHabits() -> [Habit] {
        return habits
    }
    
    func fetchSingleHabit(habitID: String) async throws -> Habit? {
        return try await dataService.fetchHabitFromFirestore(habitID: habitID)
    }
    
    func deleteHabit(_ habit: Habit) async {
        // delete locally
        habits.removeAll(where: { $0.id == habit.id })
        try? await dataService.saveHabitsLocally(habits)
        
        // delete notifications
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [habit.id.uuidString])
        
        let weekdays = TimeFormatter.allDays
        let dayIdentifiers = weekdays.map { "\(habit.id.uuidString)_\($0)" }
        center.removePendingNotificationRequests(withIdentifiers: dayIdentifiers)
        
        // delete from firestore
        Task {
            do {
                try await dataService.deleteHabitFromFirestore(habitId: habit.id)
            } catch {
                print("error deleting habit from firestore: \(error)")
                needsSync = true
            }
        }
    }
    
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
    enum HabitChangeType {
        case levelChanged(habitId: UUID, oldLevel: Level, newLevel: Level)
        case streakChanged(habitId: UUID, newStreak: Int)
        case habitCRUD
    }
    
    private func notifyChange(_ changeType: HabitChangeType) {
        DispatchQueue.main.async {
            self.habitSubject.send(changeType)
        }
    }
    
    // MARK: - Data Clearing
    func clearLocalData() async {
        // clear in memory data
        habits = []
        
        // clear persisted data
        do {
            try await dataService.clearLocalStorage()
        } catch {
            print("Error clearing local storage: \(error)")
        }
        
        notifyChange(.habitCRUD)
    }
    
    // MARK: - Location Specific Methods
    // returns all habits currently using location tracking
    func locationBasedHabits() -> [Habit] {
        return habits.filter { $0.location != nil }
    }
    
    // converts location tracked habits to self tracked
    func changeLocationToSelfTrack(habits habitsToChange: [Habit]? = nil) async {
        let habitsToModify = habitsToChange ?? locationBasedHabits()
        
        for var habit in habitsToModify {
            habit.accountabilityMetric = .selfTracking
            habit.location = nil
            
            await updateHabit(habit)
        }
    }
}
