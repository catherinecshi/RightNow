import Foundation

class TimerModel {
    weak var delegate: TimerModelDelegate?
    var timer: Timer?
    var startTime: Date?
    
    func startTimer() {
        startTime = Date()
        timer = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(updateTime), userInfo: nil, repeats: true)
    }
    
    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    @objc func updateTime() {
        delegate?.timerModelDidUpdateTime(self)
    }
    
    //makes sure timer becomes invalidated when view is deallocated
    deinit {
        stopTimer()
    }
}
