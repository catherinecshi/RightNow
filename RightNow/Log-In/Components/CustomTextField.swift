import UIKit

class CustomTextField: UITextField {
    
    private var padding: UIEdgeInsets = .zero
    
    init(placeHolderText: String, isPasswordType: Bool = false) {
        super.init(frame: .zero)
        self.placeholder = placeHolderText
        
        if isPasswordType {
            self.isSecureTextEntry = true
        }
        
        applyMyTextFieldStyle()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func textRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: padding)
    }
    
    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: padding)
    }
    
    override func placeholderRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: padding)
    }

    private func applyMyTextFieldStyle() {
        self.layer.cornerRadius = 25
        self.layer.borderWidth = 1
        self.layer.borderColor = UIColor.gray.cgColor
        self.padding = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
    }
}
