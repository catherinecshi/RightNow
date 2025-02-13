import Foundation
import UIKit

protocol TimerModelDelegate: AnyObject {
    func timerModelDidUpdateTime()
}

class TimerModel {
    static let shared = TimerModel()
    weak var delegate: TimerModelDelegate?
    
    var timer: Timer?
    var focusTime: Int = UserDefaults.standard.integer(forKey: "userFocusTime") != 0 ? UserDefaults.standard.integer(forKey: "userFocusTime") : 25 {
        didSet {
            UserDefaults.standard.set(focusTime, forKey: "userFocusTime")
            if !isSessionActive { // only update if no session active
                remainingSeconds = focusTime * 60
                delegate?.timerModelDidUpdateTime()
            }
        }
    }
    var remainingSeconds: Int
    var sessionStartTime: Date? {
        didSet {
            if let date = sessionStartTime {
                UserDefaults.standard.set(date.timeIntervalSince1970, forKey: "sessionStartTime")
            } else {
                UserDefaults.standard.removeObject(forKey: "sessionStartTime")
            }
        }
    }
    var intoBackgroundTime: Date?
    var isSessionActive = false {
        didSet {
            UserDefaults.standard.set(isSessionActive, forKey: "isSessionActive")
        }
    }
    var currentNotificationIdentifier: String = "workFailed"
    
    init() {
        let savedFocusTime = UserDefaults.standard.integer(forKey: "userFocusTime")
        let initialFocusTime = savedFocusTime != 0 ? savedFocusTime : 25
        self.remainingSeconds = initialFocusTime * 60
    }
    
    
    // MARK: - Session Management
    func startSession() {
        isSessionActive = true
        sessionStartTime = Date()
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(updateTime), userInfo: nil, repeats: true)
    }
    
    func endSession(failed: Bool = false) {
        timer?.invalidate()
        timer = nil
        isSessionActive = false
        remainingSeconds = focusTime * 60
        sessionStartTime = nil
        
        if failed {
            showFailureNotification()
        } else {
            showSuccessNotification()
        }
        
        delegate?.timerModelDidUpdateTime()
    }
    
    @objc func updateTime() {
        guard let startTime = sessionStartTime else { return }
        
        let elapsedSeconds = Int(Date().timeIntervalSinceReferenceDate - startTime.timeIntervalSinceReferenceDate)
        remainingSeconds = max(0, (focusTime * 60) - elapsedSeconds)
        
        delegate?.timerModelDidUpdateTime()
        
        if remainingSeconds == 0 {
            endSession()
        }
    }
    
    func buttonTapped() {
        if isSessionActive {
            endSession(failed: true)
        } else {
            startSession()
        }
    }
    
    // MARK: - Notifications & Alerts
    private func showFailureNotification() {
        Task {
            do {
                try await PushNotificationDelegate.shared.scheduleNow(title: "Work Stopped", body: "You left the app before your session finished!")
            } catch {
                print("Failure timer notification failed: \(error)")
            }
        }
    }
    
    private func showSuccessNotification() {
        Task {
            do {
                try await PushNotificationDelegate.shared.scheduleNow(title: "Work done!", body: "Great work on your session!")
            } catch {
                print("Success timer notification failed: \(error)")
            }
        }
    }
    
    // MARK: - App State Observers
    func setupObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }
    
    @objc private func appDidEnterBackground() {
        // check if app went to background due to phone lock
        let isDeviceLocked = !UIApplication.shared.isProtectedDataAvailable
        
        print("session is active: \(isSessionActive), device is locked: \(isDeviceLocked)")
        if isSessionActive && !isDeviceLocked {
            print("trying to send notification")
            intoBackgroundTime = Date()
            
            Task {
                do {
                    try await PushNotificationDelegate.shared.scheduleNow(title: "Work Stopped", body: "Your work will be forefeited if you don't return to the app in one minute!")
                    
                    // schedule notification for them failing work
                    try await PushNotificationDelegate.shared.scheduleAfterDelay(title: "Work Stopped", body: "You've left the app for too long", delay: TimeInterval(60), identifier: currentNotificationIdentifier)
                } catch {
                    print("Background notification didn't send: \(error)")
                }
            }
        }
    }
    
    @objc private func appWillEnterForeground() {
        print("foreground - session is active \(isSessionActive), time is \(intoBackgroundTime)")
        guard isSessionActive,
              let backgroundDate = intoBackgroundTime else { return }
        
        // cancels notification if the user is back before 60 seconds are up
        if Date().timeIntervalSince(backgroundDate) < 60 {
            Task {
                await PushNotificationDelegate.shared.cancelNotification(withIdentifier: currentNotificationIdentifier)
            }
        } else {
            endSession(failed: true)
        }
        
        self.intoBackgroundTime = nil
    }
}
