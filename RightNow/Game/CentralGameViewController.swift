import UIKit
import Combine

/// A central view controller that manages the main game interface.
/// Responsible for:
/// - Displaying the current game state (numbers, coupons)
/// - Handling user interactions for generating numbers
/// - Managing the upgrades table view
/// - Implementing onboarding functionality
/// - Handling game state persistence
class CentralGameViewController: UIViewController {
    // MARK: - Properties
    
    // Model
    private let gameModel = CentralGameModel.shared
    var coordinator: OnboardingCoordinator?
    weak var sceneDelegate: SceneDelegate?
    let appState: AppState = .shared
    
    // UI elements
    private let factoryImage: UIImageView = {
        let image = UIImageView()
        image.translatesAutoresizingMaskIntoConstraints = false
        image.image = EmojiImage.createImage(from: "🏭", size: 150)
        image.contentMode = .scaleAspectFit
        return image
    }()
    
    private let buttonStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .fill
        stackView.spacing = 8
        return stackView
    }()
    
    private let factoryButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Make Numbers", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UIConfiguration.tintColor
        button.layer.cornerRadius = 12
        return button
    }()
    
    private let couponsImage: UIImageView = {
        let image = UIImageView()
        image.translatesAutoresizingMaskIntoConstraints = false
        image.image = EmojiImage.createImage(from: "🎟️", size: 20)
        image.contentMode = .scaleAspectFit
        return image
    }()
    
    private let couponsCountLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIConfiguration.buttonFont
        label.textColor = .black
        label.textAlignment = .center
        return label
    }()
    
    private let numbersCountLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.font = UIFont.boldSystemFont(ofSize: 24)
        label.text = "0"
        return label
    }()
    
    private let upgradesTableView = UITableView()
    private var expandedCells = Set<IndexPath>() // tracks which cells are currently expanded
    
    // Timer for automatic game state persistence
    private var saveTimer: Timer?
    
    // store cancellables to prevent deallocation
    private var cancellables = Set<AnyCancellable>()
    
    // onboarding
    private lazy var focusView: FocusView = {
       let view = FocusView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true
        view.alpha = 0.0
        view.shapeType = .circle
        return view
    }()
    
    private lazy var onboardingLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 20, weight: .medium)
        label.textColor = .white
        label.textAlignment = .center
        label.numberOfLines = 0
        label.text = "You can use your coupons to make numbers"
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isHidden = true
        label.alpha = 0.0
        return label
    }()
    
    // MARK: - Lifecycle Methods
    
    /// sets up UI, saving, and subscriptions
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        startSaveTimer()
        setupSubscriptions()
        setupNotifications()
        self.sceneDelegate = getSceneDelegate()
    }
    
    /// sets up subscriptions to react to game state changes
    private func setupSubscriptions() {
        // subscribe to game state changes
        gameModel.$gameState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateUI()
            }
            .store(in: &cancellables)
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleUserLogin),
            name: .userDidLogin,
            object: nil
        )
    }
    
    @objc private func handleUserLogin() {
        gameModel.checkFirebaseReadiness()
    }
    
    /// retrieves scene delegate from window scene
    /// - Returns: scenedelegate if available, nil otherwise
    private func getSceneDelegate() -> SceneDelegate? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let sceneDelegate = windowScene.delegate as? SceneDelegate else {
            return nil
        }
        return sceneDelegate
    }
    
    // MARK: - Game Setup
    
    /// sets up UI with layout and constraints
    /// Sets up the user interface including layout and constraints
        private func setupUI() {
            view.backgroundColor = .systemBackground
            
            setupFactoryImage()
            setupCouponAndButtonStack()
            setupNumbersCountLabel()
            setupUpgradesTableView()
        }
        
        /// Configures the factory image view
        private func setupFactoryImage() {
            view.addSubview(factoryImage)
            
            NSLayoutConstraint.activate([
                factoryImage.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                factoryImage.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 50),
                factoryImage.widthAnchor.constraint(equalToConstant: 200),
                factoryImage.heightAnchor.constraint(equalToConstant: 200),
            ])
        }
        
        /// Configures the coupon display and factory button stack
        private func setupCouponAndButtonStack() {
            couponsCountLabel.text = String(gameModel.gameState.coupons)
            factoryButton.addTarget(self, action: #selector(numbersTapped), for: .touchUpInside)
            
            // Add components to stack view
            buttonStackView.addArrangedSubview(couponsImage)
            buttonStackView.addArrangedSubview(couponsCountLabel)
            buttonStackView.addArrangedSubview(factoryButton)
            view.addSubview(buttonStackView)
            
            NSLayoutConstraint.activate([
                // Factory button constraints
                couponsImage.widthAnchor.constraint(equalToConstant: 28),
                couponsImage.heightAnchor.constraint(equalToConstant: 28),
                
                factoryButton.widthAnchor.constraint(equalToConstant: 150),
                factoryButton.heightAnchor.constraint(equalToConstant: 44),
                
                buttonStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                buttonStackView.topAnchor.constraint(equalTo: factoryImage.bottomAnchor, constant: 20)
            ])
        }
        
        /// Configures the numbers count label
        private func setupNumbersCountLabel() {
            view.addSubview(numbersCountLabel)
            
            NSLayoutConstraint.activate([
                numbersCountLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                numbersCountLabel.topAnchor.constraint(equalTo: factoryButton.bottomAnchor, constant: 20),
                numbersCountLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
                numbersCountLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
            ])
        }
        
        /// Configures the upgrades table view
        private func setupUpgradesTableView() {
            upgradesTableView.translatesAutoresizingMaskIntoConstraints = false
            upgradesTableView.delegate = self
            upgradesTableView.dataSource = self
            upgradesTableView.register(UpgradeCell.self, forCellReuseIdentifier: "UpgradeCell")
            view.addSubview(upgradesTableView)
            
            NSLayoutConstraint.activate([
                upgradesTableView.topAnchor.constraint(equalTo: numbersCountLabel.bottomAnchor, constant: 20),
                upgradesTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                upgradesTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                upgradesTableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
            ])
        }
    
    private func startSaveTimer() {
        saveTimer = Timer.scheduledTimer(timeInterval: 25.0, target: self, selector: #selector(saveGame), userInfo: nil, repeats: true)
    }
    
    // MARK: - Game Logic
    
    /// Presents NumberFactoryViewController when factory button is tapped
    @objc private func numbersTapped() {
        let factoryVC = NumberFactoryViewController()
        factoryVC.couponCount = gameModel.gameState.coupons
        
        // check if this is part of the onboarding process
        if coordinator != nil {
            hideOnboardingFocus()
            factoryVC.coordinator = coordinator
            coordinator?.showNumberFactory()
            return
        }
        
        // set up callback to receive the numbers
        factoryVC.onNumbersGenerated = { [weak self] amount in
            self?.gameModel.addNumbers(Double(amount))
            
            Task {
                await self?.gameModel.saveGameState()
            }
        }
        
        factoryVC.onCouponUsed = { [weak self] amount in
            self?.gameModel.useCoupons(amount)
            
            Task {
                await self?.gameModel.saveGameState()
            }
        }
        
        let navController = UINavigationController(rootViewController: factoryVC)
        navController.modalPresentationStyle = .fullScreen
        present(navController, animated: true, completion: nil)
    }
    
    @objc private func saveGame() {
        Task {
            await gameModel.saveGameState()
        }
    }
    
    /// Updates UI to reflect current game state
    private func updateUI() {
        // Format large numbers
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = gameModel.gameState.numbers < 1000 ? 1 : 0
        
        let numbersText = formatter.string(from: NSNumber(value: gameModel.gameState.numbers)) ?? "0"
        numbersCountLabel.text = "\(numbersText)"
        
        couponsCountLabel.text = String(gameModel.gameState.coupons)
        
        // Refresh the upgrades table to update affordability status
        upgradesTableView.reloadData()
    }
}

// MARK: - TableView DataSource & Delegate

extension CentralGameViewController: UITableViewDataSource, UITableViewDelegate {
    
    /// Returns the number of rows in the upgrades table view
    /// - Parameters:
    ///   - tableView: The table view requesting this information
    ///   - section: The section index
    /// - Returns: The number of upgrade types available
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return UpgradeType.allCases.count
    }
    
    /// Configures and returns a cell for the specified index path
    /// - Parameters:
    ///   - tableView: The table view requesting this information
    ///   - indexPath: The index path for the cell
    /// - Returns: A configured cell displaying upgrade information
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "UpgradeCell", for: indexPath) as? UpgradeCell else {
            return UITableViewCell()
        }
        
        let upgradeType = UpgradeType.allCases[indexPath.row]
        let level = gameModel.gameState.upgradeLevels[upgradeType.rawValue] ?? 0
        let cost = gameModel.calculateUpgradeCost(upgradeType)
        let canAfford = gameModel.canPurchaseUpgrade(upgradeType)
        
        let isExpanded = expandedCells.contains(indexPath)
        
        cell.configure(with: upgradeType, level: level, cost: cost, canAfford: canAfford, isExpanded: isExpanded)
        
        cell.buyButtonTapped = { [weak self] upgradeType in
            _ = self?.gameModel.purchaseUpgrade(upgradeType)
            
            Task {
                await self?.gameModel.saveGameState()
            }
        }
        
        return cell
    }
    
    /// Returns the height for the cell at the specified index path
    /// - Parameters:
    ///   - tableView: The table view requesting this information
    ///   - indexPath: The index path for the cell
    /// - Returns: The cell height (expanded or collapsed)
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return expandedCells.contains(indexPath) ? 140 : 80
    }
    
    /// Handles selection of a cell in the upgrades table view
    /// Toggles the expanded state of the selected cell
    /// - Parameters:
    ///   - tableView: The table view in which a row was selected
    ///   - indexPath: The index path of the selected row
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        // toggle expanded state
        if expandedCells.contains(indexPath) {
            expandedCells.remove(indexPath)
        } else {
            expandedCells.insert(indexPath)
        }
        
        // update expanded state in cell
        if let cell = tableView.cellForRow(at: indexPath) as? UpgradeCell {
            cell.toggleExpanded()
        }
        
        // animate height change
        UIView.animate(withDuration: 0.3) {
            tableView.beginUpdates()
            tableView.endUpdates()
        }
    }
}

