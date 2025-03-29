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
    private var imageViewObserver: NSKeyValueObservation?
    
    private lazy var focusView: FocusView = {
       let view = FocusView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true
        view.alpha = 0.0
        view.shapeType = .circle
        return view
    }()
    
    private lazy var focusInstructionLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 20, weight: .medium)
        label.textColor = .white
        label.textAlignment = .center
        label.numberOfLines = 0
        label.text = "Tap Maow to make it happy!"
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isHidden = true
        label.alpha = 0.0
        return label
    }()
    
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
        slider.minimumValue = 1 // 10 minute minimum
        slider.maximumValue = 120
        slider.value = 25
        slider.minimumTrackTintColor = UIConfiguration.tintColor
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
        setupObservers()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        imageViewObserver?.invalidate()
    }
    
    private func setupObservers() {
        imageViewObserver = imageView.observe(\.bounds, options: [.new]) { [weak self] _, _ in
            guard let self = self, !self.focusView.isHidden else { return }
            self.updateFocusView()
        }
    }
    
    private func setupUI() {
        backgroundColor = .white
        
        setupImageView()
        setupTimerLabel()
        setupSlider()
        setupButton()
        setupTapGesture()
        setupFocusView()
    }
    
    private func setupImageView() {
        if let frontImage = UIImage(named: "Maow_Normal") {
            print("Successfully loaded maow normal")
            imageView.image = frontImage
        } else {
            print("Failed to load maow normal")
        }
        
        imageView.contentMode = .scaleAspectFill
        imageView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(imageView)
        
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            imageView.widthAnchor.constraint(equalTo: self.widthAnchor, multiplier: 0.3),
            imageView.heightAnchor.constraint(equalTo: self.heightAnchor, multiplier: 0.3)
        ])
    }
    
    private func setupFocusView() {
        addSubview(focusView)
        addSubview(focusInstructionLabel)
        
        NSLayoutConstraint.activate([
            focusView.topAnchor.constraint(equalTo: topAnchor),
            focusView.leadingAnchor.constraint(equalTo: leadingAnchor),
            focusView.trailingAnchor.constraint(equalTo: trailingAnchor),
            focusView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            focusInstructionLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 20),
            focusInstructionLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            focusInstructionLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 40),
            focusInstructionLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -40)
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
            timerLabel.topAnchor.constraint(equalTo: self.safeAreaLayoutGuide.topAnchor, constant: 40),
            timerLabel.centerXAnchor.constraint(equalTo: self.centerXAnchor)
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
            startStopButton.bottomAnchor.constraint(equalTo: self.safeAreaLayoutGuide.bottomAnchor, constant: -40),
            startStopButton.widthAnchor.constraint(equalToConstant: 200),
            startStopButton.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        startStopButton.addTarget(self, action: #selector(startButtonTapped), for: .touchUpInside)
    }
    
    // MARK: - Actions
    @objc private func handleTap() {
        delegate?.maowViewDidTapCharacter()
        hideFocusView()
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
        guard let newImage = UIImage(named: isAsleep ? "Maow_Happy_Jump" : "Maow_Normal") else {
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
    
    // MARK: - Focus View Methods
    func showFocusView(withInstructions text: String? = nil) {
        // make sure the view has been laid out
        layoutIfNeeded()
        
        focusView.ovalRect = imageView.frame.insetBy(dx: -20, dy: -20)
        
        // update instruction text
        if let text = text {
            focusInstructionLabel.text = text
        }
        
        // bring to the front
        bringSubviewToFront(focusView)
        bringSubviewToFront(focusInstructionLabel)
        bringSubviewToFront(imageView) // to keep it interactive
        
        focusView.isHidden = false
        focusInstructionLabel.isHidden = false
        
        UIView.animate(withDuration: 0.3) {
            self.focusView.alpha = 1.0
            self.focusInstructionLabel.alpha = 1.0
        }
    }
    
    func updateFocusView() {
        // get actual frame of image view
        let actualFrame = convert(imageView.frame, from: imageView.superview)
        
        focusView.ovalRect = actualFrame.insetBy(dx: -20, dy: -20)
    }
    
    func hideFocusView() {
        UIView.animate(withDuration: 0.3, animations: {
            self.focusView.alpha = 0.0
            self.focusInstructionLabel.alpha = 0.0
        }, completion: { _ in
            self.focusView.isHidden = true
            self.focusInstructionLabel.isHidden = true
        })
    }
}
