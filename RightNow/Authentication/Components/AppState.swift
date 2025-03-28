/// Stores reference to current user that is maintained through a session
class AppState {
    static let shared = AppState()
    
    var currentUser: User?
}
