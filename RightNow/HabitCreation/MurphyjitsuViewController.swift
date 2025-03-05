import Foundation
import UIKit

class MurphyjitsuViewController: UIViewController {
    // MARK: - Declaration
    var repo = HabitRepository.shared
    var habitData = HabitData()
    
    let daysOfWeek = TimeFormatter.allDays
    
    let viewTitle: UILabel = {
        let label = UILabel()
        label.text = "Create Habit"
        label.font = UIConfiguration.titleFont
        label.textColor = .white
        label.textAlignment = .center
        return label
    }()
    
    let habitDetails: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = UIConfiguration.genericFont
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    private let notificationContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
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
    
    let confidenceLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = UIConfiguration.subtitleFont
        label.textAlignment = .center
        label.numberOfLines = 0
        label.text = "How confident are you that you'll keep up the habit for a month?"
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let confidenceSlider: UISlider = {
        let slider = UISlider()
        slider.minimumValue = 0
        slider.maximumValue = 100
        slider.value = 100 // initial value
        slider.isContinuous = true
        slider.tintColor = .white
        slider.translatesAutoresizingMaskIntoConstraints = false
        return slider
    }()
    
    let selectedConfidenceLabel: UILabel = {
        let label = UILabel()
        label.font = UIConfiguration.subtitleFont
        label.textColor = .white
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    //button to go to the next step
    private let nextButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Save", for: .normal)
        button.isEnabled = true //button is disabled until a habit is selected
        return button
    }()
    
    // MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIConfiguration.tintColor
        
        setupTitle()
        setupNextButton()
        setupHabitDetails()
        setupNotificationToggle()
        setupConfidenceLabel()
        setupConfidenceSlider()
        setupSelectedConfidence()
        
