import UIKit

/// Utility class for creating UIImages from emoji characters
final class EmojiImage {
    /// Creates a basic emoji image with default styling
    /// - Parameters:
    ///   - emoji: The emoji string to convert
    ///   - size: The font size of the emoji
    /// - Returns: A UIImage containing the rendered emoji
    static func createImage(from emoji: String, size: CGFloat) -> UIImage {
        // Configure the rendering attributes
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: size)
        ]
        
        // Calculate the size needed
        let stringSize = emoji.size(withAttributes: attributes)
        
        // Create the renderer with the calculated size
        let renderer = UIGraphicsImageRenderer(size: stringSize)
        
        // Generate the image
        return renderer.image { context in
            emoji.draw(at: .zero, withAttributes: attributes)
        }
    }
    
    /// Creates an emoji image with a colored circular background
    /// - Parameters:
    ///   - emoji: The emoji string to convert
    ///   - size: The font size of the emoji
    ///   - backgroundColor: The background color for the circular container
    ///   - padding: Additional padding around the emoji (as a multiplier of size)
    /// - Returns: A UIImage containing the emoji with circular background
    static func createCircularImage(from emoji: String,
                                   size: CGFloat,
                                   backgroundColor: UIColor = .systemBlue,
                                   padding: CGFloat = 0.5) -> UIImage {
        // Calculate dimensions
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: size)
        ]
        let emojiSize = emoji.size(withAttributes: attributes)
        let diameter = max(emojiSize.width, emojiSize.height) + (size * padding)
        
        // Center point calculation
        let centerX = diameter / 2
        let centerY = diameter / 2
        
        // Create renderer with square dimensions
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: diameter, height: diameter))
        
        return renderer.image { context in
            // Draw the circular background
            let circlePath = UIBezierPath(arcCenter: CGPoint(x: centerX, y: centerY),
                                         radius: diameter / 2,
                                         startAngle: 0,
                                         endAngle: .pi * 2,
                                         clockwise: true)
            backgroundColor.setFill()
            circlePath.fill()
            
            // Calculate emoji position to center it
            let emojiX = (diameter - emojiSize.width) / 2
            let emojiY = (diameter - emojiSize.height) / 2
            
            // Draw the emoji
            emoji.draw(at: CGPoint(x: emojiX, y: emojiY), withAttributes: attributes)
        }
    }
    
    /// Creates an emoji image with a custom background shape
    /// - Parameters:
    ///   - emoji: The emoji string to convert
    ///   - size: The font size of the emoji
    ///   - backgroundColor: The background color
    ///   - cornerRadius: The corner radius for the rounded rectangle
    /// - Returns: A UIImage containing the emoji with rounded rectangle background
    static func createRoundedRectImage(from emoji: String,
                                      size: CGFloat,
                                      backgroundColor: UIColor = .systemGray5,
                                      cornerRadius: CGFloat = 12) -> UIImage {
        // Calculate dimensions with padding
        let padding = size * 0.6
        let width = size + padding
        let height = size + padding
        
        // Create the renderer
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: width, height: height))
        
        return renderer.image { context in
            // Draw rounded rectangle background
            let rectangle = CGRect(x: 0, y: 0, width: width, height: height)
            let path = UIBezierPath(roundedRect: rectangle, cornerRadius: cornerRadius)
            backgroundColor.setFill()
            path.fill()
            
            // Calculate position to center the emoji
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: size)
            ]
            let emojiSize = emoji.size(withAttributes: attributes)
            let emojiX = (width - emojiSize.width) / 2
            let emojiY = (width - emojiSize.height) / 2
            
            // Draw the emoji
            emoji.draw(at: CGPoint(x: emojiX, y: emojiY), withAttributes: attributes)
        }
    }
    
    /// Creates an emoji image with a custom font and color
    /// - Parameters:
    ///   - emoji: The emoji string to convert
    ///   - size: The font size of the emoji
    ///   - tintColor: Optional tint color to apply to the emoji
    ///   - fontName: The name of the font to use (defaults to system font)
    /// - Returns: A UIImage containing the styled emoji
    static func createStyledImage(from emoji: String,
                                 size: CGFloat,
                                 tintColor: UIColor? = nil,
                                 fontName: String? = nil) -> UIImage {
        // Configure font
        var font: UIFont
        if let name = fontName, let customFont = UIFont(name: name, size: size) {
            font = customFont
        } else {
            font = UIFont.systemFont(ofSize: size)
        }
        
        // Set up attributes
        var attributes: [NSAttributedString.Key: Any] = [.font: font]
        if let color = tintColor {
            attributes[.foregroundColor] = color
        }
        
        // Calculate the size needed
        let stringSize = emoji.size(withAttributes: attributes)
        
        // Create the renderer
        let renderer = UIGraphicsImageRenderer(size: stringSize)
        
        // Generate the image
        return renderer.image { context in
            emoji.draw(at: .zero, withAttributes: attributes)
        }
    }
    
    // MARK: - Preset Emoji Factory Methods
    
    /// Creates a warning emoji image
    /// - Parameter size: The size of the emoji
    /// - Returns: A warning emoji image
    static func createWarningEmoji(size: CGFloat) -> UIImage {
        return createCircularImage(from: "⚠️", size: size, backgroundColor: .systemYellow)
    }
    
    /// Creates a success emoji image
    /// - Parameter size: The size of the emoji
    /// - Returns: A success emoji image
    static func createSuccessEmoji(size: CGFloat) -> UIImage {
        return createCircularImage(from: "✅", size: size, backgroundColor: .systemGreen, padding: 0.4)
    }
    
    /// Creates an error emoji image
    /// - Parameter size: The size of the emoji
    /// - Returns: An error emoji image
    static func createErrorEmoji(size: CGFloat) -> UIImage {
        return createCircularImage(from: "❌", size: size, backgroundColor: .systemRed, padding: 0.4)
    }
    
    /// Creates a loading/progress emoji image
    /// - Parameter size: The size of the emoji
    /// - Returns: A loading emoji image
    static func createLoadingEmoji(size: CGFloat) -> UIImage {
        return createCircularImage(from: "⏳", size: size, backgroundColor: .systemBlue)
    }
}
