import Foundation
import UIKit

enum FocusShape {
    case circle
    case roundedRect(cornerRadius: CGFloat)
}

class FocusView: UIView {
    // defines the bounds of the focus area
    public var ovalRect: CGRect = .zero {
        didSet { setNeedsLayout() }
    }
    
    public var shapeType: FocusShape = .circle {
        didSet { setNeedsLayout() }
    }
    
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
