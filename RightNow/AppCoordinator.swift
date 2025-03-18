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
        if hasCompletedOnboarding {
            showMainApp()
            print("show main app")
        } else {
            showOnboarding()
            print("show onboarding")
        }
    }
    
    private func showMainApp() {
        let tabBarController = TabBarController()
        window.rootViewController = tabBarController
        window.makeKeyAndVisible()
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
        UserDefaults.standard.set(true, forKey: "finishedOnboarding")
        
        // remove onboarding coordinator from child coordinators
        removeChildCoordinator(coordinator)
        
        showMainApp()
    }
}
