/// The first view controller in the habit creation flow - user indicates which habit they want to track here
///
/// ## Features
///  - Scrollable list of predefined habit suggestions
/// - Text input for custom habits
/// - Filters suggestion list based on user input
/// - Handles navigation to next step in habit creation process
/// - Supports onboarding with guided focus areas
///
/// ## Usage
///  ```swift
/// // Standard usage - instantiate and present
/// let creationVC = SelectHabitViewController()
/// let navController = UINavigationController(rootViewController: creationVC)
/// navController.modalPresentationStyle = .pageSheet
/// present(navController, animated: true, completion: nil)
///
/// // For onboarding - call from OnboardingCoordinator
/// let creationVC = SelectHabitViewController()
/// creationVC.coordinator = self
/// ```

import Foundation
import UIKit

class SelectHabitViewController: UIViewController, UITextFieldDelegate {
    // MARK: - Properties
    weak var coordinator: OnboardingCoordinator?
    var habitData = HabitData()
    var habitButtons: [UIButton] = []
    let predefinedHabits = ["Read", "Meditate", "Skincare Routine", "Learn a New Language", "Journal", "Exercise", "Walk", "Drink More Water", "Wake Up on Time", "Bedtime Routine", "Stretching", "Brush Teeth", "Gym", "Cold Showers", "Yoga", "Quality Time", "Gratitude Journal", "Floss", "Spend Time in Nature", "Pray", "Random Act of Kindness", "Save", "Draw", "Play the Guitar", "Martial Arts", "Take a Break", "Write", "Clean Room", "Water Plants", "Take off Makeup", "Shave", "Feed Pets"]
    
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
    
    /// container for what label, text field, and suggestions label
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
    
