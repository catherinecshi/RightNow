import UIKit

class HabitEditingViewController: UIViewController {
    
    // MARK: Properties
    
    let repo = HabitRepository.shared
    let oldHabit: Habit // the habit being modified
    var tempHabit = HabitData()
    let daysOfWeek = TimeFormatter.allDays
    
    // for the time picker
    private let hours = Array(1...12)
    private let minutes = Array(0...59)
    private let amPm = ["AM", "PM"]
    
    let viewTitle: UILabel = {
        let label = UILabel()
        label.font = UIConfiguration.titleFont
        label.textColor = .white
        label.textAlignment = .center
        return label
    }()
    
    let whatLabel: UILabel = {
        let label = UILabel()
        label.text = "Time"
        label.font = UIConfiguration.subtitleFont
        label.textColor = .white
        return label
    }()
    
    let timePicker: UIPickerView = {
        let picker = UIPickerView()
        picker.translatesAutoresizingMaskIntoConstraints = false
        return picker
    }()
    
    let daysStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = 5
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    lazy var notificationLabel: UILabel = {
        let label = UILabel()
        label.text = "Enable Notifications"
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .white
        return label
    }()
    
    lazy var notificationSwitch: UISwitch = {
        let turnOnOff = UISwitch()
        turnOnOff.isOn = true
        turnOnOff.translatesAutoresizingMaskIntoConstraints = false
        return turnOnOff
    }()
    
    let accountabilityLabel: UILabel = {
        let label = UILabel()
        label.text = "Accountability Metric"
        label.textColor = .white
        return label
    }()
    
    /*
    let accountabilityMetric: UISegmentedControl = {
        let segmentedControl = UISegmentedControl(items: ["Location Tracking", "Lock Phone Away", "Take a Photo", "Self Tracking"])
        segmentedControl.backgroundColor = .lightGray
        segmentedControl.selectedSegmentTintColor = .white

        // Set white text for all segments
        let normalAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIConfiguration.tintColor,
            .font: UIFont.systemFont(ofSize: 16)
        ]
        segmentedControl.setTitleTextAttributes(normalAttributes, for: .normal)
        segmentedControl.setTitleTextAttributes(normalAttributes, for: .selected)
        
        segmentedControl.addTarget(self, action: #selector(segmentChanged(_:)), for: .valueChanged)
        
        return segmentedControl
    }()
     */
    
