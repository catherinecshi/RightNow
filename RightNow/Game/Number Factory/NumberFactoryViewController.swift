import UIKit

class NumberFactoryViewController: UIViewController {
    // MARK: - Properties
    // Game constants
    private let boardSize: CGFloat = 350
    private let padding: CGFloat = 4
    
    // Game components
    private var gameBoard = NumberFactoryBoard()
    private var scrollingEngine: ScrollingEngine!
    
    private var cellViews = [[UIView]]()
    private var boardView: UIView!
    private var avoidRuleLabel: UILabel!
    private var goalLabel: UILabel!
    private var startButton: UIButton!
    private let couponsImage = UIImageView()
    private let couponsCountLabel = UILabel()
    
    var couponCount = 0
    
    //button to x out
    private let dismissButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("x", for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 24)
        button.setTitleColor(.black, for: .normal)
        return button
    }()
    
    // Game state
    private var gameActive = false
    
    // callback to send numbers and coupons back to central game
    var onNumbersGenerated: ((Int) -> Void)?
    var onCouponUsed: ((Int) -> Void)?
    
    // Color configuration
    private let boardColor = UIColor.systemGray6
    private let cellColor = UIColor.systemGray5
    private let playerColor = UIColor.systemBlue
    private let avoidBoxColor = UIColor.systemRed.withAlphaComponent(0.2)
    private let goalBoxColor = UIColor.systemGreen.withAlphaComponent(0.2)
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        
        // disable analytics for better performance
        AnalyticsController.shared.disableForComponent()
        
        setupDismissButton()
        setupGameBoard()
        setupInfoLabels()
        setupStartButton()
        setupGestureRecognizers()
        setupObservers()
        
        // Initialize cell views array
        initializeCellViews()
        
        // create scrolling engine
        scrollingEngine = ScrollingEngine(scrollInterval: 1.0) { [weak self] in
            self?.scrollGridDown()
        }
        
        // Initial update
        updateUI(animated: false)
    }
    
    deinit {
        // re-enable analytics when game is closed
        AnalyticsController.shared.enableForComponent()
    }
    
    private func initializeCellViews() {
        // Create a 2D array of cell views
        let gridSize = gameBoard.gridSize
        let cellSize = (boardSize - CGFloat(gridSize + 1) * padding) / CGFloat(gridSize)
        
        var newCellViews = [[UIView]]()
        
        for row in 0..<gridSize {
            var rowViews = [UIView]()
            
            for col in 0..<gridSize {
                let cellView = UIView()
                cellView.backgroundColor = cellColor
                cellView.layer.cornerRadius = 4
                
                let x = padding + CGFloat(col) * (cellSize + padding)
                let y = padding + CGFloat(row) * (cellSize + padding)
                cellView.frame = CGRect(x: x, y: y, width: cellSize, height: cellSize)
                
                // Add number label
                let numberLabel = UILabel(frame: cellView.bounds)
                numberLabel.textAlignment = .center
                numberLabel.font = .boldSystemFont(ofSize: 18)
                numberLabel.tag = 100 // Tag for easy access later
                cellView.addSubview(numberLabel)
                
                boardView.addSubview(cellView)
                rowViews.append(cellView)
            }
            
            newCellViews.append(rowViews)
        }
        
        cellViews = newCellViews
    }
    
    // MARK: - Setup UI
    private func setupGameBoard() {
        // Create board container view
        boardView = UIView(frame: CGRect(x: 0, y: 0, width: boardSize, height: boardSize))
        boardView.center = CGPoint(x: view.center.x, y: view.center.y) // Move down slightly
        boardView.backgroundColor = boardColor
        boardView.layer.cornerRadius = 8
        view.addSubview(boardView)
    }
    
    private func setupInfoLabels() {
        // Create container for the rule boxes
        let infoContainer = UIView()
        infoContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(infoContainer)
        
        NSLayoutConstraint.activate([
            infoContainer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            infoContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            infoContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            infoContainer.bottomAnchor.constraint(equalTo: boardView.topAnchor, constant: -20)
        ])
        
        // Avoid rule box
        let avoidBox = UIView()
        avoidBox.translatesAutoresizingMaskIntoConstraints = false
        avoidBox.backgroundColor = avoidBoxColor
        avoidBox.layer.cornerRadius = 8
        infoContainer.addSubview(avoidBox)
        
        avoidRuleLabel = UILabel()
        avoidRuleLabel.translatesAutoresizingMaskIntoConstraints = false
        avoidRuleLabel.text = "AVOID: " + gameBoard.avoidRule.description
        avoidRuleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        avoidRuleLabel.textAlignment = .center
        avoidRuleLabel.numberOfLines = 0
        avoidBox.addSubview(avoidRuleLabel)
        
        // Goal box
        let goalBox = UIView()
        goalBox.translatesAutoresizingMaskIntoConstraints = false
        goalBox.backgroundColor = goalBoxColor
        goalBox.layer.cornerRadius = 8
        infoContainer.addSubview(goalBox)
        
        goalLabel = UILabel()
        goalLabel.translatesAutoresizingMaskIntoConstraints = false
        goalLabel.text = "GOAL: \(gameBoard.goalValue)"
        goalLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        goalLabel.textAlignment = .center
        goalLabel.numberOfLines = 0
        goalBox.addSubview(goalLabel)
        
        // Layout constraints
        NSLayoutConstraint.activate([
            avoidBox.topAnchor.constraint(equalTo: infoContainer.topAnchor, constant: 10),
            avoidBox.leadingAnchor.constraint(equalTo: infoContainer.leadingAnchor),
            avoidBox.widthAnchor.constraint(equalTo: infoContainer.widthAnchor, multiplier: 0.45),
            avoidBox.bottomAnchor.constraint(equalTo: infoContainer.bottomAnchor),
            
            avoidRuleLabel.topAnchor.constraint(equalTo: avoidBox.topAnchor, constant: 8),
            avoidRuleLabel.leadingAnchor.constraint(equalTo: avoidBox.leadingAnchor, constant: 8),
            avoidRuleLabel.trailingAnchor.constraint(equalTo: avoidBox.trailingAnchor, constant: -8),
            avoidRuleLabel.bottomAnchor.constraint(equalTo: avoidBox.bottomAnchor, constant: -8),
            
            goalBox.topAnchor.constraint(equalTo: infoContainer.topAnchor, constant: 10),
            goalBox.trailingAnchor.constraint(equalTo: infoContainer.trailingAnchor),
            goalBox.widthAnchor.constraint(equalTo: infoContainer.widthAnchor, multiplier: 0.45),
            goalBox.bottomAnchor.constraint(equalTo: infoContainer.bottomAnchor),
            
            goalLabel.topAnchor.constraint(equalTo: goalBox.topAnchor, constant: 8),
            goalLabel.leadingAnchor.constraint(equalTo: goalBox.leadingAnchor, constant: 8),
            goalLabel.trailingAnchor.constraint(equalTo: goalBox.trailingAnchor, constant: -8),
            goalLabel.bottomAnchor.constraint(equalTo: goalBox.bottomAnchor, constant: -8)
        ])
    }
    
    private func setupStartButton() {
        startButton = UIButton(type: .system)
        startButton.translatesAutoresizingMaskIntoConstraints = false
        startButton.setTitle("Start Game", for: .normal)
        startButton.titleLabel?.font = .boldSystemFont(ofSize: 18)
        startButton.backgroundColor = .systemBlue
        startButton.tintColor = .white
        startButton.layer.cornerRadius = 8
        startButton.addTarget(self, action: #selector(toggleGame), for: .touchUpInside)
        view.addSubview(startButton)
        
        NSLayoutConstraint.activate([
            startButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            startButton.topAnchor.constraint(equalTo: boardView.bottomAnchor, constant: 20),
            startButton.widthAnchor.constraint(equalToConstant: 150),
            startButton.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        // coupon image
        couponsImage.translatesAutoresizingMaskIntoConstraints = false
        couponsImage.image = EmojiImage.createImage(from: "🎟️", size: 20)
        couponsImage.contentMode = .scaleAspectFit
        view.addSubview(couponsImage)
        
        // coupoins label
        couponsCountLabel.translatesAutoresizingMaskIntoConstraints = false
        couponsCountLabel.text = String(couponCount)
        couponsCountLabel.font = UIConfiguration.buttonFont
        couponsCountLabel.textColor = .black
        couponsCountLabel.textAlignment = .center
        view.addSubview(couponsCountLabel)
        
        NSLayoutConstraint.activate([
            couponsImage.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            couponsImage.topAnchor.constraint(equalTo: startButton.bottomAnchor, constant:20),
            couponsImage.widthAnchor.constraint(equalToConstant: 28),
            couponsImage.heightAnchor.constraint(equalToConstant: 28),
            
            couponsCountLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            couponsCountLabel.topAnchor.constraint(equalTo: couponsImage.bottomAnchor, constant:10)
        ])
    }
    
    private func setupDismissButton() {
        dismissButton.translatesAutoresizingMaskIntoConstraints = false
        
        let dismissBarButton = UIBarButtonItem(customView: dismissButton)
        self.navigationItem.leftBarButtonItem = dismissBarButton
        
        // add action
        dismissButton.addTarget(self, action: #selector(dismissSelf), for: .touchUpInside)
    }
    
    // MARK: - Setup Utilities
    private func setupGestureRecognizers() {
        // Add swipe gesture recognizers
        let directions: [UISwipeGestureRecognizer.Direction] = [.up, .down, .left, .right]
        
        for direction in directions {
            let gesture = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
            gesture.direction = direction
            view.addGestureRecognizer(gesture)
        }
    }
    
    private func setupObservers() {
        gameBoard.stateDidChange = { [weak self] newState, oldState in
            DispatchQueue.main.async {
                self?.updateUI(animated: newState.playerPosition != oldState.playerPosition)
            }
        }
        
        // observe game over state
        gameBoard.gameDidEnd = { [weak self] in
            DispatchQueue.main.async {
                self?.endGame()
            }
        }
        
        // observe goal reached state
        gameBoard.didReachGoal = { [weak self] in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                UIView.animate(withDuration: 0.1, animations: {
                    self.goalLabel.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
                    self.goalLabel.text = "GOAL : \(self.gameBoard.goalValue)"
                }) { _ in
                    UIView.animate(withDuration: 0.1) {
                        self.goalLabel.transform = .identity
                    }
                }
            }
        }
    }
    
    // MARK: - Actions
    @objc private func dismissSelf() {
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc private func handleSwipe(_ gesture: UISwipeGestureRecognizer) {
        guard gameActive else { return }
        
        var direction: PlayerDirection
        
        // Convert UIKit gesture direction to game direction
        switch gesture.direction {
        case .up:
            direction = .up
        case .down:
            direction = .down
        case .left:
            direction = .left
        case .right:
            direction = .right
        default:
            return
        }
        
        // Update model and UI
        if gameBoard.movePlayer(direction: direction) {
            updateUI(animated: true)
        }
    }
    
    @objc private func toggleGame() {
        if gameActive {
            endGame()
        } else {
            // check if the user has any coupons
            if couponCount <= 0 {
                showAlert(title: "No Coupons", message: "You need a coupon to make numbers")
                return
            }
            
            startGame()
            
            // update local count
            couponCount -= 1
            updateCouponCount()
            
            // send back a coupon was used
            onCouponUsed?(1)
        }
    }
    
    private func startGame() {
        gameBoard.startNewGame()
        updateUI(animated: false)
        
        // Start scrolling timer
        scrollingEngine.start()
        
        startButton.setTitle("End Game", for: .normal)
        startButton.backgroundColor = UIConfiguration.tintColor
        gameActive = true
    }
    
    private func endGame() {
        // Stop scrolling timer
        scrollingEngine.stop()
        
        startButton.setTitle("Start Game", for: .normal)
        startButton.backgroundColor = UIConfiguration.tintColor
        gameActive = false
        
        // Show game over message if game ended due to losing
        if gameBoard.isGameOver {
            showAlert(title: "Game Over", message: "Your score: \(gameBoard.playerValue)")
        }
        
        // send playervalue back to central game
        onNumbersGenerated?(gameBoard.playerValue)
    }
    
    private func scrollGridDown() {
        if gameBoard.scrollDown() {
            // Animate the grid scrolling down
            UIView.animate(withDuration: 0.1) {
                self.updateUI(animated: false)
            }
        } else {
            // Game over
            endGame()
        }
    }
    
    private func updateCouponCount() {
        couponsCountLabel.text = String(couponCount)
    }
    
    private func updateUI(animated: Bool) {
        // Update avoid rule and goal
        avoidRuleLabel.text = "AVOID: " + gameBoard.avoidRule.description
        goalLabel.text = "GOAL: \(gameBoard.goalValue)"
        
        let gridSize = gameBoard.gridSize
        
        // Update cell views based on model
        for row in 0..<gridSize {
            for col in 0..<gridSize {
                let cellView = cellViews[row][col]
                let value = gameBoard.grid[row][col]
                
                // Get the number label
                if let numberLabel = cellView.viewWithTag(100) as? UILabel {
                    numberLabel.text = value > 0 ? "\(value)" : ""
                    
                    // Highlight player's position
                    if row == gameBoard.playerRow && col == gameBoard.playerCol {
                        cellView.backgroundColor = playerColor
                        numberLabel.textColor = .white
                    } else {
                        cellView.backgroundColor = cellColor
                        numberLabel.textColor = .black
                    }
                    
                    // Scale number size based on value
                    if value < 10 {
                        numberLabel.font = .boldSystemFont(ofSize: 18)
                    } else if value < 100 {
                        numberLabel.font = .boldSystemFont(ofSize: 16)
                    } else {
                        numberLabel.font = .boldSystemFont(ofSize: 14)
                    }
                    
                    // Add animation if requested
                    if animated && row == gameBoard.playerRow && col == gameBoard.playerCol {
                        UIView.animate(withDuration: 0.1) {
                            cellView.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
                        } completion: { _ in
                            UIView.animate(withDuration: 0.1) {
                                cellView.transform = .identity
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func showAlert(title: String, message: String) {
        let alert = CustomAlertViewController(title: title, message: message)
        present(alert, animated: true)
    }
}
