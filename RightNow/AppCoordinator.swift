import UIKit

protocol Coordinator: AnyObject {
    var childCoordinators: [Coordinator] { get set }
    var navigationController: UINavigationController { get set }
    
    func start()
    func finish()
}

extension Coordinator {
    func addChildCoordinator(_ coordinator: Coordinator) {
        childCoordinators.append(coordinator)
    }
    
    func removeChildCoordinator(_ coordinator: Coordinator) {
        childCoordinators.removeAll { $0 === coordinator }
    }
    
    func finish() {
        childCoordinators.removeAll()
    }
}

class AppCoordinator: Coordinator {
    var childCoordinators: [Coordinator] = []
    var navigationController: UINavigationController
    private let window: UIWindow
    
    private var hasCompletedOnboarding: Bool {
        return UserDefaults.standard.bool(forKey: "finishedOnboarding")
    }
    
    init(navigationController: UINavigationController, window: UIWindow) {
        self.navigationController = navigationController
        self.window = window
    }
    
    func start() {
        Task {
            if await checkOnboardingStatus() {
                showMainApp()
            } else {
                showOnboarding()
            }
        }
    }
    
    private func showMainApp() {
        DispatchQueue.main.async {
            let tabBarController = TabBarController()
            self.window.rootViewController = tabBarController
            self.window.makeKeyAndVisible()
            
            NotificationCenter.default.post(name: .userDidLogin, object: nil)
        }
    }
    
    private func checkOnboardingStatus() async -> Bool {
        do {
            let userSettings: UserSettings? = try await FirebaseManager.shared.getDocument(
                collection: FirebaseManager.FirestoreCollection.users.rawValue,
                subcollection: nil,
                subdocument: nil
            )
            
            if let settings = userSettings {
                UserDefaults.standard.set(settings.hasCompletedOnboarding, forKey: "finishedOnboarding")
                return settings.hasCompletedOnboarding
            }
            
            return false
        } catch {
            print("Error retrieving onboarding status: \(error)")
            return false
        }
    }
    
    private func saveOnboardingStatus(completed: Bool) async {
        let userSettings = UserSettings(hasCompletedOnboarding: completed)
        
        do {
            try await FirebaseManager.shared.setDocument(
                data: userSettings,
                collection: FirebaseManager.FirestoreCollection.users.rawValue,
                subcollection: nil,
                subdocument: nil
            )
            
            UserDefaults.standard.set(completed, forKey: "finishedOnboarding")
        } catch {
            print("Error saving onboarding status \(error)")
        }
    }
}

extension AppCoordinator: OnboardingCoordinatorDelegate {
    private func showOnboarding() {
        let onboardingCoordinator = OnboardingCoordinator(navigationController: navigationController, window: window)
        onboardingCoordinator.delegate = self
        onboardingCoordinator.start()
        addChildCoordinator(onboardingCoordinator)
    }
    
    func onboardingCoordinatorDidFinish(_ coordinator: OnboardingCoordinator) {
        Task {
            await saveOnboardingStatus(completed: true)
        }
        
        DispatchQueue.main.async {
            // Remove onboarding coordinator from child coordinators
            self.removeChildCoordinator(coordinator)
            
            // Animate transition to main app
            UIView.transition(with: self.window, duration: 0.3, options: .transitionCrossDissolve, animations: {
                self.showMainApp()
            }, completion: nil)
        }
    }
}

extension Notification.Name {
    static let userDidLogin = Notification.Name("userDidLogin")
}
