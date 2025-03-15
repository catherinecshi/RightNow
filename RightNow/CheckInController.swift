import Foundation
import UIKit

protocol HabitCompleteDelegate: AnyObject {
    func completeHabit(for habit: inout Habit) async
}

class CheckInController: UIViewController {
    // MARK: Declaration
    var habit: Habit!
    weak var delegate: HabitCompleteDelegate?
    
    // button to go to the next step
    private let checkInButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Done", for: .normal)
        button.isEnabled = true
        return button
    }()
    
    let checkInLabel: UILabel = {
        let label = UILabel()
        label.text = "Check off Habit"
        label.font = UIConfiguration.titleFont
        label.textColor = .white
        label.textAlignment = .center
        return label
    }()
    
    let dismissButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("X", for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 24)
        button.setTitleColor(.white, for: .normal)
        return button
    }()
    
    // MARK: Lifecycle
    
    init(habit: Habit) {
        self.habit = habit
        super.init(nibName: nil, bundle: nil)
    }
    
    // Required initializer when subclassing UIViewController
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIConfiguration.tintColor
        
        setupCheckInButton()
        setupLabel()
        setupDismissButton()
    }
    
    // MARK: Initialisation
    
    private func setupCheckInButton() {
        // add to view
        view.addSubview(checkInButton)
        checkInButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            checkInButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            checkInButton.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        // appearance
        checkInButton.backgroundColor = .white
        checkInButton.setTitleColor(UIConfiguration.tintColor, for: .normal)
        checkInButton.setTitleColor(UIColor.gray, for: .disabled)
        checkInButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 32)
        checkInButton.layer.cornerRadius = 20
        checkInButton.clipsToBounds = true
        
        checkInButton.addTarget(self, action: #selector(habitCompleted), for: .touchUpInside)
    }
    
    private func setupLabel() {
        view.addSubview(checkInLabel)
        checkInLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            checkInLabel.topAnchor.constraint(equalTo: checkInButton.bottomAnchor, constant: 20),
            checkInLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }
    
    private func setupDismissButton() {
        view.addSubview(dismissButton)
        dismissButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            dismissButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            dismissButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 10),
            dismissButton.widthAnchor.constraint(equalToConstant: 40),
            dismissButton.heightAnchor.constraint(equalToConstant: 40)
        ])
        
        dismissButton.addTarget(self, action: #selector(dismissSelf), for: .touchUpInside)
    }
    
    @objc private func habitCompleted() {
        let habitCopy = habit
        dismiss(animated: true) { [weak self] in
            guard var habit = habitCopy else { return }
            
            Task {
                await self?.delegate?.completeHabit(for: &habit)
            }
        }
    }
    
    @objc private func dismissSelf() {
        self.dismiss(animated: true, completion: nil)
    }
}
