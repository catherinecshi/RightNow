import Foundation
import UIKit

class OnboardingTabBarController: UITabBarController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // create instances of view controllers
        let towerVC = GameViewController()
        let towerNav = UINavigationController(rootViewController: towerVC)
        
        let onboardingVC = OnboardingViewController()
        let onboardingNav = UINavigationController(rootViewController: onboardingVC)
        
        let habitListVC = HabitListViewController()
        let habitListNav = UINavigationController(rootViewController: habitListVC)
        
        // configure tab bar items
        towerNav.tabBarItem = UITabBarItem(
            title: "Defense",
            image: UIImage(systemName: "shield"),
            selectedImage: UIImage(systemName: "shield.fill")
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
        self.viewControllers = [towerNav, onboardingNav, habitListNav]
        
        self.tabBar.tintColor = UIConfiguration.tintColor
        self.tabBar.unselectedItemTintColor = .gray
    }
    
    override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        super.tabBar(tabBar, didSelect: item)
        
        // post notification when tab bar item is selected
        NotificationCenter.default.post(name: UITabBarController.didSelectItemNotification, object: self)
    }
}

extension NSNotification.Name {
    static let tabBarItemSelected = NSNotification.Name("tabBarItemSelected")
}

extension UITabBarController {
    static let didSelectItemNotification = NSNotification.Name("UITabBarControllerDidSelectItem")
}
