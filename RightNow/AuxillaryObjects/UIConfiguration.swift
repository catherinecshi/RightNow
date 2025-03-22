import SwiftUI
import UIKit

class UIConfiguration {
    // Fonts
    static let titleFont = UIFont(name: "Arial Rounded MT Bold", size: 28)!
    static let subtitleFont = UIFont(name: "Avenir-Medium", size: 16)!
    static let genericFont = UIFont(name: "Avenir-Medium", size: 20)!
    static let buttonFont = UIFont(name: "Avenir-Heavy", size: 20)!
    
    // Color
    static let backgroundColor: UIColor = .white
    static let tintColor = UIColor(hexString: "#ff5a66")
    static let subtitleColor = UIColor(hexString: "#464646")
    static let buttonColor = UIColor(hexString: "#414665")
    static let buttonBorderColor = UIColor(hexString: "#B0B3C6")
}

extension UIColor {
    convenience init?(hexString: String) {
        let chars = Array(hexString.dropFirst())
        self.init(red: CGFloat(strtoul(String(chars[0...1]), nil, 16)) / 255,
                  green: CGFloat(strtoul(String(chars[2...3]), nil, 16)) / 255,
                  blue: CGFloat(strtoul(String(chars[4...5]), nil, 16)) / 255,
                  alpha: 1.0)
    }
}
