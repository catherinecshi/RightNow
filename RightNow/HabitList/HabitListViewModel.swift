import UIKit
import Network
import FirebaseAuth
import FirebaseFirestore

class HabitListViewModel {
    static let shared = HabitListViewModel()
    
    var habits: [Habit] = [] // current list of habits available
    var currentDay: Date = Date() //default to day the view is on
    let db = Firestore.firestore() // firestore instance
    private var isNetworkAvailable = true // track network status
    private var isSyncing = false
    private var needsSync = false
    
    // MARK: - Initialisation
    
    init() {
        if let localHabits = loadHabitsLocally() {
            habits = localHabits
            notifyObservers(of: .habitCRUD)
        }
        
        loadHabitsFirestore()
    }
    
    // MARK: - Centralisation Methods
    
    enum HabitChangeType {
        case levelChanged(habitId: UUID, oldLevel: Level, newLevel: Level)
        case streakChanged(habitId: UUID, newStreak: Int)
        case habitCRUD
    }
    
    private var observers: [((HabitChangeType) -> Void)] = []
    
    func addObserver(_ callback: @escaping (HabitChangeType) -> Void) {
        observers.append(callback)
    }
    
    private func notifyObservers(of changeType: HabitChangeType) {
        //let currentHabits = self.habitsForCurrentDay
        observers.forEach { callback in
            DispatchQueue.main.async {
                callback(changeType)
            }
        }
    }
    
