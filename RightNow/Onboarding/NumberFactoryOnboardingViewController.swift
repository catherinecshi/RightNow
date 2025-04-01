import UIKit
import AVFoundation

struct OnboardingStep {
    enum OnboardingMediaType {
        case mp4
        case staticImage
        case emoji
    }
    
    let mediaName: String
    let mediaType: OnboardingMediaType
    let caption: String
}

class NumberFactoryOnboardingViewController: UIViewController {
    // MARK: - Properties
    private let steps: [OnboardingStep]
    private var currentStepIndex = 0
    
    // UI Components
    private let containerView = UIView()
    private let mediaContainerView = UIView()
    private let captionLabel = UILabel()
    private let nextButton = UIButton(type: .system)
    private let skipButton = UIButton(type: .system)
    private let pageControl = UIPageControl()
    
    // video playback properties
    private var playerLayer: AVPlayerLayer?
    private var player: AVPlayer?
    private var playerLooper: AVPlayerLooper?
    
    // Completion handler
    var onComplete: (() -> Void)?
    
    // MARK: - Initialization
    init(steps: [OnboardingStep]) {
        self.steps = steps
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        displayCurrentStep()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Update player layer frame when layout changes
        playerLayer?.frame = mediaContainerView.bounds
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        
        // Container View
        containerView.backgroundColor = .systemBackground
        containerView.layer.cornerRadius = 16
        containerView.clipsToBounds = true
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(containerView)
        
        // GIF ImageView
        mediaContainerView.clipsToBounds = true
        mediaContainerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(mediaContainerView)
        
        // Caption Label
        captionLabel.font = .systemFont(ofSize: 16, weight: .medium)
        captionLabel.textAlignment = .center
        captionLabel.numberOfLines = 0
        captionLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(captionLabel)
        
        // Page Control
        pageControl.numberOfPages = steps.count
        pageControl.currentPage = 0
        pageControl.translatesAutoresizingMaskIntoConstraints = false
        pageControl.addTarget(self, action: #selector(pageControlTapped(_:)), for: .valueChanged)
        containerView.addSubview(pageControl)
        
        // Next Button
        nextButton.setTitle("Next", for: .normal)
        nextButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
        nextButton.backgroundColor = UIConfiguration.tintColor
        nextButton.setTitleColor(.white, for: .normal)
        nextButton.layer.cornerRadius = 8
        nextButton.translatesAutoresizingMaskIntoConstraints = false
        nextButton.addTarget(self, action: #selector(nextButtonTapped), for: .touchUpInside)
        containerView.addSubview(nextButton)
        
        // Skip Button
        skipButton.setTitle("Skip", for: .normal)
        skipButton.titleLabel?.font = .systemFont(ofSize: 16)
        skipButton.setTitleColor(.systemGray, for: .normal)
        skipButton.translatesAutoresizingMaskIntoConstraints = false
        skipButton.addTarget(self, action: #selector(skipButtonTapped), for: .touchUpInside)
        containerView.addSubview(skipButton)
        
        // Layout
        NSLayoutConstraint.activate([
            containerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            containerView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.85),
            containerView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.7),
            
            mediaContainerView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 20),
            mediaContainerView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            mediaContainerView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            mediaContainerView.heightAnchor.constraint(equalTo: containerView.heightAnchor, multiplier: 0.6),
            
            captionLabel.topAnchor.constraint(equalTo: mediaContainerView.bottomAnchor, constant: 16),
            captionLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            captionLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            
            pageControl.topAnchor.constraint(equalTo: captionLabel.bottomAnchor, constant: 16),
            pageControl.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            
            nextButton.topAnchor.constraint(equalTo: pageControl.bottomAnchor, constant: 16),
            nextButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            nextButton.widthAnchor.constraint(equalToConstant: 100),
            nextButton.heightAnchor.constraint(equalToConstant: 44),
            nextButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -20),
            
            skipButton.centerYAnchor.constraint(equalTo: nextButton.centerYAnchor),
            skipButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20)
        ])
    }
    
    // MARK: - Actions
    @objc private func nextButtonTapped() {
        if currentStepIndex < steps.count - 1 {
            currentStepIndex += 1
            displayCurrentStep()
        } else {
            dismiss(animated: true) { [weak self] in
                self?.onComplete?()
            }
        }
    }
    
    @objc private func skipButtonTapped() {
        dismiss(animated: true) { [weak self] in
            self?.onComplete?()
        }
    }
    
    @objc private func pageControlTapped(_ sender: UIPageControl) {
        currentStepIndex = sender.currentPage
        displayCurrentStep()
    }
    
    // MARK: - Helper Methods
    private func displayCurrentStep() {
        guard currentStepIndex < steps.count else { return }
        
        let step = steps[currentStepIndex]
        
        // stop any previous animation
        cleanupCurrentMedia()
        
        // Load media
        switch step.mediaType {
        case .mp4:
            if let videoURL = Bundle.main.url(forResource: step.mediaName, withExtension: "mp4") {
                print("Found video at path: \(videoURL.path)")
                setupVideo(with: videoURL)
            } else {
                print("❌ Could not find video: \(step.mediaName).mp4")
                displayPlaceholder()
            }
        case .staticImage:
            if let image = UIImage(named: step.mediaName) {
                displayImage(image)
            } else {
                print("❌ Could not find image: \(step.mediaName)")
                displayPlaceholder()
            }
        case .emoji:
            displayEmoji(step.mediaName)
        }
        
        captionLabel.text = step.caption
        pageControl.currentPage = currentStepIndex
        
        // Update button title for last step
        if currentStepIndex == steps.count - 1 {
            nextButton.setTitle("Start", for: .normal)
        } else {
            nextButton.setTitle("Next", for: .normal)
        }
    }
    
    private func displayEmoji(_ emoji: String) {
        let label = UILabel()
        label.text = emoji
        
        // Calculate appropriate font size based on container size
        let fontSize = min(mediaContainerView.bounds.width, mediaContainerView.bounds.height) * 0.5
        label.font = UIFont.systemFont(ofSize: fontSize)
        
        label.textAlignment = .center
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.5
        label.frame = mediaContainerView.bounds
        label.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mediaContainerView.addSubview(label)
    }
    
    // MARK: - Setup Media Player
    private func cleanupCurrentMedia() {
        // Remove any existing image views
        mediaContainerView.subviews.forEach { $0.removeFromSuperview() }
        
        // Stop and remove video player
        player?.pause()
        playerLayer?.removeFromSuperlayer()
        player = nil
        playerLayer = nil
        playerLooper = nil
    }
    
    private func setupVideo(with url: URL) {
        // Create AVPlayerItem
        let playerItem = AVPlayerItem(url: url)
        
        // Create player
        let player = AVQueuePlayer(playerItem: playerItem)
        self.player = player
        
        // Create player looper for automatic repeating
        playerLooper = AVPlayerLooper(player: player, templateItem: playerItem)
        
        // Create and configure layer
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = .resizeAspect
        playerLayer.frame = mediaContainerView.bounds
        mediaContainerView.layer.addSublayer(playerLayer)
        self.playerLayer = playerLayer
        
        // Make sure our playerLayer resizes with its container
        mediaContainerView.layoutIfNeeded()
        
        // Start playback
        player.play()
    }
    
    private func displayImage(_ image: UIImage) {
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        imageView.frame = mediaContainerView.bounds
        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mediaContainerView.addSubview(imageView)
    }
    
    private func displayPlaceholder() {
        let imageView = UIImageView(image: UIImage(systemName: "photo"))
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .systemGray
        imageView.frame = mediaContainerView.bounds
        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mediaContainerView.addSubview(imageView)
    }
    
    // MARK: - Cleanup
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
