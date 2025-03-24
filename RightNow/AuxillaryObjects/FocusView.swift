import Foundation
import UIKit

/// Possible shapes of FocusView
enum FocusShape {
    case circle
    case roundedRect(cornerRadius: CGFloat)
}

/// View that casts a shadow on everything except for the outlined ovalRect
///
/// `FocusView` creates a spotlight or focus effect by rendering a semi-transparent shadow
/// over the entire view except for a specified area defined by `ovalRect` and `shapeType`.
/// This can be used to draw attention to specific UI elements in tutorials, onboarding,
/// or feature highlight scenarios.
///
/// Example usage:
/// ```
/// let focusView = FocusView(frame: view.bounds)
/// focusView.ovalRect = buttonToHighlight.frame
/// focusView.shapeType = .roundedRect(cornerRadius: 8)
/// view.addSubview(focusView)
/// ```
class FocusView: UIView {
    /// Defines the bounds of the non-shadowed area
    /// Changing this property will trigger a layout update
    public var ovalRect: CGRect = .zero {
        didSet { setNeedsLayout() }
    }
    
    /// Defines shape type of focus area
    /// Defaults to .circle
    /// Changing this property will trigger a layout update
    public var shapeType: FocusShape = .circle {
        didSet { setNeedsLayout() }
    }
    
    /// Updates shadow path when variables are updated
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let clearPath: UIBezierPath
        
        switch shapeType {
        case .circle:
            // make sure it's a perfect circle
            let diameter = min(ovalRect.width, ovalRect.height)
            let centerX = ovalRect.midX
            let centerY = ovalRect.midY
            let circleRect = CGRect(
                x: centerX - diameter / 2,
                y: centerY - diameter / 2,
                width: diameter,
                height: diameter
            )
            clearPath = UIBezierPath(ovalIn: circleRect)
            
        case .roundedRect(let cornerRadius):
            clearPath = UIBezierPath(
                roundedRect: ovalRect,
                cornerRadius: cornerRadius
            )
        }
        
        let opaquePath = UIBezierPath(rect: bounds.insetBy(dx: -80.0, dy: -80.0)).reversing()
        clearPath.append(opaquePath)
        
        self.layer.shadowPath = clearPath.cgPath
        self.layer.shadowColor = UIColor.black.cgColor
        self.layer.shadowOffset = CGSize.zero
        self.layer.shadowOpacity = 0.7
        self.layer.shadowRadius = 8
    }
}

/// Handles associations between gesture recognizers and closure callbacks
///
/// Bridges the target-action pattern in UIKit with closure-based event handling
/// Maintains a dictionary of closures keyed by gesture recognizer identifiers
/// Handler exceutes associated closure when gesture is triggered
///
/// Typically used in conjunction with FocusView
/// Eliminates need to subclass or create separate methods for each gesture handler
class ClosureGestureHandler: NSObject {
    static let shared = ClosureGestureHandler()
    
    /// Dictionary that maps gesture recognizer identiifers to their handler closures
    private var closures = [ObjectIdentifier: (UIGestureRecognizer) -> Void]()
    
    /// Connects a closure with a gesture recognizer
    ///
    /// Parameters:
    /// - closure : closure to execute
    /// - gesture : gesture recognizer to associate
    func add(_ closure: @escaping (UIGestureRecognizer) -> Void, for gesture: UIGestureRecognizer) {
        let id = ObjectIdentifier(gesture)
        closures[id] = closure
    }
    
    /// Executes closure associated with gesture recognizer when gestured
    ///
    /// Target action of all gesture recognizers
    /// Called whenever any registered gestures are reocgnized
    ///
    /// Parameters:
    /// - gesture : the gesture recognizer that was triggered
    @objc func handle(gesture: UIGestureRecognizer) {
        let id = ObjectIdentifier(gesture)
        if let closure = closures[id] {
            closure(gesture)
        }
    }
    
    /// Disassociates a closure from a gesture recognizer
    ///
    /// Parameter:
    /// - gesture : gesture reocgnizer to be disassociated
    func remove(for gesture: UIGestureRecognizer) {
        let id = ObjectIdentifier(gesture)
        closures.removeValue(forKey: id)
    }
}

// Extension to make it easier to use closures with gesture recognizers
extension UIGestureRecognizer {
    /// Adds a closure-based handler to the gesture recognizer.
    ///
    /// Example usage:
    /// ```
    /// let tapGesture = UITapGestureRecognizer()
    /// tapGesture.addTarget { gesture in
    ///     // Handle the tap gesture
    ///     print("Tapped at \((gesture as! UITapGestureRecognizer).location(in: nil))")
    /// }
    /// view.addGestureRecognizer(tapGesture)
    /// ```
    ///
    /// - Important: To prevent memory leaks, call `ClosureGestureHandler.shared.remove(for:)` when
    ///   the gesture recognizer is no longer needed.
    ///
    /// Parameters:
    /// - closure: The closure to execute when the gesture is recognized.
    func addTarget(closure: @escaping (UIGestureRecognizer) -> Void) {
        self.addTarget(ClosureGestureHandler.shared, action: #selector(ClosureGestureHandler.handle(gesture:)))
        ClosureGestureHandler.shared.add(closure, for: self)
    }
}
