import UIKit

/// A custom table view cell that displays game upgrades with:
/// - Visual representation of upgrade level using emoji indicators
/// - Expandable/collapsible details view
/// - Purchase button with cost display
/// - Support for different upgrade types with appropriate visuals
///
/// This cell handles its own state transitions and animations.
class UpgradeCell: UITableViewCell {
    // MARK: - Properties
    
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGray6
        view.layer.cornerRadius = 12
        view.layer.masksToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let emojiContainerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let expandableContentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.alpha = 0
        view.isHidden = true
        return view
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 16)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = .secondaryLabel
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let dividerView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGray3
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let buyButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("+", for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 24)
        button.backgroundColor = UIConfiguration.tintColor
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let costLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private var emojiCount = 0
    private var emojiType = ""
    private var emojiViews: [UILabel] = []
    
    private var upgradeType: UpgradeType?
    var buyButtonTapped: ((UpgradeType) -> Void)?
    
    private(set) var isExpanded = false
    
    // MARK: - Lifecycle
    
    /// Initializes the cell with given style and reuse identifier
    /// - Parameters:
    ///     - style: cell style
    ///     - reuseIdentifier: reuse identifier for cell
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// prepares cell for reuse by clearing emoji views
    override func prepareForReuse() {
        super.prepareForReuse()
        clearEmojiViews()
    }
    
    // MARK: - Setup UI
    private func setupUI() {
        // clear default selection style
        selectionStyle = .none
        backgroundColor = .clear
        
        setupContainerView()
        setupBuyButton()
        setupEmojiContainer()
        setupExpandableContainer()
    }
    
    private func setupContainerView() {
        contentView.addSubview(containerView)
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
        ])
    }
    
    private func setupBuyButton() {
        buyButton.addTarget(self, action: #selector(buyButtonPressed), for: .touchUpInside)
        containerView.addSubview(buyButton)
        containerView.addSubview(costLabel)
        containerView.addSubview(dividerView)
        
        NSLayoutConstraint.activate([
            dividerView.topAnchor.constraint(equalTo: containerView.topAnchor),
            dividerView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            dividerView.widthAnchor.constraint(equalToConstant: 1),
            dividerView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -60),
            
            buyButton.topAnchor.constraint(equalTo: containerView.topAnchor),
            buyButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            buyButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            buyButton.leadingAnchor.constraint(equalTo: dividerView.trailingAnchor),
            
            costLabel.centerXAnchor.constraint(equalTo: buyButton.centerXAnchor),
            costLabel.bottomAnchor.constraint(equalTo: buyButton.bottomAnchor, constant: -4),
            costLabel.leadingAnchor.constraint(equalTo: buyButton.leadingAnchor, constant: 4),
            costLabel.trailingAnchor.constraint(equalTo: buyButton.trailingAnchor, constant: -4)
        ])
    }
    
    private func setupEmojiContainer() {
        containerView.addSubview(emojiContainerView)
        
        NSLayoutConstraint.activate([
            emojiContainerView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 10),
            emojiContainerView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 10),
            emojiContainerView.trailingAnchor.constraint(equalTo: dividerView.leadingAnchor, constant: -10)
        ])
    }
    
    private func setupExpandableContainer() {
        containerView.addSubview(expandableContentView)
        expandableContentView.addSubview(nameLabel)
        expandableContentView.addSubview(descriptionLabel)
        
        NSLayoutConstraint.activate([
            expandableContentView.topAnchor.constraint(equalTo: emojiContainerView.bottomAnchor, constant: 8),
            expandableContentView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 10),
            expandableContentView.trailingAnchor.constraint(equalTo: dividerView.leadingAnchor, constant: -10),
            expandableContentView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -10),
            
            // Name label at top of expandable area
            nameLabel.topAnchor.constraint(equalTo: expandableContentView.topAnchor),
            nameLabel.leadingAnchor.constraint(equalTo: expandableContentView.leadingAnchor),
            nameLabel.trailingAnchor.constraint(equalTo: expandableContentView.trailingAnchor),
            
            // Description label below name
            descriptionLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            descriptionLabel.leadingAnchor.constraint(equalTo: expandableContentView.leadingAnchor),
            descriptionLabel.trailingAnchor.constraint(equalTo: expandableContentView.trailingAnchor),
            descriptionLabel.bottomAnchor.constraint(lessThanOrEqualTo: expandableContentView.bottomAnchor)
        ])
    }
    
    // MARK: - Configuration
    
    /// Configures the cell with upgrade information
    /// - Parameters:
    ///   - upgradeType: The type of upgrade
    ///   - level: The current level of the upgrade
    ///   - cost: The cost to purchase the next level
    ///   - canAfford: Whether the player can afford the upgrade
    ///   - isExpanded: Whether the cell should be displayed in expanded state
    func configure(with upgradeType: UpgradeType, level: Int, cost: Double, canAfford: Bool, isExpanded: Bool = false) {
        self.upgradeType = upgradeType
        self.isExpanded = isExpanded
        
        let previousEmojiCount = self.emojiCount
        self.emojiCount = level
        
        // Select appropriate emoji for each upgrade type
        switch upgradeType {
        case .d6: emojiType = "🎲"
        case .cards: emojiType = "🃏"
        case .roulette: emojiType = "🎰"
        case .bingo: emojiType = "🎱"
        case .lottery: emojiType = "🎫"
        }
        
        // Configure text elements
        nameLabel.text = upgradeType.rawValue
        descriptionLabel.text = upgradeType.description
        
        // Configure cost inside buy button
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        
        let costText = formatter.string(from: NSNumber(value: cost)) ?? "0"
        costLabel.text = "\(costText)"
        
        // Configure buy button appearance based on affordability
        buyButton.backgroundColor = canAfford ? UIConfiguration.tintColor : .systemGray3
        buyButton.isEnabled = canAfford
        
        // Set initial state of expandable content
        expandableContentView.isHidden = !isExpanded
        expandableContentView.alpha = isExpanded ? 1.0 : 0.0
        
        // Set height for emoji container based on expanded state
        let emojiContainerHeight: CGFloat = isExpanded ? 40 : 60
        
        // Add or update height constraint for emoji container
        if let constraint = emojiContainerView.constraints.first(where: { $0.firstAttribute == .height }) {
            constraint.constant = emojiContainerHeight
        } else {
            emojiContainerView.heightAnchor.constraint(equalToConstant: emojiContainerHeight).isActive = true
        }
        
        // Create emoji views
        refreshEmojiDisplay()
    }
    
    // MARK: - Updates and Actions
    
    /// removes all emoji views from the container
    private func clearEmojiViews() {
        emojiViews.forEach { $0.removeFromSuperview() }
        emojiViews.removeAll()
    }
    
    /// creates and displays emoji indicators representing upgrade level
    /// handles empty state, grid layout and overflow indicating
    private func refreshEmojiDisplay() {
        // Clear existing emoji views
        clearEmojiViews()
        
        // Handle empty state
        if emojiCount == 0 {
            let noneLabel = UILabel()
            noneLabel.text = "None yet"
            noneLabel.font = UIFont.systemFont(ofSize: 12)
            noneLabel.textAlignment = .center
            noneLabel.textColor = .secondaryLabel
            noneLabel.translatesAutoresizingMaskIntoConstraints = false
            emojiContainerView.addSubview(noneLabel)
            
            NSLayoutConstraint.activate([
                noneLabel.centerXAnchor.constraint(equalTo: emojiContainerView.centerXAnchor),
                noneLabel.centerYAnchor.constraint(equalTo: emojiContainerView.centerYAnchor)
            ])
            
            emojiViews.append(noneLabel)
            return
        }
        
        // Get container dimensions
        let containerWidth = emojiContainerView.bounds.width
        let containerHeight = emojiContainerView.bounds.height
        
        // If bounds are zero, delay emoji creation until layout
        if containerWidth <= 0 || containerHeight <= 0 {
            DispatchQueue.main.async { [weak self] in
                self?.refreshEmojiDisplay()
            }
            return
        }
        
        // Size settings for emojis
        let emojiSize: CGFloat = 16  // Slightly smaller to fit more
        let emojiPadding: CGFloat = 4
        
        // Calculate how many can fit in a row
        let emojisPerRow = max(1, Int((containerWidth - emojiPadding) / (emojiSize + emojiPadding)))
        
        // Limit to 4 rows maximum
        let maxRows = 4
        let maxEmojisVisible = emojisPerRow * maxRows
        let emojisToShow = min(emojiCount, maxEmojisVisible)
        
        // Create emoji labels in grid layout
        for i in 0..<emojisToShow {
            let row = i / emojisPerRow
            let col = i % emojisPerRow
            
            let emojiLabel = UILabel()
            emojiLabel.text = emojiType
            emojiLabel.font = UIFont.systemFont(ofSize: 12)
            emojiLabel.textAlignment = .center
            
            // Position in grid
            let xPos = emojiPadding + CGFloat(col) * (emojiSize + emojiPadding)
            let yPos = emojiPadding + CGFloat(row) * (emojiSize + emojiPadding)
            
            emojiLabel.frame = CGRect(x: xPos, y: yPos, width: emojiSize, height: emojiSize)
            emojiContainerView.addSubview(emojiLabel)
            
            emojiViews.append(emojiLabel)
        }
        
        // If there are more emojis than we're showing, add a count label
        if emojiCount > maxEmojisVisible {
            let countLabel = UILabel()
            countLabel.text = "+\(emojiCount - maxEmojisVisible) more"
            countLabel.font = UIFont.systemFont(ofSize: 12)
            countLabel.textAlignment = .right
            countLabel.textColor = .secondaryLabel
            countLabel.translatesAutoresizingMaskIntoConstraints = false
            emojiContainerView.addSubview(countLabel)
            
            NSLayoutConstraint.activate([
                countLabel.trailingAnchor.constraint(equalTo: emojiContainerView.trailingAnchor, constant: -4),
                countLabel.bottomAnchor.constraint(equalTo: emojiContainerView.bottomAnchor, constant: -4)
            ])
            
            emojiViews.append(countLabel)
        }
    }
    
    /// Updates mask for buy button to create rounded corners only on right side
    private func updateBuyButtonMask() {
        let buyButtonMaskPath = UIBezierPath(
            roundedRect: buyButton.bounds,
            byRoundingCorners: [.topRight, .bottomRight],
            cornerRadii: CGSize(width: 12, height: 12)
        )
        
        let buyButtonMaskLayer = CAShapeLayer()
        buyButtonMaskLayer.path = buyButtonMaskPath.cgPath
        buyButton.layer.mask = buyButtonMaskLayer
    }
    
    /// toggles expanded state of cell with animation
    func toggleExpanded() {
        isExpanded = !isExpanded
        
        // Calculate height for emoji container based on expanded state
        let emojiContainerHeight: CGFloat = isExpanded ? 40 : 60
        
        // Update emoji container height constraint
        if let constraint = emojiContainerView.constraints.first(where: { $0.firstAttribute == .height }) {
            constraint.constant = emojiContainerHeight
        } else {
            emojiContainerView.heightAnchor.constraint(equalToConstant: emojiContainerHeight).isActive = true
        }
        
        // Important: If expanding, unhide BEFORE animation starts
        if isExpanded {
            expandableContentView.isHidden = false
        }
        
        UIView.animate(withDuration: 0.3, animations: {
            // unhide view first before animation if going from collapsed -> expanded
            if self.isExpanded {
                self.expandableContentView.isHidden = !self.isExpanded
            }
            
            self.expandableContentView.alpha = self.isExpanded ? 1.0 : 0.0
            
            // Force layout during animation
            self.layoutIfNeeded()
            //self.updateBuyButtonMask()
        }, completion: { finished in
            // hide view after animation if going from expanded -> collapsed
            if finished {
                self.expandableContentView.isHidden = !self.isExpanded
                self.updateBuyButtonMask()
            }
        })
    }
    
    /// calls buyButtonTapped closure with current upgrade type
    @objc private func buyButtonPressed() {
        if let upgradeType = upgradeType {
            buyButtonTapped?(upgradeType)
            
            // force layout update
            updateBuyButtonMask()
        }
    }
}

