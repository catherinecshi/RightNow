import Foundation

// Handles scrolling behavior independent of game logic
struct ScrollingEngine {
    let scrollInterval: TimeInterval // in seconds per row
    let onScroll: () -> Void // call to scroll
    private(set) var timer: Timer? // timer powering the scroll
    
    /// Creates a new scrolling engine
    init(scrollInterval: TimeInterval, onScroll: @escaping () -> Void) {
        self.scrollInterval = scrollInterval
        self.onScroll = onScroll
    }
    
    /// Starts the scrolling
    mutating func start() {
        // stop any existing timer
        stop()
        
        // create a new timer
        timer = Timer.scheduledTimer(withTimeInterval: scrollInterval, repeats: true) { [self] _ in
            onScroll()
        }
    }
    
    /// Stops the scrolling
    mutating func stop() {
        timer?.invalidate()
        timer = nil
    }
    
    /// Change the scroll speed
    mutating func changeSpeed(to newInterval: TimeInterval) {
        let wasRunning = timer != nil
        stop()
        
        if wasRunning {
            timer = Timer.scheduledTimer(withTimeInterval: newInterval, repeats: true) { [self] _ in
                onScroll()
            }
        }
    }
}
