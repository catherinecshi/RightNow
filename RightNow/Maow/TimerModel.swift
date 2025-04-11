/// TimerModel.swift
/// A comprehensive timer management system for focus/pomodoro sessions.
///
/// ## Features
/// - Tracking active sessions and remaining time
/// - Persisting user preferences and session state
/// - Handling app state transitions (foreground/background)
/// - Managing device lock state detection
/// - Sending notifications based on session state
/// - Rewarding users for completed sessions
/// - Communicating state changes via delegate pattern

import Foundation
import UIKit

protocol TimerModelDelegate: AnyObject {
    func timerModelDidUpdateTime()
    func showFailureAlert()
    func showSuccessAlert(coupons: Int?)
}

/// Manages timer functionality, session state, and rewards
class TimerModel: Resettable {
    static let shared = TimerModel()
    weak var delegate: TimerModelDelegate?
    let rewardModel = RewardModel()
    
    var timer: Timer?
    
    /// User's preferred focus session duration in minutes
    ///
    /// Stored and retrieved from UserDefaults for persistence
    /// Automatically updates userDefaults when changed by user
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
    
    /// start time of the current session
    /// used to calculate elapsed time
    /// persisted to UserDefaults
    var sessionStartTime: Date? {
        didSet {
            if let date = sessionStartTime {
                UserDefaults.standard.set(date.timeIntervalSince1970, forKey: "sessionStartTime")
            } else {
                UserDefaults.standard.removeObject(forKey: "sessionStartTime")
            }
        }
    }
    
    /// time when app transitioned to the background
    /// used to determine if hte user has been away for too long
    var intoBackgroundTime: Date?
    
    /// flag to determine whether a focus session is currently running
    var isSessionActive = false {
        didSet {
            UserDefaults.standard.set(isSessionActive, forKey: "isSessionActive")
        }
    }
    
    /// identifier for current notification that would be triggered when user abandons session
    /// used to cancel notification if user returns in time
    var currentNotificationIdentifier: String = "workFailed"
    private var observersSetup = false // to prevent multiple observers working at once
    private var isDeviceLocked = false // whether the device is currently locked
    
    /// initialises timer model with saved focus time length
    /// sets initial remaining seconds on that number
    init() {
        let savedFocusTime = UserDefaults.standard.integer(forKey: "userFocusTime")
        let initialFocusTime = savedFocusTime != 0 ? savedFocusTime : 25
        self.remainingSeconds = initialFocusTime * 60
        
        // register with singleton registry
        SingletonRegistry.shared.register(self)
    }
    
    /// cleans up by removing notification observers when model is deallocated
    deinit {
        NotificationCenter.default.removeObserver(self)
        observersSetup = false
    }
    
    func reset() {
        // stop any active timer sessions
        timer?.invalidate()
        timer = nil
        isSessionActive = false
        
        // reset session state
        sessionStartTime = nil
        intoBackgroundTime = nil
        remainingSeconds = focusTime * 60
        
        // reset notification state
        if currentNotificationIdentifier != "workFailed" {
            Task {
                await PushNotificationDelegate.shared.cancelNotification(withIdentifier: currentNotificationIdentifier)
            }
        }
        currentNotificationIdentifier = "workFailed"
        
        // reset device state tracking
        isDeviceLocked = false
        
        // reset observers
        if observersSetup {
            NotificationCenter.default.removeObserver(self)
            observersSetup = false
            setupObservers()
        }
    }
    
    // MARK: - Session Management
    
