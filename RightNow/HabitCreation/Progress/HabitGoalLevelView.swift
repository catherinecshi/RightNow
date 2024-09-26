import Foundation
import UIKit

protocol HabitGoalLevelDelegate: AnyObject {
    func goalLengthSelected(_ goalLength: Int)
}

class HabitGoalLevelView: UIView, UITextFieldDelegate {
    // MARK: Declaration
    weak var delegate: HabitGoalLevelDelegate?
    
    let daysOfWeek = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    
    //initiate labels
    // goal level
    let goalLevelLabel: UILabel = {
        let label = UILabel()
        label.font = UIConfiguration.subtitleFont
        label.textColor = .white
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
    
    let selectedDaysLabel: UILabel = {
        let label = UILabel()
        label.font = UIConfiguration.subtitleFont
        label.textColor = .white
        label.textAlignment = .center
        return label
    }()
    
    // goal length
    
    let goalLengthLabel: UILabel = {
        let label = UILabel()
        label.font = UIConfiguration.subtitleFont
        label.textColor = .white
        label.text = "What is your goal minutes per session?"
        label.numberOfLines = 0 // allow multiple lines
        label.lineBreakMode = .byWordWrapping
        return label
    }()
    
    let lengthSlider: UISlider = {
        let slider = UISlider()
        slider.minimumValue = 0
        slider.maximumValue = 121
        slider.isContinuous = true
        slider.tintColor = UIConfiguration.tintColor
        return slider
    }()
    
    let selectedLengthLabel: UILabel = {
        let label = UILabel()
        label.font = UIConfiguration.subtitleFont
        label.textColor = .white
        label.textAlignment = .center
        label.text = "0 minutes"
        return label
    }()
    
    // MARK: Initialisation
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIConfiguration.tintColor
        
        //setupWhatSubtitle()
        setupDaysStackView()
        setupSelectedDaysLevel()
        setupLengthSubtitle()
        setupLengthSlider()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Setup UI
    
    func updateTitleText(with text: String) {
        let textLower = text.lowercased()
        goalLevelLabel.text = "How often do you want to \(textLower) ideally?"
        //goalLengthLabel.text = "How long do you want to spend on \(textLower) per session?"
    }
    
    private func setupWhatSubtitle() {
        self.addSubview(goalLevelLabel)
        goalLevelLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            goalLevelLabel.topAnchor.constraint(equalTo: self.topAnchor, constant: 20),
            goalLevelLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 20),
            goalLevelLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -20),
            goalLevelLabel.heightAnchor.constraint(equalToConstant: 22) // value taken from the natural height
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
            button.isEnabled = false
            button.alpha = 0.5
            button.addTarget(self, action: #selector(dayButtonTapped), for: .touchUpInside)
            daysStackView.addArrangedSubview(button)
        }
        
        NSLayoutConstraint.activate([
            daysStackView.topAnchor.constraint(equalTo: self.topAnchor, constant: 20),
            daysStackView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 20),
            daysStackView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -20),
            daysStackView.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
    
    func updateSelectedDaysLabel(with daysSelected: [String: Bool], with text: String) {
        //update text
        let days = daysSelected.filter { $0.value }.map { $0.key }.joined(separator: ", ")
        let daysLower = days.lowercased()
        
        let textLower = text.lowercased()
        selectedDaysLabel.text = "Currently, you've chosen to \(textLower) on \(daysLower.isEmpty ? "None" : daysLower)"
        
        //update buttons
        for case let button as UIButton in daysStackView.arrangedSubviews {
            if let day = button.titleLabel?.text, let isSelected = daysSelected[day] {
                button.isSelected = isSelected
                button.backgroundColor = isSelected ? .white : .lightGray
            }
        }
    }
    
    private func setupSelectedDaysLevel() {
        self.addSubview(selectedDaysLabel)
        selectedDaysLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            selectedDaysLabel.topAnchor.constraint(equalTo: daysStackView.bottomAnchor, constant: 10),
            selectedDaysLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 20),
            selectedDaysLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -20),
        ])
    }
    
    private func setupLengthSubtitle() {
        self.addSubview(goalLengthLabel)
        goalLengthLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            goalLengthLabel.topAnchor.constraint(equalTo: selectedDaysLabel.bottomAnchor, constant: 40),
            goalLengthLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 20),
            goalLengthLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -20),
            //currentLengthLabel.heightAnchor.constraint(equalToConstant: 22) // value taken from the natural height
        ])
    }
    
    private func setupLengthSlider() {
        self.addSubview(lengthSlider)
        lengthSlider.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            lengthSlider.topAnchor.constraint(equalTo: goalLengthLabel.bottomAnchor, constant: 20),
            lengthSlider.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 20),
            lengthSlider.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -20),
        ])
        
        self.addSubview(selectedLengthLabel)
        selectedLengthLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            selectedLengthLabel.topAnchor.constraint(equalTo: lengthSlider.bottomAnchor, constant: 10),
            selectedLengthLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 20),
            selectedLengthLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -20),
        ])
        
        lengthSlider.addTarget(self, action: #selector(lengthSliderValueChanged(_:)), for: .valueChanged)
        lengthSlider.isUserInteractionEnabled = true
    }
    
    // MARK: Detect Actions
    
    //just for visualisation for the user
    @objc func dayButtonTapped(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        sender.backgroundColor = sender.isSelected ? .white : .lightGray
    }
    
    @objc private func lengthSliderValueChanged(_ sender: UISlider) {
        let selectedValue = Int(sender.value.rounded())
        
        if selectedValue == Int(lengthSlider.maximumValue) {
            selectedLengthLabel.text = ">120 minutes"
        } else {
            selectedLengthLabel.text = "\(selectedValue) minutes"
        }
        
        delegate?.goalLengthSelected(selectedValue)
    }
    
    func calculateViewHeight() -> CGFloat {
        // always visible components
        let topMargin = CGFloat(40) // from top of view to first label
        let daysStack = CGFloat(40)
        let firstSpacing = CGFloat(10)
        let daysLabel = selectedDaysLabel.frame.size.height
        let secondSpacing = CGFloat(40)
        let lengthLabel = goalLengthLabel.frame.size.height
        let thirdSpacing = CGFloat(20)
        let lengthSlider = lengthSlider.frame.size.height
        let fourthSpacing = CGFloat(10)
        let selectedLength = selectedLengthLabel.frame.size.height
        let total = topMargin + daysStack + firstSpacing + daysLabel + secondSpacing + lengthLabel + thirdSpacing + lengthSlider + fourthSpacing + selectedLength
        
        return total
    }
}
