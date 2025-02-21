import Foundation
import UIKit

class MaowViewController: UIViewController, TimerModelDelegate, MaowViewDelegate {
    private let timerModel = TimerModel.shared
    private let maowView: MaowView
    
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
        label.text = "0"
        label.font = UIConfiguration.subtitleFont
        return label
    }()
    
    private var isFirstImage = true
    
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
    
    private func setupNavigationBar() {
        coinStackView.addArrangedSubview(coinImageView)
        coinStackView.addArrangedSubview(coinCountLabel)
        
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
    
    private func setupDelegates() {
        TimerModel.shared.delegate = self
        maowView.delegate = self
    }
    
    func maowViewDidTapCharacter() {
        isFirstImage.toggle()
        maowView.updateCharacterState(isAsleep: isFirstImage)
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
    
    func initialViewSetup() {
        timerModelDidUpdateTime()
        maowView.updateSliderDisplay(value: Float(TimerModel.shared.focusTime))
    }
    
    func updateCoinCount(_ count: Int) {
        if let customView = navigationItem.rightBarButtonItem?.customView as? UIStackView,
           let label = customView.arrangedSubviews.last as? UILabel {
            label.text = "\(count)"
        }
    }
    
    @objc private func coinButtonTapped() {
        // put shop in here
    }
    
    func showFailureAlert() {
        let alert = CustomAlertViewController(title: "Oh No!", message: "You left before the time was up!")
        present(alert, animated: true)
    }
    
    func showSuccessAlert() {
        let alert = CustomAlertViewController(title: "Success!", message: "You completed your session!")
        present(alert, animated: true)
    }
}
