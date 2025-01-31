import Foundation

class FirstLaunchManager {
    static let shared = FirstLaunchManager()
    private let defaults = UserDefaults.standard
    
    private enum Keys {
        static let hasLaunchedBefore = "hasLaunchedBefore"
        static let hasShownOnboarding = "hasShownOnboarding"
        static let hasShownWelcomeAlert = "hasShownWelcomeAlert"
    }
    
    private init() {}
    
    var isFirstLaunch: Bool {
        !defaults.bool(forKey: Keys.hasLaunchedBefore)
    }
    
    var shouldShowOnboarding: Bool {
        !defaults.bool(forKey: Keys.hasShownOnboarding)
    }
    
    var shouldShowWelcomeAlert: Bool {
        !defaults.bool(forKey: Keys.hasShownWelcomeAlert)
    }
    
    func markAsLaunched() {
        defaults.set(true, forKey: Keys.hasLaunchedBefore)
    }
    
    func markOnboardingAsShown() {
        defaults.set(true, forKey: Keys.hasShownOnboarding)
    }
    
    func markWelcomeAsShown() {
        defaults.set(true, forKey: Keys.hasShownWelcomeAlert)
    }
    
    // for testing
    func resetFirstLaunchState() {
        defaults.set(false, forKey: Keys.hasLaunchedBefore)
        defaults.set(false, forKey: Keys.hasShownOnboarding)
        defaults.set(false, forKey: Keys.hasShownWelcomeAlert)
    }
}
