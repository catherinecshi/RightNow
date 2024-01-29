import UIKit

class TimerController: UIViewController, TimerModelDelegate, TimerViewDelegate {
    private var timerModel = TimerModel()
    private var timerView = TimerView()
    
    var habit: Habit?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIConfiguration.tintColor
        
        //add timerview and add targets for interactive interface
        view.addSubview(timerView)
        setupTimerViewConstraints()
        timerView.startStopButton.addTarget(self, action: #selector(toggleTimer), for: .touchUpInside)
        
        //add delegate for model for decoupling
        timerModel.delegate = self
        timerView.delegate = self
        
        //add observers for when the user leaves app
        NotificationCenter.default.addObserver(self, selector: #selector(appDidEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appWillEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
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
    
    func timerViewDidDismiss(_ view: TimerView) {
        self.dismiss(animated: true, completion: nil)
    }
    
    // MARK: Persistent Storage
    
    func saveTimerState() {
        if let startTime = timerModel.startTime {
            let elapsedTime = Date().timeIntervalSince(startTime)
            UserDefaults.standard.set(elapsedTime, forKey: "timerElapsedTime")
            UserDefaults.standard.set(true, forKey: "timerIsRunning")
        }
    }
    
    @objc func appDidEnterBackground() {
        saveTimerState()
        timerModel.stopTimer()
        timerView.startStopButton.setTitle("Start", for: .normal)
    }
    
    @objc func appWillEnterForeground() {
        //load timer state
        if let elapsedTime = UserDefaults.standard.object(forKey: "timerElapsedTime") as? TimeInterval {
            showTimeAlert(elapsedTime: elapsedTime)
        }
        
        UserDefaults.standard.set(false, forKey: "timerIsRunning")
        UserDefaults.standard.removeObject(forKey: "timerElapsedTime")
    }
    
    func showTimeAlert(elapsedTime: TimeInterval) {
        let hours = Int(elapsedTime / 3600)
        let minutes = Int((elapsedTime / 60).truncatingRemainder(dividingBy: 60))
        let seconds = Int(elapsedTime.truncatingRemainder(dividingBy: 60))
        
        let timeString = String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        
        let alert = UIAlertController(title: "Timer Paused", message: "Your timer was paused at \(timeString).", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            //actions when user acknowledges the alert
        })
        
        self.present(alert, animated: true, completion: nil)
    }
}
