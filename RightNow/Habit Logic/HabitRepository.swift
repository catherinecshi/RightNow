/// Manages habit collection and synchronization. Handles network connectivity with Firebase

import UIKit
import Network
import Combine

class HabitRepository {
    static let shared = HabitRepository()
    
    // MARK: - Properties
    private let dataService = HabitDataService.shared
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
    private init() {
        loadInitialHabits()
        setupNetworkMonitoring()
    }
    
    private func loadInitialHabits() {
        // load from local storage
        if let localHabits = dataService.loadHabitsLocally() {
            habits = localHabits
            notifyChange(.habitCRUD)
        }
        
        // then try to load from firestore
        Task {
            await syncWithFirestore()
        }
    }
    
    // MARK: - Network Monitoring
    private func setupNetworkMonitoring() {
        let monitor = NWPathMonitor()
        monitor.pathUpdateHandler = { [weak self] path in
            let isConnected = path.status == .satisfied
            
            DispatchQueue.main.async {
                let wasDisconnected = !(self?.isNetworkAvailable ?? true)
                self?.isNetworkAvailable = isConnected
                
                if isConnected && wasDisconnected {
                    Task {
                        await self?.syncWithFirestore()
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
            DispatchQueue.main.async {
                self.habits = updatedHabits
                try? self.dataService.saveHabitsLocally(updatedHabits)
                self.notifyChange(.habitCRUD)
                
                // update notification and geofences
                PushNotificationDelegate.shared.auditNotifications()
                LocationManager.shared.synchronizeGeofencesWithHabits()
                
                self.isSyncing = false
            }
        } catch {
            print("Error syncing with Firestore: \(error)")
            isSyncing = false
        }
    }
    
    // MARK: - CRUD Operations
    func addHabit(_ habit: Habit) {
        habits.append(habit)
        try? dataService.saveHabitsLocally(habits) // add locally
        
        // add notificaitons
        PushNotificationDelegate.shared.scheduleNotificationsForHabit(habit)
        
        // monitor location if needed
        if habit.location != nil {
            LocationManager.shared.startMonitoringGeofence(for: habit)
        }
        
        // save to firestore
        Task {
            do {
                try await dataService.saveHabitsToFirestore(habits: [habit])
            } catch {
                print("Error saving habit to firestore: \(error)")
                needsSync = true
            }
        }
        
        notifyChange(.habitCRUD)
    }
    
    func updateHabit(_ habit: Habit) {
        // update locally
        if let index = habits.firstIndex(where: { $0.id == habit.id }) {
            let oldHabit = habits[index]
            habits[index] = habit
            
            // save locally
            try? dataService.saveHabitsLocally(habits)
            
            // check for level change
            if oldHabit.currentLevel != habit.currentLevel {
                notifyChange(.levelChanged(habitId: habit.id,
                                           oldLevel: oldHabit.currentLevel,
                                           newLevel: habit.currentLevel))
            }
            
            // check for streak change
            if oldHabit.streaks != habit.streaks {
                notifyChange(.streakChanged(habitId: habit.id, newStreak: habit.streaks))
            }
        }
        
        // update firestore
        Task {
            do {
                try await dataService.updateHabitInFirestore(habit)
            } catch {
                print("Error updating habit in firestore: \(error)")
                needsSync = true
            }
        }
        
        notifyChange(.habitCRUD)
    }
    
    func deleteHabit(_ habit: Habit) {
        // delete locally
        habits.removeAll(where: { $0.id == habit.id })
        try? dataService.saveHabitsLocally(habits)
        
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
    
    func completeHabit(_ habit: inout Habit) {
        let currentDayString = TimeFormatter.dateToString(Date())
        let oldLevel = habit.currentLevel
        
        habit.streaks += 1
        habit.totalDone += 1
        habit.dailyCompletion[currentDayString, default: 0] += 1
        
        // check if level has changed
        let newLevel = habit.currentLevel
        
        updateHabit(habit)
        
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
    
    // MARK: - Location Specific Methods
    // returns all habits currently using location tracking
    func locationBasedHabits() -> [Habit] {
        return habits.filter { $0.location != nil }
    }
    
    // converts location tracked habits to self tracked
    func changeLocationToSelfTrack(habits habitsToChange: [Habit]? = nil) {
        let habitsToModify = habitsToChange ?? locationBasedHabits()
        
        for var habit in habitsToModify {
            habit.accountabilityMetric = .selfTracking
            habit.location = nil
            
            updateHabit(habit)
        }
    }
}
