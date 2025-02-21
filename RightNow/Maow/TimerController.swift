import UIKit

class TimerController: UIViewController, TimerViewDelegate {
    private var timerModel = TimerModel()
    private var timerView = TimerView()
    
    var habit: Habit!
    
    init(habit: Habit) {
        self.habit = habit
        super.init(nibName: nil, bundle: nil)
    }
    
    // Required initializer when subclassing UIViewController
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIConfiguration.tintColor
        
        //add timerview and add targets for interactive interface
        view.addSubview(timerView)
        setupTimerViewConstraints()
        timerView.startStopButton.addTarget(self, action: #selector(toggleTimer), for: .touchUpInside)
        
        //add delegate for model for decoupling
        //timerModel.delegate = self
        timerView.delegate = self
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
            timerModel.startSession()
            timerView.startStopButton.setTitle("Stop", for: .normal)
        } else {
            timerModel.endSession()
            timerView.startStopButton.setTitle("Start", for: .normal)
        }
    }
    
    func timerModelDidUpdateTime(_ timerModel: TimerModel) {
        guard let startTime = timerModel.sessionStartTime else { return }
        
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
        if let startTime = timerModel.sessionStartTime {
            let elapsedTime = Date().timeIntervalSince(startTime)
            UserDefaults.standard.set(elapsedTime, forKey: "timerElapsedTime")
            UserDefaults.standard.set(true, forKey: "timerIsRunning")
        }
    }
    
    @objc func appDidEnterBackground() {
        saveTimerState()
        timerModel.endSession()
        timerView.startStopButton.setTitle("Start", for: .normal)
    }
}
