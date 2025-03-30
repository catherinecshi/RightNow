import UIKit
import Combine

class CentralGameViewController: UIViewController {
    // Model
    private let gameModel = CentralGameModel.shared
    
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
