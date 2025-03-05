import Firebase

protocol FirebaseConfigurable {
    var isConfigured: Bool { get }
    func configure()
}

class FirebaseManager: FirebaseConfigurable {
    static let shared: FirebaseConfigurable = FirebaseManager()
    
    private(set) var isConfigured = false
    
    func configure() {
        guard !isConfigured else { return }
        FirebaseApp.configure()
        isConfigured = true
        
        Task {
            Database.database().isPersistenceEnabled = true
        }
    }
}
