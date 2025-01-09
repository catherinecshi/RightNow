import Foundation
import UIKit

class MurphyjitsuViewController: UIViewController {
    // MARK: Declaration
    var viewModel = HabitListViewModel.shared
    var habitData = HabitData()
    
    let daysOfWeek = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    
    let viewTitle: UILabel = {
        let label = UILabel()
        label.text = "Create Habit"
        label.font = UIConfiguration.titleFont
        label.textColor = .white
        label.textAlignment = .center
        return label
    }()
    
    //button to go to the next step
    private let nextButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Save", for: .normal)
        button.isEnabled = true //button is disabled until a habit is selected
        return button
    }()
    
    let yourHabit: UILabel = {
        let label = UILabel()
        label.text = "Your Habit Is: "
        label.font = UIConfiguration.titleFont
        label.textColor = .white
        label.textAlignment = .center
        return label
    }()
    
    let habitDetails: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.numberOfLines = 0
        return label
    }()
    
    // MARK: Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIConfiguration.tintColor
        
        setupTitle()
        setupNextButton()
        setupYourHabit()
        setupHabitDetails()
    }
    
    // MARK: Initialisation
    
    private func setupTitle() {
        view.addSubview(viewTitle)
        viewTitle.translatesAutoresizingMaskIntoConstraints = false
        
        //make sure it can go to multiple lines if squished
        viewTitle.numberOfLines = 0 //allows line breaks
        viewTitle.lineBreakMode = .byWordWrapping //breaks lines by words, not characters
        
        self.navigationItem.titleView = viewTitle
    }
    
    private func setupNextButton() {
        //add to view
        view.addSubview(nextButton)
        nextButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            nextButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            nextButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            nextButton.heightAnchor.constraint(equalToConstant: 100),
            nextButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -30)
        ])
        
        //appearance
        nextButton.backgroundColor = .white
        nextButton.setTitleColor(UIConfiguration.tintColor, for: .normal)
        nextButton.setTitleColor(UIColor.gray, for: .disabled)
        nextButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 32)
        nextButton.layer.cornerRadius = 20
        nextButton.clipsToBounds = true
        
        //add action
        nextButton.addTarget(self, action: #selector(nextButtonTapped), for: .touchUpInside)
    }
    
    private func setupYourHabit() {
        view.addSubview(yourHabit)
        yourHabit.translatesAutoresizingMaskIntoConstraints = false
        
        if let habitName = habitData.name, !habitName.isEmpty {
            yourHabit.text = "Your Habit Is: \(habitName)"
        }
        
        NSLayoutConstraint.activate([
            yourHabit.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            yourHabit.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            yourHabit.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20)
        ])
    }
    
    private func setupHabitDetails() {
        view.addSubview(habitDetails)
        habitDetails.translatesAutoresizingMaskIntoConstraints = false
        
        var detailsText = "Done at: "
        
        if let hour = habitData.hour, let minute = habitData.minute {
            detailsText += "\(hour):\(String(format: "%02d", minute))"
        } else {
            detailsText += "Not set"
        }
        
        if let selectedDays = habitData.selectedDays {
            let days = selectedDays.filter { $0.value }.map { $0.key }.joined(separator: ", ")
            detailsText += " on \(days.isEmpty ? "None" : days)"
        }
        
        if let accountabilityMetric = habitData.accountabilityMetric {
            detailsText += "\nWe'll keep you accountable through \(accountabilityMetric)"
        }
        
        habitDetails.text = detailsText
        
        NSLayoutConstraint.activate([
            habitDetails.topAnchor.constraint(equalTo: yourHabit.bottomAnchor, constant: 20),
            habitDetails.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }
    
    
    @objc private func nextButtonTapped() {
        // save the habitData
        var habitDate = createDateFromHourMinute(hour: habitData.hour ?? 7, minute: habitData.minute ?? 0)
        var newHabit = Habit(id: UUID(),
                             name: habitData.name!,
                             description: "",
                             time: habitDate!,
                             daysOfTheWeek: habitData.selectedDays!,
                             accountabilityMetric: habitData.accountabilityMetric!,
                             incentive: habitData.incentive!,
                             notificationEnabled: true,
                             totalDone: 0,
                             totalFailed: 0,
                             streaks: 0)
        print(newHabit)

        viewModel.addHabit(newHabit)
        requestAccessToNotifications()
        scheduleNotification(for: newHabit)
        
        // monitor location if that is the chosen form of habit accountability
        if habitData.location != nil {
            LocationManager.shared.startMonitoringGeofence(for: newHabit)
        }
        
        dismissSelf()
    }
     
    
    @objc private func dismissSelf() {
        self.dismiss(animated: true, completion: nil)
    }
    
    func createDateFromHourMinute(hour: Int, minute: Int) -> Date? {
        let calendar = Calendar.current
        let currentDate = Date()
        
        let components = calendar.dateComponents([.year, .month, .day], from: currentDate)
        
        var dateComponents = DateComponents()
        dateComponents.year = components.year
        dateComponents.month = components.month
        dateComponents.day = components.day
        dateComponents.hour = hour
        dateComponents.minute = minute
        
        return calendar.date(from: dateComponents)
    }
    
    private func requestAccessToNotifications() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { (granted, error) in
            if granted {
                print("Notification permission granted!")
            } else {
                print("Notification permission denied because: \(error?.localizedDescription ?? " no error")")
                //maybe make this an alert in the future
            }
        }
    }
    
    private func scheduleNotification(for habit: Habit) {
        let center = UNUserNotificationCenter.current()
        
        //define notification actions depending on accountability metric
        var actions = [UNNotificationAction]()
        
        switch habit.accountabilityMetric {
        case .locationTracking:
            let trackAction = UNNotificationAction(identifier: "Track_Action", title: "Track Habit", options: [.foreground])
            actions.append(trackAction)
        case .photoEvidence:
            let recordAction = UNNotificationAction(identifier: "Record_Action", title: "Record Habit", options: [.foreground])
            actions.append(recordAction)
        default:
            // in the future have location tracking lead to a map
            break
        }
        
        //defining notification category
        let category = UNNotificationCategory(identifier: "Habit_Action_Category", actions: actions, intentIdentifiers: [], options: [])
        center.setNotificationCategories([category])
        
        //creating notification
        for (day, isActive) in habit.daysOfTheWeek {
            if isActive {
                let content = UNMutableNotificationContent()
                content.title = "Right Now"
                content.body = "Log \(habit.name) now"
                content.sound = UNNotificationSound.default
                
                // information that can be fetched in notification
                let uuidString = habit.id.uuidString
                let metric = habit.accountabilityMetric.displayName
                content.userInfo = ["habitID": uuidString, "metric": metric]
                
                //categories
                content.categoryIdentifier = "Habit_Action_Category"
                
                //just making the console readable
                let triggerDate = habit.time
                
                let dateFormatter = DateFormatter()
                dateFormatter.dateStyle = .long
                dateFormatter.timeStyle = .medium
                dateFormatter.timeZone = TimeZone.current
                print("Scheduling notification for \(day) at \(dateFormatter.string(from: triggerDate))")
                
                //getting the days of week
                let calendar = Calendar.current
                var components = calendar.dateComponents([.hour, .minute], from: habit.time)
                components.weekday = daysOfWeek.firstIndex(of: day)! + 1 //plus one bc sunday starts at 1
                
                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
                let request = UNNotificationRequest(identifier: "\(habit.id)", content: content, trigger: trigger)
                
                center.add(request) { (error) in
                    if let error = error {
                        print("Error scheduling notification for \(day): \(error)")
                    } else {
                        print("Notification scheduled")
                    }
                }
            }
        }
    }
}
