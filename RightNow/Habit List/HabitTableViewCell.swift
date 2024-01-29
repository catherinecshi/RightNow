import UIKit

class HabitTableViewCell: UITableViewCell {
    
    // MARK: Initialisation
    
    let nameLabel = UILabel()
    let containerView = UIView()
    
    let timeLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .black
        label.adjustsFontSizeToFitWidth = true //auto adjust font size
        label.minimumScaleFactor = 0.5
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        setupTimeLabel()
        setupContainerView()
        setupNameLabel()
        setupCellConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Setup
    
    private func setupTimeLabel() {
        contentView.addSubview(timeLabel)
    }
    
    private func setupContainerView() {
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.backgroundColor = UIColor(hexString: "#ff5a66")
        
        //styling
        containerView.layer.cornerRadius = 10
        containerView.layer.shadowColor = UIColor.gray.cgColor
        containerView.layer.shadowOffset = CGSize(width: 0.0, height: 0.0)
        containerView.layer.shadowRadius = 5.0
        containerView.layer.shadowOpacity = 0.5
        
        contentView.addSubview(containerView)
    }
    
    private func setupNameLabel() {
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.textColor = .white
        containerView.addSubview(nameLabel)
    }
    
    private func setupCellConstraints() {
        NSLayoutConstraint.activate([
            //time label
            timeLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            timeLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
            timeLabel.widthAnchor.constraint(equalToConstant: 60),
            
            //container view
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),
            containerView.leadingAnchor.constraint(equalTo: timeLabel.trailingAnchor, constant: 10),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10),
            
            //minimum width and height
            containerView.widthAnchor.constraint(greaterThanOrEqualToConstant: 100),
            containerView.heightAnchor.constraint(greaterThanOrEqualToConstant: 50),
            
            //name label
            nameLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 8),
            nameLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -8),
            nameLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            nameLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16)
        ])
    }
    
    // MARK: Configuration
    
    func configure(with habit: Habit) {
        let dateFormatter = DateFormatter()
        
        //adjust according to user preferences
        if is24HourTimeFormat() {
            dateFormatter.dateFormat = "HH:mm" //24 hour format
        } else {
            dateFormatter.dateFormat = "h:mm a"
        }

        timeLabel.text = dateFormatter.string(from: habit.time)
        
        nameLabel.text = habit.name
    }
    
    func is24HourTimeFormat() -> Bool {
        let dateFormat = DateFormatter.dateFormat(fromTemplate: "j", options: 0, locale: Locale.current)
        
        //if it doesn't contain an "a", it is 24-hour format
        return !(dateFormat?.contains("a") ?? true)
    }
}
