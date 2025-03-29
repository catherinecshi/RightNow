import UIKit

// MARK: - Upgrade Cell
class UpgradeCell: UITableViewCell {
    private let containerView = UIView()
    private let emojiContainerView = UIView()
    private let expandableContentView = UIView()
    
    private let nameLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let dividerView = UIView()
    
    private let buyButton = UIButton(type: .system)
    private let costLabel = UILabel()
    
    private var emojiCount = 0
    private var emojiType = ""
    private var emojiViews: [UILabel] = []
    
    private var upgradeType: UpgradeType?
    var buyButtonTapped: ((UpgradeType) -> Void)?
    
    private(set) var isExpanded = false
    
    // MARK: - Lifecycle
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let buyButtonMaskPath = UIBezierPath(
            roundedRect: buyButton.bounds,
            byRoundingCorners: [.topRight, .bottomRight],
            cornerRadii: CGSize(width: 12, height: 12)
        )
        
        let buyButtonMaskLayer = CAShapeLayer()
        buyButtonMaskLayer.path = buyButtonMaskPath.cgPath
        buyButton.layer.mask = buyButtonMaskLayer
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        clearEmojiViews()
    }
    
    // MARK: - Setup UI
    private func setupUI() {
        // clear default selection style
        selectionStyle = .none
        backgroundColor = .clear
        
        // configure container view
        containerView.backgroundColor = .systemGray6
        containerView.layer.cornerRadius = 12
        containerView.layer.masksToBounds = true
        containerView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(containerView)
        
        // emoji container
        emojiContainerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(emojiContainerView)
        
        // configure expandable content view
        expandableContentView.translatesAutoresizingMaskIntoConstraints = false
        expandableContentView.alpha = 0
        expandableContentView.isHidden = true
        containerView.addSubview(expandableContentView)
        
        // Name label
        nameLabel.font = UIFont.boldSystemFont(ofSize: 16)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        expandableContentView.addSubview(nameLabel)
        
        // Description label
        descriptionLabel.font = UIFont.systemFont(ofSize: 12)
        descriptionLabel.textColor = .secondaryLabel
        descriptionLabel.numberOfLines = 2
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        expandableContentView.addSubview(descriptionLabel)
        
        // buy button
        dividerView.backgroundColor = .systemGray3
        dividerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(dividerView)
        
        buyButton.setTitle("+", for: .normal)
        buyButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 24)
        buyButton.backgroundColor = UIConfiguration.tintColor
        buyButton.setTitleColor(.white, for: .normal)
        buyButton.layer.cornerRadius = 8
        buyButton.addTarget(self, action: #selector(buyButtonPressed), for: .touchUpInside)
        buyButton.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(buyButton)
        
        // Cost label
        costLabel.textAlignment = .center
        costLabel.font = UIFont.systemFont(ofSize: 12)
        costLabel.textColor = .white
        costLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(costLabel)
        
        // Layout constraints
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            
            // buy button
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
            costLabel.trailingAnchor.constraint(equalTo: buyButton.trailingAnchor, constant: -4),
            
            // Emoji container takes the main area
            emojiContainerView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 10),
            emojiContainerView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 10),
            emojiContainerView.trailingAnchor.constraint(equalTo: dividerView.leadingAnchor, constant: -10),
            
            // Expandable content appears below emojis
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
    private func clearEmojiViews() {
        emojiViews.forEach { $0.removeFromSuperview() }
        emojiViews.removeAll()
    }
    
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
        
        // Animate all changes together
        UIView.animate(withDuration: 0.3, animations: {
            // Toggle visibility with alpha for smooth animation
            self.expandableContentView.isHidden = !self.isExpanded
            self.expandableContentView.alpha = self.isExpanded ? 1.0 : 0.0
            
            // Force layout during animation
            self.layoutIfNeeded()
        })
        
        // animate
        UIView.animate(withDuration: 0.3) {
            self.expandableContentView.isHidden = !self.isExpanded
            
            // force layout update
            self.layoutIfNeeded()
        }
    }
    
    @objc private func buyButtonPressed() {
        if let upgradeType = upgradeType {
            buyButtonTapped?(upgradeType)
        }
    }
}

// MARK: - UICollectionView DataSource & Delegate
extension UpgradeCell: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return emojiCount > 0 ? emojiCount : 1 // At least one item to show "None yet"
    }
    
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
