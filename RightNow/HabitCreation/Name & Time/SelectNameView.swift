import Foundation
import UIKit

protocol SelectNameDelegate: AnyObject {
    func habitSelected(_ habit: String)
    
    func shouldAdjustHeight()
}

class SelectNameView: UIView, UITextFieldDelegate {
    // MARK: Declaration
    weak var delegate: SelectNameDelegate?
    
    // might be artifacts of trying to fix the problem with equalorlessthan - don't delete tho
    private var scrollViewBottomConstraint: NSLayoutConstraint!
    
    // some generic habit variables
    var habitButtons: [UIButton] = []
    let habitTextField = UITextField()
    let predefinedHabits = ["Read", "Meditate", "Journal", "Exercise", "Walk"]
    let habitCount = 5
    
    // for the onboarding process
    private var focusView: FocusView?
    private var useDeviceButton: UIButton?
    
    private var onboardingLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 20, weight: .medium)
        label.textColor = .white
        label.textAlignment = .center
        label.numberOfLines = 0
        label.text = "For your first habit, let's get used to using RightNow."
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isHidden = true
        label.alpha = 0.0
        return label
    }()
    
    //initiate labels
    let whatLabel: UILabel = {
        let label = UILabel()
        label.text = "Which Habit do You Want to Start?"
        label.font = UIConfiguration.subtitleFont
        label.textColor = .white
        //label.textAlignment = .center
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
        stackView.distribution = .fill
        return stackView
    }()
    
    // MARK: Initialisation
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIConfiguration.tintColor
        
        setupWhatSubtitle()
        setupHabitTextField()
        setupSuggestionSubtitle()
        setupHabitButtons()
        
        //observe keyboard actions
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Setup UI
    
    private func setupWhatSubtitle() {
        self.addSubview(whatLabel)
        whatLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            whatLabel.topAnchor.constraint(equalTo: self.topAnchor, constant: 20),
            whatLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 20),
            whatLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -20),
            whatLabel.heightAnchor.constraint(equalToConstant: 22) // value taken from the natural height
        ])
    }
    
    private func setupHabitTextField() {
        habitTextField.placeholder = "Enter your habit"
        habitTextField.borderStyle = .roundedRect
        habitTextField.delegate = self
        habitTextField.clearButtonMode = .whileEditing //clear button
        
        //add to view
        self.addSubview(habitTextField)
        habitTextField.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            habitTextField.topAnchor.constraint(equalTo: whatLabel.bottomAnchor, constant: 20),
            habitTextField.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 20),
            habitTextField.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -20),
            habitTextField.heightAnchor.constraint(equalToConstant: 40)
        ])
        
        //target to capture text changes
        habitTextField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        
        /*
        habitTextField.layer.backgroundColor = UIColor.white.cgColor
        habitTextField.layer.cornerRadius = 5
        habitTextField.layer.masksToBounds = true
        habitTextField.layer.borderWidth = 1.0
         */
        //weird border color with this
    }
    
    private func setupSuggestionSubtitle() {
        self.addSubview(suggestionsLabel)
        suggestionsLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            suggestionsLabel.topAnchor.constraint(equalTo: habitTextField.bottomAnchor, constant: 20),
            suggestionsLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 20),
            suggestionsLabel.heightAnchor.constraint(equalToConstant: 22)
        ])
    }
    
    private func setupHabitButtons() {
        self.addSubview(habitsScrollView)
        habitsScrollView.addSubview(habitsStackView)
        habitsStackView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            habitsScrollView.topAnchor.constraint(equalTo: suggestionsLabel.bottomAnchor, constant: 20),
            habitsScrollView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 20),
            habitsScrollView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -20),
            
            habitsStackView.topAnchor.constraint(equalTo: habitsScrollView.topAnchor),
            habitsStackView.leadingAnchor.constraint(equalTo: habitsScrollView.leadingAnchor),
            habitsStackView.trailingAnchor.constraint(equalTo: habitsScrollView.trailingAnchor),
            habitsStackView.bottomAnchor.constraint(equalTo: habitsScrollView.bottomAnchor),
            habitsStackView.widthAnchor.constraint(equalTo: habitsScrollView.widthAnchor),
        ])
        
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
            
            // for onboarding
            if habit == "Use Device" {
                useDeviceButton = button
            }
            
            
            habitsStackView.addArrangedSubview(button)
            habitButtons.append(button)
        }
        
        // setting up the dynamic bottom constraint
        let contentHeight = calculateStackViewContentHeight()
        let spacing = CGFloat(10 * habitCount)
        let total = contentHeight + spacing
        
        scrollViewBottomConstraint = habitsScrollView.bottomAnchor.constraint(equalTo: habitsScrollView.topAnchor, constant: total)
        scrollViewBottomConstraint.priority = UILayoutPriority(750)
        scrollViewBottomConstraint.isActive = true
    }
    
    // MARK: Detect Actions
    
    @objc private func textFieldDidChange(_ textField: UITextField) {
        if let text = textField.text, !text.isEmpty {
            filterHabits(with: text)
            delegate?.habitSelected(text) // send to habitData in main VC
            
            updateContentView()
        } else {
            //text field is empty, disable next button
            habitButtons.forEach { $0.isHidden = false }
            updateContentView()
        }
    }
    
    @objc private func habitButtonTapped(_ sender: UIButton) {
        print("Habit button tapped")
        guard let habitName = sender.titleLabel?.text else { return }
        
        habitTextField.text = habitName
        filterHabits(with: habitName)
        delegate?.habitSelected(habitName) // send to habitData in main VC
        updateContentView()
        //removeFocus()
    }
    
    @objc private func keyboardWillShow(notification: NSNotification) {
        if let keyboardFrame: NSValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
            let keyboardRectangle = keyboardFrame.cgRectValue
            let keyboardHeight = keyboardRectangle.height
            
            scrollViewBottomConstraint.constant = keyboardHeight + 20
            updateContentView()
        }
    }
    
    @objc private func keyboardWillHide(notification: NSNotification) {
        //reset bottom anchor
        scrollViewBottomConstraint.constant = 20
        updateContentView()
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
        case "Read":
            return UIImage(systemName: "book")
        case "Meditate":
            return UIImage(systemName: "leaf")
        case "Journal":
            return UIImage(systemName: "note.text")
        case "Exercise":
            return UIImage(systemName: "figure.walk")
        default:
            return UIImage(systemName: "checkmark")
        }
    }
    
    // for calculating the height that should be sent to the main VC
    private func calculateStackViewContentHeight() -> CGFloat {
        // top and bottom padding of the stackview
        var totalHeight = CGFloat(20 + (habitCount * 20))
        
        let visibleSubviews = habitsStackView.arrangedSubviews.filter { !$0.isHidden }
        let spacing = habitsStackView.spacing
        
        //calculate height of visible items
        for item in visibleSubviews {
            totalHeight += item.frame.size.height
        }
        
        // add spacing between items
        if visibleSubviews.count > 1 {
            totalHeight += CGFloat(visibleSubviews.count - 1) * spacing
        }
        
        return totalHeight
    }
    
    //potentially a detrimental method. commented out for now in places where it's called - updateContentView
    private func updateScrollViewBottomConstraint() {
        let contentHeight = calculateStackViewContentHeight()
        let spacing = CGFloat(10 * habitCount)
        let total = contentHeight + spacing
        
        scrollViewBottomConstraint.constant = total
    }
    
    // for onboarding
    public func showFocusOnUseDevice() {
        guard let useDeviceButton = useDeviceButton else { return }
        guard let window = window else { return }
        
        // Remove existing views
        focusView?.removeFromSuperview()
        onboardingLabel.removeFromSuperview()
        
        // Create and setup focus view
        focusView = FocusView()
        guard let focusView = focusView else { return }
        
        // Add focus view to window
        window.addSubview(focusView)
        focusView.frame = window.bounds
        focusView.isUserInteractionEnabled = false
        
        let buttonFrame = useDeviceButton.convert(useDeviceButton.bounds, to: window)
        focusView.ovalRect = buttonFrame.insetBy(dx: -4, dy: -4)
        
        // Add label to window instead of self
        window.addSubview(onboardingLabel)
        onboardingLabel.isUserInteractionEnabled = false
        
        // Convert the button's frame to window coordinates for positioning the label
        NSLayoutConstraint.activate([
            onboardingLabel.topAnchor.constraint(equalTo: window.safeAreaLayoutGuide.topAnchor, constant: buttonFrame.maxY + 20),
            onboardingLabel.centerXAnchor.constraint(equalTo: window.centerXAnchor),
            onboardingLabel.leadingAnchor.constraint(equalTo: window.leadingAnchor, constant: 40),
            onboardingLabel.trailingAnchor.constraint(equalTo: window.trailingAnchor, constant: -40)
        ])
        
        // Animate the label appearance
        onboardingLabel.alpha = 0.0
        onboardingLabel.isHidden = false
        
        UIView.animate(withDuration: 0.3) {
            self.onboardingLabel.alpha = 1.0
        }
    }
    
    public func removeFocus() {
        print("remove focus called")
        UIView.animate(withDuration: 0.3, animations: {
            self.onboardingLabel.alpha = 0.0
            self.focusView?.alpha = 0.0
        }, completion: { _ in
            // Then clean up any window-level views
           if let window = self.window {
               for subview in window.subviews {
                   if subview is FocusView || subview == self.onboardingLabel {
                       subview.removeFromSuperview()
                   }
               }
           }
           self.focusView = nil
        })
    }
    
    // MARK: Intrinsic Content Size for Subview
    
    override var intrinsicContentSize: CGSize {
        self.layoutIfNeeded() // makes sure layout is updated before calculation
        let height = calculateContentHeight()
        return CGSize(width: UIView.noIntrinsicMetric, height: height)
    }
    
    func calculateContentHeight() -> CGFloat {
        //calculate height to feed back into main vc such that height is declared for this subview
        let staticHeight = whatLabel.frame.height + habitTextField.frame.height + suggestionsLabel.frame.height + 20
        let dynamicScrollHeight = calculateStackViewContentHeight()
        let totalHeight = staticHeight + dynamicScrollHeight
        return totalHeight
    }
    
    private func updateContentView() {
        //invalidateIntrinsicContentSize()
        delegate?.shouldAdjustHeight()
        updateScrollViewBottomConstraint()
        self.layoutIfNeeded()
    }
}
