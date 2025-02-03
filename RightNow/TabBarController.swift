import Foundation
import UIKit

class TabBarController: UITabBarController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // create instances of view controllers
        let maowVC = MaowViewController()
        let maowNav = UINavigationController(rootViewController: maowVC)
        
        let habitListVC = HabitListViewController()
        let habitListNav = UINavigationController(rootViewController: habitListVC)
        
        // configure tab bar items
        maowNav.tabBarItem = UITabBarItem(
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
        self.viewControllers = [maowNav, habitListNav]
        
        self.tabBar.tintColor = UIConfiguration.tintColor
        self.tabBar.unselectedItemTintColor = .gray
    }
}