        // ask for notifications if not yet present
        requestNotificationPermission()
        checkNotificationPermission(alert: false)
    }
    
    // MARK: - Setup UI Componenets
    
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
    
    private func setupHabitDetails() {
        view.addSubview(habitDetails)
        habitDetails.translatesAutoresizingMaskIntoConstraints = false
        
        var detailsText = "Your goal is to \(habitData.name ?? "do your habit") "
        
        if let hour = habitData.hour, let minute = habitData.minute {
            let period = hour >= 12 ? "PM" : "AM"
            let displayHour = hour % 12 == 0 ? 12 : hour % 12
            detailsText += "at \(hour):\(String(format: "%02d", minute)) \(period)"
        } else if let cue = habitData.cue {
            detailsText += "after you \(cue)"
        } else {
            detailsText += "Not set"
        }
        
        if let selectedDays = habitData.selectedDays {
            let days = selectedDays.filter { $0.value }.map { $0.key }.joined(separator: ", ")
            detailsText += " on \(days.isEmpty ? "None" : days)"
        }
        
        if let accountabilityMetric = habitData.accountabilityMetric {
            detailsText += " and you'll track your habit by \(accountabilityMetric.displayName)"
        }
        
        habitDetails.text = detailsText
        
        NSLayoutConstraint.activate([
            habitDetails.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 60),
            habitDetails.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 40),
            habitDetails.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -40)
        ])
    }
    
    func setupNotificationToggle() {
        // container for centering
        view.addSubview(notificationContainer)
        
        notificationContainer.addSubview(notificationLabel)
        notificationContainer.addSubview(notificationSwitch)
        
        NSLayoutConstraint.activate([
            notificationContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            notificationContainer.topAnchor.constraint(equalTo: habitDetails.bottomAnchor, constant: 40),
            
            notificationLabel.topAnchor.constraint(equalTo: notificationContainer.topAnchor),
            notificationLabel.leadingAnchor.constraint(equalTo: notificationContainer.leadingAnchor),
            notificationLabel.bottomAnchor.constraint(equalTo: notificationContainer.bottomAnchor),
            
            notificationSwitch.centerYAnchor.constraint(equalTo: notificationLabel.centerYAnchor),
            notificationSwitch.leadingAnchor.constraint(equalTo: notificationLabel.trailingAnchor, constant: 10),
            notificationSwitch.trailingAnchor.constraint(equalTo: notificationContainer.trailingAnchor)
        ])
        
        notificationSwitch.addTarget(self, action: #selector(notificationSwitchChanged(_:)), for: .valueChanged)
    }
    
    private func setupConfidenceLabel() {
        view.addSubview(confidenceLabel)
        
        NSLayoutConstraint.activate([
            confidenceLabel.topAnchor.constraint(equalTo: notificationContainer.bottomAnchor, constant: 40),
            confidenceLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            confidenceLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20)
        ])
    }
    
    private func setupConfidenceSlider() {
        view.addSubview(confidenceSlider)
        
        NSLayoutConstraint.activate([
            confidenceSlider.topAnchor.constraint(equalTo: confidenceLabel.bottomAnchor, constant: 20),
            confidenceSlider.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            confidenceSlider.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20)
        ])
        
        confidenceSlider.addTarget(self, action: #selector(confidenceSliderValueChanged(_:)), for: .valueChanged)
        confidenceSlider.isUserInteractionEnabled = true
    }
    
    private func setupSelectedConfidence() {
        view.addSubview(selectedConfidenceLabel)
        
        selectedConfidenceLabel.text = "I am 100% confident I will keep up my habit to \(String(describing: habitData.name)) for a month"
        
        NSLayoutConstraint.activate([
            selectedConfidenceLabel.topAnchor.constraint(equalTo: confidenceSlider.bottomAnchor, constant: 10),
            selectedConfidenceLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            selectedConfidenceLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20)
        ])
    }
    
    // MARK: - Action Methods
    @objc private func notificationSwitchChanged(_ sender: UISwitch) {
        let isEnabled = sender.isOn
        
        if isEnabled {
            checkNotificationPermission(alert: true)
        }
    }

    @objc private func confidenceSliderValueChanged(_ sender: UISlider) {
        let selectedValue = Int(sender.value.rounded())
        
        if let name = habitData.name {
            selectedConfidenceLabel.text = "I am \(selectedValue)% confident I will keep up my habit to \(name) for a month"
        } else {
            selectedConfidenceLabel.text = "I am \(selectedValue)% confident I will keep up my habit for a month"
        }
        
        // hide or display reminder label depending on confidence
        /*
        if selectedValue < 90 {
            reminderLabel.isHidden = false
        } else {
            reminderLabel.isHidden = true
        }
         */
    }
    
    @objc private func nextButtonTapped() {
        // save the habitData
        let habitDate = TimeFormatter.hourMinuteToDate(hour: habitData.hour ?? 7, minute: habitData.minute ?? 0)
        let newHabit = Habit(id: UUID(),
                             name: habitData.name!,
                             description: "",
                             time: habitDate!,
                             daysOfTheWeek: habitData.selectedDays!,
                             accountabilityMetric: habitData.accountabilityMetric!,
                             location: habitData.location,
                             incentive: habitData.incentive ?? .none,
                             notificationEnabled: notificationSwitch.isOn,
                             totalDone: 0,
                             totalFailed: 0,
                             streaks: 0,
                             lastUpdateDate: Date())
        
        repo.addHabit(newHabit)
        
        dismissSelf()
    }
     
    
    @objc private func dismissSelf() {
        self.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Push Notifications
    private func requestNotificationPermission() {
        PushNotificationDelegate.shared.requestAccessToNotifications { [weak self] granted in
            DispatchQueue.main.async {
                if !granted {
                    self?.userDeniedNotificationPermissions()
                }
            }
        }
    }
    
    private func checkNotificationPermission(alert: Bool) {
        PushNotificationDelegate.shared.getPermissionStatus { status in
            switch status {
            case .denied:
                self.userDeniedNotificationPermissions()
                
                if alert {
                    self.deniedNotificationAlert()
                }
            default:
                return
            }
        }
    }
    
    private func userDeniedNotificationPermissions() {
        notificationSwitch.isOn = false
    }
    
    private func deniedNotificationAlert() {
        DispatchQueue.main.async {
            let alert = CustomAlertViewController.createNotificationSettingsAlert()
            self.present(alert, animated: true)
        }
    }
}
