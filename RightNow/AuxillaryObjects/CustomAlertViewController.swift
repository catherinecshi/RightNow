import Foundation
import UIKit

class CustomAlertViewController: UIViewController {
    private var completionOk: (() -> Void)?
    private var completionCancel: (() -> Void)?
    
    private var alertTitle: String
    private var message: String
    private var okButtonTitle: String
    private var cancelButtonTitle: String?
    
    // MARK: - UI Elements
    
    private lazy var containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 12
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = UIConfiguration.titleFont
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var messageLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.numberOfLines = 0
        label.font = UIConfiguration.subtitleFont
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var okButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = .white
        button.setTitleColor(UIConfiguration.tintColor, for: .normal)
        button.setTitleColor(UIColor.gray, for: .disabled)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 32)
        button.layer.cornerRadius = 20
        button.clipsToBounds = true
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private lazy var cancelButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // MARK: - Lifecycle
    
    convenience init(title: String, message: String, okButtonTitle: String = "OK", cancelButtonTitle: String? = nil, completionOk: (() -> Void)? = nil, completionCancel: (() -> Void)? = nil) {
        self.init(nibName: nil, bundle: nil)
        
        self.completionOk = completionOk
        self.completionCancel = completionCancel
        
        self.alertTitle = title
        self.message = message
        self.okButtonTitle = okButtonTitle
        self.cancelButtonTitle = cancelButtonTitle
        
        // configure modal presentation
        self.modalPresentationStyle = .overFullScreen
        self.modalTransitionStyle = .crossDissolve
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        self.alertTitle = ""
        self.message = ""
        self.okButtonTitle = ""
        self.cancelButtonTitle = nil
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupContainerView()
        setupTitleLabel()
        setupMessageLabel()
        setupButtons()
    }
    
    // MARK: - Setup UI Constraints
    
    private func setupContainerView() {
        view.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        view.addSubview(containerView)
        
        NSLayoutConstraint.activate([
            containerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
    }
    
    private func setupTitleLabel() {
        containerView.addSubview(titleLabel)
        titleLabel.text = alertTitle
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 40),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20)
        ])
    }
    
    private func setupMessageLabel() {
        containerView.addSubview(messageLabel)
        messageLabel.text = message
        
        NSLayoutConstraint.activate([
            messageLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            messageLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            messageLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20)
        ])
    }
    
    private func setupButtons() {
        // OK Button
        containerView.addSubview(okButton)
        okButton.setTitle(okButtonTitle, for: .normal)
        
        NSLayoutConstraint.activate([
            okButton.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 20),
            okButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            okButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            okButton.heightAnchor.constraint(equalToConstant: 60)
        ])
        
        okButton.addTarget(self, action: #selector(okClicked), for: .touchUpInside)
        
        // Cancel Button (if applicable)
        if cancelButtonTitle != nil {
            containerView.addSubview(cancelButton)
            cancelButton.setTitle("Cancel", for: .normal)
            
            NSLayoutConstraint.activate([
                cancelButton.topAnchor.constraint(equalTo: okButton.bottomAnchor, constant: 20),
                cancelButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
                cancelButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
                cancelButton.heightAnchor.constraint(equalToConstant: 30),
                
                containerView.bottomAnchor.constraint(equalTo: cancelButton.bottomAnchor, constant: 20)
            ])
            
            cancelButton.addTarget(self, action: #selector(cancelClicked), for: .touchUpInside)
        } else {
            // if there is no cancel button, adjust bottom anchor of container
            NSLayoutConstraint.activate([
                containerView.bottomAnchor.constraint(equalTo: okButton.bottomAnchor, constant: 20)
            ])
        }
    }
    
    // MARK: - Button Actions
    
    @objc private func okClicked() {
        dismiss(animated: true) {
            self.completionOk?()
        }
    }
    
    @objc private func cancelClicked() {
        dismiss(animated: true) {
            self.completionCancel?()
        }
    }
}
