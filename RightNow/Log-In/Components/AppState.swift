import SwiftUI

class AppState: ObservableObject {
    static let shared = AppState() // make singleton
    
    @Published var user: User?
    var currentUser: User?
    var notificationHabitID: String?
    var actionIdentifier: String?
}
