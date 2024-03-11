import Foundation
import UIKit

class HabitProgressViewController: UIViewController {
    // MARK: Declaration
    
    var habitData = HabitData()
    let currentLevelView = HabitCurrentLevelView()
    let goalLevelView = HabitGoalLevelView()
    private var currentLevelHeightConstraint: NSLayoutConstraint?
    private var goalLevelHeightConstraint: NSLayoutConstraint?
    private var stackViewBottomConstraint: NSLayoutConstraint?
    
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
    
    // stack + scroll for subviews
    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 20
        stack.distribution = .fill
        return stack
    }()
    
    private let scrollView = UIScrollView()
    
    // MARK: Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIConfiguration.tintColor
        
        setupTitle()
        setupNextButton()
        setupScroll()
        
        currentLevelView.updateTitleText(with: habitData.habitName ?? "do your habit")
        goalLevelView.updateTitleText(with: habitData.habitName ?? "your habit")
        goalLevelView.updateSelectedDaysLabel(with: habitData.selectedDays!, with: habitData.habitName ?? "your habit")
    }
    
    // MARK: Initialisation
    
    private func setupTitle() {
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
    
    private func setupScroll() {
        //setup stack view
        view.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            //stackView.bottomAnchor.constraint(equalTo: nextButton.topAnchor)
        ])
        
        stackViewBottomConstraint = stackView.bottomAnchor.constraint(equalTo: nextButton.topAnchor)
        stackViewBottomConstraint?.priority = UILayoutPriority(750)
        stackViewBottomConstraint?.isActive = true
        
        // add subviews
        stackView.addArrangedSubview(currentLevelView)
        stackView.addArrangedSubview(goalLevelView)
        
        NSLayoutConstraint.activate([
            currentLevelView.topAnchor.constraint(equalTo: stackView.topAnchor)
        ])
        
        // calculate height
        let currentHeight = currentLevelView.calculateViewHeight()
        let goalHeight = goalLevelView.calculateViewHeight()
        
        currentLevelHeightConstraint = currentLevelView.heightAnchor.constraint(equalToConstant: currentHeight)
        currentLevelHeightConstraint?.isActive = true
        goalLevelHeightConstraint = goalLevelView.heightAnchor.constraint(equalToConstant: goalHeight)
        goalLevelHeightConstraint?.isActive = true
        
        //assign delegates
        currentLevelView.delegate = self
        goalLevelView.delegate = self
    }

    //activate the next button if appropriate
    private func updateNextButtonState() {
        //check if habit & day have been selected
        let isLevelSelected = !(habitData.currentLevel?.isEmpty ?? true)
        let isGoalLengthSelected = habitData.goalLength ?? 0 > 0
        
        nextButton.isEnabled = isLevelSelected && isGoalLengthSelected
    }
    
    
    @objc private func nextButtonTapped() {
        //create and push the next view controller
        let progressionVC = ProgressionViewController()
        
        // back button
        let backButton = UIBarButtonItem(title: "", style: .plain, target: self, action: #selector(backButtonTapped))
        navigationItem.backBarButtonItem = backButton
        self.navigationController?.navigationBar.tintColor = .white
        
        progressionVC.habitData = habitData
        navigationController?.pushViewController(progressionVC, animated: true)
    }
    
    @objc func backButtonTapped() {
        self.navigationController?.popViewController(animated: true)
    }
    
    @objc private func dismissSelf() {
        self.dismiss(animated: true, completion: nil)
    }
}

extension HabitProgressViewController: HabitCurrentLevelDelegate {
    func levelSelected(_ currentLevel: String) {
        habitData.currentLevel = currentLevel
        updateNextButtonState()
    }
    
    func lengthSelected(_ currentLength: Int) {
        habitData.currentLength = currentLength
        updateNextButtonState()
    }
    
    func heightUpdated() {
        let height = currentLevelView.calculateViewHeight()
        currentLevelHeightConstraint?.constant = height
        
        UIView.animate(withDuration: 0.2) {
            self.view.layoutIfNeeded()
        }
    }
}

extension HabitProgressViewController: HabitGoalLevelDelegate {
    func goalLengthSelected(_ goalLength: Int) {
        habitData.goalLength = goalLength
        updateNextButtonState()
    }
}