    // MARK: - Network Connectivity
    func setupNetworkMonitoring() {
        let monitor = NWPathMonitor()
        // this is called every time the connection status changes
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isNetworkAvailable = path.status == .satisfied
                
                if path.status == .satisfied {
                    self?.syncPendingChanges()
                    print("network connected")
                } else {
                    print("network currently available")
                }
            }
        }
        
        let queue = DispatchQueue(label: "NetworkMonitor")
        monitor.start(queue: queue)
    }
    
    private func syncPendingChanges() { // sync pending changes when network becomes vailable
        
    }
    
    // MARK: - CRUD Firebase Methods
    
    func addHabit(_ habit: Habit) {
        print("------------------")
        print("adding habit")
        print(habit)
        print("------------------")
        
        // add to local storage
        habits.append(habit) // temporary storage
        saveHabitsLocally() // persistent storage
        
        // add notifications for habit
        PushNotificationDelegate.shared.scheduleNotificationsForHabit(habit)
        
        // monitor location if that is the chosen form of habit accountability
        if habit.location != nil {
            print("starting geofence monitoring for \(habit.name)")
            LocationManager.shared.startMonitoringGeofence(for: habit)
        }
        
        // save to firestore cloud storage
        saveHabitsFirestore()
        
        // inform view controller so UI updates
        notifyObservers(of: .habitCRUD)
    }
    
    // currently this saves habits based on local habits array, and not directly
    func saveHabitsFirestore() {
        print("saving habits to firestore")
        if let userId = Auth.auth().currentUser?.uid {
            print("User is logged in with ID: \(userId)")
            for habit in habits {
                let habitData = try! JSONEncoder().encode(habit)
                let habitDict = try! JSONSerialization.jsonObject(with: habitData, options: []) as! [String: Any]
                
                db.collection("habits").document(userId).collection("userHabits").document(habit.id.uuidString).setData(habitDict)
            }
        } else {
            print("User is not logged in")
        }
    }
    
    //this is for fetching all habits
    func loadHabitsFirestore() {
        print("loading all habits from firestore")
        if let userId = Auth.auth().currentUser?.uid {
            db.collection("habits").document(userId).collection("userHabits").getDocuments { [weak self] (querySnapshot, err) in
                guard let self = self else { return }
                self.isSyncing = false
                
                if let err = err {
                    print("Error getting documents: \(err)")
                    return
                }
                
                let existingHabits = Dictionary(uniqueKeysWithValues: self.habits.map { ($0.id.uuidString, $0) })
                var updatedHabits: [Habit] = []
                
                for document in querySnapshot!.documents {
                    let jsonData = try! JSONSerialization.data(withJSONObject: document.data(), options: [])
                    var habit = try! JSONDecoder().decode(Habit.self, from: jsonData)
                    
                    if let existingHabit = existingHabits[habit.id.uuidString] {
                        if existingHabit.lastUpdateDate >= habit.lastUpdateDate {
                            habit = existingHabit // local storage is more recent
                        } else {
                            print("firestore habits are more recent")
                        }
                        
                    }
                    
                    habit.updateStats() // check if streak was broken since last update
                    updatedHabits.append(habit)
                }
                
                // update locally if loaded habits are more recent
                self.habits = updatedHabits
                self.saveHabitsLocally()
                
                //notify that data is loaded
                self.notifyObservers(of: .habitCRUD)
                print(self.habits)
                
                // make sure notifications and geofences match up with habits
                PushNotificationDelegate.shared.auditNotifications()
                LocationManager.shared.synchronizeGeofencesWithHabits()
            }
        }
    }
    
    //this is for fetching a single habit
    func fetchHabitFromFirestore(habitID: String, retries: Int = 3, delay: TimeInterval = 2, completion: @escaping (Habit?) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            completion(nil)
            return
        }
        
        let habitDocument = db.collection("habits").document(userId).collection("userHabits").document(habitID)
        
        habitDocument.getDocument { (documentSnapshot, err) in
            if let err = err {
                print("Error getting document: \(err)")
                if retries > 0 {
                    //here retries are a limited resource that we are using up
                    //use up a retry after a delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                        print("Retrying to fetch habit...")
                        self.fetchHabitFromFirestore(habitID: habitID, retries: retries - 1, delay: delay * 2, completion: completion)
                    }
                } else {
                    //no retries left, complete with nil
                    completion(nil)
                }
            } else if let document = documentSnapshot, document.exists {
                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: document.data()!, options: [])
                    let habit = try JSONDecoder().decode(Habit.self, from: jsonData)
                    completion(habit)
                } catch {
                    print("Error decoding document: \(error)")
                    completion(nil)
                }
            } else {
                print("Document does not exist")
                completion(nil)
            }
        }
    }
    
    func deleteHabit(habit: Habit) {
        //delete locally from array
        deleteHabitLocally(habitId: habit.id)
        
        guard let userId = Auth.auth().currentUser?.uid else {
            return
        }
        
        //use habit's UUID as the document ID
        let habitId = habit.id.uuidString
        
        // delete the pending notification
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [habitId])
        
        // delete day specific notifications
        let weekdays = TimeFormatter.allDays
        let dayIdentifiers = weekdays.map { "\(habitId)_\($0)" }
        center.removePendingNotificationRequests(withIdentifiers: dayIdentifiers)
        
        //delete from firestore
        db.collection("habits").document(userId).collection("userHabits").document(habitId).delete() { err in
            if let err = err {
                print("Error removing document: \(err)")
            } else {
                let pathToDelete = "habits/\(userId)/userHabits/\(habitId)"
                print("Attempting to delete document at path: ", pathToDelete)
                print("Document successfully removed!")
            }
        }
        
        notifyObservers(of: .habitCRUD)
    }
    
    func updateHabit(_ updatedHabit: Habit) {
        GeofenceLogger.shared.log("Updating habit: \(updatedHabit.name)")
        GeofenceLogger.shared.log("Location status: \(updatedHabit.location == nil ? "nil" : "has location")")
        GeofenceLogger.shared.log("Accountability: \(updatedHabit.accountabilityMetric)")
        
        updateHabitLocally(updatedHabit) // update locally first
        
        if let userId = Auth.auth().currentUser?.uid {
            // update firestore habit
            let habitData = try! JSONEncoder().encode(updatedHabit)
            var habitDict = try! JSONSerialization.jsonObject(with: habitData, options: []) as! [String: Any]
            GeofenceLogger.shared.log("Habit dict to save: \(habitDict)")
            
            if updatedHabit.location == nil {
                habitDict["location"] = NSNull()
            }
            
            GeofenceLogger.shared.log("Habit dict to save: \(habitDict)")
                
                db.collection("habits").document(userId).collection("userHabits").document(updatedHabit.id.uuidString).updateData(habitDict)
        }
        
        notifyObservers(of: .habitCRUD)
    }
    
    // MARK: - CRUD Local Storage Methods
    
    private func getHabitsFileURL() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0].appendingPathComponent("habits.json")
    }
    
    private func saveHabitsLocally() {
        let fileURL = getHabitsFileURL()
        
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(habits)
            try data.write(to: fileURL)
            print("Successfully saved habits locally")
        } catch {
            print("Error saving habits locally \(error.localizedDescription)")
        }
    }
    
    func loadHabitsLocally() -> [Habit]? {
        let fileURL = getHabitsFileURL()
        
        do {
            if FileManager.default.fileExists(atPath: fileURL.path) {
                let data = try Data(contentsOf: fileURL)
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let localHabits = try decoder.decode([Habit].self, from: data)
                print("Successfully loaded \(localHabits.count) habits locally")
                return localHabits
            }
        } catch {
            print("Error loading habits locally: \(error)")
        }
        
        return nil
    }
    
    func updateHabitLocally(_ updatedHabit: Habit) {
        if let index = habits.firstIndex(where: { $0.id == updatedHabit.id }) {
            habits[index] = updatedHabit
        }
        
        saveHabitsLocally() // save the updated array to the local storage
    }
    
    func deleteHabitLocally(habitId: UUID) {
        habits.removeAll(where: { $0.id == habitId })
        
        saveHabitsLocally() // save the updated array to the local storage
    }
        
    // MARK: Updating Habits
    
    func habitCompleted(_ completedHabit: inout Habit) {
        let currentDayString = TimeFormatter.dateToString(currentDay)
        let oldLevel = completedHabit.currentLevel
        
        completedHabit.streaks += 1
        completedHabit.totalDone += 1
        completedHabit.dailyCompletion[currentDayString, default: 0] += 1
        
        // check if the level or streak has changed
        let newLevel = completedHabit.currentLevel
        if oldLevel != newLevel {
            notifyObservers(of: .levelChanged(habitId: completedHabit.id,
                                              oldLevel: oldLevel,
                                              newLevel: newLevel))
        }
        
        updateHabit(completedHabit)
    }
    
    // MARK: Swipe Methods
    
    @objc func handleSwipe(direction: UISwipeGestureRecognizer.Direction) {
        let dayInterval: TimeInterval = 24 * 60 * 60
        
        if direction == .left {
            currentDay = currentDay.addingTimeInterval(dayInterval)
        } else if direction == .right {
            currentDay = currentDay.addingTimeInterval(-dayInterval)
        }
        
        notifyObservers(of: .habitCRUD)
    }
    
    // MARK: Time Methods
    
    private func findUltimateTimeHabit(_ habit: Habit, in habits: [Habit], visited: Set<String> = []) -> Date? {
        // if this habit has time, return it
        if let time = habit.time {
            return time
        }
        
        // if habit has no cue, or already visited, return nil (in cases of circularity
        guard let cue = habit.cue, !visited.contains(cue) else {
            return nil
        }
        
        // find chained habit
        guard let chainedHabit = habits.first(where: { $0.name == cue }) else {
            return nil
        }
        
        return findUltimateTimeHabit(chainedHabit, in: habits, visited: visited.union([cue]))
    }
    
    var habitsForCurrentDay: [Habit] {
        let currentDayString = TimeFormatter.weekdayToString(currentDay)
        let filteredHabits = habits.filter { $0.daysOfTheWeek[currentDayString] == true }
        
        // sort time based habits by time, then sort cue based habits by alphabetical order at the bottom
        // exception when there is habit chaining, which will always follow the habit before
        let sortedHabits = filteredHabits.sorted { habit1, habit2 in
            // habit 1 is chained to another habit
            if let cue1 = habit1.cue, let matchingHabit1 = filteredHabits.first(where: { $0.name == cue1 }) {
                if habit2.name == matchingHabit1.name { // habit 1 is chained to another habit
                    return false
                }
                
                // habit2 is time based and habit1 is cue based and is chained to a later habit than habit 2
                if let time2 = habit2.time, let matchingTime = matchingHabit1.time {
                    return matchingTime < time2
                }
            }
            
            // habit 2 is chained to another habit
            if let cue2 = habit2.cue, let matchingHabit2 = filteredHabits.first(where: { $0.name == cue2 }) {
                if habit1.name == matchingHabit2.name {
                    // habit 2 is chained to habit 1
                    return true
                }
                
                if let time1 = habit1.time, let matchingTime = matchingHabit2.time {
                    return time1 < matchingTime
                }
            }
            
            // both habits are chained
            if let cue1 = habit1.cue,
               let cue2 = habit2.cue {
                // check if they're chained to a a time based habit
                let ultimateTime1 = findUltimateTimeHabit(habit1, in: filteredHabits)
                let ultimateTime2 = findUltimateTimeHabit(habit2, in: filteredHabits)
                
                // if both eventually chain to time-based habits
                if let time1 = ultimateTime1, let time2 = ultimateTime2 {
                    return time1 < time2
                }
                
                // if only one habit chains to time based habit
                if ultimateTime1 != nil {
                    return true
                }
                
                if ultimateTime2 != nil {
                    return false
                }
            }
            
            // both habits have time based reminders
            if let time1 = habit1.time, let time2 = habit2.time {
                return time1 < time2
            }
            
            // first habit has time, second doesn't
            if habit1.time != nil && habit2.time == nil {
                return true
            }
            
            // inverse here
            if habit1.time == nil && habit2.time != nil {
                return false
            }
            
            // both habits are cue based - sort alphabetically
            return habit1.name < habit2.name
        }
        
        return sortedHabits
    }
    
    func isHabitCompletedForDay(_ habit: Habit) -> Bool {
        let currentDayString = TimeFormatter.dateToString(currentDay)
        let currentCompletions = habit.dailyCompletion[currentDayString, default: 0]
        
        return currentCompletions >= habit.numberOfRepetitions
    }
    
    func isHabitForToday(_ habit: Habit) -> Bool {
        let currentDayString = TimeFormatter.getTodayWeekday()
        print("current day of week: \(currentDayString)")
        print("do habit for current day: \(String(describing: habit.daysOfTheWeek[currentDayString]))")
        return habit.daysOfTheWeek[currentDayString] == true
    }
    
    // MARK: - Location Based Functions
    func locationBasedHabits() -> [Habit] {
        var thereIsLocationHabit: [Habit] = []
        for habit in habits {
            if habit.location != nil {
                thereIsLocationHabit.append(habit)
            }
        }
        
        return thereIsLocationHabit
    }
    
    func changeLocationToSelfTrack(habits: [Habit]?) {
        let habitsToChange = habits ?? locationBasedHabits()
        
        for var habit in habitsToChange {
            habit.accountabilityMetric = .selfTracking
            habit.location = nil
            
            updateHabit(habit)
        }
    }
}
