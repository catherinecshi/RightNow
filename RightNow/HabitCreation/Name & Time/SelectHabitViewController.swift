import Foundation
import UIKit

class SelectHabitViewController: UIViewController, UITextFieldDelegate {
    // MARK: - Declaration
    var habitData = HabitData()
    var habitButtons: [UIButton] = []
    let predefinedHabits = ["Read", "Meditate", "Journal", "Exercise", "Walk"]
    
    //initiate labels
    let viewTitle: UILabel = {
        let label = UILabel()
        label.text = "Create Habit"
        label.font = UIConfiguration.titleFont
        label.textColor = .white
        label.textAlignment = .center
        return label
    }()
    
    private let scrollView = UIScrollView()
    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 20
        stack.distribution = .fill
        return stack
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
        setupScrollView()
        setupContentStack()
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
    
    private func setupScrollView() {
        view.addSubview(scrollView)
        view.addSubview(stackView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            scrollView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            scrollView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            scrollView.bottomAnchor.constraint(equalTo: nextButton.topAnchor),
            
            stackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            stackView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor)
        ])
    }
    
    private func setupContentStack() {
        [whatLabel, habitTextField, suggestionsLabel, habitsStackView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            stackView.addArrangedSubview($0)
        }
        
        habitTextField.delegate = self
        habitTextField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
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
        
        let icon = iconForHabit(name: title)
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
            nextButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            nextButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
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
            filterHabits(with: text)
            habitData.name = text
            nextButton.isEnabled = true
        } else {
            habitButtons.forEach { $0.isHidden = false }
            nextButton.isEnabled = false
        }
    }
    
    @objc private func habitButtonTapped(_ sender: UIButton) {
        guard let habitName = sender.titleLabel?.text else { return }
        habitTextField.text = habitName
        filterHabits(with: habitName)
        habitData.name = habitName
        nextButton.isEnabled = true
    }
    
    @objc private func nextButtonTapped() {
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
    private func iconForHabit(name: String) -> UIImage? {
        switch name {
        case "Read": return UIImage(systemName: "book")
        case "Meditate": return UIImage(systemName: "leaf")
        case "Journal": return UIImage(systemName: "note.text")
        case "Exercise": return UIImage(systemName: "figure.walk")
        default: return UIImage(systemName: "checkmark")
        }
    }
    
    private func filterHabits(with text: String) {
        let lowercasedText = text.lowercased()
        for button in habitButtons {
            let shouldShow = button.titleLabel?.text?.lowercased().contains(lowercasedText) ?? false
            button.isHidden = !shouldShow
        }
    }
}
