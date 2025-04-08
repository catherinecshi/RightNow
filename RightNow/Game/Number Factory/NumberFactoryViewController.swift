import UIKit

/// # NumberFactoryViewController
///
/// A game-based view controller that creates a grid-based number collection game where
/// players navigate through a dynamically scrolling grid to accumulate number values
/// while avoiding specific rule violations.
 
/// ## Game Overview
/// - Players navigate a number around a grid using swipe gestures
/// - The grid continuously scrolls downward at timed intervals
/// - Players can double their score if they reach goal values
/// - Players must avoid specific rule conditions
/// - The game uses a coupon system as entry payment
/// - Upon completion, a multiplier wheel determines final number rewards
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
    
    // onboarding
    var coordinator: OnboardingCoordinator?
    
    // Color configuration
    private let boardColor = UIColor.systemGray6
    private let cellColor = UIColor.systemGray5
    private let playerColor = UIConfiguration.tintColor
    private let avoidBoxColor = UIColor.systemRed.withAlphaComponent(0.2)
    private let goalBoxColor = UIColor.systemGreen.withAlphaComponent(0.2)
    
    // MARK: - Lifecycle
    
    /// sets up game environment
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        
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
    
    /// check if onboarding, and if so, present tutorial through coordinator
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // check if onboarding
        if coordinator != nil {
            coordinator?.presentNumberFactoryOnboarding() { [weak self] in
                print("presented onboarding stuff")
                //self?.showAlert(title: "Play around!", message: "placeholder")
            }
        }
    }
    
     /// Creates the visual grid of cell views that represent the game board
     ///
     /// This method:
     /// 1. Calculates the appropriate cell size based on board dimensions
     /// 2. Creates a 2D array of UIViews for each cell
     /// 3. Positions each cell on the board with proper spacing
     /// 4. Adds a label to each cell for displaying the number value
     /// 5. Stores the cell views for later reference and updates
     ///
     /// The cell size calculation considers both the board size and the
     /// padding between cells to ensure consistent spacing throughout the grid.
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
    
    /// Creates the container view for the game board
    private func setupGameBoard() {
        // Create board container view
        boardView = UIView(frame: CGRect(x: 0, y: 0, width: boardSize, height: boardSize))
        boardView.center = CGPoint(x: view.center.x, y: view.center.y) // Move down slightly
        boardView.backgroundColor = boardColor
        boardView.layer.cornerRadius = 8
        view.addSubview(boardView)
    }
    
    /// Sets up information labels for game rules and goals
    ///
    /// This method creates:
    /// 1. A container to organize the information boxes
    /// 2. A red-tinted box displaying the rule to avoid
    /// 3. A green-tinted box displaying the current goal value
    ///
    /// The layout uses Auto Layout constraints to position the elements
    /// properly and ensure they adapt to different screen sizes.
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
    
    /// Sets up the start/end game button and coupon display
    private func setupStartButton() {
        startButton = UIButton(type: .system)
        startButton.translatesAutoresizingMaskIntoConstraints = false
        startButton.setTitle("Start Game", for: .normal)
        startButton.titleLabel?.font = .boldSystemFont(ofSize: 18)
        startButton.backgroundColor = UIConfiguration.tintColor
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
    
    /// sets up swipe gestures recognizers for player movement
    private func setupGestureRecognizers() {
        // Add swipe gesture recognizers
        let directions: [UISwipeGestureRecognizer.Direction] = [.up, .down, .left, .right]
        
        for direction in directions {
            let gesture = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
            gesture.direction = direction
            view.addGestureRecognizer(gesture)
        }
    }
    
    /// Sets up observers for game state changes
    ///
    /// This method establishes three key callback closures:
    /// 1. stateDidChange: Triggers UI updates when the game state changes
    /// 2. gameDidEnd: Handles game completion
    /// 3. didReachGoal: Handles when the player reaches the goal value
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
    
    /// dismisses view
    /// if ionboarding, call coordinator
    @objc private func dismissSelf() {
        // check if currently doing onboarding or not
        if coordinator != nil {
            Task {
                await coordinator?.dismissNumberFactory()
            }
        }
        
        self.dismiss(animated: true, completion: nil)
    }
    
    /// processes swip gesture input for player movement
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
    
    ///Toggles between starting and ending the game
    ///
    /// This method:
    /// 1. If game is active, ends the current game
    /// 2. If game is inactive, checks for coupon availability
    /// 3. If coupon is available, starts a new game and deducts a coupon
    /// 4. If no coupon is available, shows an alert
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
    
    // MARK: - Game State
    
    /// Starts a new game session
    ///
    /// This method:
    /// 1. Initializes a new game in the model
    /// 2. Updates the UI to reflect initial state
    /// 3. Starts the scrolling timer
    /// 4. Updates button appearance and text
    /// 5. Sets game active flag
    private func startGame() {
        gameBoard.startNewGame()
        updateUI(animated: false)
        
        // Start scrolling timer
        scrollingEngine.start()
        
        startButton.setTitle("End Game", for: .normal)
        startButton.backgroundColor = UIConfiguration.tintColor
        gameActive = true
    }
    
    /// Ends the current game session
    ///
    /// This method:
    /// 1. Stops the scrolling timer
    /// 2. Resets button appearance and text
    /// 3. Clears game active flag
    /// 4. Shows multiplier wheel for final reward calculation
    private func endGame() {
        // Stop scrolling timer
        scrollingEngine.stop()
        
        startButton.setTitle("Start Game", for: .normal)
        startButton.backgroundColor = UIConfiguration.tintColor
        gameActive = false
        
        showMultiplierWheel(baseNumber: gameBoard.playerValue)
    }
    
    /// Presents the multiplier wheel for reward calculation
    ///
    /// This method:
    /// 1. Retrieves player upgrades from central game model
    /// 2. If upgrades exist, creates and shows multiplier wheel UI
    /// 3. Sets callback for final number determination
    /// 4. If no upgrades, shows simple completion alert
    private func showMultiplierWheel(baseNumber: Int) {
        let upgrades = getUserUpgrades()
        
        if !upgrades.isEmpty {
            // create and present multiplier wheel controller
            let wheelVC = MultiplierWheelViewController(baseNumber: baseNumber, upgrades: upgrades)
            
            wheelVC.onMultiplierDetermined = { [weak self] finalNumber in
                self?.onNumbersGenerated?(finalNumber)
            }
            
            wheelVC.modalPresentationStyle = .overFullScreen
            present(wheelVC, animated: true)
        } else {
            showAlert(title: "Congrats", message: "You just made \(baseNumber) numbers!")
            onNumbersGenerated?(baseNumber)
        }
    }
    
    /// return dictionary mapping upgrade types to current levels
    private func getUserUpgrades() -> [UpgradeType: Int] {
        let upgrades = CentralGameModel.shared.getUpgrades()
        return upgrades
    }
    
    // MARK: - Updates
    
    /// scroll down the grid by one row
    /// if cannot scroll down, user is out of bounds and lost
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
    
    /// update coupon count display
    private func updateCouponCount() {
        couponsCountLabel.text = String(couponCount)
    }
    
    /// Updates the entire game UI to reflect current model state
    ///
    /// This comprehensive method:
    /// 1. Updates rule and goal labels
    /// 2. Updates all grid cells to show current values
    /// 3. Highlights the player's current position
    /// 4. Handles bomb cells differently with emoji
    /// 5. Adjusts font size based on number magnitude
    /// 6. Optionally animates the player position
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
                    // display bombs
                    if value == NumberFactoryBoard.bombValue {
                        numberLabel.text = "💣"
                        numberLabel.font = .systemFont(ofSize: 18)
                        cellView.backgroundColor = cellColor
                        numberLabel.textColor = .black
                    } else {
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
    
    /// utility method for showing alert
    private func showAlert(title: String, message: String) {
        let alert = CustomAlertViewController(title: title, message: message)
        present(alert, animated: true)
    }
}
