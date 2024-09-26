import Foundation
import UIKit

protocol HabitIncentivesDelegate: AnyObject {
    func incentiveSelected(_ incentive: String)
}

class HabitIncentivesViewController: UIViewController, UITextFieldDelegate {
    // MARK: Declaration
    weak var delegate: HabitIncentivesDelegate?
    var habitData = HabitData()
    var viewModel: HabitListViewModel?
    
    // accountability metric variables
    var punishmentButtons: [UIButton] = []
    let punishmentTextField = UITextField()
    let predefinedPunishments = ["None", "Lock Phone Away", "Lose Money", "Make Your Own"]
    let punishmentCount = 4
    
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
        label.text = "Punishments"
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
    
    //button to go to the next step
    private let nextButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Next", for: .normal)
        button.isEnabled = false //button is disabled until a habit is selected
        return button
    }()
    
    //for the stack to be able to scroll inside this view
    let punishmentScrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()
    
    //stack to hold habit buttons
    let punishmentStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 10
        stackView.alignment = .fill
        stackView.distribution = .fill
        return stackView
    }()
    
    // MARK: Initialisation
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.delegate = self
        view.backgroundColor = UIConfiguration.tintColor
        
        setupTitle()
        setupWhatSubtitle()
        setupPunishmentTextField()
        setupSuggestionSubtitle()
        setupNextButton()
        setupPunishmentButtons()
    }
    
    // MARK: Setup UI
    
    private func setupTitle() {
        view.addSubview(viewTitle)
        viewTitle.translatesAutoresizingMaskIntoConstraints = false
        
        //make sure it can go to multiple lines if squished
        viewTitle.numberOfLines = 0 //allows line breaks
        viewTitle.lineBreakMode = .byWordWrapping //breaks lines by words, not characters
        
        self.navigationItem.titleView = viewTitle
    }
    
    private func setupWhatSubtitle() {
        view.addSubview(whatLabel)
        whatLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            whatLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            whatLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            whatLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            whatLabel.heightAnchor.constraint(equalToConstant: 22) // value taken from the natural height
        ])
    }
    
    private func setupPunishmentTextField() {
        punishmentTextField.placeholder = "Punishment"
        punishmentTextField.borderStyle = .roundedRect
        punishmentTextField.delegate = self
        punishmentTextField.clearButtonMode = .whileEditing //clear button
        
        //add to view
        view.addSubview(punishmentTextField)
        punishmentTextField.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            punishmentTextField.topAnchor.constraint(equalTo: whatLabel.bottomAnchor, constant: 20),
            punishmentTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            punishmentTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            punishmentTextField.heightAnchor.constraint(equalToConstant: 40)
        ])
        
        //target to capture text changes
        punishmentTextField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
    }
    
    private func setupSuggestionSubtitle() {
        view.addSubview(suggestionsLabel)
        suggestionsLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            suggestionsLabel.topAnchor.constraint(equalTo: punishmentTextField.bottomAnchor, constant: 40),
            suggestionsLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            suggestionsLabel.heightAnchor.constraint(equalToConstant: 22)
        ])
    }
    
    private func setupPunishmentButtons() {
        view.addSubview(punishmentScrollView)
        punishmentScrollView.addSubview(punishmentStackView)
        punishmentStackView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            punishmentScrollView.topAnchor.constraint(equalTo: suggestionsLabel.bottomAnchor, constant: 20),
            punishmentScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            punishmentScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            punishmentScrollView.bottomAnchor.constraint(equalTo: nextButton.topAnchor, constant: 20),
            
            punishmentStackView.topAnchor.constraint(equalTo: punishmentScrollView.topAnchor),
            punishmentStackView.leadingAnchor.constraint(equalTo: punishmentScrollView.leadingAnchor),
            punishmentStackView.trailingAnchor.constraint(equalTo: punishmentScrollView.trailingAnchor),
            punishmentStackView.bottomAnchor.constraint(equalTo: punishmentScrollView.bottomAnchor),
            punishmentStackView.widthAnchor.constraint(equalTo: punishmentScrollView.widthAnchor),
        ])
        
        for punishment in predefinedPunishments {
            let button = UIButton(type: .system)
            button.setTitle(punishment, for: .normal)
            button.setTitleColor(.white, for: .normal)
            button.backgroundColor = .white
            button.layer.cornerRadius = 10
            button.clipsToBounds = true //for rounded radius
            button.layer.borderWidth = 1
            button.layer.borderColor = UIConfiguration.tintColor?.cgColor
            
            //set up image
            let icon = iconForPunishment(name: punishment) //method
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
            
            button.addTarget(self, action: #selector(punishmentButtonTapped), for: .touchUpInside)
            punishmentStackView.addArrangedSubview(button)
            punishmentButtons.append(button)
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
    
    // MARK: Detect Actions
    
    private func updateNextButtonState() {
        //check if habit & day have been selected
        let accountabilityMetricSelected = !(habitData.accountabilityMetric?.isEmpty ?? true)
        
        nextButton.isEnabled = accountabilityMetricSelected
    }
    
    @objc private func textFieldDidChange(_ textField: UITextField) {
        if let text = textField.text, !text.isEmpty {
            filterIncentives(with: text)
            delegate?.incentiveSelected(text) // send to habitData in main VC
        } else {
            //text field is empty, disable next button
            punishmentButtons.forEach { $0.isHidden = false }
        }
    }
    
    @objc private func punishmentButtonTapped(_ sender: UIButton) {
        guard let incentive = sender.titleLabel?.text else { return }
        
        punishmentTextField.text = incentive
        filterIncentives(with: incentive)
        delegate?.incentiveSelected(incentive) // send to habitData in main VC
    }
    
    @objc private func nextButtonTapped() {
        //create and push the next view controller
        let murphyVC = HabitMurphyjitsuViewController()
        
        // back button
        let backButton = UIBarButtonItem(title: "", style: .plain, target: self, action: #selector(backButtonTapped))
        navigationItem.backBarButtonItem = backButton
        self.navigationController?.navigationBar.tintColor = .white
        
        murphyVC.viewModel = viewModel
        murphyVC.habitData = habitData
        navigationController?.pushViewController(murphyVC, animated: true)
    }
    
    @objc func backButtonTapped() {
        self.navigationController?.popViewController(animated: true)
    }
    
    
    // MARK: Auxillary Methods
    
    private func filterIncentives(with text: String) {
        let lowercasedText = text.lowercased()
        for button in punishmentButtons {
            let shouldShow = button.titleLabel?.text?.lowercased().contains(lowercasedText) ?? false
            button.isHidden = !shouldShow
        }
    }
    
    private func iconForPunishment(name: String) -> UIImage? {
        switch name {
        case "None":
            return UIImage(systemName: "xmark.circle")
        case "Lock Phone Away":
            return UIImage(systemName: "iphone.gen1.slash")
        case "Lose Money":
            return UIImage(systemName: "dollarsign.arrow.circlepath")
        case "Make Your Own":
            return UIImage(systemName: "person.3.fill")
        default:
            return UIImage(systemName: "lightbulb.max.fill")
        }
    }
}

extension HabitIncentivesViewController: HabitIncentivesDelegate {
    func incentiveSelected(_ incentive: String) {
        habitData.incentive = incentive
        updateNextButtonState()
    }
}