    /// Starts a new focus session
    ///
    /// This method:
    /// 1. Sets the session as active
    /// 2. Records the start time
    /// 3. Creates a repeating timer that fires every second to update the remaining time
    func startSession() {
        isSessionActive = true
        sessionStartTime = Date()
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(updateTime), userInfo: nil, repeats: true)
    }
    
    /// Ends the current focus session and calculates rewards if successful
    ///
    /// This method:
    /// 1. Invalidates and nullifies the timer
    /// 2. Marks the session as inactive
    /// 3. Calculates the session duration for reward purposes
    /// 4. Resets the remaining seconds to the full focus time
    /// 5. Clears the session start time
    /// 6. Shows appropriate alerts or notifications based on success/failure and app state
    ///
    /// - Parameter failed: true if failed session, false otherwise
    func endSession(failed: Bool = false) {
        timer?.invalidate()
        timer = nil
        isSessionActive = false
        
        // get duration for reward calculation if successful
        let sessionDuration = calculateSessionDuration()
        remainingSeconds = focusTime * 60
        sessionStartTime = nil
        
        if UIApplication.shared.applicationState == .active {
            if failed {
                delegate?.showFailureAlert()
            } else {
                let couponsCount = rewardModel.timeToCoupons(minutes: sessionDuration)
                delegate?.showSuccessAlert(coupons: couponsCount)
            }
        } else {
            if failed {
                showFailureNotification()
            } else {
                let couponsCount = rewardModel.timeToCoupons(minutes: sessionDuration)
                showSuccessNotification(coupons: couponsCount)
            }
        }
        
        delegate?.timerModelDidUpdateTime()
    }
    
    /// Calculates the duration of the current session in minutes.
    /// This is used to determine rewards for completed sessions.
    ///
    /// - Returns: The duration of the current session in minutes (0 if no session)
    private func calculateSessionDuration() -> Int {
        guard let startTime = sessionStartTime else { return 0 }
        let totalSeconds = focusTime * 60 - remainingSeconds
        return totalSeconds / 60 // convert to minutes
    }
    
    /// Updates the remaining time in the current session
    ///
    /// This method is called every second by the timer and:
    /// 1. Calculates elapsed time since session start
    /// 2. Updates remaining seconds
    /// 3. Notifies the delegate to update the UI
    /// 4. Automatically ends the session when time reaches zero
    @objc func updateTime() {
        guard let startTime = sessionStartTime else { return }
        
        let elapsedSeconds = Int(Date().timeIntervalSinceReferenceDate - startTime.timeIntervalSinceReferenceDate)
        remainingSeconds = max(0, (focusTime * 60) - elapsedSeconds)
        
        delegate?.timerModelDidUpdateTime()
        
        if remainingSeconds == 0 {
            endSession()
        }
    }
    
    /// if session is active -> ends it as failed
    /// if no session -> starts a new session
    func buttonTapped() {
        if isSessionActive {
            endSession(failed: true)
        } else {
            startSession()
        }
    }
    
    // MARK: - Notifications
    
    /// shows push notification when a session fails
    /// happens when app is in the background when a session fails
    private func showFailureNotification() {
        Task {
            do {
                try await PushNotificationDelegate.shared.scheduleNow(title: "Work Stopped", body: "You left the app before your session finished!")
            } catch {
                print("Failure timer notification failed: \(error)")
            }
        }
    }
    
    /// shows push notification when session is completed successfully
    /// happens when app is in background when session succeeds
    ///
    /// - Parameter coupons: optional number of coupons earned duringsession
    ///     If provided, value is included in notification
    private func showSuccessNotification(coupons: Int? = nil) {
        Task {
            do {
                if let coupons = coupons {
                    try await PushNotificationDelegate.shared.scheduleNow(title: "Work done!", body: "Great work earning \(coupons) coupons this session!")
                } else {
                    try await PushNotificationDelegate.shared.scheduleNow(title: "Work done!", body: "Great work on your session!")
                }
            } catch {
                print("Success timer notification failed: \(error)")
            }
        }
    }
    
    /// Sends notification when user leaves the app during a session
    ///
    /// This method:
    /// 1. immediately sends notification warning
    /// 2. schedules another notification in 60 seconds if the user doesn't return to app in time
    ///
    /// delayed notification is cancelled if the user returns in time
    private func userLeftAppNotification() {
        Task {
            do {
                try await PushNotificationDelegate.shared.scheduleNow(title: "Work Stopped", body: "Your work will be forefeited if you don't return to the app in one minute!")
                
                // schedule notification for them failing work
                try await PushNotificationDelegate.shared.scheduleAfterDelay(
                    title: "Work Stopped",
                    body: "You've left the app for too long",
                    delay: TimeInterval(60),
                    identifier: currentNotificationIdentifier
                )
            } catch {
                print("Background notification didn't send: \(error)")
            }
        }
    }
    
    // MARK: - App State Observers
    
    /// Sets up observers for app and device state changes.
    ///
    /// This method registers for notifications about:
    /// 1. App entering background
    /// 2. App entering foreground
    /// 3. Device being locked (protected data becoming unavailable)
    /// 4. Device being unlocked (protected data becoming available)
    ///
    /// Allows for user to lock their phone without killing session with the combination of observers
    /// however, user can go from locked -> another app in this configuration
    ///
    /// Note: doesn't work if user does not have a passcode
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
    
    /// Handles the app transitioning to the background
    ///
    /// This method:
    /// 1. If no session is active, it does nothing
    /// 2. If a session is active, it requests background execution time
    /// 3. It checks if the app went to background due to device lock
    /// 4. It sets up a timer to periodically check if the device is locked
    /// 5. After a few seconds of checks, it decides whether to show a notification
    ///    based on whether the user locked their device or left the app
    ///
    /// locking phone -> no trigger
    /// switching to another app -> trigger warnings after time
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
    
    /// Handles the app transitioning to the foreground.
    /// This method:
    /// 1. If no session is active or no background time is recorded, it does nothing
    /// 2. If the user returns within 60 seconds, it cancels the pending notification
    /// 3. If the user returns after 60 seconds, it ends the session as failed
    @objc private func appWillEnterForeground() {
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
    
    /// updates device lock when device is locked
    @objc private func handleDeviceLock() {
        isDeviceLocked = true
    }
    
    /// updates device lock when device is not locked
    @objc private func handleDeviceUnlock() {
        isDeviceLocked = false
    }
}
