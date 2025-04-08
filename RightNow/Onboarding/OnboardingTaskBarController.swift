import Foundation
import UIKit

/// manages main navigation structure during onboarding
class OnboardingTabBarController: UITabBarController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // create instances of view controllers
        let gameVC = CentralGameViewController()
        let gameNav = UINavigationController(rootViewController: gameVC)
        
        let onboardingVC = OnboardingViewController()
        let onboardingNav = UINavigationController(rootViewController: onboardingVC)
        
        let habitListVC = HabitListViewController()
        let habitListNav = UINavigationController(rootViewController: habitListVC)
        
        // configure tab bar items
        gameNav.tabBarItem = UITabBarItem(
            title: "Numbers",
            image: UIImage(systemName: "number.circle"),
            selectedImage: UIImage(systemName: "number.circle.fill")
        )
        
        onboardingNav.tabBarItem = UITabBarItem(
            title: "Pets",
            image: UIImage(systemName: "pawprint.circle"),
            selectedImage: UIImage(systemName: "pawprint.circle.fill")
        )
        
        habitListNav.tabBarItem = UITabBarItem(
            title: "Habits",
            image: UIImage(systemName: "heart.circle"),
            selectedImage: UIImage(systemName: "heart.circle.fill")
        )
        
        // set tab bar
        self.viewControllers = [gameNav, onboardingNav, habitListNav]
        
        self.tabBar.tintColor = UIConfiguration.tintColor
        self.tabBar.unselectedItemTintColor = .gray
    }
    
    /// response to selection of tab bar item by posting notification
    /// - Parameters:
    ///     - tabBar: the tab bar containing the selected item
    ///     - item: the tab bar item that was selected
    override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        super.tabBar(tabBar, didSelect: item)
        
        // post notification when tab bar item is selected
        NotificationCenter.default.post(name: UITabBarController.didSelectItemNotification, object: self)
    }
}

/// adds custom notification name for tab bar selection
extension NSNotification.Name {
    static let tabBarItemSelected = NSNotification.Name("tabBarItemSelected")
}

/// adds custom notification name for UITabBarController
extension UITabBarController {
    static let didSelectItemNotification = NSNotification.Name("UITabBarControllerDidSelectItem")
}
