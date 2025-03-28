import UIKit

// Upgrade model
class Upgrade {
    let name: String
    let baseCost: Double
    let range: Int
    let description: String
    var level: Int = 0
    
    var currentCost: Double {
        return baseCost * pow(1.15, Double(level))
    }
    
    init(name: String, baseCost: Double, range: Int, description: String) {
        self.name = name
        self.baseCost = baseCost
        self.range = range
        self.description = description
    }
}

enum UpgradeType: String, CaseIterable {
    case d6 = "Add a dice roll to total"
    case cards = "Add playing cards to total"
    case roulette = "Add a roulette to total"
    case bingo = "Add a bingo cage to total"
    case lottery = "Add a lottery card to total"
    
    var baseCost: Double {
        switch self {
        case .d6: return 15
        case .cards: return 100
        case .roulette: return 1100
        case .bingo: return 12000
        case .lottery: return 130000
        }
    }
    
    var range: Double {
        switch self {
        case .d6: return 6
        case .cards: return 13
        case .roulette: return 36
        case .bingo: return 75
        case .lottery: return 200
        }
    }
    
    var description: String {
        switch self {
        case .d6: return "Adds 1-6 to your total in the number factory"
        case .cards: return "Adds 1-13 to your total in the number factory"
        case .roulette: return "Adds 1-36 to your total in the number factory"
        case .bingo: return "Adds 1-75 to your total in the number factory"
        case .lottery: return "Adds 1-150 to your total in the number factory"
        }
    }
}

// Custom cell for upgrades
class UpgradeCell: UITableViewCell {
    private let nameLabel = UILabel()
    private let costLabel = UILabel()
    private let levelLabel = UILabel()
    private let descriptionLabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        // Name label
        nameLabel.font = UIFont.boldSystemFont(ofSize: 18)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(nameLabel)
        
        // Cost label
        costLabel.font = UIFont.systemFont(ofSize: 14)
        costLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(costLabel)
        
        // Level label
        levelLabel.font = UIFont.systemFont(ofSize: 14)
        levelLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(levelLabel)
        
        // Description label
        descriptionLabel.font = UIFont.systemFont(ofSize: 12)
        descriptionLabel.textColor = .secondaryLabel
        descriptionLabel.numberOfLines = 2
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(descriptionLabel)
        
        // Layout constraints
        NSLayoutConstraint.activate([
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 15),
            
            levelLabel.centerYAnchor.constraint(equalTo: nameLabel.centerYAnchor),
            levelLabel.leadingAnchor.constraint(equalTo: nameLabel.trailingAnchor, constant: 10),
            
            costLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            costLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -15),
            
            descriptionLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 5),
            descriptionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 15),
            descriptionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -15),
        ])
    }
    
    func configure(with upgradeType: UpgradeType, level: Int, cost: Double, canAfford: Bool) {
        nameLabel.text = upgradeType.rawValue
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        
        let costText = formatter.string(from: NSNumber(value: cost)) ?? "0"
        costLabel.text = "Cost: \(costText)"
        costLabel.textColor = canAfford ? .systemGreen : .systemRed
        
        levelLabel.text = "Lvl \(level)"
        descriptionLabel.text = upgradeType.description
    }
}
