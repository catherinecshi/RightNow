import Foundation
import UIKit

protocol SelectTimeDelegate: AnyObject {
    func hourSelected(_ hour: Int)
    func minuteSelected(_ minute: Int)
    func daySelected(_ days: [String: Bool])
}

class SelectTimeView: UIView {
    //MARK: Initialisation
    weak var delegate: SelectTimeDelegate?
    
    let daysOfWeek = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    var selectedDays = [String: Bool]()
    
    //initialize labels
    
    let whatLabel: UILabel = {
        let label = UILabel()
        label.text = "What Time do You Want to do this Habit?"
        label.font = UIConfiguration.subtitleFont
        label.textColor = .white
        //label.textAlignment = .center
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
    
    //MARK: Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIConfiguration.tintColor
        
        //initialise selecteDays with all set to false
        daysOfWeek.forEach { selectedDays[$0] = false}
        
        setupDaysSubtitle()
        setupDaysStackView()
        setupWhatSubtitle()
        setupTimePicker()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.layoutIfNeeded()
        print("Height of timePicker: \(timePicker.frame.size.height)")
    }
    
    //MARK: Setup
    
    private func setupDaysSubtitle() {
        self.addSubview(daysLabel)
        daysLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            daysLabel.topAnchor.constraint(equalTo: self.topAnchor, constant: 20),
            daysLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 20),
            daysLabel.heightAnchor.constraint(equalToConstant: 22)
        ])
    }
    
    private func setupDaysStackView() {
        self.addSubview(daysStackView)
        
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
            daysStackView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 20),
            daysStackView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -20),
            daysStackView.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
    
    private func setupWhatSubtitle() {
        self.addSubview(whatLabel)
        whatLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            whatLabel.topAnchor.constraint(equalTo: daysStackView.bottomAnchor, constant: 40),
            whatLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 20),
            whatLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -20),
            whatLabel.heightAnchor.constraint(equalToConstant: 22)
        ])
    }
    
    private func setupTimePicker() {
        timePicker.delegate = self
        timePicker.dataSource = self
        self.addSubview(timePicker)
        
        //change text to white
        timePicker.setValue(UIColor.white, forKey: "textColor")
        
        //readjusts layout after scaling
        timePicker.sizeToFit()
        
        NSLayoutConstraint.activate([
            timePicker.topAnchor.constraint(equalTo: whatLabel.bottomAnchor),
            timePicker.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            timePicker.heightAnchor.constraint(equalToConstant: 216)
        ])
        
        //start timepicker at 7am
        timePicker.selectRow(6, inComponent: 0, animated: false)
        timePicker.selectRow(1200, inComponent: 1, animated: false)
    }
    
    //MARK: OBJC Methods
    
    @objc private func dayButtonTapped(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        sender.backgroundColor = sender.isSelected ? .white : .lightGray
        selectedDays[sender.titleLabel?.text ?? ""] = sender.isSelected
        
        //update main vc
        delegate?.daySelected(selectedDays)
    }
}

//for making my own timepicker
//arrays
let hours = Array(1...12)
let minutes = Array(0...59)
let amPm = ["AM", "PM"]

//data source
extension SelectTimeView: UIPickerViewDataSource {
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
extension SelectTimeView: UIPickerViewDelegate {
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
        delegate?.hourSelected(selectedHour)
        delegate?.minuteSelected(selectedMinute)
    }
}
