///# SelectTimeViewController
///
/// The second view controller in the habit creation flow. Allows users to select which days of the week
/// they want to perform their habit and at what time of day.

/// ## Features
/// - Day of week selection via button toggles
/// - Time selection via a customized UIPickerView with hours, minutes, and AM/PM
/// - Handles navigation to the next step in the habit creation process
/// - Supports guided onboarding with focused highlighting and instructions

import Foundation
import UIKit

class SelectTimeViewController: UIViewController {
    // MARK: - Properties
    var habitData: HabitData!
    weak var coordinator: OnboardingCoordinator?
    
    let daysOfWeek = TimeFormatter.allDays
    var selectedDays = [String: Bool]()
    let hours = Array(1...12)
    let minutes = Array(0...59)
    let amPm = ["AM", "PM"]
    
    let viewTitle: UILabel = {
        let label = UILabel()
        label.text = "Create Habit"
        label.font = UIConfiguration.titleFont
        label.textColor = .white
        label.textAlignment = .center
        return label
    }()
    
    let whatLabel: UILabel = {
        let label = UILabel()
        label.text = "What Time do You Want to do this Habit?"
        label.font = UIConfiguration.subtitleFont
        label.textColor = .white
        return label
    }()
    
    let daysLabel: UILabel = {
        let label = UILabel()
        label.text = "Which Days do You Want to do this Habit?"
        label.font = UIConfiguration.subtitleFont
        label.textColor = .white
        label.textAlignment = .center
        return label
    }()
    
