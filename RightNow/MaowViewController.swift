import Foundation
import UIKit

class MaowViewController: UIViewController, TimerModelDelegate {
    private var imageView = UIImageView()
    private var isFirstImage = true
    
    private let timerLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 48, weight: .bold)
        label.textAlignment = .center
        label.text = "25:00"
        label.textColor = UIConfiguration.tintColor
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private var timerSlider: UISlider = {
        let slider = UISlider()
        slider.minimumValue = 10 // 10 minute minimum
        slider.maximumValue = 120
        slider.value = Float(TimerModel.shared.focusTime)
        slider.translatesAutoresizingMaskIntoConstraints = false
        return slider
    }()
    
    private lazy var startStopButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Work", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 20)
        button.setTitleColor(UIColor.white, for: .normal)
        button.backgroundColor = UIConfiguration.tintColor
        button.layer.cornerRadius = 12
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        TimerModel.shared.delegate = self
        TimerModel.shared.setupObservers()
        
        setupImageView()
        setupTapGesture()
        setupTimerLabel()
        setupSlider()
        setupButton()
        
         updateUIForSessionState()
        
        print("timer model \(TimerModel.shared.remainingSeconds / 60)")
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
        view.addSubview(imageView)
        
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            imageView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.3),
            imageView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.3)
        ])
    }
    
    private func setupTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        imageView.addGestureRecognizer(tapGesture)
        imageView.isUserInteractionEnabled = true
    }
    
    private func setupTimerLabel() {
        view.addSubview(timerLabel)
        
        NSLayoutConstraint.activate([
            timerLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            timerLabel.bottomAnchor.constraint(equalTo: imageView.topAnchor, constant: -40)
        ])
        
        // check if the focusTime is supposed to be something different
        timerModelDidUpdateTime()
    }
    
    private func setupSlider() {
        view.addSubview(timerSlider)
        
        NSLayoutConstraint.activate([
            timerSlider.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            timerSlider.topAnchor.constraint(equalTo: timerLabel.bottomAnchor, constant: 20),
            timerSlider.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.7)
        ])
        
        timerSlider.addTarget(self, action: #selector(sliderValueChanged), for: .valueChanged)
    }
    
    private func setupButton() {
        view.addSubview(startStopButton)
        
        NSLayoutConstraint.activate([
            startStopButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            startStopButton.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 40),
            startStopButton.widthAnchor.constraint(equalToConstant: 200),
            startStopButton.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        startStopButton.addTarget(self, action: #selector(startButtonTapped), for: .touchUpInside)
    }
    
    @objc private func sliderValueChanged() {
        let minutes = Int(timerSlider.value)
        TimerModel.shared.focusTime = minutes
        TimerModel.shared.remainingSeconds = minutes * 60
        timerModelDidUpdateTime()
    }
    
    @objc private func handleTap() {
        // create new image
        guard let newImage = UIImage(named: isFirstImage ? "patamon_asleep" : "patamon_front") else {
            print("failed to load image for transition")
            return
        }
        
        // perform animation
        UIView.transition(with: imageView,
                          duration: 0.2,
                          options: .transitionCrossDissolve,
                          animations: { [weak self] in
            self?.imageView.image = newImage
        })
        
        isFirstImage.toggle()
    }
    
    @objc private func startButtonTapped() {
        TimerModel.shared.buttonTapped()
        updateUIForSessionState()
    }
    
    private func updateUIForSessionState() {
        if TimerModel.shared.isSessionActive {
            startStopButton.setTitle("Give Up", for: .normal)
            timerSlider.isEnabled = false
        } else {
            startStopButton.setTitle("Work", for: .normal)
            timerSlider.isEnabled = true
        }
    }
    
    func timerModelDidUpdateTime() {
        let minutes = TimerModel.shared.remainingSeconds / 60
        let seconds = TimerModel.shared.remainingSeconds % 60
        timerLabel.text = String(format: "%02d:%02d", minutes, seconds)
        
        updateUIForSessionState()
    }
}