    //button to go to the next step
    private let saveButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Save", for: .normal)
        return button
    }()
    
    //button to x out
    private let dismissButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("x", for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 24)
        button.setTitleColor(.white, for: .normal)
        return button
    }()
    
    // MARK: Lifecycle Methods
    
    init(habit: Habit) {
        self.oldHabit = habit
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIConfiguration.tintColor
        
        // pre select stuff based on what's true of old habit
        tempHabit.selectedDays = oldHabit.daysOfTheWeek
        //selectSegment(withText: oldHabit.accountabilityMetric.displayName)
        
        setupTitle()
        setupWhatLabel()
        setupTimePicker()
        setupDaysStackView()
        //setupAccountability()
        setupNotificationToggle()
        setupNextButton()
        setupDismissButton()
    }
    
    // MARK: Setup
    
    private func setupTitle() {
        view.addSubview(viewTitle)
        viewTitle.translatesAutoresizingMaskIntoConstraints = false
        viewTitle.text = oldHabit.name
        
        //make sure it can go to multiple lines if squished
        viewTitle.numberOfLines = 0 //allows line breaks
        viewTitle.lineBreakMode = .byWordWrapping //breaks lines by words, not characters
        
        self.navigationItem.titleView = viewTitle
    }
    
    private func setupWhatLabel() {
        view.addSubview(whatLabel)
        whatLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            whatLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            whatLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            whatLabel.heightAnchor.constraint(equalToConstant: 22)
        ])
    }
    
    private func setupTimePicker() {
        if let time = oldHabit.time {
            view.addSubview(timePicker)
            
            timePicker.delegate = self
            timePicker.dataSource = self
            
            // change text to white
            timePicker.setValue(UIColor.white, forKey: "textColor")
            
            NSLayoutConstraint.activate([
                timePicker.topAnchor.constraint(equalTo: whatLabel.bottomAnchor, constant: 20),
                timePicker.leadingAnchor.constraint(equalTo: whatLabel.trailingAnchor, constant: 20),
                timePicker.heightAnchor.constraint(equalToConstant: 216),
                timePicker.widthAnchor.constraint(equalToConstant: 280)
            ])
            
            // initial values based on oldhabit
            let calendar = Calendar.current
            let hour = calendar.component(.hour, from: time)
            let minute = calendar.component(.minute, from: time)
            
            let hourFor12Format: Int
            let amPmIndex: Int
            
            if hour == 0 {
                hourFor12Format = 12
                amPmIndex = 0 // AM
            } else if hour < 12 {
                hourFor12Format = hour
                amPmIndex = 0 // AM
            } else if hour == 12 {
                hourFor12Format = 12
                amPmIndex = 1 // PM
            } else {
                hourFor12Format = hour - 12
                amPmIndex = 1 // PM
            }
            
            // start midway through
            let midPoint = 5000
            let hourRow = midPoint + (hourFor12Format - 1)
            let minuteRow = midPoint + minute
            
            timePicker.selectRow(hourRow, inComponent: 0, animated: false)
            timePicker.selectRow(minuteRow, inComponent: 1, animated: false)
            timePicker.selectRow(amPmIndex, inComponent: 2, animated: false)
            
        }
    }
    
    private func setupDaysStackView() {
        view.addSubview(daysStackView)
        
        for day in daysOfWeek {
            let button = UIButton()
            button.setTitle(day, for: .normal)
            button.setTitleColor(UIConfiguration.tintColor, for: .normal)
            button.setTitleColor(UIConfiguration.tintColor, for: .selected)
            
            let isSelected = oldHabit.daysOfTheWeek[day] ?? false
            button.isSelected = isSelected
            button.backgroundColor = isSelected ? .white : .lightGray
            
            button.layer.cornerRadius = 5
            button.addTarget(self, action: #selector(dayButtonTapped), for: .touchUpInside)
            daysStackView.addArrangedSubview(button)
        }
        
        NSLayoutConstraint.activate([
            daysStackView.topAnchor.constraint(equalTo: timePicker.bottomAnchor, constant: 20),
            daysStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            daysStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            daysStackView.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
    
    /*
    private func setupAccountability() {
        view.addSubview(accountabilityLabel)
        view.addSubview(accountabilityMetric)
        accountabilityLabel.translatesAutoresizingMaskIntoConstraints = false
        accountabilityMetric.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            accountabilityLabel.topAnchor.constraint(equalTo: daysStackView.bottomAnchor, constant: 40),
            accountabilityLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            
            accountabilityMetric.topAnchor.constraint(equalTo: accountabilityLabel.bottomAnchor, constant: 20),
            accountabilityMetric.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            accountabilityMetric.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            accountabilityMetric.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
     */
    
    func setupNotificationToggle() {
        view.addSubview(notificationLabel)
        view.addSubview(notificationSwitch)
        
        NSLayoutConstraint.activate([
            notificationLabel.topAnchor.constraint(equalTo: daysStackView.bottomAnchor, constant: 40),
            notificationLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            
            notificationSwitch.centerYAnchor.constraint(equalTo: notificationLabel.centerYAnchor),
            notificationSwitch.leadingAnchor.constraint(equalTo: notificationLabel.trailingAnchor, constant: 10)
        ])
    }
    
    private func setupNextButton() {
        //add to view
        view.addSubview(saveButton)
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            saveButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            saveButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            saveButton.heightAnchor.constraint(equalToConstant: 100),
            saveButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -30)
        ])
        
        //appearance
        saveButton.backgroundColor = .white
        saveButton.setTitleColor(UIConfiguration.tintColor, for: .normal)
        saveButton.setTitleColor(UIColor.gray, for: .disabled)
        saveButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 32)
        saveButton.layer.cornerRadius = 20
        saveButton.clipsToBounds = true
        
        //add action
        saveButton.addTarget(self, action: #selector(saveButtonTapped), for: .touchUpInside)
    }
    
    private func setupDismissButton() {
        dismissButton.translatesAutoresizingMaskIntoConstraints = false
        
        let dismissBarButton = UIBarButtonItem(customView: dismissButton)
        self.navigationItem.leftBarButtonItem = dismissBarButton
        
        // add action
        dismissButton.addTarget(self, action: #selector(dismissSelf), for: .touchUpInside)
    }
    
    // MARK: Button Methods
    
    @objc private func dayButtonTapped(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        sender.backgroundColor = sender.isSelected ? .white : .lightGray
        tempHabit.selectedDays![sender.titleLabel?.text ?? ""] = sender.isSelected
    }
    
    /*
    @objc private func segmentChanged(_ sender: UISegmentedControl) {
        print("Selected segment: \(sender.selectedSegmentIndex)")
    }
    
    private func selectSegment(withText text: String) {
        // Loop through the segments to find the one with the matching title
        for index in 0..<accountabilityMetric.numberOfSegments {
            if accountabilityMetric.titleForSegment(at: index) == text {
                accountabilityMetric.selectedSegmentIndex = index
                return
            }
        }

        // If the text is not found, handle appropriately (e.g., default to no selection)
        print("Segment with text '\(text)' not found.")
        accountabilityMetric.selectedSegmentIndex = UISegmentedControl.noSegment
    }
     */
    
    @objc private func saveButtonTapped() async { // FUTURE CAT REMEMBER TO UPDATE LOCATION TO NIL AS WELL IF METRIC CHANGE
        let newHabit = Habit(
            id: oldHabit.id,
            name: oldHabit.name,
            description: oldHabit.description,
            time: getSelectedTime(),
            daysOfTheWeek: tempHabit.selectedDays ?? oldHabit.daysOfTheWeek,
            notificationEnabled: oldHabit.notificationEnabled,
            totalDone: oldHabit.totalDone,
            totalFailed: oldHabit.totalFailed,
            streaks: oldHabit.streaks,
            lastUpdateDate: Date()
        )
        
        //handle notifications
        PushNotificationDelegate.shared.cancelNotificationForHabit(for: oldHabit)
        
        //enable notifications if user indicates the desire
        if newHabit.notificationEnabled {
            PushNotificationDelegate.shared.scheduleNotificationsForHabit(newHabit)
        }
        
        // update local and firestore databases with new habit
        await repo.updateHabit(newHabit)
        
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func dismissSelf() {
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Helper Methods
    private func getSelectedTime() -> Date {
        // Get selected values from picker
        let selectedHour = hours[timePicker.selectedRow(inComponent: 0) % hours.count]
        let selectedMinute = minutes[timePicker.selectedRow(inComponent: 1) % minutes.count]
        let isPM = timePicker.selectedRow(inComponent: 2) % amPm.count == 1
        
        // Convert to 24-hour format
        let hourIn24Format: Int
        if isPM {
            hourIn24Format = selectedHour == 12 ? 12 : selectedHour + 12
        } else {
            hourIn24Format = selectedHour == 12 ? 0 : selectedHour
        }
        
        // Create a date using the hour and minute
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.hour = hourIn24Format
        components.minute = selectedMinute
        
        return Calendar.current.date(from: components) ?? Date()
    }
}

// MARK: - UIPickerViewDataSource
extension HabitEditingViewController: UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 3 // Hour, Minute, AM/PM
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        switch component {
        case 0, 1:
            return 10000 // Large number for infinite scrolling effect
        case 2:
            return amPm.count
        default:
            return 0
        }
    }
}

// MARK: - UIPickerViewDelegate
extension HabitEditingViewController: UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        var title = ""
        
        switch component {
        case 0:
            let hourValue = hours[row % hours.count]
            title = "\(hourValue)"
        case 1:
            let minuteValue = minutes[row % minutes.count]
            title = String(format: "%02d", minuteValue) // Show minutes as 00, 01, etc.
        case 2:
            title = amPm[row % amPm.count]
        default:
            title = "?"
        }
        
        let attributedTitle = NSAttributedString(string: title, attributes: [NSAttributedString.Key.foregroundColor: UIColor.white])
        return attributedTitle
    }
    
    func pickerView(_ pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat {
        switch component {
        case 0:
            return 60 // Hours
        case 1:
            return 60 // Minutes
        case 2:
            return 60 // AM/PM
        default:
            return 60
        }
    }
}
