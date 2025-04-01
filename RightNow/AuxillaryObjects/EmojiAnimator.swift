import UIKit

class EmojiAnimator {
    
    enum AnimationType {
        case bounce, spin, fadeInOut, moveInPath, pulse
    }
    
    static func animate(emojiLabel: UILabel, type: AnimationType) {
        switch type {
        case .bounce:
            bounceAnimation(emojiLabel: emojiLabel)
        case .spin:
            spinAnimation(emojiLabel: emojiLabel)
        case .fadeInOut:
            fadeAnimation(emojiLabel: emojiLabel)
        case .moveInPath:
            pathAnimation(emojiLabel: emojiLabel)
        case .pulse:
            pulseAnimation(emojiLabel: emojiLabel)
        }
    }
    
    private static func bounceAnimation(emojiLabel: UILabel) {
        UIView.animate(withDuration: 0.5,
                       delay: 0,
                       usingSpringWithDamping: 0.5,
                       initialSpringVelocity: 0.5,
                       options: [.repeat, .autoreverse],
                       animations: {
            emojiLabel.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
        }, completion: nil)
    }
    
    private static func spinAnimation(emojiLabel: UILabel) {
        UIView.animate(withDuration: 1.0,
                       delay: 0,
                       options: [.repeat, .curveLinear],
                       animations: {
            emojiLabel.transform = CGAffineTransform(rotationAngle: .pi * 2)
        }, completion: nil)
    }
    
    private static func fadeAnimation(emojiLabel: UILabel) {
        UIView.animate(withDuration: 0.8,
                       delay: 0,
                       options: [.repeat, .autoreverse],
                       animations: {
            emojiLabel.alpha = 0.2
        }, completion: nil)
    }
    
    private static func pathAnimation(emojiLabel: UILabel) {
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 0, y: 0))
        path.addCurve(to: CGPoint(x: 0, y: 100),
                     controlPoint1: CGPoint(x: 50, y: 0),
                     controlPoint2: CGPoint(x: -50, y: 100))
        
        let animation = CAKeyframeAnimation(keyPath: "position")
        animation.path = path.cgPath
        animation.duration = 2.0
        animation.repeatCount = Float.infinity
        
        emojiLabel.layer.add(animation, forKey: "moveOnPath")
    }
    
    private static func pulseAnimation(emojiLabel: UILabel) {
        let pulseAnimation = CABasicAnimation(keyPath: "transform.scale")
        pulseAnimation.duration = 0.5
        pulseAnimation.fromValue = 1.0
        pulseAnimation.toValue = 1.2
        pulseAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        pulseAnimation.autoreverses = true
        pulseAnimation.repeatCount = Float.infinity
        
        emojiLabel.layer.add(pulseAnimation, forKey: "pulse")
    }
}
