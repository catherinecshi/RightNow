import UIKit

/// A view controller that displays a game-over screen with spinning wheels that provide multipliers
/// for the player's base score. Each wheel corresponds to a different upgrade type that the player
/// has acquired during gameplay.
///
/// The controller allows players to:
/// - View their base number
/// - Spin multiple wheels corresponding to different upgrades
/// - Collect the final multiplied score
///
/// Usage:
/// ```
/// let multiplierVC = MultiplierWheelViewController(baseNumber: 100, upgrades: [.d6: 2, .cards: 1])
/// multiplierVC.onMultiplierDetermined = { finalScore in
///     // Handle the final score
/// }
/// present(multiplierVC, animated: true)
/// ```
class MultiplierWheelViewController: UIViewController {
    // MARK: - Properties
    private var containerView: UIView!
    private var spinnerContainerScrollView: UIScrollView! // container for multiple spinner wheels
    private var spinnerStackView: UIStackView! // horizontal stack view for spinner wheels
    private var spinButton: UIButton!
    private var finalNumber: Int = 1 // accumulated score after all multipliers have applied
    private var baseNumber: Int = 0
    private var upgrades: [UpgradeType: Int] = [:]
    private var totalLabel: UILabel!
    private var spinnerViews: [SpinnerWheelView] = []
    
    /// callback final multiplied score
    var onMultiplierDetermined: ((Int) -> Void)?
    
    /// Upgrade emojis
    private let upgradeEmojis: [UpgradeType: String] = [
        .d6: "🎲",
        .cards: "🃏",
        .roulette: "🎰",
        .bingo: "🎱",
        .lottery: "🎫"
    ]
    
    private var spinnersReady = false
    
    // MARK: - Initialization
    
    /// Creates a new multiplier wheel view controller with specified base number and upgrades
    ///
    /// - Parameters:
    ///   - baseNumber: The initial score value before multipliers
    ///   - upgrades: Dictionary mapping upgrade types to their levels
    init(baseNumber: Int, upgrades: [UpgradeType: Int]) {
        self.baseNumber = baseNumber
        self.upgrades = upgrades
        super.init(nibName: nil, bundle: nil)
        self.modalPresentationStyle = .overFullScreen
        self.modalTransitionStyle = .crossDissolve
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    /// sets up user interface and animates controller's entrance
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        animateIn()
    }
    
    /// mark spinners as ready for animation when view has appeared
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        spinnersReady = true
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        // Semi-transparent background
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        
        // Container view
        containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.backgroundColor = .systemBackground
        containerView.layer.cornerRadius = 16
        containerView.clipsToBounds = true
        containerView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        view.addSubview(containerView)
        
        // Title label
        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "Game Over"
        titleLabel.font = .boldSystemFont(ofSize: 20)
        titleLabel.textAlignment = .center
        containerView.addSubview(titleLabel)
        