// MARK: - Onboarding
extension CentralGameViewController {
    
    /// sets up focus view and onboarding label
    func setupOnboarding() {
        // this makes sure that the focusview is added on top of everything, including the tab bar controller, because there were issues where only putting on top of the current view controller creates additional tab bar controller that causes crashes if tapped on when focus view was up
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootViewController = window.rootViewController else {
            print("Failed to get window or root view controller")
            return
        }
        
        // Get the appropriate container view (should be the tab bar controller)
        let containerView = rootViewController.view!
        
        // Clean up any existing focus views (to prevent duplicates)
        containerView.subviews.forEach { subview in
            if subview is FocusView {
                subview.removeFromSuperview()
            }
        }
        
        containerView.addSubview(focusView)
        containerView.addSubview(onboardingLabel)
        
        NSLayoutConstraint.activate([
            focusView.topAnchor.constraint(equalTo: view.topAnchor),
            focusView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            focusView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            focusView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // position label above add button
            onboardingLabel.bottomAnchor.constraint(equalTo: buttonStackView.topAnchor, constant: -20),
            onboardingLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            onboardingLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            onboardingLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40)
        ])
    }
    
    /// show onboarding foucs view highlighting button stack view
    /// adds tap gesture to focus view that activates when tapped in button vicinity
    func showOnboardingFocus() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootViewController = window.rootViewController else {
            print("Failed to get window or root view controller")
            return
        }
        
        let containerView = rootViewController.view!
        
        containerView.bringSubviewToFront(focusView)
        containerView.bringSubviewToFront(onboardingLabel)
        //containerView.bringSubviewToFront(addButton)
        
        // make focus oval around add button
        let convertedButtonFrame = view.convert(buttonStackView.frame, to: containerView)
        focusView.shapeType = .roundedRect(cornerRadius: 12)
        focusView.frame = window.bounds
        focusView.isUserInteractionEnabled = true
        
        // convert frame to coords
        let buttonFrame = buttonStackView.convert(buttonStackView.bounds, to: window)
        let paddedFrame = buttonFrame.insetBy(dx: -4, dy: -4)
        focusView.ovalRect = paddedFrame
        
        focusView.isHidden = false
        onboardingLabel.isHidden = false
        
        UIView.animate(withDuration: 0.3) {
            self.focusView.alpha = 1.0
            self.onboardingLabel.alpha = 1.0
        }
        
        // add tap gesture recogniser to the focus view - makes sure user can only tap within focus view highlight
        let tapGesture = UITapGestureRecognizer()
        
        tapGesture.addTarget { [weak self, weak focusView] gesture in
            guard let self = self, let focusView = focusView else { return }
            
            // Get the tap location
            let location = gesture.location(in: focusView)
            
            // Check if the tap is within the highlighted area
            let isInHighlightedArea: Bool
            
            switch focusView.shapeType {
            case .circle:
                // For circle, check if distance from center is less than radius
                let diameter = min(paddedFrame.width, paddedFrame.height)
                let radius = diameter / 2
                let centerX = paddedFrame.midX
                let centerY = paddedFrame.midY
                
                let dx = location.x - centerX
                let dy = location.y - centerY
                let distance = sqrt(dx*dx + dy*dy)
                
                isInHighlightedArea = distance <= radius
                
            case .roundedRect(let cornerRadius):
                // For rounded rect, check if point is inside the rect
                isInHighlightedArea = paddedFrame.contains(location)
            }
            
            // Only trigger the button tap if the gesture is within the highlight area
            if isInHighlightedArea {
                Task {
                    await InteractionBlocker.shared.unblockInteractions()
                }
                numbersTapped()
            }
        }
        
        focusView.addGestureRecognizer(tapGesture)
    }
    
    /// hides onboarding foucs view with animation
    /// removes all gesture recognizer from focus view
    func hideOnboardingFocus() {
        UIView.animate(withDuration: 0.3, animations: {
            self.focusView.alpha = 0.0
            self.onboardingLabel.alpha = 0.0
        }, completion: { _ in
            self.focusView.isHidden = true
            self.onboardingLabel.isHidden = true
            
            // remove gesture recognizers when hiding
            if let existingGestures = self.focusView.gestureRecognizers {
                for gesture in existingGestures {
                    self.focusView.removeGestureRecognizer(gesture)
                }
            }
        })
    }
    
    /// Shows completion alert at the end of onboarding
    /// - Parameter completion: Optional closure to execute after alert dismissal
    func showCompletionAlert(completion: (() -> Void)? = nil) {
        let alert = CustomAlertViewController(
            title: "That's it!",
            message: "Hope you enjoy playing RightNow!",
            completionOk: completion
        )
        present(alert, animated: true)
    }
}

