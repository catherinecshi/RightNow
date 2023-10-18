import UIKit

class TimerView: UIView {
    let timeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 30)
        label.textAlignment = .center
        label.text = "00:00:00"
        label.textColor = UIColor.white
        return label
    }()
    
    lazy var startStopButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Start", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 20)
        button.setTitleColor(UIColor.white, for: .normal)
        return button
    }()
    
    //initialisation and layout code goes below
    init() {
        super.init(frame: .zero)
        setupSubviews()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupSubviews() {
        addSubview(timeLabel)
        addSubview(startStopButton)
    }
    
    private func setupConstraints() {
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        startStopButton.translatesAutoresizingMaskIntoConstraints = false
        
        startStopButton.widthAnchor.constraint(equalToConstant: 150).isActive = true
        startStopButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        
        NSLayoutConstraint.activate([
            timeLabel.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            timeLabel.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            
            startStopButton.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            startStopButton.topAnchor.constraint(equalTo: timeLabel.bottomAnchor, constant: 20)
        ])

    }
}
