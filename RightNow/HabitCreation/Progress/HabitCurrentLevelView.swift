import Foundation
import UIKit

protocol HabitCurrentLevelDelegate: AnyObject {
    func levelSelected(_ currentLevel: String)
    
    func lengthSelected(_ currentLength: Int)
    
    func heightUpdated()
}

class HabitCurrentLevelView: UIView, UITextFieldDelegate {
    // MARK: Declaration
    weak var delegate: HabitCurrentLevelDelegate?
    
    let levels = ["0 times a week", "1-2 times a week", "3-6 times a week", "Every day", "More than once a day"]
    
    //initiate labels
    // current level
    let currentLevelLabel: UILabel = {
        let label = UILabel()
        label.font = UIConfiguration.subtitleFont
        label.textColor = .white
        return label
    }()
    
    let levelSlider: UISlider = {
        let slider = UISlider()
        slider.minimumValue = 0
        slider.maximumValue = 4 // for numbers of levels - 1
        slider.isContinuous = true
        slider.tintColor = UIConfiguration.tintColor
        return slider
    }()
    
    let selectedLevelLabel: UILabel = {
        let label = UILabel()
        label.font = UIConfiguration.subtitleFont
        label.textColor = .white
        label.textAlignment = .center
        label.text = "0 times a week"
        return label
    }()
    
    // current length
    
    let currentLengthLabel: UILabel = {
        let label = UILabel()
        label.font = UIConfiguration.subtitleFont
        label.textColor = .white
        label.text = "How many minutes per session do you do on average?"
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
        
        setupWhatSubtitle()
        setupLevelSlider()
        setupLengthSubtitle()
        setupLengthSlider()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Setup UI
    
    func updateTitleText(with text: String) {
        let textLower = text.lowercased()
        currentLevelLabel.text = "How often do you currently \(textLower)?"
    }
    
    private func setupWhatSubtitle() {
        self.addSubview(currentLevelLabel)
        currentLevelLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            currentLevelLabel.topAnchor.constraint(equalTo: self.topAnchor, constant: 40),
            currentLevelLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 20),
            currentLevelLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -20),
            currentLevelLabel.heightAnchor.constraint(equalToConstant: 22) // value taken from the natural height
        ])
    }
    
    private func setupLevelSlider() {
        self.addSubview(levelSlider)
        levelSlider.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            levelSlider.topAnchor.constraint(equalTo: currentLevelLabel.bottomAnchor, constant: 20),
            levelSlider.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 20),
            levelSlider.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -20),
        ])
        
        self.addSubview(selectedLevelLabel)
        selectedLevelLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            selectedLevelLabel.topAnchor.constraint(equalTo: levelSlider.bottomAnchor, constant: 10),
            selectedLevelLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 20),
            selectedLevelLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -20),
        ])
        
        levelSlider.addTarget(self, action: #selector(sliderValueChanged(_:)), for: .valueChanged)
    }
    
    private func setupLengthSubtitle() {
        self.addSubview(currentLengthLabel)
        currentLengthLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            currentLengthLabel.topAnchor.constraint(equalTo: selectedLevelLabel.bottomAnchor, constant: 40),
            currentLengthLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 20),
            currentLengthLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -20),
            //currentLengthLabel.heightAnchor.constraint(equalToConstant: 22) // value taken from the natural height
        ])
        
        currentLengthLabel.isHidden = true // hide incase they've never engaged in habit
    }
    
    private func setupLengthSlider() {
        self.addSubview(lengthSlider)
        lengthSlider.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            lengthSlider.topAnchor.constraint(equalTo: currentLengthLabel.bottomAnchor, constant: 20),
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
        
        // hide initially incase they've never engaged in habit
        lengthSlider.isHidden = true
        selectedLengthLabel.isHidden = true
    }
    
    // MARK: Detect Actions
    
    @objc private func sliderValueChanged(_ sender: UISlider) {
        updateSelectedLevelLabel()
        let selectedIndex = Int(sender.value.rounded())
        delegate?.levelSelected(levels[selectedIndex])
        updateLengthVisibility(forLevel: selectedIndex)
    }
     
    
    private func updateSelectedLevelLabel() {
        let selectedIndex = Int(levelSlider.value.rounded())
        selectedLevelLabel.text = levels[selectedIndex]
    }
     
    
    private func updateLengthVisibility(forLevel levelIndex: Int) {
        let shouldShow = levelIndex != 0
        
        //show or hide length components
        currentLengthLabel.isHidden = !shouldShow
        lengthSlider.isHidden = !shouldShow
        selectedLengthLabel.isHidden = !shouldShow
        
        delegate?.heightUpdated()
    }
     
    
    @objc private func lengthSliderValueChanged(_ sender: UISlider) {
        let selectedValue = Int(sender.value.rounded())
        
        if selectedValue == Int(lengthSlider.maximumValue) {
            selectedLengthLabel.text = ">120 minutes"
        } else {
            selectedLengthLabel.text = "\(selectedValue) minutes"
        }
        
        delegate?.lengthSelected(selectedValue)
    }
    
    func calculateViewHeight() -> CGFloat {
        // always visible components
        let topMargin = CGFloat(40) // from top of view to first label
        let levelLabel = currentLevelLabel.frame.size.height
        let firstSpacing = CGFloat(20)
        let levelSlider = levelSlider.frame.size.height
        let secondSpacing = CGFloat(10)
        let selectedLevel = selectedLevelLabel.frame.size.height
        let thirdSpacing = CGFloat(40)
        let alwaysVisible = topMargin + levelLabel + firstSpacing + levelSlider + secondSpacing + selectedLevel + thirdSpacing
        
        // conditionally visible components
        let lengthLabel = currentLengthLabel.frame.size.height
        let fourthSpacing = CGFloat(20)
        let lengthSlider = lengthSlider.frame.size.height
        let fifthSpacing = CGFloat(10)
        let selectedLength = selectedLengthLabel.frame.size.height
        let conditionallyVisible = lengthLabel + fourthSpacing + lengthSlider + fifthSpacing + selectedLength
        
        var total = alwaysVisible
        if !currentLengthLabel.isHidden {
            total = alwaysVisible + conditionallyVisible
        }
        
        return total
    }
}
