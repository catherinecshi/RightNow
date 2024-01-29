import SwiftUI

class AppState: ObservableObject {
    @Published var user: User?
    var currentUser: User?
    var notificationHabitID: String?
    var actionIdentifier: String?
}
