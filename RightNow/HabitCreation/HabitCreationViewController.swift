import Foundation
import UIKit

class HabitCreationSelectHabit: UIViewController, UITextFieldDelegate {
    // MARK: Declaration
    let timeSelectionView = HabitSetTime()
    
    // might be artifacts of trying to fix the problem with equalorlessthan - don't delete tho
    private var nextButtonBottomConstraint: NSLayoutConstraint!
    private var scrollViewBottomConstraint: NSLayoutConstraint!
    
    // some generic habit variables
    var habitData = HabitData()
    var habitButtons: [UIButton] = []
    let habitTextField = UITextField()
    let predefinedHabits = ["Exercise", "Read", "Meditate", "Journal"]
    
    //initiate labels
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
        label.text = "What Habit do You Want to Start?"
        label.font = UIConfiguration.subtitleFont
        label.textColor = .white
        label.textAlignment = .center
        return label
    }()
    
    let suggestionsLabel: UILabel = {
        let label = UILabel()
        label.text = "Suggestions:"
        label.font = UIConfiguration.subtitleFont
        label.textColor = .white
        label.textAlignment = .center
        return label
    }()
    
    //for the stack to be able to scroll inside this view
    let habitsScrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()
    
    //stack to hold habit buttons
    let habitsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 10
        stackView.alignment = .fill
        stackView.distribution = .fillEqually
        return stackView
    }()
    
    //button to go to the next step
    private let nextButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Next", for: .normal)
        button.isEnabled = false //button is disabled until a habit is selected
        return button
    }()
    
    //button to x out
    private let dismissButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("X", for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 24)
        button.setTitleColor(.white, for: .normal)
        button.addTarget(self, action: #selector(dismissSelf), for: .touchUpInside)
        return button
    }()
    
    // MARK: Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIConfiguration.tintColor
        
        setupTitle()
        setupWhatSubtitle()
        setupHabitTextField()
        setupSuggestionSubtitle()
        setupNextButton()
        setupHabitButtons()
        setupDismissButton()
        setupTimeSelectionView()
        
        //observe keyboard actions
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    // MARK: Setup UI
    
    private func setupTitle() {
        view.addSubview(viewTitle)
        viewTitle.translatesAutoresizingMaskIntoConstraints = false
        
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
            whatLabel.topAnchor.constraint(equalTo: viewTitle.bottomAnchor, constant: 20),
            whatLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20)
        ])
    }
    
    private func setupHabitTextField() {
        habitTextField.placeholder = "Enter your habit"
        habitTextField.borderStyle = .roundedRect
        habitTextField.delegate = self
        habitTextField.clearButtonMode = .whileEditing //clear button
        
        //add to view
        view.addSubview(habitTextField)
        habitTextField.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            habitTextField.topAnchor.constraint(equalTo: whatLabel.bottomAnchor, constant: 20),
            habitTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            habitTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            habitTextField.heightAnchor.constraint(equalToConstant: 40)
        ])
        
        //target to capture text changes
        habitTextField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
    }
    
    private func setupSuggestionSubtitle() {
        view.addSubview(suggestionsLabel)
        suggestionsLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            suggestionsLabel.topAnchor.constraint(equalTo: habitTextField.bottomAnchor, constant: 40),
            suggestionsLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20)
        ])
    }
    
    private func setupHabitButtons() {
        view.addSubview(habitsScrollView)
        habitsScrollView.addSubview(habitsStackView)
        habitsStackView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            habitsScrollView.topAnchor.constraint(equalTo: suggestionsLabel.bottomAnchor, constant: 20),
            habitsScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            habitsScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            habitsStackView.topAnchor.constraint(equalTo: habitsScrollView.topAnchor),
            habitsStackView.leadingAnchor.constraint(equalTo: habitsScrollView.leadingAnchor),
            habitsStackView.trailingAnchor.constraint(equalTo: habitsScrollView.trailingAnchor),
            habitsStackView.bottomAnchor.constraint(equalTo: habitsScrollView.bottomAnchor),
            habitsStackView.widthAnchor.constraint(equalTo: habitsScrollView.widthAnchor),
        ])
        
        scrollViewBottomConstraint = habitsScrollView.bottomAnchor.constraint(equalTo: nextButton.topAnchor, constant: -20)
        scrollViewBottomConstraint.priority = UILayoutPriority(750) //lower priority than default
        scrollViewBottomConstraint.isActive = true
        
        for habit in predefinedHabits {
            let button = UIButton(type: .system)
            button.setTitle(habit, for: .normal)
            button.setTitleColor(.white, for: .normal)
            button.backgroundColor = .white
            button.layer.cornerRadius = 10
            button.clipsToBounds = true //for rounded radius
            button.layer.borderWidth = 1
            button.layer.borderColor = UIConfiguration.tintColor?.cgColor
            
            //set up image
            let icon = iconForHabit(name: habit) //method
            button.setImage(icon, for: .normal)
            button.imageView?.contentMode = .scaleAspectFit
            button.tintColor = UIConfiguration.tintColor //if images are template images
            
            //adjust image and title positions
            button.contentHorizontalAlignment = .left
            var configuration = UIButton.Configuration.filled()
            configuration.imagePlacement = .leading
            configuration.imagePadding = 10
            configuration.titleAlignment = .center
            configuration.titlePadding = 10
            
            //apply configuration
            button.configuration = configuration
            
            button.addTarget(self, action: #selector(habitButtonTapped), for: .touchUpInside)
            habitsStackView.addArrangedSubview(button)
            habitButtons.append(button)
        }
    }
    
    private func setupNextButton() {
        //add to view
        view.addSubview(nextButton)
        nextButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            nextButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            nextButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            nextButton.heightAnchor.constraint(equalToConstant: 100),
        ])
        
        //bottom anchor adjustments
        nextButtonBottomConstraint = nextButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -30)
        nextButtonBottomConstraint.isActive = true
        
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
    
    private func setupDismissButton() {
        view.addSubview(dismissButton)
        dismissButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            dismissButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            dismissButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 10),
            dismissButton.widthAnchor.constraint(equalToConstant: 40),
            dismissButton.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
    
    private func setupTimeSelectionView() {
        view.addSubview(timeSelectionView)
        timeSelectionView.translatesAutoresizingMaskIntoConstraints = false
        timeSelectionView.isHidden = true // initially hidden
        
        NSLayoutConstraint.activate([
            timeSelectionView.topAnchor.constraint(equalTo: habitsScrollView.bottomAnchor, constant: 20),
            timeSelectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            timeSelectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
    }
    
    // MARK: Detect Actions
    
    @objc private func textFieldDidChange(_ textField: UITextField) {
        if let text = textField.text, !text.isEmpty {
            filterHabits(with: text)
            nextButton.isEnabled = true
        } else {
            //text field is empty, disable next button
            habitButtons.forEach { $0.isHidden = false }
            nextButton.isEnabled = false
        }
    }
    
    @objc private func habitButtonTapped(_ sender: UIButton) {
        guard let habitName = sender.titleLabel?.text else { return }
        
        habitTextField.text = habitName
        nextButton.isEnabled = true
        filterHabits(with: habitName)
        
        //show time selection view
        timeSelectionView.isHidden = false
        UIView.animate(withDuration: 0.3) { // can add animations later
            self.timeSelectionView.alpha = 1
        }
    }
    
    @objc private func nextButtonTapped() {
        //save habit name
        habitData.habitName = habitTextField.text
        
        //create and push the next view controller
        let setTimeViewController = HabitSetTime()
        setTimeViewController.habitData = habitData
        navigationController?.pushViewController(setTimeViewController, animated: true)
    }
    
    @objc private func dismissSelf() {
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc private func keyboardWillShow(notification: NSNotification) {
        if let keyboardFrame: NSValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
            let keyboardRectangle = keyboardFrame.cgRectValue
            let keyboardHeight = keyboardRectangle.height
            
            //adjust bottom constraints for the button & scrollview
            nextButtonBottomConstraint.constant = -keyboardHeight - 20
            scrollViewBottomConstraint.constant = nextButtonBottomConstraint.constant - 20
            view.layoutIfNeeded()
        }
    }
    
    @objc private func keyboardWillHide(notification: NSNotification) {
        //reset bottom anchor
        nextButtonBottomConstraint.constant = -30
        scrollViewBottomConstraint.constant = -20
        view.layoutIfNeeded()
    }
    
    // MARK: Auxillary Methods
    
    private func filterHabits(with text: String) {
        let lowercasedText = text.lowercased()
        for button in habitButtons {
            let shouldShow = button.titleLabel?.text?.lowercased().contains(lowercasedText) ?? false
            button.isHidden = !shouldShow
        }
    }
    
    private func iconForHabit(name: String) -> UIImage? {
        switch name {
        case "Exercise":
            return UIImage(systemName: "figure.walk")
        case "Read":
            return UIImage(systemName: "book")
        case "Meditate":
            return UIImage(systemName: "leaf")
        case "Journal":
            return UIImage(systemName: "note.text")
        default:
            return UIImage(systemName: "checkmark")
        }
    }
}
