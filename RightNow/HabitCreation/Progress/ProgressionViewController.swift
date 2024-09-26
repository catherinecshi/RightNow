import Foundation
import UIKit

class ProgressionViewController: UIViewController {
    var habitData = HabitData()
    
    let viewTitle: UILabel = {
        let label = UILabel()
        label.text = "Create Habit"
        label.font = UIConfiguration.titleFont
        label.textColor = .white
        label.textAlignment = .center
        return label
    }()
    
    let message: UILabel = {
        let label = UILabel()
        label.text = "Great, we'll adjust your progress with the habit for you"
        label.numberOfLines = 0
        label.font = UIConfiguration.titleFont
        label.textColor = .white
        label.textAlignment = .center
        return label
    }()
    
    private let nextButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Next", for: .normal)
        button.isEnabled = true //button is disabled until a habit is selected
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIConfiguration.tintColor
        
        setupTitle()
        setupMessage()
        setupNextButton()
    }
    
    private func setupTitle() {
        viewTitle.translatesAutoresizingMaskIntoConstraints = false
        
        //make sure it can go to multiple lines if squished
        viewTitle.numberOfLines = 0 //allows line breaks
        viewTitle.lineBreakMode = .byWordWrapping //breaks lines by words, not characters
        
        self.navigationItem.titleView = viewTitle
    }
    
    private func setupMessage() {
        view.addSubview(message)
        message.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            message.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            message.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            message.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            message.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor)
        ])
    }
    
    private func setupNextButton() {
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
        
        nextButton.addTarget(self, action: #selector(nextButtonTapped), for: .touchUpInside)
    }
    
    @objc private func nextButtonTapped() {
        //create and push the next view controller
        let murphyjitsuVC = HabitMurphyjitsuViewController()
        murphyjitsuVC.habitData = habitData
        navigationController?.pushViewController(murphyjitsuVC, animated: true)
    }
    
    @objc private func dismissSelf() {
        self.dismiss(animated: true, completion: nil)
    }
}
