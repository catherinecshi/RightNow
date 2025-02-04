import Foundation
import UIKit

class SelectTimeViewController: UIViewController {
    //MARK: - Declaration
    var habitData: HabitData!
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
    
    //MARK: - Lifecycle Methods

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
    
    //MARK: - Setup UI
    
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
        timePicker.selectRow(6, inComponent: 0, animated: false)
        timePicker.selectRow(1200, inComponent: 1, animated: false)
    }
    
    private func setupNextButton() {
        view.addSubview(nextButton)
        nextButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            nextButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            nextButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            nextButton.heightAnchor.constraint(equalToConstant: 100),
            nextButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20)
        ])
        
        nextButton.addTarget(self, action: #selector(nextButtonTapped), for: .touchUpInside)
    }
    
    //MARK: - Actions
    
    @objc private func dayButtonTapped(_ sender: UIButton) {
        // toggle selection
        sender.isSelected = !sender.isSelected
        sender.backgroundColor = sender.isSelected ? .white : .lightGray
        
        // update UI, next button, and habit data
        selectedDays[sender.titleLabel?.text ?? ""] = sender.isSelected
        nextButton.isEnabled = selectedDays.values.contains(true)
        habitData.selectedDays = selectedDays
    }
    
    @objc private func nextButtonTapped() {
        //create and push the next view controller
        let accountabilityVC = AccountabilityViewController()
        
        // back button
        let backButton = UIBarButtonItem(title: "", style: .plain, target: self, action: #selector(backButtonTapped))
        navigationItem.backBarButtonItem = backButton
        self.navigationController?.navigationBar.tintColor = .white
        
        // send info forward
        accountabilityVC.habitData = habitData
        navigationController?.pushViewController(accountabilityVC, animated: true)
    }
    
    @objc private func backButtonTapped() {
        self.navigationController?.popViewController(animated: true)
    }
}

//data source
extension SelectTimeViewController: UIPickerViewDataSource {
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
extension SelectTimeViewController: UIPickerViewDelegate {
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
