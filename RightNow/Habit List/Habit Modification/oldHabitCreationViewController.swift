import UIKit
import UserNotifications

class HabitCreationViewController: UIViewController {
    
    // communicate with model
    var viewModel: HabitListViewModel?
    
    // MARK: UI Components Declaration
    
    // habit name
    lazy var nameLabel: UILabel = {
        return createLabel(withText: "Habit: ")
    }()
    
    lazy var nameTextField: UITextField = {
        return createTextField()
    }()
    
    // description
    lazy var descriptionLabel: UILabel = {
        return createLabel(withText: "Description: ")
    }()
    
    lazy var descriptionTextField: UITextField = {
        return createTextField()
    }()
    
    let timePicker: UIDatePicker = {
        let picker = UIDatePicker()
        picker.datePickerMode = .time
        picker.translatesAutoresizingMaskIntoConstraints = false
        return picker
    }()
    
    //setting up whether the user wants to receive notifications or not
    
    
    //setting up for the days of the week the habit is active for
    let daysOfWeek = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
    var dayLabels: [UILabel] = []
    var daySwitches: [UISwitch] = []
    
    // toggle for notifications or not
    lazy var notificationLabel: UILabel = {
        return createLabel(withText: "Enable Notifications")
    }()
    
    lazy var notificationSwitch: UISwitch = {
        return createSwitch()
    }()
    
    //buttons
    let saveButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Save", for: .normal)
        //don't change the self to vc.self -> crashes the app
        button.addTarget(self, action: #selector(saveButtonTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    let cancelButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Cancel", for: .normal)
        button.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // MARK: Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        setupHabitInfoUI()
        setupTimePickerUI()
        setupNotificationToggle()
        setupButtonsUI() //this also sets up the days of the week UI
    }
    
    // MARK: Setup
    
    func setupHabitInfoUI() {
        view.addSubview(nameLabel)
        view.addSubview(nameTextField)
        view.addSubview(descriptionLabel)
        view.addSubview(descriptionTextField)
        
        NSLayoutConstraint.activate([
            nameLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            nameLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            
            nameTextField.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 10),
            nameTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            nameTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            descriptionLabel.topAnchor.constraint(equalTo: nameTextField.bottomAnchor, constant: 20),
            descriptionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            
            descriptionTextField.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 10),
            descriptionTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            descriptionTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
    }
    
    func setupTimePickerUI() {
        view.addSubview(timePicker)
        
        NSLayoutConstraint.activate([
            timePicker.topAnchor.constraint(equalTo: descriptionTextField.bottomAnchor, constant: 20),
            timePicker.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            timePicker.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
    }
    
    func setupNotificationToggle() {
        view.addSubview(notificationLabel)
        view.addSubview(notificationSwitch)
        
        NSLayoutConstraint.activate([
            notificationLabel.topAnchor.constraint(equalTo: timePicker.bottomAnchor, constant: 20),
            notificationLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            
            notificationSwitch.centerYAnchor.constraint(equalTo: notificationLabel.centerYAnchor),
            notificationSwitch.leadingAnchor.constraint(equalTo: notificationLabel.trailingAnchor, constant: 10)
        ])
    }
    
    @discardableResult
    func setupDaysUI() -> UISwitch? {
        var lastSwitch: UISwitch? = nil
        
        for day in daysOfWeek {
            let label = createLabel(withText: day)
            let switchControl = createSwitch()
            
            dayLabels.append(label)
            daySwitches.append(switchControl)
            
            view.addSubview(label)
            view.addSubview(switchControl)
            
            NSLayoutConstraint.activate([
                label.topAnchor.constraint(equalTo: lastSwitch?.bottomAnchor ?? notificationLabel.bottomAnchor, constant: 20),
                label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
                
                switchControl.centerYAnchor.constraint(equalTo: label.centerYAnchor),
                switchControl.leadingAnchor.constraint(equalTo: label.trailingAnchor, constant: 10),
            ])
            
            lastSwitch = switchControl
        }
        
        return lastSwitch
    }
    
    func setupButtonsUI() {
        view.addSubview(saveButton)
        view.addSubview(cancelButton)
        
        let buttonSpacing: CGFloat = 100
        
        //to get bottomanchor for buttons
        let lastSwitch = setupDaysUI()
        
        NSLayoutConstraint.activate([
            saveButton.topAnchor.constraint(equalTo: lastSwitch?.bottomAnchor ?? notificationLabel.bottomAnchor, constant: 20),
            saveButton.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: buttonSpacing/2),
            
            cancelButton.topAnchor.constraint(equalTo: lastSwitch?.bottomAnchor ?? notificationLabel.bottomAnchor, constant: 20),
            cancelButton.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: -buttonSpacing/2)
        ])
    }
    
