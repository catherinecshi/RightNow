import UIKit

class TimerController: UIViewController, TimerModelDelegate {
    private var timerModel = TimerModel()
    private var timerView = TimerView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIConfiguration.tintColor
        
        //add timerview and add targets for interactive interface
        view.addSubview(timerView)
        setupTimerViewConstraints()
        timerView.startStopButton.addTarget(self, action: #selector(toggleTimer), for: .touchUpInside)
        
        //add delegate for model for decoupling
        timerModel.delegate = self
    }
    
    private func setupTimerViewConstraints() {
        timerView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            timerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            timerView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            timerView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            timerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }
    
    @objc func toggleTimer() {
        if timerModel.timer == nil {
            timerModel.startTimer()
            timerView.startStopButton.setTitle("Stop", for: .normal)
        } else {
            timerModel.stopTimer()
            timerView.startStopButton.setTitle("Start", for: .normal)
        }
    }
    
    func timerModelDidUpdateTime(_ timerModel: TimerModel) {
        guard let startTime = timerModel.startTime else { return }
        
        let elapsedTime = Date().timeIntervalSince(startTime)
        
        let hours = Int(elapsedTime / 3600)
        let minutes = Int(elapsedTime / 60)
        let seconds = Int(elapsedTime.truncatingRemainder(dividingBy: 60))
        
        timerView.timeLabel.text = String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}
