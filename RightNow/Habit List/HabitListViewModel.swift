import UIKit
import FirebaseAuth
import FirebaseFirestore

class HabitListViewModel {
    static let shared = HabitListViewModel()
    
    var habits: [Habit] = []
    var currentDay: Date = Date() //default to current day
    let db = Firestore.firestore()
    
    //callback
    var onDataLoaded: (() -> Void)?
    
    // MARK: Initialisation
    
    init() {
        loadHabitsFirestore()
    }
    
    // MARK: Storage
    
    func addHabit(_ habit: Habit) {
        print("adding habit")
        habits.append(habit)
        saveHabitsFirestore()
    }
    
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
            db.collection("habits").document(userId).collection("userHabits").getDocuments { (querySnapshot, err) in
                if let err = err {
                    print("Error getting documents: \(err)")
                } else {
                    self.habits.removeAll()
                    for document in querySnapshot!.documents {
                        let jsonData = try! JSONSerialization.data(withJSONObject: document.data(), options: [])
                        let habit = try! JSONDecoder().decode(Habit.self, from: jsonData)
                        self.habits.append(habit)
                    }
                    
                    //notify that data is loaded
                    self.onDataLoaded?()
                }
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
        guard let userId = Auth.auth().currentUser?.uid else {
            return
        }
        
        // stop geofence tracking if there is a location
        if let location = habit.location {
            LocationManager.shared.stopMonitoringGeofence(for: location)
        }
        
        //use habit's UUID as the document ID
        let habitId = habit.id.uuidString
        
        //delete locally from array
        if let indexInHabits = habits.firstIndex(where: { $0.id == habit.id}) {
            habits.remove(at: indexInHabits)
        }
        
        // delete the pending notification
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["\(habit.id)"])
        
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
    }
    
    func updateHabit(_ updatedHabit: Habit) {
        if let userId = Auth.auth().currentUser?.uid {
            //update local array
            if let index = habits.firstIndex(where: { $0.id == updatedHabit.id}) {
                habits[index] = updatedHabit
            }
            
            
            // update firestore habit
            let habitData = try! JSONEncoder().encode(updatedHabit)
            let habitDict = try! JSONSerialization.jsonObject(with: habitData, options: []) as! [String: Any]
                
                db.collection("habits").document(userId).collection("userHabits").document(updatedHabit.id.uuidString).updateData(habitDict)
        }
    }
    
    // MARK: Habit Modification
    // habit completed
    func habitCompleted(_ completedHabit: inout Habit) {
        completedHabit.streaks += 1
        completedHabit.totalDone += 1
        
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
    }
    
    // MARK: Habit Display
    
    func getCurrentDay() -> String {
        return dayOfWeek(from: currentDay)
    }
    
    func dayOfWeek(from date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEE"
        let dayName = dateFormatter.string(from: date)
        return dayName
    }
    
    var habitsForCurrentDay: [Habit] {
        let currentDay = getCurrentDay()
        let filteredHabits = habits.filter { $0.daysOfTheWeek[currentDay] == true }
        
        let sortedHabits = filteredHabits.sorted { $0.time < $1.time }
        
        return sortedHabits
    }
    
    // MARK: Checking stuff is ok
    func checkGeofenceLocations() {
        for habit in habits {
            
        }
    }
}
