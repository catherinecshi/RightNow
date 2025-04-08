import UIKit

/// just a simple screen with coming soon for now
class ShopViewController: UIViewController {
    // MARK: - Properties
    
    private let comingSoonLabel: UILabel = {
        let label = UILabel()
        label.text = "Coming Soon!"
        label.font = .boldSystemFont(ofSize: 24)
        label.textColor = .white
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let dismissButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("×", for: .normal)
        button.titleLabel?.font = .boldSystemFont(ofSize: 24)
        button.setTitleColor(.white, for: .normal)
        return button
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIConfiguration.tintColor
        
        setupComingSoonLabel()
        setupDismissButton()
    }
    
    // MARK: - Setup UI
    
    private func setupComingSoonLabel() {
        view.addSubview(comingSoonLabel)
        
        NSLayoutConstraint.activate([
            comingSoonLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            comingSoonLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    private func setupDismissButton() {
        dismissButton.translatesAutoresizingMaskIntoConstraints = false
        
        let dismissBarButton = UIBarButtonItem(customView: dismissButton)
        navigationItem.leftBarButtonItem = dismissBarButton
        
        dismissButton.addTarget(self, action: #selector(dismissSelf), for: .touchUpInside)
    }
    
    // MARK: - Actions
    
    @objc private func dismissSelf() {
        dismiss(animated: true, completion: nil)
    }
}
