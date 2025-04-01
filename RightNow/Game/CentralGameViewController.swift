import UIKit
import Combine

class CentralGameViewController: UIViewController {
    // Model
    private let gameModel = CentralGameModel.shared
    var coordinator: OnboardingCoordinator?
    
    // UI elements
    private let factoryImage = UIImageView()
    
    private let buttonStackView = UIStackView()
    private let factoryButton = UIButton()
    private let couponsImage = UIImageView()
    private let couponsCountLabel = UILabel()
    
    private let numbersCountLabel = UILabel()
    private let upgradesTableView = UITableView()
    
    private var expandedCells = Set<IndexPath>()
    
    // Available upgrades
    private var upgrades: [Upgrade] = []
    
    // Timer for automatic cookie generation
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        startSaveTimer()
        setupSubscriptions()
    }
    
    private func setupSubscriptions() {
        // subscribe to game state changes
        gameModel.$gameState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateUI()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Game Setup
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // Setup cookie button
        factoryImage.translatesAutoresizingMaskIntoConstraints = false
        factoryImage.image = EmojiImage.createImage(from: "🏭", size: 150)
        factoryImage.contentMode = .scaleAspectFit
        view.addSubview(factoryImage)
        
        // coupon image
        couponsImage.translatesAutoresizingMaskIntoConstraints = false
        couponsImage.image = EmojiImage.createImage(from: "🎟️", size: 20)
        couponsImage.contentMode = .scaleAspectFit
        
        // coupoins label
        couponsCountLabel.translatesAutoresizingMaskIntoConstraints = false
        couponsCountLabel.text = String(gameModel.gameState.coupons) 
        couponsCountLabel.font = UIConfiguration.buttonFont
        couponsCountLabel.textColor = .black
        couponsCountLabel.textAlignment = .center
        
        // setup tap button
        factoryButton.translatesAutoresizingMaskIntoConstraints = false
        factoryButton.setTitle("Make Numbers", for: .normal)
        factoryButton.setTitleColor(.white, for: .normal)
        factoryButton.backgroundColor = UIConfiguration.tintColor
        factoryButton.layer.cornerRadius = 12
        factoryButton.addTarget(self, action: #selector(numbersTapped), for: .touchUpInside)
        
        // setup stack view
        buttonStackView.translatesAutoresizingMaskIntoConstraints = false
        buttonStackView.axis = .horizontal
        buttonStackView.alignment = .center
        buttonStackView.distribution = .fill
        buttonStackView.spacing = 8
        
        // add it all up together
        buttonStackView.addArrangedSubview(couponsImage)
        buttonStackView.addArrangedSubview(couponsCountLabel)
        buttonStackView.addArrangedSubview(factoryButton)
        view.addSubview(buttonStackView)
        
        // Setup numbers count label
        numbersCountLabel.translatesAutoresizingMaskIntoConstraints = false
        numbersCountLabel.textAlignment = .center
        numbersCountLabel.font = UIFont.boldSystemFont(ofSize: 24)
        numbersCountLabel.text = "0"
        view.addSubview(numbersCountLabel)
        
        // Setup upgrades table view
        upgradesTableView.translatesAutoresizingMaskIntoConstraints = false
        upgradesTableView.delegate = self
        upgradesTableView.dataSource = self
        upgradesTableView.register(UpgradeCell.self, forCellReuseIdentifier: "UpgradeCell")
        view.addSubview(upgradesTableView)
        
        // Layout constraints
        NSLayoutConstraint.activate([
            // Factory Image constraints
            factoryImage.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            factoryImage.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 50),
            factoryImage.widthAnchor.constraint(equalToConstant: 200),
            factoryImage.heightAnchor.constraint(equalToConstant: 200),
            
            // factory button constraints
            couponsImage.widthAnchor.constraint(equalToConstant: 28),
            couponsImage.heightAnchor.constraint(equalToConstant: 28),
            
            factoryButton.widthAnchor.constraint(equalToConstant: 150),
            factoryButton.heightAnchor.constraint(equalToConstant: 44),
            
            buttonStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            buttonStackView.topAnchor.constraint(equalTo: factoryImage.bottomAnchor, constant: 20),
            
            // Cookie count label constraints
            numbersCountLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            numbersCountLabel.topAnchor.constraint(equalTo: factoryButton.bottomAnchor, constant: 20),
            numbersCountLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            numbersCountLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            // Upgrades table view constraints
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
        }
        
        factoryVC.onCouponUsed = { [weak self] amount in
            self?.gameModel.useCoupons(amount)
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
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return UpgradeType.allCases.count
    }
    
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
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return expandedCells.contains(indexPath) ? 140 : 80
    }
    
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
    
    func showCompletionAlert() {
        let alert = CustomAlertViewController(title: "That's it!", message: "Hope you enjoy playing RightNow!")
        present(alert, animated: true)
    }
}
