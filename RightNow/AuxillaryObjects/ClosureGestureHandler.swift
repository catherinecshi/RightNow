/// Handles tap gestures - typically used with FocusView to make sure user cannot click outside of highglighted zone

import UIKit

// Handle gesture recognizer closures
class ClosureGestureHandler: NSObject {
    static let shared = ClosureGestureHandler()
    private var closures = [ObjectIdentifier: (UIGestureRecognizer) -> Void]()
    
    func add(_ closure: @escaping (UIGestureRecognizer) -> Void, for gesture: UIGestureRecognizer) {
        let id = ObjectIdentifier(gesture)
        closures[id] = closure
    }
    
    @objc func handle(gesture: UIGestureRecognizer) {
        let id = ObjectIdentifier(gesture)
        if let closure = closures[id] {
            closure(gesture)
        }
    }
    
    func remove(for gesture: UIGestureRecognizer) {
        let id = ObjectIdentifier(gesture)
        closures.removeValue(forKey: id)
    }
}

// Extension to make it easier to use closures with gesture recognizers
extension UIGestureRecognizer {
    func addTarget(closure: @escaping (UIGestureRecognizer) -> Void) {
        self.addTarget(ClosureGestureHandler.shared, action: #selector(ClosureGestureHandler.handle(gesture:)))
        ClosureGestureHandler.shared.add(closure, for: self)
    }
}
