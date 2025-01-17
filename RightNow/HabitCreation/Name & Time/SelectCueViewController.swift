import Foundation
import UIKit

protocol SelectCueDelegate: AnyObject {
    func cueSelected(_ cue: String)
    
    func daySelectedCues(_ days: [String: Bool])
}

class SelectCueView: UIView, UITextFieldDelegate {
    // MARK: Declaration
    weak var delegate: SelectCueDelegate?
    
    // might be artifacts of trying to fix the problem with equalorlessthan - don't delete tho
    private var scrollViewBottomConstraint: NSLayoutConstraint!
    
    // some generic habit variables
    var cueButtons: [UIButton] = []
    let cueTextField = UITextField()
    let cueCount = HabitListViewModel.shared.habits.count
    
    let daysOfWeek = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    var selectedDays = [String: Bool]()
    
    let daysLabel: UILabel = {
        let label = UILabel()
        label.text = "Which Days do You Want to do this Habit?"
        label.font = UIConfiguration.subtitleFont
        label.textColor = .white
        label.textAlignment = .center
        return label
    }()
    
    let daysStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = 5
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    //initiate labels
    let whatLabel: UILabel = {
        let label = UILabel()
        label.text = "What cue do you want to be reminded by?"
        label.font = UIConfiguration.subtitleFont
        label.textColor = .white
        //label.textAlignment = .center
        return label
    }()
    
    let suggestionsLabel: UILabel = {
        let label = UILabel()
        label.text = "Or do you want to chain it with a pre-existing habit?"
        label.font = UIConfiguration.subtitleFont
        label.textColor = .white
        label.textAlignment = .center
        return label
    }()
    
    //for the stack to be able to scroll inside this view
    let cuesScrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()
    
