import Foundation
import UIKit

class HabitMurphyjitsuViewController: UIViewController {
    // MARK: Declaration
    
    var habitData = HabitData()
    
    let viewTitle: UILabel = {
        let label = UILabel()
        label.text = "Create Habit"
        label.font = UIConfiguration.titleFont
        label.textColor = .white
        label.textAlignment = .center
        return label
    }()
    
    //button to go to the next step
    private let nextButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Next", for: .normal)
        button.isEnabled = false //button is disabled until a habit is selected
        return button
    }()
    
    let yourHabit: UILabel = {
        let label = UILabel()
        label.text = "Your Habit Is: "
        label.font = UIConfiguration.titleFont
        label.textColor = .white
        return label
    }()
    
    let habitDetails: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.numberOfLines = 0
        return label
    }()
    
    // MARK: Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIConfiguration.tintColor
        
        setupTitle()
        setupNextButton()
        setupYourHabit()
        setupHabitDetails()
    }
    
    // MARK: Initialisation
    
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
        //nextButton.addTarget(self, action: #selector(nextButtonTapped), for: .touchUpInside)
    }
    
    private func setupYourHabit() {
        view.addSubview(yourHabit)
        yourHabit.translatesAutoresizingMaskIntoConstraints = false
        
        if let habitName = habitData.habitName, !habitName.isEmpty {
            yourHabit.text = "Your Habit Is: \(habitName)"
        }
        
        NSLayoutConstraint.activate([
            yourHabit.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            yourHabit.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            yourHabit.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20)
        ])
    }
    
    private func setupHabitDetails() {
        view.addSubview(habitDetails)
        habitDetails.translatesAutoresizingMaskIntoConstraints = false
        
        var detailsText = "Done at: "
        
        if let hour = habitData.hour, let minute = habitData.minute {
            detailsText += "\(hour): \(String(format: "%02d", minute))"
        } else {
            detailsText += "Not set"
        }
        
        if let selectedDays = habitData.selectedDays {
            let days = selectedDays.filter { $0.value }.map { $0.key }.joined(separator: ", ")
            detailsText += " on \(days.isEmpty ? "None" : days)"
        }
        
        habitDetails.text = detailsText
        
        NSLayoutConstraint.activate([
            habitDetails.topAnchor.constraint(equalTo: yourHabit.bottomAnchor, constant: 10),
            habitDetails.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            habitDetails.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20)
        ])
    }
    
    /*
    //activate the next button if appropriate
    private func updateNextButtonState() {
        //check if habit & day have been selected
        let isHabitSelected = !(habitData.habitName?.isEmpty ?? true)
        let isDaySelected = habitData.selectedDays?.contains(where: { $0.value }) ?? false
        
        nextButton.isEnabled = isHabitSelected && isDaySelected
    }
    
    
    @objc private func nextButtonTapped() {
        //create and push the next view controller
        let murphyjitsuVC = HabitMurphyjitsuViewController()
        murphyjitsuVC.habitData = habitData
        navigationController?.pushViewController(murphyjitsuVC, animated: true)
    }
     */
    
    @objc private func dismissSelf() {
        self.dismiss(animated: true, completion: nil)
    }
}
