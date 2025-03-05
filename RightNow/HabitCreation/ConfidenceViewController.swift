import Foundation
import UIKit

class ConfidenceViewController: UIViewController {
    // MARK: - Declaration
    var habitData = HabitData()
    var confidenceValue: Int = 0
    
    let daysOfWeek = TimeFormatter.allDays
    
    let viewTitle: UILabel = {
        let label = UILabel()
        label.text = "Create Habit"
        label.font = UIConfiguration.titleFont
        label.textColor = .white
        label.textAlignment = .center
        return label
    }()
    
    let confidenceLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = UIConfiguration.subtitleFont
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
        setupConfidenceLabel()
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
    
    private func setupConfidenceLabel() {
        view.addSubview(confidenceLabel)
        confidenceLabel.text = "What would make you more than \(confidenceValue)% confident that you'll keep up your habit for more than a month?"
        
        NSLayoutConstraint.activate([
            confidenceLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: 20),
            confidenceLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            confidenceLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20)
        ])
    }
    
    // MARK: - Action Methods
    @objc private func nextButtonTapped() {
        // save the habitData
        let habitDate = TimeFormatter.hourMinuteToDate(hour: habitData.hour ?? 7, minute: habitData.minute ?? 0)
        
        dismissSelf()
    }
     
    
    @objc private func dismissSelf() {
        self.dismiss(animated: true, completion: nil)
    }
}
