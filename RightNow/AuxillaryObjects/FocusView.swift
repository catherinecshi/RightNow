import Foundation
import UIKit

class FocusView: UIView {
    public var ovalRect: CGRect = .zero {
        didSet { setNeedsLayout() }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let clearPath = UIBezierPath(ovalIn: ovalRect)
        let opaquePath = UIBezierPath(rect: bounds.insetBy(dx: -80.0, dy: -80.0)).reversing()
        clearPath.append(opaquePath)
        
        self.layer.shadowPath = clearPath.cgPath
        self.layer.shadowColor = UIColor.black.cgColor
        self.layer.shadowOffset = CGSize.zero
        self.layer.shadowOpacity = 0.7
        self.layer.shadowRadius = 8
    }
}
