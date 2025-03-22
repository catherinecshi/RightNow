import Foundation

struct User {
    enum LoginType {
        case email
        case guest
        case google
    }
    
    let id: String
    let email: String?
    let loginType: LoginType
    let isAnonymous: Bool
    
    init(id: String, email: String?, loginType: LoginType = .guest, isAnonymous: Bool = false) {
        self.id = id
        self.email = email
        self.loginType = loginType
        self.isAnonymous = isAnonymous
    }
}