        // Dismiss button
        let dismissButton = UIButton(type: .system)
        dismissButton.translatesAutoresizingMaskIntoConstraints = false
        dismissButton.setTitle("✕", for: .normal)
        dismissButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
        dismissButton.tintColor = .systemGray
        dismissButton.addTarget(self, action: #selector(dismissWithAnimation), for: .touchUpInside)
        containerView.addSubview(dismissButton)
        
        // Base number label
        let baseNumberLabel = UILabel()
        baseNumberLabel.translatesAutoresizingMaskIntoConstraints = false
        baseNumberLabel.text = "Base Number: \(baseNumber)"
        baseNumberLabel.font = .systemFont(ofSize: 16)
        baseNumberLabel.textAlignment = .center
        containerView.addSubview(baseNumberLabel)
        
        // Scroll view for spinners (in case there are many)
        spinnerContainerScrollView = UIScrollView()
        spinnerContainerScrollView.translatesAutoresizingMaskIntoConstraints = false
        spinnerContainerScrollView.showsHorizontalScrollIndicator = false
        containerView.addSubview(spinnerContainerScrollView)
        
        // Stack view for horizontal layout of spinners
        spinnerStackView = UIStackView()
        spinnerStackView.translatesAutoresizingMaskIntoConstraints = false
        spinnerStackView.axis = .horizontal
        spinnerStackView.alignment = .top
        spinnerStackView.distribution = .fillEqually
        spinnerStackView.spacing = 8
        spinnerContainerScrollView.addSubview(spinnerStackView)
        
        // Total label
        totalLabel = UILabel()
        totalLabel.translatesAutoresizingMaskIntoConstraints = false
        totalLabel.text = "Total: \(baseNumber)"
        totalLabel.font = .boldSystemFont(ofSize: 18)
        totalLabel.textAlignment = .center
        totalLabel.textColor = .systemGreen
        containerView.addSubview(totalLabel)
        
        // Spin button
        spinButton = UIButton(type: .system)
        spinButton.translatesAutoresizingMaskIntoConstraints = false
        spinButton.setTitle("Spin All Wheels", for: .normal)
        spinButton.titleLabel?.font = .boldSystemFont(ofSize: 16)
        spinButton.backgroundColor = UIConfiguration.tintColor
        spinButton.tintColor = .white
        spinButton.layer.cornerRadius = 8
        spinButton.addTarget(self, action: #selector(spinButtonTapped), for: .touchUpInside)
        containerView.addSubview(spinButton)
        
        // Layout constraints
        NSLayoutConstraint.activate([
            containerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            containerView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.9),
            containerView.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 20),
            containerView.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20),
            
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 20),
            titleLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            
            dismissButton.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            dismissButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            dismissButton.widthAnchor.constraint(equalToConstant: 30),
            dismissButton.heightAnchor.constraint(equalToConstant: 30),
            
            baseNumberLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            baseNumberLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            
            spinnerContainerScrollView.topAnchor.constraint(equalTo: baseNumberLabel.bottomAnchor, constant: 20),
            spinnerContainerScrollView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            spinnerContainerScrollView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            spinnerContainerScrollView.heightAnchor.constraint(equalToConstant: 200),
            
            spinnerStackView.topAnchor.constraint(equalTo: spinnerContainerScrollView.topAnchor),
            spinnerStackView.leadingAnchor.constraint(equalTo: spinnerContainerScrollView.leadingAnchor),
            spinnerStackView.trailingAnchor.constraint(equalTo: spinnerContainerScrollView.trailingAnchor),
            spinnerStackView.bottomAnchor.constraint(equalTo: spinnerContainerScrollView.bottomAnchor),
            spinnerStackView.heightAnchor.constraint(equalTo: spinnerContainerScrollView.heightAnchor),
            
