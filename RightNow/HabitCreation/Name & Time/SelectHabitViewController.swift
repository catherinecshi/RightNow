/**
 This is the first view controller when the user creates a habit. The user indicates which habit they want to track with the app here.
It supports users putting in their own habits via the textfield or a list of predefined habits shown at the start. Either way the code
 */

import Foundation
import UIKit

class SelectHabitViewController: UIViewController, UITextFieldDelegate {
    // MARK: - Declaration
    var habitData = HabitData()
    var habitButtons: [UIButton] = []
    let predefinedHabits = ["Read", "Meditate", "Skincare Routine", "Learn a New Language", "Journal", "Exercise", "Walk", "Drink More Water", "Wake Up on Time", "Bedtime Routine", "Stretching", "Brush Teeth", "Gym", "Cold Showers", "Yoga", "Quality Time", "Gratitude Journal", "Floss", "Spend Time in Nature", "Pray", "Random Act of Kindness", "Save", "Draw", "Play the Guitar", "Martial Arts", "Take a Break", "Write", "Rumination", "Clean Room", "Water Plants", "Take off Makeup", "Shave", "Feed Pets"]
    
    // for when the user inserts their own habit
    private var customButton: UIButton?
    private var isShowingCustomButton = false
    
    //initiate labels
    let viewTitle: UILabel = {
        let label = UILabel()
        label.text = "Create Habit"
        label.font = UIConfiguration.titleFont
        label.textColor = .white
        label.textAlignment = .center
        return label
    }()
    
