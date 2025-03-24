import Foundation
import UIKit

/// Custom alert view controller to match with the app's aesthetics
///
/// # Features:
/// - Customizable title and message
/// - Primary action button with configurable title
/// - Optional cancel button with configurable title
/// - Completion handlers for primary action and cancel
/// - Adaptive font sizing based on content and screen size
/// - Factory methods for common alerts
///
/// ## Example Usage
/// ```
/// let alert = CustomAlertViewController(
///     title: "Success",
///     message: "Your data has been saved.",
///     okButtonTitle: "Continue",
///     completionOk: {
///         // Handle the OK button tap
///     }
/// )
/// present(alert, animated: true)
/// ```
class CustomAlertViewController: UIViewController {
    var completionOk: (() -> Void)? // primary action completion handler
    var completionCancel: (() -> Void)? // cancel action completion handler
    
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
        label.numberOfLines = 0
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
        button.titleLabel?.textAlignment = .center
        button.titleLabel?.numberOfLines = 0
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
    /// Creates a new custom alert view controller
    ///
    /// Parameters:
    /// - title : title to be displayed
    /// - message : message to be displayed
    /// - okButtonTitle : title for primary action button
    ///     - defaults to "OK"
    /// - cancelButtonTitle : title for cancel button
    ///     - defaults to nil
    ///     - nil value -> no cancel button
    /// - completionOk : Optional closure when primary action is picked
    /// - completionCancel : Optional closure when cancel action is picked
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
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // update font sizes after layout
        let okFontSize = calculateFontSize(for: okButtonTitle)
        okButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: okFontSize)
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
            cancelButton.setTitle(cancelButtonTitle, for: .normal)
            cancelButton.setTitleColor(UIColor.gray, for: .normal)
            cancelButton.titleLabel?.numberOfLines = 0
            cancelButton.titleLabel?.textAlignment = .center
            
            NSLayoutConstraint.activate([
                cancelButton.topAnchor.constraint(equalTo: okButton.bottomAnchor, constant: 10),
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
    /// Dismisses alert and calls completionOk handler
    @objc private func okClicked() {
        dismiss(animated: true) {
            self.completionOk?()
        }
    }
    
    /// Dismisses alert and calls completionCancel handler
    @objc private func cancelClicked() {
        dismiss(animated: true) {
            self.completionCancel?()
        }
    }
    
    // MARK: - Auxillary Functions
    /// Calculates appropriate font size for given text according to how many words can fit
    ///
    /// Font sizes are determined based upon:
    /// - number of words in the text
    /// - width of container view
    /// - base font sizes - varies with screen width
    ///
    /// Parameters:
    /// - text : text to calculate the font size for
    ///
    /// Returns:
    /// - CGFloat : calculated font size
    private func calculateFontSize(for text: String) -> CGFloat {
        let words = text.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        let wordCount = words.count

        // Get alert widht
        let containerWidth = containerView.bounds.width
        let buttonWidth = containerWidth - 40
        
        // Base font sizes according to screen width
        let baseLargeFontSize: CGFloat
        let baseMediumFontSize: CGFloat
        let baseSmallFontSize: CGFloat
        let baseMiniFontSize: CGFloat
        
        // Adjust base sizes according to screen width
        switch containerWidth {
        case ..<280: // very narrow alert
            baseLargeFontSize = 24
            baseMediumFontSize = 18
            baseSmallFontSize = 16
            baseMiniFontSize = 14
        case 280..<340: // narrow alert
            baseLargeFontSize = 28
            baseMediumFontSize = 22
            baseSmallFontSize = 18
            baseMiniFontSize = 16
        default: // standard
            baseLargeFontSize = 32
            baseMediumFontSize = 24
            baseSmallFontSize = 20
            baseMiniFontSize = 20
        }
        
        let testLabel = UILabel()
        testLabel.text = text
        testLabel.numberOfLines = 0
        
        // start with base font size based on word count, but rapidly adjust based on how much space it's taking up
        let initialFontSize: CGFloat
        switch wordCount {
        case 0...2:
            initialFontSize = baseLargeFontSize
        case 3...5:
            initialFontSize = baseMediumFontSize
        case 6...8:
            initialFontSize = baseSmallFontSize
        default:
            initialFontSize = baseMiniFontSize
        }
        
        testLabel.font = UIFont.boldSystemFont(ofSize: initialFontSize)
        let size = testLabel.sizeThatFits(CGSize(width: buttonWidth, height: .greatestFiniteMagnitude))
        if size.width > buttonWidth {
            let scaleFactor = buttonWidth / size.width
            return max(initialFontSize * scaleFactor, 14) // never go smaller than 14
        }
        
        return initialFontSize
    }
}

extension String {
    /// Calculates height required to display string within constraints
    ///
    /// Parameters:
    /// - width : maximum width available for text
    /// - font : font used for text
    ///
    /// Returns:
    /// - CGFloat : calculated height required to display the text
    func height(withConstrainedWidth width: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
        let boundingBox = self.boundingRect(with: constraintRect,
                                            options: .usesLineFragmentOrigin,
                                            attributes: [NSAttributedString.Key.font: font],
                                            context: nil)
        
        return ceil(boundingBox.height)
    }
}

// MARK: - Common Alerts
extension CustomAlertViewController {
    /// Creates an alert prompting user to enable location services
    ///
    /// Parameter:
    /// - completion
    ///     - optional closure called when user taps the primary action
    ///
    /// Returns:
    /// - configured CustomAlertViewController instance
    static func createLocationSettingsAlert(completion: (() -> Void)? = nil) -> CustomAlertViewController {
        let alert = CustomAlertViewController(
            title: "Granting Location Authorization",
            message: "Go to Settings > RightNow > Location > Always (To allow background tracking)",
            okButtonTitle: "I've changed my settings!",
            completionOk: completion
        )
        
        return alert
    }
    
    /// Creates an alert prompting the user to enable notifications
    ///
    /// Parameters:
    /// - completion
    ///     - optional closure called when user taps the primary action
    ///
    /// Returns:
    /// - configured CustomAlertViewController instance
    static func createNotificationSettingsAlert(completion: (() -> Void)? = nil) -> CustomAlertViewController {
        let alert = CustomAlertViewController(
            title: "Notification Permission is Currently Denied!",
            message: "You can change the settings in Settings > RightNow > Notifications > Allow Notifications",
            completionOk: completion
        )
        
        return alert
    }
}
