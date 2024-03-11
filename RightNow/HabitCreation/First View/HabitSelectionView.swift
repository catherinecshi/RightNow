import Foundation
import UIKit

protocol HabitSelectionDelegate: AnyObject {
    func habitSelected(_ habit: String)
    
    func shouldAdjustHeight()
}

class HabitSelectionView: UIView, UITextFieldDelegate {
    // MARK: Declaration
    weak var delegate: HabitSelectionDelegate?
    
    // might be artifacts of trying to fix the problem with equalorlessthan - don't delete tho
    private var scrollViewBottomConstraint: NSLayoutConstraint!
    
    // some generic habit variables
    var habitButtons: [UIButton] = []
    let habitTextField = UITextField()
    let predefinedHabits = ["Read", "Meditate", "Journal", "Exercise"]
    let habitCount = 4
    
    //initiate labels
    let whatLabel: UILabel = {
        let label = UILabel()
        label.text = "What Habit do You Want to Start?"
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
            suggestionsLabel.topAnchor.constraint(equalTo: habitTextField.bottomAnchor, constant: 40),
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
        guard let habitName = sender.titleLabel?.text else { return }
        
        habitTextField.text = habitName
        filterHabits(with: habitName)
        delegate?.habitSelected(habitName) // send to habitData in main VC
        updateContentView()
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
