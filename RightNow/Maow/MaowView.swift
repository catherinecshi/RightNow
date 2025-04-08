import Foundation
import UIKit

/// defines delegate methods for handling user interactions with maowview
protocol MaowViewDelegate {
    func maowViewDidTapStart()
    func maowViewDidAdjustTime(_ minutes: Int)
    func maowViewDidTapCharacter()
}

/// displays character, timer controls and UI components
class MaowView: UIView {
    // MARK: - Properties
    var delegate: MaowViewDelegate?
    
    let imageView = UIImageView()
    private var imageViewObserver: NSKeyValueObservation? // observer tracking changes in image view bounds
    
    var emoji = "😺"  // Default emoji
    var happyEmoji = "😸" // Emoji for happy state
    
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
        slider.minimumValue = 15 // 15 minute minimum
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
    
    // MARK: - Initialisation
    
    /// initialises view with a frame
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupObservers()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// Clean up KVO observers when view is deallocated
    deinit {
        imageViewObserver?.invalidate()
    }
    
    // MARK: - Setup
    
    /// Set up KVO observers for tracking layout changes
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
    
    /// Sets up image view using the emoji as a label, and drawing it
    private func setupImageView() {
        // Create a clear background for the emoji rendering
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 200, height: 200))
        let emojiImage = renderer.image { context in
            // Fill with clear color
            UIColor.clear.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 200, height: 200))
            
            // Draw the emoji centered
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .center
            
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 120),
                .paragraphStyle: paragraphStyle,
                .foregroundColor: UIColor.black
            ]
            
            let attributedText = NSAttributedString(string: emoji, attributes: attributes)
            attributedText.draw(in: CGRect(x: 0, y: 40, width: 200, height: 200))
        }
        
        imageView.image = emojiImage
        imageView.contentMode = .scaleAspectFit // Changed to fit to avoid clipping
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.backgroundColor = .clear // Ensure background is clear
        self.addSubview(imageView)
        
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: self.centerYAnchor, constant: 20),
            imageView.widthAnchor.constraint(equalTo: self.widthAnchor, multiplier: 0.6),
            imageView.heightAnchor.constraint(equalTo: self.heightAnchor, multiplier: 0.6)
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
    
    /// tap gesture for maow
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
    
    /// Updates timer display with specified time
    /// - Parameters: minutes, seconds
    func updateTimeDisplay(minutes: Int, seconds: Int) {
        timerLabel.text = String(format: "%02d:%02d", minutes, seconds)
    }
    
    /// Updates slider position to specified value
    /// - Parameter value: new slider value
    func updateSliderDisplay(value: Float) {
        timerSlider.value = value
    }
    
    /// Updates button title based on whether a session is active
    /// - Parameter isActive: whether a time session is currently active
    func updateControlsForSession(isActive: Bool) {
        startStopButton.setTitle(isActive ? "Give Up" : "Work", for: .normal)
        timerSlider.isEnabled = !isActive
    }
    
    /// Updates character emoji based on happiness state
    /// - Parameter isHappy: whether the character should be in a happy state
    func updateCharacterState(isHappy: Bool) {
        let newEmoji = isHappy ? happyEmoji : emoji
        
        // Create a clear background for the emoji rendering
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 200, height: 200))
        let emojiImage = renderer.image { context in
            // Fill with clear color
            UIColor.clear.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 200, height: 200))
            
            // Draw the emoji centered
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .center
            
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 120),
                .paragraphStyle: paragraphStyle,
                .foregroundColor: UIColor.black
            ]
            
            let attributedText = NSAttributedString(string: newEmoji, attributes: attributes)
            attributedText.draw(in: CGRect(x: 0, y: 40, width: 200, height: 120))
        }
        
        // Animate the transition to the new emoji
        UIView.transition(with: imageView,
                          duration: 0.3,
                          options: .transitionCrossDissolve,
                          animations: { [weak self] in
            self?.imageView.image = emojiImage
        })
    }
    
    func updateCoinCount(_ count: Int) {
        
    }
    
    // MARK: - Focus View Methods
    
    /// Show focus view on maow
    /// - Parameter text: optional text for instrutions label
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
    
    /// updates position and size of focus view
    func updateFocusView() {
        // get actual frame of image view
        let actualFrame = convert(imageView.frame, from: imageView.superview)
        
        focusView.ovalRect = actualFrame.insetBy(dx: -20, dy: -20)
    }
    
    /// hides focus view with an animation
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