// MARK: - UICollectionView DataSource & Delegate
extension UpgradeCell: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    /// Returns the number of emoji items to display in the collection view
    /// - Parameters:
    ///   - collectionView: The collection view requesting this information
    ///   - section: The section index
    /// - Returns: The number of emoji indicators to show
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return emojiCount > 0 ? emojiCount : 1 // At least one item to show "None yet"
    }
    
    /// Configures and returns a cell for the emoji collection
    /// - Parameters:
    ///   - collectionView: The collection view requesting this information
    ///   - indexPath: The index path for the cell
    /// - Returns: A cell displaying an emoji or "None yet" message
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "EmojiCell", for: indexPath) as? EmojiCell else {
            print("Failed to dequeue EmojiCell - check registrations")
            
            // return a default cell as fallback
            let defaultCell = UICollectionViewCell()
            defaultCell.backgroundColor = .clear
            return defaultCell
        }
        
        if emojiCount > 0 {
            cell.configure(with: emojiType)
        } else {
            cell.configureEmpty()
        }
        
        return cell
    }
    
    /// Returns the size for items in the emoji collection
    /// - Parameters:
    ///   - collectionView: The collection view requesting this information
    ///   - collectionViewLayout: The layout object requesting the information
    ///   - indexPath: The index path of the item
    /// - Returns: The size for the cell at the specified index path
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        // If this is an empty state cell
        if emojiCount == 0 && indexPath.item == 0 {
            return CGSize(width: collectionView.bounds.width, height: 30)
        }
        
        // Normal emoji cell size
        let width = (collectionView.bounds.width - 4) / 2 // 2 columns with 4 points spacing
        return CGSize(width: width, height: width)
    }
}