            totalLabel.topAnchor.constraint(equalTo: spinnerContainerScrollView.bottomAnchor, constant: 16),
            totalLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            
            spinButton.topAnchor.constraint(equalTo: totalLabel.bottomAnchor, constant: 16),
            spinButton.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            spinButton.widthAnchor.constraint(equalToConstant: 200),
            spinButton.heightAnchor.constraint(equalToConstant: 44),
            spinButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -20)
        ])
        
        setupSpinners()
    }
    
    /// Creates and configures the spinner wheels based on active upgrades
    ///
    /// This method:
    /// - Filters upgrades that have a level greater than 0
    /// - Displays a message if no upgrades are active
    /// - Calculates optimal width for spinner display
    /// - Creates visual components for each spinner including emoji, level indicator, and wheel
    private func setupSpinners() {
        // Get upgrades sorted by their natural order
        let activeUpgrades = UpgradeType.allCases.filter { upgrades[$0, default: 0] > 0 }
        
        if activeUpgrades.isEmpty {
            // No upgrades message
            let noUpgradesLabel = UILabel()
            noUpgradesLabel.translatesAutoresizingMaskIntoConstraints = false
            noUpgradesLabel.text = "No upgrades yet!"
            noUpgradesLabel.font = .systemFont(ofSize: 16)
            noUpgradesLabel.textAlignment = .center
            spinnerStackView.addArrangedSubview(noUpgradesLabel)
            return
        }
        
        // Determine width for each spinner (minimum of 50pt)
        let availableWidth = spinnerContainerScrollView.bounds.width
        let isSmallScreen = UIScreen.main.bounds.width <= 375
        let minSpinnerWidth: CGFloat = isSmallScreen ? 40 : 50
        
        let optimalWidth = min(max(minSpinnerWidth, availableWidth / CGFloat(activeUpgrades.count)), 80)
        
        // Create a spinner for each upgrade
        for upgrade in activeUpgrades {
            let level = upgrades[upgrade, default: 0]
            
            // Container for each spinner column
            let spinnerContainer = UIView()
            spinnerContainer.translatesAutoresizingMaskIntoConstraints = false
            
            // Emoji label
            let emojiLabel = UILabel()
            emojiLabel.translatesAutoresizingMaskIntoConstraints = false
            emojiLabel.text = upgradeEmojis[upgrade] ?? "🎮"
            emojiLabel.font = .systemFont(ofSize: 24)
            emojiLabel.textAlignment = .center
            spinnerContainer.addSubview(emojiLabel)
            
            // Level label
            let levelLabel = UILabel()
            levelLabel.translatesAutoresizingMaskIntoConstraints = false
            levelLabel.text = "x\(level)"
            levelLabel.font = .systemFont(ofSize: 14)
            levelLabel.textAlignment = .center
            spinnerContainer.addSubview(levelLabel)
            
            // Create spinner view
            let spinnerView = SpinnerWheelView(upgradeType: upgrade, level: level)
            spinnerView.translatesAutoresizingMaskIntoConstraints = false
            spinnerContainer.addSubview(spinnerView)
            spinnerViews.append(spinnerView)
            
            // Layout spinner container
            NSLayoutConstraint.activate([
                spinnerContainer.widthAnchor.constraint(equalToConstant: optimalWidth),
                
                emojiLabel.topAnchor.constraint(equalTo: spinnerContainer.topAnchor),
                emojiLabel.centerXAnchor.constraint(equalTo: spinnerContainer.centerXAnchor),
                emojiLabel.widthAnchor.constraint(equalTo: spinnerContainer.widthAnchor),
                
                levelLabel.topAnchor.constraint(equalTo: emojiLabel.bottomAnchor, constant: 4),
                levelLabel.centerXAnchor.constraint(equalTo: spinnerContainer.centerXAnchor),
                levelLabel.widthAnchor.constraint(equalTo: spinnerContainer.widthAnchor),
                
                spinnerView.topAnchor.constraint(equalTo: levelLabel.bottomAnchor, constant: 8),
                spinnerView.leadingAnchor.constraint(equalTo: spinnerContainer.leadingAnchor, constant: 2),
                spinnerView.trailingAnchor.constraint(equalTo: spinnerContainer.trailingAnchor, constant: -2),
                spinnerView.bottomAnchor.constraint(equalTo: spinnerContainer.bottomAnchor),
                spinnerView.heightAnchor.constraint(equalToConstant: 120)
            ])
            
            spinnerStackView.addArrangedSubview(spinnerContainer)
        }
    }
    
    // MARK: - Animations
    
    /// Animates the container view entrance with a scale and fade-in effect
    private func animateIn() {
        containerView.alpha = 0
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut, animations: {
            self.containerView.alpha = 1
            self.containerView.transform = .identity
        })
    }
    /// Dismisses the view controller with a scale and fade-out animation
    @objc private func dismissWithAnimation() {
        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseIn, animations: {
            self.containerView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
            self.containerView.alpha = 0
            self.view.backgroundColor = UIColor.black.withAlphaComponent(0)
        }, completion: { _ in
            self.dismiss(animated: false)
        })
    }
    
    // MARK: - Actions
    
    /// Handles tap on the spin button to initiate spinner animations
    ///
    /// The method:
    /// - Checks if spinners are ready for animation
    /// - Disables the button during animation
    /// - Starts all spinners with a brief delay
    /// - Schedules stopping of the spinners after a minimum spin time
    @objc private func spinButtonTapped() {
        guard !spinnerViews.isEmpty && spinnersReady else {
            // Delay and retry if spinners aren't ready yet
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                self?.spinButtonTapped()
            }
            return
        }
        
        // Disable button during animation
        spinButton.isEnabled = false
        spinButton.setTitle("Spinning...", for: .normal)
        
        // Reset final multiplier
        finalNumber = 0
        
        // Add a small delay before starting first spinner
        // This helps ensure all spinners are fully ready
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let self = self else { return }
            
            // Start all spinners with special attention to the first one
            for (index, spinnerView) in self.spinnerViews.enumerated() {
                if index == 0 {
                    // Log start of the dice spinner specifically
                    print("Starting dice spinner specifically")
                    // Add a tiny offset to make sure this one starts properly
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        spinnerView.startSpinning()
                    }
                } else {
                    spinnerView.startSpinning()
                }
            }
            
            // After minimum spin time, stop the wheels one by one
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.3) { [weak self] in
                self?.stopSpinners(index: 0)
            }
        }
    }
    
    /// Stops spinners one by one and accumulates the result values
    ///
    /// - Parameter index: The index of the spinner to stop
    ///
    /// This method:
    /// - Stops the spinner at the given index
    /// - Adds its value to the final score
    /// - Updates the total label
    /// - Recursively calls itself to stop the next spinner
    /// - Shows the final result when all spinners are stopped
    private func stopSpinners(index: Int) {
        guard index < spinnerViews.count else {
            // All spinners have been stopped, show final result
            showFinalResult()
            return
        }
        
        let spinner = spinnerViews[index]
        let isDice = index == 0 // First spinner is the dice
        
        if isDice {
            print("Attempting to stop dice spinner specifically")
        }
        
        // Make sure we're on the main thread
        DispatchQueue.main.async {
            // For dice spinner, add a small delay to ensure it's ready to stop
            if isDice {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    spinner.stopSpinning { [weak self] value in
                        guard let self = self else { return }
                        
                        // Log dice value
                        print("Dice spinner stopped with value: \(value)")
                        
                        // Update the final multiplier
                        self.finalNumber += baseNumber * value
                        
                        // Update total label
                        self.totalLabel.text = "Total: \(self.finalNumber)"
                        
                        // Stop the next spinner after a longer delay for dice
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                            self.stopSpinners(index: index + 1)
                        }
                    }
                }
            } else {
                // Normal handling for other spinners
                spinner.stopSpinning { [weak self] value in
                    guard let self = self else { return }
                    
                    // Update the final multiplier
                    self.finalNumber += baseNumber * value
                    
                    // Update total label
                    self.totalLabel.text = "Total: \(self.finalNumber)"
                    
                    // Stop the next spinner after a delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.stopSpinners(index: index + 1)
                    }
                }
            }
        }
    }
    
    /// Displays the final result after all spinners have stopped
    ///
    /// This method:
    /// - Updates the button text to show the final score
    /// - Changes the button's appearance and action
    /// - Animates the total label to highlight the result
    private func showFinalResult() {
        // Update button
        spinButton.setTitle("Collect \(finalNumber)", for: .normal)
        spinButton.backgroundColor = .systemGreen
        spinButton.isEnabled = true
        
        // Highlight total
        UIView.animate(withDuration: 0.5, animations: {
            self.totalLabel.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
            self.totalLabel.textColor = .systemGreen
        }) { _ in
            UIView.animate(withDuration: 0.3) {
                self.totalLabel.transform = .identity
            }
        }
        
        // Change button action
        spinButton.removeTarget(self, action: #selector(spinButtonTapped), for: .touchUpInside)
        spinButton.addTarget(self, action: #selector(collectButtonTapped), for: .touchUpInside)
    }
    
    /// Handles tap on the collect button to finalize the score and dismiss the view
    ///
    /// This method:
    /// - Calls the completion handler with the final score
    /// - Dismisses the view controller with animation
    @objc private func collectButtonTapped() {
        // Call completion handler with the final number
        onMultiplierDetermined?(finalNumber)
        
        // Dismiss the view controller with animation
        dismissWithAnimation()
    }
}