    let daysStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = 5
        return stackView
    }()
    
    let timePicker: UIPickerView = {
        let picker = UIPickerView()
        return picker
    }()
    
    private let nextButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Next", for: .normal)
        button.backgroundColor = .white
        button.setTitleColor(UIConfiguration.tintColor, for: .normal)
        button.setTitleColor(UIColor.gray, for: .disabled)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 32)
        button.layer.cornerRadius = 20
        button.clipsToBounds = true
        button.isEnabled = false //button is disabled until a habit is selected
        return button
    }()
    
    // for the onboarding process
    private lazy var focusView: FocusView = {
        let view = FocusView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true
        view.alpha = 0.0
        return view
    }()
    
    private lazy var daysOnboardingLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 20, weight: .medium)
        label.textColor = .white
        label.textAlignment = .center
        label.numberOfLines = 0
        label.text = "We'll do the habit everyday"
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isHidden = true
        label.alpha = 0.0
        return label
    }()
    
    private lazy var timeOnboardingLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 20, weight: .medium)
        label.textColor = .white
        label.textAlignment = .center
        label.numberOfLines = 0
        label.text = "And let's set the time at 9 AM"
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isHidden = true
        label.alpha = 0.0
        return label
    }()
    
    private lazy var nextLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 20, weight: .medium)
        label.textColor = .white
        label.textAlignment = .center
        label.numberOfLines = 0
        label.text = "And make the habit!"
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isHidden = true
        label.alpha = 0.0
        return label
    }()
    
    // MARK: - Lifecycle Methods
    
    /// Sets up UI and initializes the days of week buttons to be false
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIConfiguration.tintColor
        
        //initialise selecteDays with all set to false
        daysOfWeek.forEach { selectedDays[$0] = false}
        
        setupTitle()
        setupNextButton()
        setupDaysLabel()
        setupDaysStackView()
        setupWhatLabel()
        setupTimePicker()
    }
    
    // MARK: - Setup UI
    
    private func setupTitle() {
        view.addSubview(viewTitle)
        viewTitle.translatesAutoresizingMaskIntoConstraints = false
        
        //make sure it can go to multiple lines if squished
        viewTitle.numberOfLines = 0 //allows line breaks
        viewTitle.lineBreakMode = .byWordWrapping //breaks lines by words, not characters
        
        self.navigationItem.titleView = viewTitle
    }
    
    private func setupDaysLabel() {
        view.addSubview(daysLabel)
        daysLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            daysLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            daysLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            daysLabel.heightAnchor.constraint(equalToConstant: 22)
        ])
    }
    
    private func setupDaysStackView() {
        view.addSubview(daysStackView)
        daysStackView.translatesAutoresizingMaskIntoConstraints = false
        
        for day in daysOfWeek {
            let button = UIButton()
            button.setTitle(day, for: .normal)
            button.setTitleColor(UIConfiguration.tintColor, for: .normal)
            button.setTitleColor(UIConfiguration.tintColor, for: .selected)
            button.backgroundColor = .lightGray
            button.layer.cornerRadius = 5
            button.addTarget(self, action: #selector(dayButtonTapped), for: .touchUpInside)
            daysStackView.addArrangedSubview(button)
        }
        
        NSLayoutConstraint.activate([
            daysStackView.topAnchor.constraint(equalTo: daysLabel.bottomAnchor, constant: 20),
            daysStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            daysStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            daysStackView.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
    
    private func setupWhatLabel() {
        view.addSubview(whatLabel)
        whatLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            whatLabel.topAnchor.constraint(equalTo: daysStackView.bottomAnchor, constant: 40),
            whatLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            whatLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            whatLabel.heightAnchor.constraint(equalToConstant: 22)
        ])
    }
    
    private func setupTimePicker() {
        timePicker.delegate = self
        timePicker.dataSource = self
        
        view.addSubview(timePicker)
        timePicker.translatesAutoresizingMaskIntoConstraints = false
        
        //change text to white
        timePicker.setValue(UIColor.white, forKey: "textColor")
        
        //readjusts layout after scaling
        timePicker.sizeToFit()
        
        NSLayoutConstraint.activate([
            timePicker.topAnchor.constraint(equalTo: whatLabel.bottomAnchor),
            timePicker.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            timePicker.heightAnchor.constraint(equalToConstant: 216)
        ])
        
        //start timepicker at 7am
        let initialHourRow = 6
        let initialMinuteRow = 1200
        let initialAMPMRow = 0
        
        timePicker.selectRow(initialHourRow, inComponent: 0, animated: false)
        timePicker.selectRow(initialMinuteRow, inComponent: 1, animated: false)
        timePicker.selectRow(initialAMPMRow, inComponent: 2, animated: false)
        
        // input an initial value incase the user wants their habit to start at 7
        pickerView(timePicker, didSelectRow: initialHourRow, inComponent: 0)
    }
    
    private func setupNextButton() {
        view.addSubview(nextButton)
        nextButton.translatesAutoresizingMaskIntoConstraints = false
        
        if let _ = coordinator { // user onboarding
            nextButton.setTitle("Save", for: .normal)
        }
        
        NSLayoutConstraint.activate([
            nextButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            nextButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            nextButton.heightAnchor.constraint(equalToConstant: 100),
            nextButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20)
        ])
        
        nextButton.addTarget(self, action: #selector(nextButtonTapped), for: .touchUpInside)
    }
    
    // MARK: - Actions
    
    /// handles tap on day of week selection buttons
    /// - toggles state
    /// - updates appearance
    /// - updates dictionary
    /// - enables/disables next button
    ///
    /// - Parameter sender: the button that was tapped
    @objc private func dayButtonTapped(_ sender: UIButton) {
        // toggle selection
        sender.isSelected = !sender.isSelected
        sender.backgroundColor = sender.isSelected ? .white : .lightGray
        
        // update UI, next button, and habit data
        selectedDays[sender.titleLabel?.text ?? ""] = sender.isSelected
        nextButton.isEnabled = selectedDays.values.contains(true)
        habitData.selectedDays = selectedDays
    }
    
    /// Handles next button tap to continue to next VC
    /// completes habit creation process when onboarding
    @objc private func nextButtonTapped() {
        if let coordinator = coordinator { // user onboarding
            coordinator.finishHabitCreation(habitData: habitData)
            dismissSelf()
        } else {
            //create and push the next view controller
            let murphyVC = MurphyjitsuViewController()
            
            // back button
            let backButton = UIBarButtonItem(title: "", style: .plain, target: self, action: #selector(backButtonTapped))
            navigationItem.backBarButtonItem = backButton
            self.navigationController?.navigationBar.tintColor = .white
            
            // send info forward
            murphyVC.habitData = habitData
            navigationController?.pushViewController(murphyVC, animated: true)
        }
    }
    
    @objc private func backButtonTapped() {
        self.navigationController?.popViewController(animated: true)
    }
    
    @objc private func dismissSelf() {
        self.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Onboarding
    
    /// Runs complete onboarding sequence for time selection
    /// 1. Blocks user interaction
    /// 2. selects all days of week
    /// 3. Shows focus view on days selection
    ///     - wait and remove the focus view
    /// 4. set time to 9AM & set focus view on time picker
    ///     - wait and remove the focus view
    /// 5. show focus view on next button
    func onboardingSequence() async {
        // make sure the user can't tap on anything while waiting for the animations
        await InteractionBlocker.shared.blockInteractions(on: self.view)
        
        allDaysTrue()
        await showDaysOfWeekFocus()
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        await removeFocus()
        
        try? await Task.sleep(nanoseconds: 500_000_000)
        set9AM()
        await showTimeOfDayFocus()
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        await removeFocus()
        
        try? await Task.sleep(nanoseconds: 500_000_000)
        await InteractionBlocker.shared.unblockInteractions()
        await showNextFocus()
    }
    
    /// Selects all days of weeks for the habit during onboarding
    private func allDaysTrue() {
        daysOfWeek.forEach { selectedDays[$0] = true }
        
        // change button UI to true
        for (index, day) in daysOfWeek.enumerated() {
            if let button = daysStackView.arrangedSubviews[index] as? UIButton {
                button.isSelected = true
                button.backgroundColor = .white
            }
        }
        
        // enable next button now that days are selected
        habitData.selectedDays = selectedDays
        nextButton.isEnabled = true
    }
    
    /// show focus on all days of weeks during onboarding
    private func showDaysOfWeekFocus() async {
        guard let window = view.window else { return }
        
        window.addSubview(focusView)
        focusView.shapeType = .roundedRect(cornerRadius: 12)
        focusView.frame = window.bounds
        focusView.isUserInteractionEnabled = true
        
        // convert frame to coords
        let viewFrame = daysStackView.convert(daysStackView.bounds, to: window)
        focusView.ovalRect = viewFrame.insetBy(dx: -4, dy: -4)
        
        // add label to window
        window.addSubview(daysOnboardingLabel)
        daysOnboardingLabel.isUserInteractionEnabled = false
        
        // position label
        NSLayoutConstraint.activate([
            daysOnboardingLabel.topAnchor.constraint(equalTo: window.safeAreaLayoutGuide.topAnchor, constant: viewFrame.maxY + 20),
            daysOnboardingLabel.centerXAnchor.constraint(equalTo: window.centerXAnchor),
            daysOnboardingLabel.leadingAnchor.constraint(equalTo: window.leadingAnchor, constant: 20),
            daysOnboardingLabel.trailingAnchor.constraint(equalTo: window.trailingAnchor, constant: -20)
        ])
        
        // animate appearance
        daysOnboardingLabel.alpha = 0.0
        daysOnboardingLabel.isHidden = false
        focusView.alpha = 0.0
        focusView.isHidden = false
        
        UIView.animate(withDuration: 0.3) {
            self.daysOnboardingLabel.alpha = 1.0
            self.focusView.alpha = 1.0
        }
    }
    
    /// Sets time picker to 9AM during onboarding
    private func set9AM() {
        let hourFor9AM = 8 // 1 based indexing
        let minuteRow = 0
        let amRow = 0 // AM
        
        timePicker.selectRow(hourFor9AM, inComponent: 0, animated: true)
        timePicker.selectRow(minuteRow, inComponent: 1, animated: true)
        timePicker.selectRow(amRow, inComponent: 2, animated: true)
        
        // update habitData
        habitData.hour = 9
        habitData.minute = 0
    }
    
    /// Show focus view on time picker during onboarding
    private func showTimeOfDayFocus() async {
        guard let window = view.window else { return }
        
        window.addSubview(focusView)
        focusView.shapeType = .roundedRect(cornerRadius: 12)
        focusView.frame = window.bounds
        focusView.isUserInteractionEnabled = true
        
        // convert frame to coords
        let viewFrame = timePicker.convert(timePicker.bounds, to: window)
        focusView.ovalRect = viewFrame.insetBy(dx: -4, dy: -4)
        
        // add label to window
        window.addSubview(timeOnboardingLabel)
        timeOnboardingLabel.isUserInteractionEnabled = false
        
        // position label
        NSLayoutConstraint.activate([
            timeOnboardingLabel.topAnchor.constraint(equalTo: window.safeAreaLayoutGuide.topAnchor, constant: viewFrame.maxY + 20),
            timeOnboardingLabel.centerXAnchor.constraint(equalTo: window.centerXAnchor),
            timeOnboardingLabel.leadingAnchor.constraint(equalTo: window.leadingAnchor, constant: 20),
            timeOnboardingLabel.trailingAnchor.constraint(equalTo: window.trailingAnchor, constant: -20)
        ])
        
        // animate appearance
        timeOnboardingLabel.alpha = 0.0
        timeOnboardingLabel.isHidden = false
        focusView.alpha = 0.0
        focusView.isHidden = false
        print(self.timeOnboardingLabel.alpha)
        print(self.focusView.alpha)
        
        UIView.animate(withDuration: 0.3) {
            self.timeOnboardingLabel.alpha = 1.0
            self.focusView.alpha = 1.0
        } completion: { success in
            print(self.timeOnboardingLabel.alpha)
            print(self.focusView.alpha)
        }
    }
    
    /// Show focus view on next button
    private func showNextFocus() async {
        guard let window = view.window else { return }
        
        window.addSubview(focusView)
        focusView.shapeType = .roundedRect(cornerRadius: 12)
        focusView.frame = window.bounds
        focusView.isUserInteractionEnabled = true
        
        // convert frame to coords
        let buttonFrame = nextButton.convert(nextButton.bounds, to: window)
        focusView.ovalRect = buttonFrame.insetBy(dx: -4, dy: -4)
        
        // add label to window
        window.addSubview(nextLabel)
        nextLabel.isUserInteractionEnabled = false
        
        // position label
        NSLayoutConstraint.activate([
            nextLabel.topAnchor.constraint(equalTo: window.safeAreaLayoutGuide.topAnchor, constant: buttonFrame.minY - 100),
            nextLabel.centerXAnchor.constraint(equalTo: window.centerXAnchor),
            nextLabel.leadingAnchor.constraint(equalTo: window.leadingAnchor, constant: 20),
            nextLabel.trailingAnchor.constraint(equalTo: window.trailingAnchor, constant: -20)
        ])
        
        // animate appearance
        nextLabel.alpha = 0.0
        nextLabel.isHidden = false
        focusView.alpha = 0.0
        focusView.isHidden = false
        
        UIView.animate(withDuration: 0.3) {
            self.nextLabel.alpha = 1.0
            self.focusView.alpha = 1.0
        }
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(focusViewNextTapped(_:)))
        focusView.addGestureRecognizer(tapGesture)
    }
    
    /// Handles tap gesture on next button
    @objc private func focusViewNextTapped(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: focusView)
        
        let isInHighlightedArea: Bool
        
        if let window = view.window {
            let buttonFrame = nextButton.convert(nextButton.bounds, to: window)
            let paddedFrame = buttonFrame.insetBy(dx: -4, dy: -4)
            
            switch focusView.shapeType {
            case .roundedRect(let cornerRadius):
                isInHighlightedArea = paddedFrame.contains(location)
            default:
                isInHighlightedArea = false
            }
        } else {
            isInHighlightedArea = false
        }
        
        // only trigger if tap is within highlighted area
        if isInHighlightedArea {
            nextButtonTapped()
            Task {
                await removeFocus()
            }
        }
    }
    
    /// Removes any focus views present
    private func removeFocus() async {
        guard let window = view.window else { return }
        
        UIView.animate(withDuration: 0.3, animations: {
            self.daysOnboardingLabel.alpha = 0.0
            self.timeOnboardingLabel.alpha = 0.0
            self.nextLabel.alpha = 0.0
            self.focusView.alpha = 0.0
        }, completion: { _ in
            // clean up window level views
            for subview in window.subviews {
                if subview is FocusView || subview == self.daysOnboardingLabel || subview == self.timeOnboardingLabel || subview == self.nextLabel {
                    subview.removeFromSuperview()
                }
            }
        })
    }
}

// MARK: - UIPickerViewDataSource

/// Data source for Time Picker in UIPickerViewDataSource
extension SelectTimeViewController: UIPickerViewDataSource {
    /// Specifies the number of component in the picker view
    /// Returns 3 columns: hours, minutes, and AM/PM
    ///
    /// - Parameter pickerView: The picker view requesting this information
    /// - Returns: The number of components
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 3
    }
    
    /// Specifies the number of rows in each component of picker view
    ///
    /// For hours and minutes, return a large number to create an infinite scroll
    /// For AM/PM return those two options
    ///
    /// - Parameter pickerView: The picker view requesting this information
    /// - Parameter component: The column being queried
    /// - Returns: The number of rows in the specified component
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        switch component {
        case 0, 1:
            return 10000
        case 2:
            return amPm.count
        default:
            return 0
        }
    }
}

