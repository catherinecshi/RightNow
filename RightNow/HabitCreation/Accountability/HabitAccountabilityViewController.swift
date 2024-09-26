import Foundation
import UIKit

protocol HabitAccountabilityDelegate: AnyObject {
    func metricSelected(_ metric: String)
}

class HabitAccountabilityViewController: UIViewController, UITextFieldDelegate {
    // MARK: Declaration
    weak var delegate: HabitAccountabilityDelegate?
    var habitData = HabitData()
    var viewModel: HabitListViewModel?
    
    // accountability metric variables
    var metricButtons: [UIButton] = []
    let metricTextField = UITextField()
    let predefinedMetrics = ["Location Tracking", "Lock Phone Away", "Accountabuddy", "Take a Photo"]
    let metricCount = 4
    
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
        label.text = "How do you want to keep yourself accountable?"
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
    let metricScrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()
    
    //stack to hold habit buttons
    let metricStackView: UIStackView = {
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
        setupMetricTextField()
        setupSuggestionSubtitle()
        setupNextButton()
        setupMetricButtons()
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
    
    private func setupMetricTextField() {
        metricTextField.placeholder = "Accountability Metric"
        metricTextField.borderStyle = .roundedRect
        metricTextField.delegate = self
        metricTextField.clearButtonMode = .whileEditing //clear button
        
        //add to view
        view.addSubview(metricTextField)
        metricTextField.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            metricTextField.topAnchor.constraint(equalTo: whatLabel.bottomAnchor, constant: 20),
            metricTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            metricTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            metricTextField.heightAnchor.constraint(equalToConstant: 40)
        ])
        
        //target to capture text changes
        metricTextField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
    }
    
    private func setupSuggestionSubtitle() {
        view.addSubview(suggestionsLabel)
        suggestionsLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            suggestionsLabel.topAnchor.constraint(equalTo: metricTextField.bottomAnchor, constant: 40),
            suggestionsLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            suggestionsLabel.heightAnchor.constraint(equalToConstant: 22)
        ])
    }
    
    private func setupMetricButtons() {
        view.addSubview(metricScrollView)
        metricScrollView.addSubview(metricStackView)
        metricStackView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            metricScrollView.topAnchor.constraint(equalTo: suggestionsLabel.bottomAnchor, constant: 20),
            metricScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            metricScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            metricScrollView.bottomAnchor.constraint(equalTo: nextButton.topAnchor, constant: 20),
            
            metricStackView.topAnchor.constraint(equalTo: metricScrollView.topAnchor),
            metricStackView.leadingAnchor.constraint(equalTo: metricScrollView.leadingAnchor),
            metricStackView.trailingAnchor.constraint(equalTo: metricScrollView.trailingAnchor),
            metricStackView.bottomAnchor.constraint(equalTo: metricScrollView.bottomAnchor),
            metricStackView.widthAnchor.constraint(equalTo: metricScrollView.widthAnchor),
        ])
        
        for metric in predefinedMetrics {
            let button = UIButton(type: .system)
            button.setTitle(metric, for: .normal)
            button.setTitleColor(.white, for: .normal)
            button.backgroundColor = .white
            button.layer.cornerRadius = 10
            button.clipsToBounds = true //for rounded radius
            button.layer.borderWidth = 1
            button.layer.borderColor = UIConfiguration.tintColor?.cgColor
            
            //set up image
            let icon = iconForMetric(name: metric) //method
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
            
            button.addTarget(self, action: #selector(metricButtonTapped), for: .touchUpInside)
            metricStackView.addArrangedSubview(button)
            metricButtons.append(button)
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
            filterMetrics(with: text)
            delegate?.metricSelected(text) // send to habitData in main VC
            
            //updateContentView()
        } else {
            //text field is empty, disable next button
            metricButtons.forEach { $0.isHidden = false }
            //updateContentView()
        }
    }
    
    @objc private func metricButtonTapped(_ sender: UIButton) {
        guard let accMetric = sender.titleLabel?.text else { return }
        
        metricTextField.text = accMetric
        filterMetrics(with: accMetric)
        delegate?.metricSelected(accMetric) // send to habitData in main VC
    }
    
    @objc private func nextButtonTapped() {
        //create and push the next view controller
        var nextVC: UIViewController
        
        if habitData.accountabilityMetric == "Location Tracking" {
            let locationVC = LocationAccountabilityViewController()
            locationVC.viewModel = viewModel
            locationVC.habitData = habitData
            nextVC = locationVC
        } else {
            let defaultVC = HabitIncentivesViewController()
            defaultVC.viewModel = viewModel
            defaultVC.habitData = habitData
            nextVC = defaultVC
        }
        
        // back button
        let backButton = UIBarButtonItem(title: "", style: .plain, target: self, action: #selector(backButtonTapped))
        navigationItem.backBarButtonItem = backButton
        self.navigationController?.navigationBar.tintColor = .white
        
        navigationController?.pushViewController(nextVC, animated: true)
    }
    
    @objc func backButtonTapped() {
        self.navigationController?.popViewController(animated: true)
    }
    
    
    // MARK: Auxillary Methods
    
    private func filterMetrics(with text: String) {
        let lowercasedText = text.lowercased()
        for button in metricButtons {
            let shouldShow = button.titleLabel?.text?.lowercased().contains(lowercasedText) ?? false
            button.isHidden = !shouldShow
        }
    }
    
    private func iconForMetric(name: String) -> UIImage? {
        switch name {
        case "Location Tracking":
            return UIImage(systemName: "location")
        case "Lock Phone Away":
            return UIImage(systemName: "iphone.gen1.slash")
        case "Accountabuddy":
            return UIImage(systemName: "figure.2.arms.open")
        case "Take a Photo":
            return UIImage(systemName: "photo.badge.checkmark")
        default:
            return UIImage(systemName: "checkmark")
        }
    }
}

extension HabitAccountabilityViewController: HabitAccountabilityDelegate {
    func metricSelected(_ metric: String) {
        habitData.accountabilityMetric = metric
        updateNextButtonState()
    }
}
