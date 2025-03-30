import UIKit

class EmojiCell: UICollectionViewCell {
    private let emojiLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        emojiLabel.textAlignment = .center
        emojiLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(emojiLabel)
        
        NSLayoutConstraint.activate([
            emojiLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            emojiLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            emojiLabel.widthAnchor.constraint(equalTo: contentView.widthAnchor),
            emojiLabel.heightAnchor.constraint(equalTo: contentView.heightAnchor)
        ])
    }
    
    func configure(with emoji: String) {
        emojiLabel.font = UIFont.systemFont(ofSize: 18)
        emojiLabel.text = emoji
    }
    
    func configureEmpty() {
        emojiLabel.font = UIFont.systemFont(ofSize: 12)
        emojiLabel.text = "None yet"
        emojiLabel.textColor = .secondaryLabel
    }
}
