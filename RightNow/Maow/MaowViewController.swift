import Foundation
import Combine
import UIKit

class MaowViewController: UIViewController, TimerModelDelegate, MaowViewDelegate {
    private let timerModel = TimerModel.shared
    private let gameModel = CentralGameModel.shared
    private let maowView: MaowView
    
    private var cancellables = Set<AnyCancellable>()
    
    private var coinStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 4
        stackView.alignment = .center
        return stackView
    }()
    
    private var coinImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "centsign.circle.fill")
        imageView.tintColor = UIConfiguration.tintColor
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private var coinCountLabel: UILabel = {
        let label = UILabel()
        label.text = String(Int(CentralGameModel.shared.gameState.numbers))
        label.font = UIConfiguration.subtitleFont
        return label
    }()
    
    private var isFirstImage = true
    
    // MARK: - Lifecycle
    init() {
        self.maowView = MaowView()
        super.init(nibName: nil, bundle: nil)
        
        setupDelegates()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented yet")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        setupNavigationBar()
        setupView()
        initialViewSetup() // since timemodel stores the user preferences for how long
        TimerModel.shared.setupObservers()
    }
    
    func setupSubscribers() {
        // subscribe to game state changes
        gameModel.$gameState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateNumberCount()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Setup UI
    private func setupNavigationBar() {
        setupSettings()
        setupCoins()
    }
    
    private func setupSettings() {
        // create a settings button
        let settingsButton = UIBarButtonItem(
            image: UIImage(systemName: "line.horizontal.3"),
            style: .plain,
            target: self,
            action: #selector(settingsButtonTapped)
        )
        settingsButton.tintColor = UIColor.lightGray
        navigationItem.leftBarButtonItem = settingsButton
    }
    
    private func setupCoins() {
        coinStackView.addArrangedSubview(coinImageView)
        coinStackView.addArrangedSubview(coinCountLabel)
        
        NSLayoutConstraint.activate([
            coinImageView.heightAnchor.constraint(equalToConstant: 32),
            coinImageView.widthAnchor.constraint(equalToConstant: 32)
        ])
        
        // container view for coins to help with alignment
        let containerView = UIView()
        containerView.backgroundColor = .clear
        
        containerView.addSubview(coinStackView)
        coinStackView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // Container size
            containerView.heightAnchor.constraint(equalToConstant: 44),
            containerView.widthAnchor.constraint(greaterThanOrEqualToConstant: 80), // Minimum width
            
            // Stack view constraints - pin to trailing edge
            coinStackView.topAnchor.constraint(equalTo: containerView.topAnchor),
            coinStackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            coinStackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
        ])
        
        // custom bar button item with stack view
        let customBarButton = UIBarButtonItem(customView: coinStackView)
        
        // add tap gesture to stack view
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(coinButtonTapped))
        coinStackView.addGestureRecognizer(tapGesture)
        coinStackView.isUserInteractionEnabled = true
        
        navigationItem.rightBarButtonItem = customBarButton
    }
    
    private func setupView() {
        maowView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(maowView)
        
        NSLayoutConstraint.activate([
            maowView.topAnchor.constraint(equalTo: view.topAnchor),
            maowView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            maowView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            maowView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    // MARK: - Delegate Methods
    func initialViewSetup() {
        timerModelDidUpdateTime()
        maowView.updateSliderDisplay(value: Float(TimerModel.shared.focusTime))
    }
    
    private func setupDelegates() {
        TimerModel.shared.delegate = self
        maowView.delegate = self
    }
    
    func maowViewDidTapCharacter() {
        isFirstImage.toggle()
        maowView.updateCharacterState(isHappy: isFirstImage)
    }
    
    func maowViewDidTapStart() {
        TimerModel.shared.buttonTapped()
        maowView.updateControlsForSession(isActive: TimerModel.shared.isSessionActive)
    }
    
    func maowViewDidAdjustTime(_ minutes: Int) {
        TimerModel.shared.focusTime = minutes
        TimerModel.shared.remainingSeconds = minutes * 60
        timerModelDidUpdateTime()
    }
    
    func timerModelDidUpdateTime() {
        let minutes = TimerModel.shared.remainingSeconds / 60
        let seconds = TimerModel.shared.remainingSeconds % 60
        maowView.updateTimeDisplay(minutes: minutes, seconds: seconds)
        maowView.updateControlsForSession(isActive: TimerModel.shared.isSessionActive)
    }
    
    // MARK: - Navigation Bar Views
    func updateCoinCount(_ count: Int) {
        if let customView = navigationItem.rightBarButtonItem?.customView as? UIStackView,
           let label = customView.arrangedSubviews.last as? UILabel {
            label.text = "\(count)"
        }
    }
    
    func updateNumberCount() {
        if let customView = navigationItem.rightBarButtonItem?.customView as? UIStackView,
           let label = customView.arrangedSubviews.last as? UILabel {
            label.text = "\(Int(gameModel.gameState.numbers))"
        }
    }
    
    @objc private func coinButtonTapped() {
        let shopVC = ShopViewController()
        let navController = UINavigationController(rootViewController: shopVC)
        navController.modalPresentationStyle = .pageSheet
        present(navController, animated: true, completion: nil)
    }
    
    private var settingsTransitionDelegate: CustomSlideInTransition?
    @objc private func settingsButtonTapped() {
        let settingsVC = SettingsViewController()
        let navController = UINavigationController(rootViewController: settingsVC)
        self.settingsTransitionDelegate = CustomSlideInTransition()
        
        navController.modalPresentationStyle = .custom
        navController.transitioningDelegate = self.settingsTransitionDelegate
        
        if let transDelegate = self.settingsTransitionDelegate {
            settingsVC.customTransitionDelegate = transDelegate
        }
        
        present(navController, animated: true)
    }
    
    // MARK: - Alerts
    func showFailureAlert() {
        let alert = CustomAlertViewController(title: "Oh No!", message: "You left before the time was up!")
        present(alert, animated: true)
    }
    
    func showSuccessAlert(coupons: Int? = nil) {
        if let coupons = coupons {
            let alert = CustomAlertViewController(title: "Congrats!", message: "You earned \(coupons) coupons from that session!")
            present(alert, animated: true)
        } else {
            let alert = CustomAlertViewController(title: "Congrats!", message: "You completed your session!")
            present(alert, animated: true)
        }
    }
}
