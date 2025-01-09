import Foundation
import UIKit

protocol AccountabilityDelegate: AnyObject {
    func metricSelected(_ metric: AccountabilityMetric)
}

class AccountabilityViewController: UIViewController, UITextFieldDelegate {
    // MARK: Declaration
    weak var delegate: AccountabilityDelegate?
    var habitData = HabitData()
    
    // accountability metric variables
    var metricButtons: [UIButton] = []
    let predefinedMetrics: [AccountabilityMetric] = [.screenTime, .locationTracking, .photoEvidence]
    let metricCount = 3
    
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
    
    private func setupMetricButtons() {
        view.addSubview(metricScrollView)
        metricScrollView.addSubview(metricStackView)
        metricStackView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            metricScrollView.topAnchor.constraint(equalTo: whatLabel.bottomAnchor, constant: 20),
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
            button.setTitle(metric.displayName, for: .normal)
            button.setTitleColor(.white, for: .normal)
            button.backgroundColor = .white
            button.layer.cornerRadius = 10
            button.clipsToBounds = true //for rounded radius
            button.layer.borderWidth = 1
            button.layer.borderColor = UIConfiguration.tintColor?.cgColor
            
            //set up image
            let icon = iconForMetric(name: metric.displayName) //method
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
            button.tag = predefinedMetrics.firstIndex(of: metric) ?? 0
            
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
        nextButton.isEnabled = true
    }
    
    @objc private func metricButtonTapped(_ sender: UIButton) {
        let selectedMetric = predefinedMetrics[sender.tag]
        delegate?.metricSelected(selectedMetric)
    }
    
    @objc private func nextButtonTapped() {
        //create and push the next view controller
        var nextVC: UIViewController
        
        if habitData.accountabilityMetric == .locationTracking {
            let locationVC = LocationAccountabilityViewController()
            locationVC.habitData = habitData
            nextVC = locationVC
        } else {
            let defaultVC = IncentivesViewController()
            defaultVC.habitData = habitData
            nextVC = defaultVC
        }
        
        // back button
        let backButton = UIBarButtonItem(title: "", style: .plain, target: self, action: #selector(backButtonTapped))
        navigationItem.backBarButtonItem = backButton
        self.navigationController?.navigationBar.tintColor = .white
        
        navigationController?.pushViewController(nextVC, animated: true)
    }
    
    @objc private func backButtonTapped() {
        self.navigationController?.popViewController(animated: true)
    }
    
    
    // MARK: Auxillary Methods
    
    private func iconForMetric(name: String) -> UIImage? {
        switch name {
        case "Track your Location":
            return UIImage(systemName: "location")
        case "Track your Screen Time Usage":
            return UIImage(systemName: "iphone.gen1.slash")
        case "Take a Photo":
            return UIImage(systemName: "photo.badge.checkmark")
        default:
            return UIImage(systemName: "checkmark")
        }
    }
}

extension AccountabilityViewController: AccountabilityDelegate {
    func metricSelected(_ metric: AccountabilityMetric) {
        habitData.accountabilityMetric = metric
        updateNextButtonState()
    }
}