// MARK: - UIPickerViewDelegate

/// delegate to handle display and selection of time picker
extension SelectTimeViewController: UIPickerViewDelegate {
    /// Provide the formatted text for each row in the picker view
    ///
    /// For hours: 1 - 12
    /// For minutes: 00 - 59
    /// For AM/PM: "AM" or "PM"
    ///
    /// - Parameter pickerView: The picker view requesting this information
    /// - Parameter row: The row being queried
    /// - Parameter component: The column being queried
    /// - Returns: An attributed string with white text color
    func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        var title = ""
        
        switch component {
        case 0:
            let hourValue = hours[row % hours.count]
            title = "\(hourValue)"
        case 1:
            let minuteValue = minutes[row % minutes.count]
            title = String(format: "%02d", minuteValue)
        case 2:
            title = amPm[row]
        default:
            title = "?"
        }
        
        let attributedTitle = NSAttributedString(string: title, attributes: [NSAttributedString.Key.foregroundColor: UIColor.white])
        return attributedTitle
    }
    
    /// Handles selection of a row in picker view
    /// Makes sure the data being stored matches the 24-hour format
    ///
    /// - For PM hours: add 12 to hours 1 - 12 (12 PM stays as 12)
    /// - For AM hours: Converts 12 AM to 0 (rest stay the same)
    ///
    /// - Parameter pickerView: The picker view where selection occurred
    /// - Parameter row: THe row that was selected
    /// - Parameter component: The column where selection occurs
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        //modulo arithmetic to determine the actual hour or minute
        let selectedHour = hours[pickerView.selectedRow(inComponent: 0) % hours.count]
        let selectedMinute = minutes[pickerView.selectedRow(inComponent: 1) % minutes.count]
        let isPM = pickerView.selectedRow(inComponent: 2) % amPm.count == 1 // true if PM
        
        // convert to 24-hour format
        let convertedHour: Int
        if isPM {
            // 12 stays the same, other hours add 12
            convertedHour = selectedHour == 12 ? 12 : selectedHour + 12
        } else {
            // 12 becomes 0, all others stay the same
            convertedHour = selectedHour == 12 ? 0 : selectedHour
        }
        
        //update habitdata
        habitData.hour = convertedHour
        habitData.minute = selectedMinute
    }
}