// MARK: - Error Handling
extension CentralGameViewController {
    
    /// sets up subscriptions to handle errors from game model
    func setupErrorHandling() {
        CentralGameModel.shared.errorOccurred
            .receive(on: RunLoop.main)
            .sink { [weak self] error in
                self?.showError(error)
            }
            .store(in: &cancellables)
    }
    
    /// handles different types of errors
    private func showError(_ error: DataServiceError) {
        switch error {
        case .authenticationRequired:
            navigateToWelcome()
        default:
            print(error.localizedDescription)
        }
    }
    
    /// Handles navigation for sending the user to initial welcome view
    /// Uses custom transition to present WelcomeViewController
    /// Removes current view from root view controller
    private func navigateToWelcome() {
        if let sceneDelegate = self.sceneDelegate, let window = sceneDelegate.window {
            let welcomeVC = WelcomeViewController(state: appState)
            
            // Create a navigation controller with the sign-in VC as the root
            let navigationController = UINavigationController(rootViewController: welcomeVC)
            
            // Create a transition animation
            let transition = CATransition()
            transition.duration = 0.3
            transition.type = CATransitionType.push
            transition.subtype = CATransitionSubtype.fromLeft
            transition.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
            
            // Set the window's root view controller to the navigation controller
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                window.layer.add(transition, forKey: nil)
                window.rootViewController = navigationController
            }
        }
    }
}
