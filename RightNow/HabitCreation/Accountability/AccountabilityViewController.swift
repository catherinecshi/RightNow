import Foundation
import UIKit

protocol AccountabilityDelegate: AnyObject {
    func metricSelected(_ metric: AccountabilityMetric)
}

class AccountabilityViewController: UIViewController, UITextFieldDelegate {
    // MARK: Declaration
    weak var delegate: AccountabilityDelegate?
    var habitData = HabitData()
    
    // accountability metric variables
    var metricButtons: [UIButton] = []
    let predefinedMetrics: [AccountabilityMetric] = [.locationTracking, .photoEvidence, .stayOffPhone, .selfTracking]
    let metricCount = 4
    
    private var selectedButton: UIButton?
    
    // initiate labels
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
        label.text = "How do you want to track your habit?"
        label.font = UIConfiguration.subtitleFont
        label.textColor = .white
        // label.textAlignment = .center
        return label
    }()
    
    // button to go to the next step
    private let nextButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Next", for: .normal)
        button.isEnabled = false // button is disabled until a habit is selected
        return button
    }()
    
    // for the stack to be able to scroll inside this view
    let metricScrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()
    
    // stack to hold habit buttons
    let metricStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 10
        stackView.alignment = .fill
        stackView.distribution = .fill
        return stackView
    }()
    
    // for the accountability metrics that require a time
    let accountabilityLabel: UILabel = {
        let label = UILabel()
        label.font = UIConfiguration.subtitleFont
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let accountabilityTime: UIDatePicker = {
        let datePicker = UIDatePicker()
        datePicker.datePickerMode = .countDownTimer
        datePicker.minuteInterval = 1
        datePicker.preferredDatePickerStyle = .wheels
        datePicker.tintColor = .white
        datePicker.setValue(UIColor.white, forKey: "textColor")
        datePicker.isHidden = true
        datePicker.translatesAutoresizingMaskIntoConstraints = false
        return datePicker
    }()
    
    // MARK: Initialisation
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.delegate = self
        view.backgroundColor = UIConfiguration.tintColor
        
        setupTitle()
        setupWhatSubtitle()
        setupNextButton()
        setupMetricButtons()
        setupAdditionalAccountability()
    }
    
    // MARK: Setup UI
    
    private func setupTitle() {
        view.addSubview(viewTitle)
        viewTitle.translatesAutoresizingMaskIntoConstraints = false
        
        // make sure it can go to multiple lines if squished
        viewTitle.numberOfLines = 0 // allows line breaks
        viewTitle.lineBreakMode = .byWordWrapping // breaks lines by words, not characters
        
        self.navigationItem.titleView = viewTitle
    }
    
    private func setupWhatSubtitle() {
        view.addSubview(whatLabel)
        whatLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            whatLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            whatLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            whatLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            whatLabel.heightAnchor.constraint(equalToConstant: 22) // value taken from the natural height
        ])
    }
    
    private func setupMetricButtons() {
        view.addSubview(metricScrollView)
        metricScrollView.addSubview(metricStackView)
        metricStackView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            metricScrollView.topAnchor.constraint(equalTo: whatLabel.bottomAnchor, constant: 20),
            metricScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            metricScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            //metricScrollView.bottomAnchor.constraint(equalTo: nextButton.topAnchor, constant: 20),
            metricScrollView.heightAnchor.constraint(equalToConstant: 400),
            
            metricStackView.topAnchor.constraint(equalTo: metricScrollView.topAnchor),
            metricStackView.leadingAnchor.constraint(equalTo: metricScrollView.leadingAnchor),
            metricStackView.trailingAnchor.constraint(equalTo: metricScrollView.trailingAnchor),
            metricStackView.bottomAnchor.constraint(equalTo: metricScrollView.bottomAnchor),
            metricStackView.widthAnchor.constraint(equalTo: metricScrollView.widthAnchor),
        ])
        
        let screenWidth = UIScreen.main.bounds.width
        let buttonWidth = (screenWidth - 60) / 2
        let buttonHeight = buttonWidth
        
        var currentRowStack: UIStackView?
        
        for (index, metric) in predefinedMetrics.enumerated() {
            // create a new horizontal stack for every 2 buttons
            if index % 2 == 0 {
                currentRowStack = UIStackView()
                currentRowStack?.axis = .horizontal
                currentRowStack?.spacing = 20
                currentRowStack?.distribution = .fillEqually
                metricStackView.addArrangedSubview(currentRowStack!)
            }
            
            // create a containerview for the button
            let containerView = UIView()
            containerView.translatesAutoresizingMaskIntoConstraints = false
            currentRowStack?.addArrangedSubview(containerView)
            
            let button = UIButton(type: .system)
            button.translatesAutoresizingMaskIntoConstraints = false
            containerView.addSubview(button)
            
            NSLayoutConstraint.activate([
                button.topAnchor.constraint(equalTo: containerView.topAnchor),
                button.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
                button.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
                button.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
                containerView.heightAnchor.constraint(equalToConstant: buttonHeight)
            ])
            
            button.setTitle(metric.displayName, for: .normal)
            button.setTitleColor(.white, for: .normal)
            button.tintColor = UIConfiguration.tintColor
            button.layer.cornerRadius = 10
            button.clipsToBounds = true // for rounded radius
            button.layer.borderWidth = 2
            button.layer.borderColor = CGColor(red: 1, green: 1, blue: 1, alpha: 1)
            
            // set up image
            let icon = iconForMetric(name: metric.displayName, color: .white)
            button.setImage(icon, for: .normal)
            button.imageView?.contentMode = .scaleAspectFit
            
            // adjust image and title positions
            button.contentHorizontalAlignment = .left
            var configuration = UIButton.Configuration.filled()
            configuration.imagePlacement = .leading
            configuration.imagePadding = 10
            configuration.titleAlignment = .center
            configuration.titlePadding = 10
            
            // apply configuration
            button.configuration = configuration
            button.tag = predefinedMetrics.firstIndex(of: metric) ?? 0
            
            button.addTarget(self, action: #selector(metricButtonTapped), for: .touchUpInside)
            currentRowStack?.addArrangedSubview(button)
            metricButtons.append(button)
        }
    }
    
    private func setupAdditionalAccountability() {
        view.addSubview(accountabilityLabel)
        view.addSubview(accountabilityTime)
        
        accountabilityLabel.text = "How long do you want to stay off your phone?"
        accountabilityLabel.isHidden = true
        
        NSLayoutConstraint.activate([
            accountabilityLabel.topAnchor.constraint(equalTo: metricScrollView.bottomAnchor, constant: 20),
            accountabilityLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            accountabilityLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            accountabilityTime.topAnchor.constraint(equalTo: accountabilityLabel.bottomAnchor, constant: 10),
            accountabilityTime.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            accountabilityTime.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.9),
            accountabilityTime.heightAnchor.constraint(equalToConstant: 150)
        ])
    }
    
    private func setupNextButton() {
        // add to view
        view.addSubview(nextButton)
        nextButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            nextButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            nextButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            nextButton.heightAnchor.constraint(equalToConstant: 100),
            nextButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -30)
        ])
        
        // appearance
        nextButton.backgroundColor = .white
        nextButton.setTitleColor(UIConfiguration.tintColor, for: .normal)
        nextButton.setTitleColor(UIColor.gray, for: .disabled)
        nextButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 32)
        nextButton.layer.cornerRadius = 20
        nextButton.clipsToBounds = true
        
        // add action
        nextButton.addTarget(self, action: #selector(nextButtonTapped), for: .touchUpInside)
    }
    
    // MARK: Detect Actions
    
    private func updateNextButtonState() {
        nextButton.isEnabled = true
    }
    
    @objc private func metricButtonTapped(_ sender: UIButton) {
        // deselect previously selected button if there was one
        if let previousButton = selectedButton, previousButton != sender {
            previousButton.isSelected = false
            
            let previousTitle = descriptionToTitle(description: previousButton.titleLabel?.text)
            previousButton.setTitle(previousTitle, for: .normal)
            var previousConfig = previousButton.configuration ?? UIButton.Configuration.filled()
            previousConfig.baseForegroundColor = .white
            previousButton.tintColor = UIConfiguration.tintColor
            previousButton.configuration = previousConfig
            
            let previousIcon = iconForMetric(name: previousTitle, color: .white)
            previousButton.setImage(previousIcon, for: .normal)
            previousButton.imageView?.contentMode = .scaleAspectFit
        }
        
        sender.isSelected.toggle()
        var config = sender.configuration ?? UIButton.Configuration.filled()
        
        if sender.isSelected {
            selectedButton = sender
            
            let newDescription = titleToDescription(title: sender.titleLabel?.text)
            sender.setTitle(newDescription, for: .normal)
            config.baseForegroundColor = UIConfiguration.tintColor
            sender.tintColor = .white
            
            // change icon color
            let icon = iconForMetric(name: sender.titleLabel?.text, color: UIConfiguration.tintColor ?? .black)
            sender.setImage(icon, for: .normal)
            sender.imageView?.contentMode = .scaleAspectFit
        } else {
            // button untapped -> reset appearance
            selectedButton = nil
            
            let newTitle = descriptionToTitle(description: sender.titleLabel?.text)
            sender.setTitle(newTitle, for: .normal)
            config.baseForegroundColor = .white
            sender.tintColor = UIConfiguration.tintColor
            
            let icon = iconForMetric(name: newTitle, color: .white)
            sender.setImage(icon, for: .normal)
            sender.imageView?.contentMode = .scaleAspectFit
        }
        
        sender.configuration = config
        
        UIView.animate(withDuration: 0.2) {
            sender.layoutIfNeeded()
        }
        
        let selectedMetric = predefinedMetrics[sender.tag]
        delegate?.metricSelected(selectedMetric)
        
        // show or hide time picker based on selection
        let shouldShowTimePicker = sender.isSelected && selectedMetric == .stayOffPhone
        accountabilityLabel.isHidden = !shouldShowTimePicker
        accountabilityTime.isHidden = !shouldShowTimePicker
    }
    
    @objc private func nextButtonTapped() {
        // create and push the next view controller
        var nextVC: UIViewController
        
        // store time duration if relevant
        if habitData.accountabilityMetric == .stayOffPhone {
            let timeInterval = accountabilityTime.countDownDuration
            habitData.stayOffPhoneDuration = timeInterval
        }
        
        if habitData.accountabilityMetric == .locationTracking {
            let locationVC = LocationAccountabilityViewController()
            locationVC.habitData = habitData
            nextVC = locationVC
            //} else if habitData.accountabilityMetric == .objectDetection {
            //let objectDetectionVC = ObjectDetectionViewController()
            //objectDetectionVC.habitData = habitData
            //nextVC = objectDetectionVC
        } else {
            //let defaultVC = IncentivesViewController()
            let defaultVC = MurphyjitsuViewController()
            defaultVC.habitData = habitData
            nextVC = defaultVC
        }
        
        // back button
        let backButton = UIBarButtonItem(title: "", style: .plain, target: self, action: #selector(backButtonTapped))
        navigationItem.backBarButtonItem = backButton
        self.navigationController?.navigationBar.tintColor = .white
        
        navigationController?.pushViewController(nextVC, animated: true)
    }
    
    @objc private func backButtonTapped() {
        self.navigationController?.popViewController(animated: true)
    }
    
    // MARK: Auxillary Methods
    
    private func iconForMetric(name: String?, color: UIColor) -> UIImage? {
        switch name {
        case "Track your Location":
            return UIImage(systemName: "location")?.withTintColor(color, renderingMode: .alwaysOriginal)
        case "Stay Still":
            return UIImage(systemName: "hourglass.circle")?.withTintColor(color, renderingMode: .alwaysOriginal)
        case "Stay Off your Phone":
            return UIImage(systemName: "hourglass.circle")?.withTintColor(color, renderingMode: .alwaysOriginal)
        case "Track your Steps":
            return UIImage(systemName: "shoeprints.fill")?.withTintColor(color, renderingMode: .alwaysOriginal)
        case "Object Detection":
            return UIImage(systemName: "photo.badge.checkmark")?.withTintColor(color, renderingMode: .alwaysOriginal)
        case "Take a Photo":
            return UIImage(systemName: "photo.badge.checkmark")?.withTintColor(color, renderingMode: .alwaysOriginal)
        case "Self Tracking":
            return UIImage(systemName: "person.crop.circle.badge.checkmark")?.withTintColor(color, renderingMode: .alwaysOriginal)
        default:
            return UIImage(systemName: "checkmark")?.withTintColor(color, renderingMode: .alwaysOriginal)
        }
    }
    
    private func titleToDescription(title: String?) -> String {
        switch title {
        case "Track your Location":
            return "Complete habit by being at a specific place during the time for your habit"
        case "Stay Still":
            return "Stay still in front of something, like your laptop for work"
        case "Stay Off your Phone":
            return "Stay off your phone for a pre-determined amount of time"
        case "Track your Steps":
            return "Track your activity levels by a certain time, like 1000 steps after waking up"
        case "Object Detection":
            return "Complete your habit by taking a photo of something proving you've finished your habit"
        case "Take a Photo":
            return "Take a photo before or after you do your habit"
        case "Self Tracking":
            return "Check off your habit yourself, no automatic tracking!"
        default:
            return "Check off your habit yourself, no automatic tracking!"
        }
    }
    
    private func descriptionToTitle(description: String?) -> String {
        switch description {
        case "Complete habit by being at a specific place during the time for your habit":
            return "Track your Location"
        case "Complete your habit by using or blocking an app for a specific time":
            return "Track your Screen Time Usage"
        case "Stay off your phone for a pre-determined amount of time":
            return "Stay Off your Phone"
        case "Complete your habit by taking a photo of something during your habit":
            return "Object Detection"
        case "Track your activity levels by a certain time, like 1000 steps after waking up":
            return "Track your Steps"
        case "Take a photo before or after you do your habit":
            return "Take a Photo"
        case "Check off your habit yourself, no automatic tracking!":
            return "Self Tracking"
        default:
            return "Self Tracking"
        }
    }
}

extension AccountabilityViewController: AccountabilityDelegate {
    func metricSelected(_ metric: AccountabilityMetric) {
        habitData.accountabilityMetric = metric
        updateNextButtonState()
    }
}
