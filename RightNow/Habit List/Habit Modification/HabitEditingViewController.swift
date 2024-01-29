import UIKit

class HabitEditingViewController: UIViewController {
    
    // communicate with model
    var viewModel: HabitListViewModel?
    
    //habits
    var habit: Habit?
    
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
    
    // toggle for notifications or not
    lazy var notificationLabel: UILabel = {
        return createLabel(withText: "Enable Notifications")
    }()
    
    lazy var notificationSwitch: UISwitch = {
        return createSwitch()
    }()
    
    //setting up for the days of the week the habit is active for
    let daysOfWeek = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
    var dayLabels: [UILabel] = []
    var daySwitches: [UISwitch] = []
    
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
        
        if let habit = habit {
            nameTextField.text = habit.name
            descriptionTextField.text = habit.description
            timePicker.date = habit.time
            
            if habit.notificationEnabled {
                notificationSwitch.isOn = habit.notificationEnabled
            }
            
            for (index, day) in daysOfWeek.enumerated() {
                daySwitches[index].isOn = habit.daysOfTheWeek[day] ?? false
            }
        }
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
        
        //update habits
        habit?.name = name
        habit?.description = description
        habit?.time = selectedTime
        habit?.daysOfTheWeek = selectedDays
        habit?.notificationEnabled = notificationSwitch.isOn
        
        if let updatedHabit = habit {
            //handle notifications
            cancelNotifications(for: updatedHabit)
            
            //enable notifications if user indicates the desire
            if updatedHabit.notificationEnabled {
                scheduleNotification(for: updatedHabit)
            }
            
            viewModel?.updateHabit(updatedHabit)
        }
        
        print(habit ?? "habit not available during update")
        
        dismiss(animated: true, completion: nil)
    }
    
    @objc func cancelButtonTapped() {
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: Notifications
    
    func scheduleNotification(for habit: Habit) {
        let center = UNUserNotificationCenter.current()
        
        for (day, isActive) in habit.daysOfTheWeek {
            if isActive {
                let content = UNMutableNotificationContent()
                content.title = "Right Now"
                content.body = "Log \(habit.name) now"
                content.sound = UNNotificationSound.default
                
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
    
    func cancelNotifications(for habit: Habit) {
        let center = UNUserNotificationCenter.current()
        
        for day in habit.daysOfTheWeek.keys {
            let identifier = "\(habit.id)_\(day)"
            center.removePendingNotificationRequests(withIdentifiers: [identifier])
        }
    }
}
