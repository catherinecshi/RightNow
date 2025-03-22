import UIKit

class HabitTableViewCell: UITableViewCell {
    
    // MARK: Initialisation
    
    let nameLabel = UILabel()
    let streaksLabel = UILabel()
    let containerView = UIView()
    let progressLayer = CALayer()
    
    private var currentProgress: CGFloat = 0
    
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
        setupProgressLayer()
        setupNameLabel()
        setupStreaksLabel()
        setupCellConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        updateProgressLayerFrame()
    }
    
    // MARK: Setup
    
    private func setupTimeLabel() {
        contentView.addSubview(timeLabel)
    }
    
    private func setupContainerView() {
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.backgroundColor = UIConfiguration.tintColor
        
        //styling
        containerView.layer.cornerRadius = 10
        containerView.layer.shadowColor = UIColor.gray.cgColor
        containerView.layer.shadowOffset = CGSize(width: 0.0, height: 0.0)
        containerView.layer.shadowRadius = 5.0
        containerView.layer.shadowOpacity = 0.5
        
        contentView.addSubview(containerView)
    }
    
    private func setupProgressLayer() {
        progressLayer.backgroundColor = UIColor.white.withAlphaComponent(0.3).cgColor
        containerView.layer.addSublayer(progressLayer)
    }
    
    private func setupNameLabel() {
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.textColor = .white
        nameLabel.textAlignment = .left
        containerView.addSubview(nameLabel)
    }
    
    private func setupStreaksLabel() {
        streaksLabel.translatesAutoresizingMaskIntoConstraints = false
        streaksLabel.textColor = .white
        streaksLabel.textAlignment = .right
        streaksLabel.adjustsFontSizeToFitWidth = true
        streaksLabel.minimumScaleFactor = 0.5
        containerView.addSubview(streaksLabel)
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
            nameLabel.trailingAnchor.constraint(equalTo: streaksLabel.leadingAnchor, constant: -8),
            
            // streaks label
            streaksLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 8),
            streaksLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -8),
            streaksLabel.leadingAnchor.constraint(equalTo: nameLabel.trailingAnchor, constant: 8),
            streaksLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            
            // make sure that name label takes up 2/3 and streaks label takes up 1/3 of container view
            nameLabel.widthAnchor.constraint(equalTo: streaksLabel.widthAnchor, multiplier: 2.0)
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
        
        if let time = habit.time {
            timeLabel.text = dateFormatter.string(from: time)
        } else if let cue = habit.cue {
            timeLabel.text = cue
        } else {
            print("something weird - no cue or time")
        }
        
        nameLabel.text = habit.name
        streaksLabel.text = "\(habit.streaks)"
        
        // calculate the % progress someone has made to the next level
        let targetStreaks = CGFloat(habit.currentLevel.streakForLevel)
        let previousStreaks = CGFloat(habit.currentLevel.previousLevel?.streakForLevel ?? 0)
        currentProgress = min((CGFloat(habit.streaks) - previousStreaks) / (targetStreaks - previousStreaks), 1.0)
        
        setNeedsLayout()
    }
    
    func is24HourTimeFormat() -> Bool {
        let dateFormat = DateFormatter.dateFormat(fromTemplate: "j", options: 0, locale: Locale.current)
        
        //if it doesn't contain an "a", it is 24-hour format
        return !(dateFormat?.contains("a") ?? true)
    }
    
    private func updateProgressLayerFrame() {
        let containerBounds = containerView.bounds
        progressLayer.frame = CGRect(x: containerBounds.width * currentProgress,
                                     y:0,
                                     width: containerBounds.width * (1 - currentProgress),
                                     height: containerBounds.height)
        
        // so that the progress is behind the labels
        containerView.layer.insertSublayer(progressLayer, at: 0)
    }
}
