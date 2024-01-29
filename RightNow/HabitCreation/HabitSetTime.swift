import Foundation
import UIKit

class HabitSetTime: UIView {
    //MARK: Initialisation
    
    var habitData = HabitData()
    let daysOfWeek = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    var selectedDays = [String: Bool]()
    
    //initiate labels
    let viewTitle: UILabel = {
        let label = UILabel()
        label.text = ""
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
        label.textAlignment = .center
        return label
    }()
    
    let timePicker: UIPickerView = {
        let picker = UIPickerView()
        picker.translatesAutoresizingMaskIntoConstraints = false
        return picker
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
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    private let nextButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Next", for: .normal)
        button.isEnabled = false //button is disabled until a habit is selected
        return button
    }()
    
    //MARK: Initiation

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        view.backgroundColor = UIConfiguration.tintColor
        
        //initialise selecteDays with all set to false
        daysOfWeek.forEach { selectedDays[$0] = false}
        
        setupTitle()
        setupWhatSubtitle()
        setupTimePicker()
        setupDaysSubtitle()
        setupDaysStackView()
        setupNextButton()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    //MARK: Setup
    
    private func setupTitle() {
        view.addSubview(viewTitle)
        viewTitle.translatesAutoresizingMaskIntoConstraints = false
        
        viewTitle.text = habitData.habitName
        
        //make sure it can go to multiple lines if squished
        viewTitle.numberOfLines = 0 //allows line breaks
        viewTitle.lineBreakMode = .byWordWrapping //breaks lines by words, not characters
        
        NSLayoutConstraint.activate([
            viewTitle.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            viewTitle.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            viewTitle.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            viewTitle.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
    }
    
    private func setupWhatSubtitle() {
        view.addSubview(whatLabel)
        whatLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            whatLabel.topAnchor.constraint(equalTo: viewTitle.bottomAnchor, constant: 40),
            whatLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20)
        ])
    }
    
    func setupTimePicker() {
        timePicker.delegate = self
        timePicker.dataSource = self
        view.addSubview(timePicker)
        
        //make picker bigger
        let scale: CGFloat = 1.5
        timePicker.transform = CGAffineTransform(scaleX: scale, y: scale)
        
        //change text to white
        timePicker.setValue(UIColor.white, forKey: "textColor")
        
        //readjusts layout after scaling
        timePicker.sizeToFit()
        
        NSLayoutConstraint.activate([
            timePicker.topAnchor.constraint(equalTo: whatLabel.bottomAnchor, constant: 20),
            timePicker.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
        
        //start timepicker in the middle
        let middleHourRow = (10000 / 2) - ((10000 / 2) % hours.count)
        let middleMinuteRow = (10000 / 2) - ((10000 / 2) % minutes.count)
        
        timePicker.selectRow(middleHourRow, inComponent: 0, animated: false)
        timePicker.selectRow(middleMinuteRow, inComponent: 1, animated: false)
    }
    
    private func setupDaysSubtitle() {
        view.addSubview(daysLabel)
        daysLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            daysLabel.topAnchor.constraint(equalTo: timePicker.bottomAnchor, constant: 60),
            daysLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20)
        ])
    }
    
    private func setupDaysStackView() {
        view.addSubview(daysStackView)
        
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
            daysStackView.topAnchor.constraint(equalTo: daysLabel.bottomAnchor, constant: 10),
            daysStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            daysStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            daysStackView.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
    
    private func setupNextButton() {
        //add to view
        view.addSubview(nextButton)
        nextButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            nextButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            nextButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            nextButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -30),
            nextButton.heightAnchor.constraint(equalToConstant: 100),
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
    
    //MARK: OBJC Methods
    
    @objc func dayButtonTapped(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        sender.backgroundColor = sender.isSelected ? .white : .lightGray
        selectedDays[sender.titleLabel?.text ?? ""] = sender.isSelected
        
        //update next button
        daysSelected()
    }
    
    @objc private func nextButtonTapped() {
        //save habit name
        habitData.selectedDays = selectedDays
        
        //create and push the next view controller
        //let setTimeViewController = HabitSetTime()
        //setTimeViewController.habitData = habitData
        //navigationController?.pushViewController(setTimeViewController, animated: true)
    }
    
    @objc private func daysSelected() {
        //check if any days are selected
        let isAnyDaySelected = selectedDays.contains { $0.value == true }
        
        //enable if so
        nextButton.isEnabled = isAnyDaySelected
    }
}

//for making my own timepicker
//arrays
let hours = Array(1...12)
let minutes = Array(1...59)
let amPm = ["AM", "PM"]

//data source
extension HabitSetTime: UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 3
    }
    
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

//delegate to handle display and selection
extension HabitSetTime: UIPickerViewDelegate {
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
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        //modulo arithmetic to determine the actual hour or minute
        let selectedHour = hours[pickerView.selectedRow(inComponent: 0) % hours.count]
        let selectedMinute = minutes[pickerView.selectedRow(inComponent: 1) % minutes.count]
        
        //update habitdata
        habitData.hour = selectedHour
        habitData.minute = selectedMinute
    }
}