    private let dismissButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("x", for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 24)
        button.setTitleColor(.white, for: .normal)
        return button
    }()
    
    // onboarding properties
    /// Button being highlighted with focus view during onboarding process
    private var useDeviceButton: UIButton?
    
    private lazy var focusView: FocusView = {
        let view = FocusView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true
        view.alpha = 0.0
        return view
    }()
    
    /// first label during onboarding
    private lazy var onboardingLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 20, weight: .medium)
        label.textColor = .white
        label.textAlignment = .center
        label.numberOfLines = 0
        label.text = "For your first habit, let's check in on Maow everyday!"
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isHidden = true
        label.alpha = 0.0
        return label
    }()
    
    /// second label during onboarding
    private lazy var nextLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 20, weight: .medium)
        label.textColor = .white
        label.textAlignment = .center
        label.numberOfLines = 0
        label.text = "Let's go to the next page"
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isHidden = true
        label.alpha = 0.0
        return label
    }()
    
    // MARK: - Lifecycle
    
    /// Sets up UI, navigation, and keyboard observers
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
    
    /// handles onboarding focus view
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if coordinator != nil && useDeviceButton != nil {
            showFocusOnUseDevice()
        }
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
    
    /// Sets up a button for each button in predefinedHabits
    /// Adds an additional button during onboarding that is at the top and focusview displays on
    private func setupHabitButtons() {
        if coordinator != nil { // onboarding currently
            let button = createHabitButton(with: "Check in on Maow")
            habitsStackView.addArrangedSubview(button)
            habitButtons.append(button)
            useDeviceButton = button
        }
        
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
    /// sets up observers for keyboard show/hide notifications
    /// Adjusts layout constraints to make sure nothing will be blocked by the keyboard
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
    
    /// adds tap gesture to dismiss keyboard when tapping off the keyboard
    private func setupTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }
    
    /// activate the next button if there is a habit name
    private func updateNextButtonState() {
        nextButton.isEnabled = !(habitData.name?.isEmpty ?? true)
    }
    
    // MARK: - Actions
    /// Handles text change in the text field
    ///
    /// When text is entered:
    /// - Updates or creates custom habit button
    /// - filters the predefined habit list so only the entered habit is present
    /// - updates habit data model
    /// - enables next button
    ///
    /// When text is cleared:
    /// - Removes custom button
    /// - shows all predefined habits again
    /// - disables the next button
    ///
    /// - Parameter textField: text field that changed
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
    
    /// Handles tap on habit buttons
    ///
    /// When a habit button is tapped:
    /// - Updates text field with selected habit name
    /// - filters the predefined habit list
    /// - updates habit data model
    /// - enables the next button
    /// - remove any present focus views (when onboarding)
    ///
    /// - Parameter sender: the button that was tapped
    @objc private func habitButtonTapped(_ sender: UIButton) {
        guard let habitName = sender.titleLabel?.text else { return }
        habitTextField.text = habitName
        
        //updateCustomButton(with: habitName)
        filterHabits(with: habitName)
        
        habitData.name = habitName
        nextButton.isEnabled = true
        
        removeFocus()
    }
    
    /// Handles next button tap and navigates to next VC
    /// - Checks if habit already exists
    ///     - shows alert if the user already has that habit
    /// - creates new vc
    /// - when onboarding, delegates back to the coordinator
    @objc private func nextButtonTapped() {
        if HabitRepository.shared.getHabits().contains(where: { $0.name == habitData.name }) {
            if let habitName = habitData.name {
                let alert = CustomAlertViewController(title: "That habit already exists!",
                                                      message: "You already have \(habitName) as a habit!")
                present(alert, animated: true)
            }
        } else {
            //create and push the next view controller
            if let coordinator = coordinator { // currently onboarding
                coordinator.showHabitTime(habitData: habitData)
            } else {
                let timeVC = SelectTimeViewController()
                
                let backButton = UIBarButtonItem(title: "", style: .plain, target: self, action: #selector(backButtonTapped))
                navigationItem.backBarButtonItem = backButton
                self.navigationController?.navigationBar.tintColor = .white
                
                // send info forward
                timeVC.habitData = habitData
                navigationController?.pushViewController(timeVC, animated: true)
            }
        }
    }
    
    @objc func backButtonTapped() {
        self.navigationController?.popViewController(animated: true)
    }
    
    /// dismisses this view controller
    /// if onboarding, delegates back to coordinator to handle (shouldn't happen)
    @objc private func dismissSelf() {
        if let coordinator = coordinator { // only call if somehow user pressed it during onboarding
            coordinator.dismissHabitCreationFlow(didCompleteHabitCreation: false)
        }
        
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    /// Adjusts scroll view so all habits are visible and not behind keyboard when it appears
    @objc private func keyboardWillShow(notification: NSNotification) {
        if let keyboardFrame: NSValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
            let keyboardRectangle = keyboardFrame.cgRectValue
            let keyboardHeight = keyboardRectangle.height
            scrollView.contentInset.bottom = keyboardHeight
            scrollView.verticalScrollIndicatorInsets.bottom = keyboardHeight
        }
    }
    
    /// Resets scroll view constraints when keyboard is dismissed
    @objc private func keyboardWillHide(notification: NSNotification) {
        scrollView.contentInset.bottom = 0
        scrollView.verticalScrollIndicatorInsets.bottom = 0
    }
    
    // MARK: - Onboarding
    /// Highlights recommended habit button during onboarding
    ///
    /// - Creates overlay with highlighted area around button
    /// - Displays instructional label to inform user
    /// - Animates appearance and disappearance of both
    /// - Adds tap gesture to the highlighted button
    func showFocusOnUseDevice() {
        guard let useDeviceButton = useDeviceButton else { return }
        guard let window = view.window else { return }
        
        window.addSubview(focusView)
        focusView.shapeType = .roundedRect(cornerRadius: 12)
        focusView.frame = window.bounds
        focusView.isUserInteractionEnabled = true
        
        // convert frame to coords
        let buttonFrame = useDeviceButton.convert(useDeviceButton.bounds, to: window)
        focusView.ovalRect = buttonFrame.insetBy(dx: -4, dy: -4)
        
        // add label to window
        window.addSubview(onboardingLabel)
        onboardingLabel.isUserInteractionEnabled = false
        
        // position label
        NSLayoutConstraint.activate([
            onboardingLabel.topAnchor.constraint(equalTo: window.safeAreaLayoutGuide.topAnchor, constant: buttonFrame.maxY + 20),
            onboardingLabel.centerXAnchor.constraint(equalTo: window.centerXAnchor),
            onboardingLabel.leadingAnchor.constraint(equalTo: window.leadingAnchor, constant: 20),
            onboardingLabel.trailingAnchor.constraint(equalTo: window.trailingAnchor, constant: -20)
        ])
        
        // animate appearance
        onboardingLabel.alpha = 0.0
        onboardingLabel.isHidden = false
        focusView.alpha = 0.0
        focusView.isHidden = false
        
        UIView.animate(withDuration: 0.3) {
            print("animating")
            self.onboardingLabel.alpha = 1.0
            self.focusView.alpha = 1.0
        }
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(focusViewTapped(_:)))
        focusView.addGestureRecognizer(tapGesture)
    }
    
    /// Handles taps on habit button focus view during onboarding
    ///
    /// If tap is within highlighted area
    /// - triggers habit button action
    /// - shows next button focus view after a delay
    ///
    /// - Parameter gesture: tap gesture recognizer
    @objc private func focusViewTapped(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: focusView)
        
        let isInHighlightedArea: Bool
        
        if let useDeviceButton = useDeviceButton, let window = view.window {
            let buttonFrame = useDeviceButton.convert(useDeviceButton.bounds, to: window)
            let paddedFrame = buttonFrame.insetBy(dx: -4, dy: -4)
            
            switch focusView.shapeType {
            case .roundedRect(let cornerRadius):
                isInHighlightedArea = paddedFrame.contains(location)
            default:
                isInHighlightedArea = false
            }
        } else {
            isInHighlightedArea = false
        }
        
        // only trigger if tap is within highlighted area
        if isInHighlightedArea {
            if let useDeviceButton = useDeviceButton {
                habitButtonTapped(useDeviceButton)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                    self?.showFocusViewOnNext()
                }
            }
        }
    }
    
    /// Highlights next button during onboarding
    ///
    /// - Creates overlay with highlighted area around button
    /// - Displays instructional label to inform user
    /// - Animates appearance and disappearance of both
    /// - Adds tap gesture to the highlighted button
    private func showFocusViewOnNext() {
        guard let window = view.window else { return }
        
        window.addSubview(focusView)
        focusView.shapeType = .roundedRect(cornerRadius: 12)
        focusView.frame = window.bounds
        focusView.isUserInteractionEnabled = true
        
        // convert frame to coords
        let buttonFrame = nextButton.convert(nextButton.bounds, to: window)
        focusView.ovalRect = buttonFrame.insetBy(dx: -4, dy: -4)
        
        // add label to window
        window.addSubview(nextLabel)
        nextLabel.isUserInteractionEnabled = false
        
        // position label
        NSLayoutConstraint.activate([
            nextLabel.topAnchor.constraint(equalTo: window.safeAreaLayoutGuide.topAnchor, constant: buttonFrame.minY - 100),
            nextLabel.centerXAnchor.constraint(equalTo: window.centerXAnchor),
            nextLabel.leadingAnchor.constraint(equalTo: window.leadingAnchor, constant: 20),
            nextLabel.trailingAnchor.constraint(equalTo: window.trailingAnchor, constant: -20)
        ])
        
        // animate appearance
        nextLabel.alpha = 0.0
        nextLabel.isHidden = false
        focusView.alpha = 0.0
        focusView.isHidden = false
        
        UIView.animate(withDuration: 0.3) {
            self.nextLabel.alpha = 1.0
            self.focusView.alpha = 1.0
        }
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(focusViewNextTapped(_:)))
        focusView.addGestureRecognizer(tapGesture)
    }
    
    /// Handles taps on next button focus view during onboarding
    ///
    /// If tap is within highlighted area
    /// - triggers next button action
    /// - removes focus view
    ///
    /// - Parameter gesture: tap gesture recognizer
    @objc private func focusViewNextTapped(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: focusView)
        
        let isInHighlightedArea: Bool
        
        if let window = view.window {
            let buttonFrame = nextButton.convert(nextButton.bounds, to: window)
            let paddedFrame = buttonFrame.insetBy(dx: -4, dy: -4)
            
            switch focusView.shapeType {
            case .roundedRect(let cornerRadius):
                isInHighlightedArea = paddedFrame.contains(location)
            default:
                isInHighlightedArea = false
            }
        } else {
            isInHighlightedArea = false
        }
        
        // only trigger if tap is within highlighted area
        if isInHighlightedArea {
            nextButtonTapped()
            DispatchQueue.main.asyncAfter(deadline: .now()) { [weak self] in
                self?.removeFocus()
            }
        }
    }
    
    /// Animates the disappearance of focus views
    private func removeFocus() {
        guard let window = view.window else { return }
        
        UIView.animate(withDuration: 0.3, animations: {
            self.onboardingLabel.alpha = 0.0
            self.nextLabel.alpha = 0.0
            self.focusView.alpha = 0.0
        }, completion: { _ in
            // clean up window level views
            for subview in window.subviews {
                if subview is FocusView || subview == self.onboardingLabel || subview == self.nextLabel {
                    subview.removeFromSuperview()
                }
            }
        })
    }
    
    // MARK: - Auxillary Methods
    /// Filters habit button based on text typed in from text field
    /// Only show buttons whose titles contains partial or complete amount of text
    ///
    /// - Parameter text: The text to filter by
    private func filterHabits(with text: String) {
        let lowercasedText = text.lowercased()
        for button in habitButtons {
            if let buttonTitle = button.titleLabel?.text {
                let shouldShow = buttonTitle.lowercased().contains(lowercasedText)
                button.isHidden = !shouldShow
            }
        }
    }
    
    /// Updates or creates a custom habit button with given text
    ///
    /// If no custom button exists yet, create one an dinsert it at the top
    /// if custom button already exists, update its title and icon
    ///
    /// - Parameter text: The text for custom button
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
    
    /// Removes custom habit button from view hierarchy
    private func removeCustomButton() {
        customButton?.removeFromSuperview()
        customButton = nil
        isShowingCustomButton = false
    }
}
