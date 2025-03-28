import Foundation

/// Controls Firebase analytics behavior throughout the app
class AnalyticsController {
    static let shared = AnalyticsController()
    
    var isEnabled: Bool = true // set false if analytics should be disabled
    
    /// Counter for how many components have requested analytics be disabled
    private var disableCounter = 0
    
    /// Disable analytics
    /// Typically used for performance-sensitive sections
    func disableForComponent() {
        disableCounter += 1
        isEnabled = disableCounter == 0
    }
    
    /// Enable analytics
    /// Typically used when exiting performance-sensitive sectiosn
    func enableForComponent() {
        disableCounter = max(0, disableCounter - 1)
        isEnabled = disableCounter == 0
    }
}