    private lazy var scrollableContentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = true
        scrollView.alwaysBounceVertical = true
        return scrollView
    }()
    
    private let whatLabel: UILabel = {
        let label = UILabel()
        label.text = "Which Habit do You Want to Start?"
        label.font = UIConfiguration.subtitleFont
        label.textColor = .white
        return label
    }()
    
    private let habitTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Enter your habit"
        textField.borderStyle = .roundedRect
        textField.clearButtonMode = .whileEditing
        return textField
    }()
    
    private let suggestionsLabel: UILabel = {
        let label = UILabel()
        label.text = "Suggestions:"
        label.font = UIConfiguration.subtitleFont
        label.textColor = .white
        label.textAlignment = .left
        return label
    }()
    
    private lazy var fixedStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 20
        stack.distribution = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    private let habitsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 10
        stackView.alignment = .fill
        stackView.distribution = .fill
        return stackView
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
    
    //button to x out
    private let dismissButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("x", for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 24)
        button.setTitleColor(.white, for: .normal)
        return button
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIConfiguration.tintColor
        
        setupTitle()
        setupNextButton()
        setupFixedStackView()
        setupScrollView()
        setupHabitButtons()
        setupDismissButton()
        
        setupKeyboardObservers()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        //showUseDeviceFocus()
    }
    
    // MARK: - Setup UI
    
    private func setupTitle() {
        view.addSubview(viewTitle)
        viewTitle.translatesAutoresizingMaskIntoConstraints = false
        
        //make sure it can go to multiple lines if squished
        viewTitle.numberOfLines = 0 //allows line breaks
        viewTitle.lineBreakMode = .byWordWrapping //breaks lines by words, not characters
        
        self.navigationItem.titleView = viewTitle
    }
    
    private func setupFixedStackView() {
        [whatLabel, habitTextField, suggestionsLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            fixedStackView.addArrangedSubview($0)
        }
        
        view.addSubview(fixedStackView)
        
        NSLayoutConstraint.activate([
            fixedStackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            fixedStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            fixedStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
        
        habitTextField.delegate = self
        habitTextField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
    }
    
    private func setupScrollView() {
        view.addSubview(scrollView)
        scrollView.addSubview(habitsStackView)
        habitsStackView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: fixedStackView.bottomAnchor, constant: 20),
            scrollView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            scrollView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            scrollView.bottomAnchor.constraint(equalTo: nextButton.topAnchor, constant: -20),
            
            habitsStackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            habitsStackView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            habitsStackView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            habitsStackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            habitsStackView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor)
        ])
    }
    
    private func setupHabitButtons() {
        for habit in predefinedHabits {
            let button = createHabitButton(with: habit)
            habitsStackView.addArrangedSubview(button)
            habitButtons.append(button)
        }
    }
    
    private func createHabitButton(with title: String) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .white
        button.layer.cornerRadius = 10
        button.clipsToBounds = true
        button.layer.borderWidth = 1
        button.layer.borderColor = UIConfiguration.tintColor?.cgColor
        button.contentHorizontalAlignment = .leading
        
        let icon = HabitIconUtility.icon(for: title)
        button.setImage(icon, for: .normal)
        button.imageView?.contentMode = .scaleAspectFit
        button.tintColor = UIConfiguration.tintColor
        
        var configuration = UIButton.Configuration.filled()
        configuration.imagePlacement = .leading
        configuration.imagePadding = 10
        configuration.titleAlignment = .leading
        configuration.titlePadding = 10
        button.configuration = configuration
        
        button.addTarget(self, action: #selector(habitButtonTapped), for: .touchUpInside)
        
        return button
    }
    
    private func setupNextButton() {
        //add to view
        view.addSubview(nextButton)
        nextButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            nextButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            nextButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            nextButton.heightAnchor.constraint(equalToConstant: 100),
            nextButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -30)
        ])
        
        //add action
        nextButton.addTarget(self, action: #selector(nextButtonTapped), for: .touchUpInside)
    }
    
    private func setupDismissButton() {
        dismissButton.translatesAutoresizingMaskIntoConstraints = false
        
        let dismissBarButton = UIBarButtonItem(customView: dismissButton)
        self.navigationItem.leftBarButtonItem = dismissBarButton
        
        // add action
        dismissButton.addTarget(self, action: #selector(dismissSelf), for: .touchUpInside)
    }
    
    // MARK: - Observers
    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillShow),
                                               name: UIResponder.keyboardWillShowNotification,
                                               object:nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillHide),
                                               name: UIResponder.keyboardWillHideNotification,
                                               object:nil)
    }
    
    private func setupTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }
    
    //activate the next button if there is a habit name
    private func updateNextButtonState() {
        nextButton.isEnabled = !(habitData.name?.isEmpty ?? true)
    }
    
    // MARK: - Actions
    @objc private func textFieldDidChange(_ textField: UITextField) {
        if let text = textField.text, !text.isEmpty {
            updateCustomButton(with: text)
            filterHabits(with: text)
            habitData.name = text
            nextButton.isEnabled = true
        } else {
            removeCustomButton()
            habitButtons.forEach { $0.isHidden = false }
            nextButton.isEnabled = false
        }
    }
    
    @objc private func habitButtonTapped(_ sender: UIButton) {
        guard let habitName = sender.titleLabel?.text else { return }
        habitTextField.text = habitName
        
        //updateCustomButton(with: habitName)
        filterHabits(with: habitName)
        
        habitData.name = habitName
        nextButton.isEnabled = true
    }
    
    @objc private func nextButtonTapped() {
        if HabitListViewModel.shared.habits.contains(where: { $0.name == habitData.name }) {
            if let habitName = habitData.name {
                let alert = CustomAlertViewController(title: "That habit already exists!",
                                                      message: "You already have \(habitName) as a habit!")
                present(alert, animated: true)
            }
        } else {
            //create and push the next view controller
            let timeVC = SelectTimeViewController()
            
            // back button
            let backButton = UIBarButtonItem(title: "", style: .plain, target: self, action: #selector(backButtonTapped))
            navigationItem.backBarButtonItem = backButton
            self.navigationController?.navigationBar.tintColor = .white
            
            // send info forward
            timeVC.habitData = habitData
            navigationController?.pushViewController(timeVC, animated: true)
        }
    }
    
    @objc func backButtonTapped() {
        self.navigationController?.popViewController(animated: true)
    }
    
    @objc private func dismissSelf() {
        print("trying to dismiss")
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @objc private func keyboardWillShow(notification: NSNotification) {
        if let keyboardFrame: NSValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
            let keyboardRectangle = keyboardFrame.cgRectValue
            let keyboardHeight = keyboardRectangle.height
            scrollView.contentInset.bottom = keyboardHeight
            scrollView.verticalScrollIndicatorInsets.bottom = keyboardHeight
        }
    }
    
    @objc private func keyboardWillHide(notification: NSNotification) {
        scrollView.contentInset.bottom = 0
        scrollView.verticalScrollIndicatorInsets.bottom = 0
    }
    
    // MARK: - Auxillary Methods
    private func filterHabits(with text: String) {
        let lowercasedText = text.lowercased()
        for button in habitButtons {
            if let buttonTitle = button.titleLabel?.text {
                let shouldShow = buttonTitle.lowercased().contains(lowercasedText)
                button.isHidden = !shouldShow
            }
        }
    }
    
    private func updateCustomButton(with text: String) {
        if !isShowingCustomButton {
            let button = createHabitButton(with: text)
            customButton = button
            
            // insert at top of stack view
            habitsStackView.insertArrangedSubview(button, at: 0)
            isShowingCustomButton = true
        } else {
            // update existing button
            customButton?.setTitle(text, for: .normal)
            let icon = HabitIconUtility.icon(for: text)
            customButton?.setImage(icon, for: .normal)
        }
        
        customButton?.isHidden = false
    }
    
    private func removeCustomButton() {
        customButton?.removeFromSuperview()
        customButton = nil
        isShowingCustomButton = false
    }
}