    //stack to hold habit buttons
    let cuesStackView: UIStackView = {
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
        
        setupDaysSubtitle()
        setupDaysStackView()
        setupWhatSubtitle()
        setupCueTextField()
        setupSuggestionSubtitle()
        setupCueButtons()
        
        //observe keyboard actions
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Setup UI
    
    private func setupDaysSubtitle() {
        self.addSubview(daysLabel)
        daysLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            daysLabel.topAnchor.constraint(equalTo: self.topAnchor, constant: 20),
            daysLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 20),
            daysLabel.heightAnchor.constraint(equalToConstant: 22)
        ])
    }
    
    private func setupDaysStackView() {
        self.addSubview(daysStackView)
        
        for day in daysOfWeek {
            let button = UIButton()
            button.setTitle(day, for: .normal)
            button.setTitleColor(UIConfiguration.tintColor, for: .normal)
            button.setTitleColor(UIConfiguration.tintColor, for: .selected)
            button.backgroundColor = .lightGray
            button.layer.cornerRadius = 5
            button.addTarget(self, action: #selector(dayButtonTapped), for: .touchUpInside)
            daysStackView.addArrangedSubview(button)
        }
        
        NSLayoutConstraint.activate([
            daysStackView.topAnchor.constraint(equalTo: daysLabel.bottomAnchor, constant: 20),
            daysStackView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 20),
            daysStackView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -20),
            daysStackView.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
    
    private func setupWhatSubtitle() {
        self.addSubview(whatLabel)
        whatLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            whatLabel.topAnchor.constraint(equalTo: daysStackView.bottomAnchor, constant: 40),
            whatLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 20),
            whatLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -20),
            whatLabel.heightAnchor.constraint(equalToConstant: 22) // value taken from the natural height
        ])
    }
    
    private func setupCueTextField() {
        cueTextField.placeholder = "Enter your cue"
        cueTextField.borderStyle = .roundedRect
        cueTextField.delegate = self
        cueTextField.clearButtonMode = .whileEditing //clear button
        
        //add to view
        self.addSubview(cueTextField)
        cueTextField.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            cueTextField.topAnchor.constraint(equalTo: whatLabel.bottomAnchor, constant: 20),
            cueTextField.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 20),
            cueTextField.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -20),
            cueTextField.heightAnchor.constraint(equalToConstant: 40)
        ])
        
        //target to capture text changes
        cueTextField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
    }
    
    private func setupSuggestionSubtitle() {
        self.addSubview(suggestionsLabel)
        suggestionsLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            suggestionsLabel.topAnchor.constraint(equalTo: cueTextField.bottomAnchor, constant: 40),
            suggestionsLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 20),
            suggestionsLabel.heightAnchor.constraint(equalToConstant: 22)
        ])
    }
    
    private func setupCueButtons() {
        self.addSubview(cuesScrollView)
        cuesScrollView.addSubview(cuesStackView)
        cuesStackView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            cuesScrollView.topAnchor.constraint(equalTo: suggestionsLabel.bottomAnchor, constant: 20),
            cuesScrollView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 20),
            cuesScrollView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -20),
            
            cuesStackView.topAnchor.constraint(equalTo: cuesScrollView.topAnchor),
            cuesStackView.leadingAnchor.constraint(equalTo: cuesScrollView.leadingAnchor),
            cuesStackView.trailingAnchor.constraint(equalTo: cuesScrollView.trailingAnchor),
            cuesStackView.bottomAnchor.constraint(equalTo: cuesScrollView.bottomAnchor),
            cuesStackView.widthAnchor.constraint(equalTo: cuesScrollView.widthAnchor),
        ])
        
        for existingHabit in HabitListViewModel.shared.habits {
            let button = UIButton(type: .system)
            button.setTitle(existingHabit.name, for: .normal)
            button.setTitleColor(.white, for: .normal)
            button.backgroundColor = .white
            button.layer.cornerRadius = 10
            button.clipsToBounds = true //for rounded radius
            button.layer.borderWidth = 1
            button.layer.borderColor = UIConfiguration.tintColor?.cgColor
            
            //set up image
            let icon = iconForCues(name: existingHabit.name) //method
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
            
            button.addTarget(self, action: #selector(cueButtonTapped), for: .touchUpInside)
            cuesStackView.addArrangedSubview(button)
            cueButtons.append(button)
        }
        
        // setting up the dynamic bottom constraint
        let contentHeight = calculateStackViewContentHeight()
        let spacing = CGFloat(10 * cueCount)
        let total = contentHeight + spacing
        
        scrollViewBottomConstraint = cuesScrollView.bottomAnchor.constraint(equalTo: cuesScrollView.topAnchor, constant: total)
        scrollViewBottomConstraint.priority = UILayoutPriority(750)
        scrollViewBottomConstraint.isActive = true
    }
    
    // MARK: Detect Actions
    
    @objc private func textFieldDidChange(_ textField: UITextField) {
        if let text = textField.text, !text.isEmpty {
            filterCues(with: text)
            delegate?.cueSelected(text) // send to habitData in main VC
        } else {
            //text field is empty, disable next button
            cueButtons.forEach { $0.isHidden = false }
        }
    }
    
    @objc private func cueButtonTapped(_ sender: UIButton) {
        guard let cueName = sender.titleLabel?.text else { return }
        
        cueTextField.text = cueName
        filterCues(with: cueName)
        delegate?.cueSelected(cueName) // send to habitData in main VC
    }
    
    @objc private func dayButtonTapped(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        sender.backgroundColor = sender.isSelected ? .white : .lightGray
        selectedDays[sender.titleLabel?.text ?? ""] = sender.isSelected
        
        //update main vc
        delegate?.daySelectedCues(selectedDays)
    }
    
    @objc private func keyboardWillShow(notification: NSNotification) {
        if let keyboardFrame: NSValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
            let keyboardRectangle = keyboardFrame.cgRectValue
            let keyboardHeight = keyboardRectangle.height
            
            scrollViewBottomConstraint.constant = keyboardHeight + 20
            //updateContentView()
        }
    }
    
    @objc private func keyboardWillHide(notification: NSNotification) {
        //reset bottom anchor
        scrollViewBottomConstraint.constant = 20
        //updateContentView()
    }
    
    // MARK: Auxillary Methods
    
    private func filterCues(with text: String) {
        let lowercasedText = text.lowercased()
        for button in cueButtons {
            let shouldShow = button.titleLabel?.text?.lowercased().contains(lowercasedText) ?? false
            button.isHidden = !shouldShow
        }
    }
    
    private func iconForCues(name: String) -> UIImage? {
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
        var totalHeight = CGFloat(20 + (cueCount * 20))
        
        let visibleSubviews = cuesStackView.arrangedSubviews.filter { !$0.isHidden }
        let spacing = cuesStackView.spacing
        
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
}
