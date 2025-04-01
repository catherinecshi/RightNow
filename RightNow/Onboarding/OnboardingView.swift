import Foundation
import UIKit

protocol OnboardingViewDelegate {
    func onboardingViewDidAdjustTime(_ minutes: Int)
    func onboardingViewDidTapCharacter()
    func onboardingViewDidTapResponseButton()
}

class OnboardingView: UIView {
    // MARK: - Normal Properties
    var delegate: OnboardingViewDelegate?
    let imageView = UIImageView()
    private var pulseAnimationIsActive = false
    private var imageViewObserver: NSKeyValueObservation?
    private var couponsImageObserver: NSKeyValueObservation?
    
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
    
    private lazy var couponsInstructionLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 20, weight: .medium)
        label.textColor = .white
        label.textAlignment = .center
        label.numberOfLines = 0
        label.text = "Maow will also give you coupons if you lock your phone away and spend time with her"
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
        label.isHidden = true
        return label
    }()
    
    var timerSlider: UISlider = {
        let slider = UISlider()
        slider.minimumValue = 15 // 15 minute minimum
        slider.maximumValue = 120
        slider.value = 25
        slider.minimumTrackTintColor = UIConfiguration.tintColor
        slider.translatesAutoresizingMaskIntoConstraints = false
        slider.isHidden = true
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
        button.isHidden = true
        return button
    }()
    
    private let couponsImage: UIImageView = {
        let image = UIImageView()
        image.translatesAutoresizingMaskIntoConstraints = false
        image.image = EmojiImage.createImage(from: "🎟️", size: 20)
        image.contentMode = .scaleAspectFit
        image.isHidden = true
        return image
    }()
    
    private let couponsCountLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = String(5)
        label.font = UIConfiguration.buttonFont
        label.textColor = .black
        label.textAlignment = .center
        label.isHidden = true
        return label
    }()
    
    // MARK: - Onboarding Properties
    var responseButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Hi Maow!", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 20)
        button.setTitleColor(UIColor.white, for: .normal)
        button.backgroundColor = UIConfiguration.tintColor
        button.layer.cornerRadius = 12
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isHidden = true
        return button
    }()
    
    var hiLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 30, weight: .bold)
        label.text = "Hi!"
        label.textColor = .black
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isHidden = true
        return label
    }()
    
    var meetMaowLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 30, weight: .bold)
        label.text = "Meet Maow!"
        label.textColor = .black
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isHidden = true
        return label
    }()
    
    var maowDescriptionLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.numberOfLines = 0
        //label.text = "Maow doesn't have any arms or legs, so her life is in your hands"
        label.text = "Thanks for adopting her! She's been abandoned for a while"
        label.textColor = .black
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isHidden = true
        return label
    }()
    
    var descriptionPSLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 20, weight: .thin)
        label.numberOfLines = 0
        //label.text = "(she doesn't have those either)"
        label.text = "ever since her last owner threw her out..."
        label.textColor = .black
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isHidden = true
        return label
    }()
    
    var lastOwnerLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 22, weight: .medium)
        label.numberOfLines = 0
        label.text = "Well, Maow doesn't have hands or legs, so you'd have to take care of her 24/7"
        label.textColor = .black
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isHidden = true
        return label
    }()
    
    var neglectLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 20, weight: .medium)
        label.numberOfLines = 0
        label.text = "So most people end up neglecting her"
        label.textColor = .black
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isHidden = true
        return label
    }()
    
    var tauntLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.numberOfLines = 0
        label.text = "Umm... Of course not..."
        label.textColor = .black
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isHidden = true
        return label
    }()
    
    var keepUpLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.numberOfLines = 0
        label.text = "I'm sure you wouldn't do that..."
        label.textColor = .black
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isHidden = true
        return label
    }()
    
    var newOwnerLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 24, weight: .medium)
        label.numberOfLines = 0
        label.text = "Anyways, as Maow's new owner, you two will be soul-linked and you'll now have to take care of her."
        label.textColor = .black
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isHidden = true
        return label
    }()
    
    // MARK: - Lifecycle
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupObservers()
        setupOnboarding()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        imageViewObserver?.invalidate()
        couponsImageObserver?.invalidate()
    }
    
    private func setupObservers() {
        imageViewObserver = imageView.observe(\.bounds, options: [.new]) { [weak self] _, _ in
            guard let self = self,
                  !self.focusView.isHidden,
                  self.currentFocusTarget == .maow else { return }
            
            self.updateFocusView()
        }
        
        couponsImageObserver = couponsImage.observe(\.bounds, options: [.new]) { [weak self] _, _ in
            guard let self = self,
                  !self.focusView.isHidden,
                  self.currentFocusTarget == .coupons else { return }
            
            self.updateFocusViewCoupons()
        }
    }
    
    // MARK: - Base UI
    
    private func setupUI() {
        backgroundColor = .white
        
        setupImageView()
        setupTimerLabel()
        setupSlider()
        setupButton()
        setupCoupons()
        setupTapGesture()
        setupFocusView()
    }
    
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
            imageView.widthAnchor.constraint(equalTo: self.widthAnchor, multiplier: 0.3),
            imageView.heightAnchor.constraint(equalTo: self.heightAnchor, multiplier: 0.3)
        ])
    }
    
    private func setupFocusView() {
        addSubview(focusView)
        addSubview(focusInstructionLabel)
        addSubview(couponsInstructionLabel)
        
        NSLayoutConstraint.activate([
            focusView.topAnchor.constraint(equalTo: topAnchor),
            focusView.leadingAnchor.constraint(equalTo: leadingAnchor),
            focusView.trailingAnchor.constraint(equalTo: trailingAnchor),
            focusView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            focusInstructionLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 20),
            focusInstructionLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            focusInstructionLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 40),
            focusInstructionLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -40),
            
            couponsInstructionLabel.bottomAnchor.constraint(equalTo: couponsCountLabel.topAnchor, constant: -10),
            couponsInstructionLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            couponsInstructionLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            couponsInstructionLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20)
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
    }
    
    private func setupCoupons() {
        self.addSubview(couponsImage)
        self.addSubview(couponsCountLabel)
        
        NSLayoutConstraint.activate([
            couponsImage.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            couponsImage.bottomAnchor.constraint(equalTo: startStopButton.topAnchor, constant: -20),
            couponsImage.widthAnchor.constraint(equalToConstant: 28),
            couponsImage.heightAnchor.constraint(equalToConstant: 28),
            
            couponsCountLabel.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            couponsCountLabel.bottomAnchor.constraint(equalTo: couponsImage.topAnchor, constant: -10)
        ])
    }
    
    // MARK: - Actions
    @objc private func handleTap() {
        stopEmojiTransitionSequence()
        delegate?.onboardingViewDidTapCharacter()
        hideFocusView()
    }
    
    @objc private func sliderValueChanged() {
        delegate?.onboardingViewDidAdjustTime(Int(timerSlider.value))
    }
    
    @objc private func responseButtonTapped() {
        delegate?.onboardingViewDidTapResponseButton()
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
    
    // MARK: - Focus View Methods
    private enum FocusTarget {
        case none
        case maow
        case coupons
    }
    
    private var currentFocusTarget: FocusTarget = .none
    
    func showFocusView(withInstructions text: String? = nil) {
        // make sure the view has been laid out
        layoutIfNeeded()
        
        currentFocusTarget = .maow
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
    
    func showFocusViewCoupons(withInstructions text: String? = nil) {
        // make sure the view has been laid out
        layoutIfNeeded()
        
        currentFocusTarget = .coupons
        focusView.ovalRect = couponsImage.frame.insetBy(dx: -20, dy: -20)
        
        // update instruction text
        if let text = text {
            couponsInstructionLabel.text = text
        }
        
        // bring to the front
        bringSubviewToFront(focusView)
        bringSubviewToFront(couponsInstructionLabel)
        
        focusView.isHidden = false
        couponsInstructionLabel.isHidden = false
        
        UIView.animate(withDuration: 0.3) {
            self.focusView.alpha = 1.0
            self.couponsInstructionLabel.alpha = 1.0
        }
    }
    
    func updateFocusView() {
        // get actual frame of image view
        let actualFrame = convert(imageView.frame, from: imageView.superview)
        
        focusView.ovalRect = actualFrame.insetBy(dx: -20, dy: -20)
    }
    
    func updateFocusViewCoupons() {
        // get actual frame of image view
        let actualFrame = convert(couponsImage.frame, from: couponsImage.superview)
        
        focusView.ovalRect = actualFrame.insetBy(dx: -20, dy: -20)
    }
    
    func hideFocusView() {
        stopEmojiTransitionSequence()
        
        UIView.animate(withDuration: 0.3, animations: {
            self.focusView.alpha = 0.0
            self.focusInstructionLabel.alpha = 0.0
        }, completion: { _ in
            self.focusView.isHidden = true
            self.focusInstructionLabel.isHidden = true
        })
    }
    
    // MARK: - Messages UI
    private func setupOnboarding() {
        setupResponseButton()
        setupHi()
        setupMeetMaow()
        setupMaowDescription()
        setupDescriptionPS()
        setupLastOwner()
        setupNeglect()
        setupTaunt()
        setupKeepUp()
        setupNewOwner()
    }
    
    private func setupResponseButton() {
        self.addSubview(responseButton)
        
        NSLayoutConstraint.activate([
            responseButton.bottomAnchor.constraint(equalTo: self.safeAreaLayoutGuide.bottomAnchor, constant: -40),
            responseButton.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            responseButton.heightAnchor.constraint(equalToConstant: 100),
            responseButton.widthAnchor.constraint(equalToConstant: 300)
        ])
        
        responseButton.addTarget(self, action: #selector(responseButtonTapped), for: .touchUpInside)
    }
    
    private func setupHi() {
        self.addSubview(hiLabel)
        
        NSLayoutConstraint.activate([
            hiLabel.bottomAnchor.constraint(equalTo: imageView.topAnchor, constant: -100),
            hiLabel.centerXAnchor.constraint(equalTo: self.centerXAnchor)
        ])
    }
    
    private func setupMeetMaow() {
        self.addSubview(meetMaowLabel)
        
        NSLayoutConstraint.activate([
            meetMaowLabel.topAnchor.constraint(equalTo: hiLabel.bottomAnchor, constant: 10),
            meetMaowLabel.centerXAnchor.constraint(equalTo: self.centerXAnchor)
        ])
    }
    
    private func setupMaowDescription() {
        self.addSubview(maowDescriptionLabel)
        
        NSLayoutConstraint.activate([
            maowDescriptionLabel.topAnchor.constraint(equalTo: hiLabel.topAnchor),
            maowDescriptionLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 20),
            maowDescriptionLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -20)
        ])
    }
    
    private func setupDescriptionPS() {
        self.addSubview(descriptionPSLabel)
        
        NSLayoutConstraint.activate([
            descriptionPSLabel.topAnchor.constraint(equalTo: maowDescriptionLabel.bottomAnchor, constant: 1),
            descriptionPSLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 20),
            descriptionPSLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -20)
        ])
    }
    
    private func setupLastOwner() {
        self.addSubview(lastOwnerLabel)
        
        NSLayoutConstraint.activate([
            lastOwnerLabel.topAnchor.constraint(equalTo: hiLabel.topAnchor, constant: -20),
            lastOwnerLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 20),
            lastOwnerLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -20)
        ])
    }
    
    private func setupNeglect() {
        self.addSubview(neglectLabel)
        
        NSLayoutConstraint.activate([
            neglectLabel.topAnchor.constraint(equalTo: lastOwnerLabel.bottomAnchor),
            neglectLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 20),
            neglectLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -20)
        ])
    }
    
    private func setupTaunt() {
        self.addSubview(tauntLabel)
        
        NSLayoutConstraint.activate([
            tauntLabel.topAnchor.constraint(equalTo: hiLabel.topAnchor),
            tauntLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 20),
            tauntLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -20)
        ])
    }
    
    private func setupKeepUp() {
        self.addSubview(keepUpLabel)
        
        NSLayoutConstraint.activate([
            keepUpLabel.topAnchor.constraint(equalTo: tauntLabel.bottomAnchor, constant: 10),
            keepUpLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 20),
            keepUpLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -20)
        ])
    }
    
    private func setupNewOwner() {
        self.addSubview(newOwnerLabel)
        
        NSLayoutConstraint.activate([
            newOwnerLabel.topAnchor.constraint(equalTo: hiLabel.topAnchor),
            newOwnerLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 20),
            newOwnerLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -20)
        ])
    }
    
    // MARK: - Onboarding Animations
    func animateAppearance(of view: UIView, duration: TimeInterval = 0.2) {
        view.alpha = 0
        view.isHidden = false
        
        UIView.animate(withDuration: duration) {
            view.alpha = 1
        }
    }
    
    func animateDisappearance(of view: UIView, duration: TimeInterval = 0.2, completion: ((Bool) -> Void)? = nil) {
        UIView.animate(withDuration: duration, animations: {
            view.alpha = 0
        }, completion: { finished in
            view.isHidden = true
            completion?(finished)
        })
    }
    
    // animate disappearances
    func hideAllOnboardingLabels() {
        hiLabel.isHidden = true
        meetMaowLabel.isHidden = true
        maowDescriptionLabel.isHidden = true
        descriptionPSLabel.isHidden = true
        lastOwnerLabel.isHidden = true
    }
    
    // animate the button and text
    func hideResponseButton(duration: TimeInterval = 0.2) {
        animateDisappearance(of: responseButton, duration: duration)
    }
    
    func showResponseButton(title: String, duration: TimeInterval = 0.2) {
        responseButton.setTitle(title, for: .normal)
        animateAppearance(of: responseButton, duration: duration)
    }
    
    // for part 2 of onbaording where it transitions between them
    private var emojiSequence = ["😺", "😿", "😸"]
    private var currentEmojiIndex = 0
    private var emojiTransitionTimer: Timer?
    private var emojiCycleCompleted: (() -> Void)?
    
    func startEmojiTransitionSequence(onCycleCompleted: (() -> Void)?) {
        // store completion handler
        self.emojiCycleCompleted = onCycleCompleted
        
        // Reset to the first emoji
        currentEmojiIndex = 0
        updateEmojiDisplay(emoji: emojiSequence[currentEmojiIndex])
        
        // Stop any existing timer
        emojiTransitionTimer?.invalidate()
        
        // Create a new timer that changes the emoji every 1.5 seconds
        emojiTransitionTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            // Move to next emoji in sequence
            self.currentEmojiIndex = (self.currentEmojiIndex + 1) % self.emojiSequence.count
            self.updateEmojiDisplay(emoji: self.emojiSequence[self.currentEmojiIndex])
            
            // check if we've completed a full cycle (back to first emoji)
            if self.currentEmojiIndex == 0 && self.emojiCycleCompleted != nil {
                let handler = self.emojiCycleCompleted
                self.emojiCycleCompleted = nil
                handler?()
            }
        }
    }
    
    func stopEmojiTransitionSequence() {
        emojiTransitionTimer?.invalidate()
        emojiTransitionTimer = nil
        emojiCycleCompleted = nil
    }

    // Reusable method to update emoji display
    func updateEmojiDisplay(emoji: String) {
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
        
        // Animate the transition to the new emoji
        UIView.transition(with: imageView,
                          duration: 0.3,
                          options: .transitionCrossDissolve,
                          animations: { [weak self] in
            self?.imageView.image = emojiImage
        })
    }
    
    // MARK: - Onboarding Pt 2
    func showTimer() {
        // have them be invisible at the start
        timerLabel.alpha = 0.0
        timerLabel.isHidden = false
        timerSlider.alpha = 0.0
        timerSlider.isHidden = false
        
        // animate them in
        UIView.animate(withDuration: 0.1) {
            self.timerLabel.alpha = 1.0
            self.timerSlider.alpha = 1.0
        }
    }
    
    func showCoupons() {
        startStopButton.alpha = 0.0
        startStopButton.isHidden = false
        
        couponsImage.alpha = 0.0
        couponsImage.isHidden = false
        couponsCountLabel.alpha = 0.0
        couponsCountLabel.isHidden = false
        
        UIView.animate(withDuration: 0.1) {
            self.startStopButton.alpha = 1.0
            self.couponsImage.alpha = 1.0
            self.couponsCountLabel.alpha = 1.0
        }
    }
}
