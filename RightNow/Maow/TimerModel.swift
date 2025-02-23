import Foundation
import UIKit

protocol TimerModelDelegate: AnyObject {
    func timerModelDidUpdateTime()
    func showFailureAlert()
    func showSuccessAlert()
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
    private var observersSetup = false // to prevent multiple observers working at once
    private var isDeviceLocked = false
    
    init() {
        let savedFocusTime = UserDefaults.standard.integer(forKey: "userFocusTime")
        let initialFocusTime = savedFocusTime != 0 ? savedFocusTime : 25
        self.remainingSeconds = initialFocusTime * 60
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        observersSetup = false
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
        
        if UIApplication.shared.applicationState == .active {
            if failed {
                delegate?.showFailureAlert()
            } else {
                delegate?.showSuccessAlert()
            }
        } else {
            if failed {
                showFailureNotification()
            } else {
                showSuccessNotification()
            }
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
    
    // MARK: - Notifications
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
    
    private func userLeftAppNotification() {
        print("trying to send notification")
        
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
    
    // MARK: - App State Observers
    func setupObservers() {
        // prevent multiple observers being setup at once
        guard !observersSetup else { return }
        
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
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleDeviceLock),
            name: UIApplication.protectedDataWillBecomeUnavailableNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleDeviceUnlock),
            name: UIApplication.protectedDataDidBecomeAvailableNotification,
            object: nil
        )
        
        observersSetup = true
    }
    
    @objc private func appDidEnterBackground() {
        // only care if there is an active session going on
        guard isSessionActive else { return }
        
        // request background execution time
        var backgroundTask: UIBackgroundTaskIdentifier = .invalid
        backgroundTask = UIApplication.shared.beginBackgroundTask {
            // cleanup if we run out o ftime
            UIApplication.shared.endBackgroundTask(backgroundTask)
            backgroundTask = .invalid
        }
        
        // check if app went to background due to phone lock
        let firstIsDeviceLocked = !UIApplication.shared.isProtectedDataAvailable
        print("initial check - session is active: \(isSessionActive), device is locked: \(firstIsDeviceLocked)")
        
        // check for lock state changes
        var lockCheckTimer: Timer?
        var attempts = 0
        let maxAttempts = 3
        var hasBeenLocked = false
        intoBackgroundTime = Date()
        
        lockCheckTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] checkTimer in
            guard let self = self else {
                checkTimer.invalidate()
                UIApplication.shared.endBackgroundTask(backgroundTask)
                return
            }
            
            attempts += 1
            print("Attempt \(attempts) - device is locked: \(isDeviceLocked)")
            
            if attempts >= maxAttempts {
                print("Final attempt reached - making decision")
                checkTimer.invalidate()
                lockCheckTimer = nil
                
                // checks if user has locked the phone at least once
                if isDeviceLocked {
                    hasBeenLocked = true
                }
                
                // don't send the notificaition if the user came back to the app before the timer's time ran up
                if !hasBeenLocked && intoBackgroundTime != nil {
                    print("user left during timer session - call notification")
                    self.userLeftAppNotification()
                } else {
                    intoBackgroundTime = nil
                    print("conditions not met - session active: \(self.isSessionActive), locked: \(isDeviceLocked)")
                }
                
                // end background task
                UIApplication.shared.endBackgroundTask(backgroundTask)
            }
        }
        
        RunLoop.current.add(lockCheckTimer!, forMode: .common)
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
    
    @objc private func handleDeviceLock() {
        isDeviceLocked = true
        print("Device is being locked")
    }
    
    @objc private func handleDeviceUnlock() {
        isDeviceLocked = false
        print("Device is being unlocked")
    }
}
