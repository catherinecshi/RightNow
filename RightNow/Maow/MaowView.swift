import Foundation
import UIKit

protocol MaowViewDelegate {
    func maowViewDidTapStart()
    func maowViewDidAdjustTime(_ minutes: Int)
    func maowViewDidTapCharacter()
}

class MaowView: UIView {
    var delegate: MaowViewDelegate?
    
    let imageView = UIImageView()
    
    let timerLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 48, weight: .bold)
        label.textAlignment = .center
        label.text = "25:00"
        label.textColor = UIConfiguration.tintColor
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    var timerSlider: UISlider = {
        let slider = UISlider()
        slider.minimumValue = 10 // 10 minute minimum
        slider.maximumValue = 120
        slider.value = 25
        slider.translatesAutoresizingMaskIntoConstraints = false
        return slider
    }()
    
    lazy var startStopButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Work", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 20)
        button.setTitleColor(UIColor.white, for: .normal)
        button.backgroundColor = UIConfiguration.tintColor
        button.layer.cornerRadius = 12
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .white
        
        setupImageView()
        setupTimerLabel()
        setupSlider()
        setupButton()
        setupTapGesture()
    }
    
    private func setupImageView() {
        if let frontImage = UIImage(named: "patamon_front") {
            print("Successfully loaded patamon front")
            imageView.image = frontImage
        } else {
            print("Failed to load patamon front")
        }
        
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(imageView)
        
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            imageView.widthAnchor.constraint(equalTo: self.widthAnchor, multiplier: 0.3),
            imageView.heightAnchor.constraint(equalTo: self.heightAnchor, multiplier: 0.3)
        ])
    }
    
    private func setupTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        imageView.addGestureRecognizer(tapGesture)
        imageView.isUserInteractionEnabled = true
    }
    
    private func setupTimerLabel() {
        self.addSubview(timerLabel)
        
        NSLayoutConstraint.activate([
            timerLabel.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            timerLabel.bottomAnchor.constraint(equalTo: imageView.topAnchor, constant: -40)
        ])
        
        // check if the focusTime is supposed to be something different
        //timerModelDidUpdateTime()
    }
    
    private func setupSlider() {
        self.addSubview(timerSlider)
        
        NSLayoutConstraint.activate([
            timerSlider.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            timerSlider.topAnchor.constraint(equalTo: timerLabel.bottomAnchor, constant: 20),
            timerSlider.widthAnchor.constraint(equalTo: self.widthAnchor, multiplier: 0.7)
        ])
        
        timerSlider.addTarget(self, action: #selector(sliderValueChanged), for: .valueChanged)
    }
    
    private func setupButton() {
        self.addSubview(startStopButton)
        
        NSLayoutConstraint.activate([
            startStopButton.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            startStopButton.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 40),
            startStopButton.widthAnchor.constraint(equalToConstant: 200),
            startStopButton.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        startStopButton.addTarget(self, action: #selector(startButtonTapped), for: .touchUpInside)
    }
    
    // MARK: - Actions
    @objc private func handleTap() {
        delegate?.maowViewDidTapCharacter()
    }
    
    @objc private func sliderValueChanged() {
        delegate?.maowViewDidAdjustTime(Int(timerSlider.value))
    }
    
    @objc private func startButtonTapped() {
        delegate?.maowViewDidTapStart()
    }
    
    // MARK: - Public Methods
    func updateTimeDisplay(minutes: Int, seconds: Int) {
        timerLabel.text = String(format: "%02d:%02d", minutes, seconds)
    }
    
    func updateSliderDisplay(value: Float) {
        timerSlider.value = value
    }
    
    func updateControlsForSession(isActive: Bool) {
        startStopButton.setTitle(isActive ? "Give Up" : "Work", for: .normal)
        timerSlider.isEnabled = !isActive
    }
    
    func updateCharacterState(isAsleep: Bool) {
        guard let newImage = UIImage(named: isAsleep ? "patamon_asleep" : "patamon_front") else {
            return
        }
        
        UIView.transition(with: imageView,
                          duration: 0.2,
                          options: .transitionCrossDissolve,
                          animations: { [weak self] in
            self?.imageView.image = newImage
        })
    }
    
    func updateCoinCount(_ count: Int) {
        
    }
}
