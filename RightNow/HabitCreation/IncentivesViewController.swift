import Foundation
import UIKit

protocol IncentivesDelegate: AnyObject {
    func incentiveSelected(_ incentive: Incentive)
}

class IncentivesViewController: UIViewController, UITextFieldDelegate {
    // MARK: Declaration
    weak var delegate: IncentivesDelegate?
    var habitData = HabitData()
    
    // accountability metric variables
    var punishmentButtons: [UIButton] = []
    let predefinedPunishments: [Incentive] = [.none, .money, .blockApps]
    let punishmentCount = 3
    
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
    
    private func setupPunishmentButtons() {
        view.addSubview(punishmentScrollView)
        punishmentScrollView.addSubview(punishmentStackView)
        punishmentStackView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            punishmentScrollView.topAnchor.constraint(equalTo: whatLabel.bottomAnchor, constant: 20),
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
            button.setTitle(punishment.displayName, for: .normal)
            button.setTitleColor(.white, for: .normal)
            button.backgroundColor = .white
            button.layer.cornerRadius = 10
            button.clipsToBounds = true //for rounded radius
            button.layer.borderWidth = 1
            button.layer.borderColor = UIConfiguration.tintColor?.cgColor
            
            //set up image
            let icon = iconForPunishment(name: punishment.displayName) //method
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
            button.tag = predefinedPunishments.firstIndex(of: punishment) ?? 0
            
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
        nextButton.isEnabled = true
    }
    
    @objc private func punishmentButtonTapped(_ sender: UIButton) {
        let selectedIncentive = predefinedPunishments[sender.tag]
        delegate?.incentiveSelected(selectedIncentive) // send to habitData in main VC
    }
    
    @objc private func nextButtonTapped() {
        //create and push the next view controller
        let murphyVC = MurphyjitsuViewController()
        
        // back button
        let backButton = UIBarButtonItem(title: "", style: .plain, target: self, action: #selector(backButtonTapped))
        navigationItem.backBarButtonItem = backButton
        self.navigationController?.navigationBar.tintColor = .white
        
        murphyVC.habitData = habitData
        navigationController?.pushViewController(murphyVC, animated: true)
    }
    
    @objc func backButtonTapped() {
        self.navigationController?.popViewController(animated: true)
    }
    
    
    // MARK: Auxillary Methods
    
    private func iconForPunishment(name: String) -> UIImage? {
        switch name {
        case "None":
            return UIImage(systemName: "xmark.circle")
        case "Block Apps":
            return UIImage(systemName: "iphone.gen1.slash")
        case "Stake Money":
            return UIImage(systemName: "dollarsign.arrow.circlepath")
        case "Make Your Own":
            return UIImage(systemName: "person.3.fill")
        default:
            return UIImage(systemName: "lightbulb.max.fill")
        }
    }
}

extension IncentivesViewController: IncentivesDelegate {
    func incentiveSelected(_ incentive: Incentive) {
        habitData.incentive = incentive
        updateNextButtonState()
    }
}