    //for repetitive initialisations
    func createLabel(withText text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }
    
    func createTextField() -> UITextField {
        let textField = UITextField()
        textField.borderStyle = .roundedRect
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }
    
    func createSwitch() -> UISwitch {
        let turnOnOff = UISwitch()
        turnOnOff.translatesAutoresizingMaskIntoConstraints = false
        return turnOnOff
    }
    
    // MARK: Button Methods
    
    @objc func saveButtonTapped() {
        //check that things are entered
        guard let name = nameTextField.text, !name.isEmpty,
              let description = descriptionTextField.text, !description.isEmpty else {
            let alert = UIAlertController(title: "Error", message: "Please fill in all the fields", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
            return
        }
        
        //days of the week
        var selectedDays: [String: Bool] = [:]
        
        for (index, day) in daysOfWeek.enumerated() {
            selectedDays[day] = daySwitches[index].isOn
        }
        
        //extract time
        let selectedTime = timePicker.date
        //if i ever want to extract hour and minute here instead of during extraction, the following line can be used
        //let (hour, minute) = extractHourAndMinute(from: timePicker.date)
        
        //input habit
        let newHabit = Habit(id: UUID(), name: name, description: description, time: selectedTime, daysOfTheWeek: selectedDays, notificationEnabled: notificationSwitch.isOn)
        print(newHabit)
        
        //passes habit to view model
        viewModel?.addHabit(newHabit)
        
        //make notification for habit if user indicates interest
        if newHabit.notificationEnabled {
            requestAccessToNotifications()
            scheduleNotification(for: newHabit)
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    @objc func cancelButtonTapped() {
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: Notifications
    
    //access has been granted on 19/9/2023
    func requestAccessToNotifications() {
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
    
    func scheduleNotification(for habit: Habit) {
        let center = UNUserNotificationCenter.current()
        
        //defining notification actions
        let recordAction = UNNotificationAction(identifier: "Record_Action", title: "Record Habit", options: [.foreground])
        let trackAction = UNNotificationAction(identifier: "Track_Action", title: "Track Habit", options: [.foreground])
        
        //defining notification category
        let category = UNNotificationCategory(identifier: "Habit_Action_Category", actions: [recordAction, trackAction], intentIdentifiers: [], options: [])
        center.setNotificationCategories([category])
        
        //creating notification
        for (day, isActive) in habit.daysOfTheWeek {
            if isActive {
                let content = UNMutableNotificationContent()
                content.title = "Right Now"
                content.body = "Log \(habit.name) now"
                content.sound = UNNotificationSound.default
                
                //user info
                let uuidString = habit.id.uuidString
                content.userInfo = ["habitID": uuidString]
                
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
                let request = UNNotificationRequest(identifier: "\(habit.id)_\(day)", content: content, trigger: trigger)
                
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
    
    // MARK: Auxillary Methods
    /*
    func extractHourAndMinute(from date: Date) -> (hour: Int, minute: Int) {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: date)
        return (components.hour ?? 0, components.minute ?? 0)
    }
     */
}
