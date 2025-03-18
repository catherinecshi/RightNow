import UIKit

protocol OnboardingCoordinatorDelegate: AnyObject {
    func onboardingCoordinatorDidFinish(_ coordinator: OnboardingCoordinator)
}

class OnboardingCoordinator: Coordinator {
    var childCoordinators: [Coordinator] = []
    var navigationController: UINavigationController
    private let window: UIWindow
    
    weak var delegate: OnboardingCoordinatorDelegate?
    private var onboardingTabBarController: OnboardingTabBarController?
    private var onboardingViewController: OnboardingViewController?
    private var habitListViewController: HabitListViewController?
    private var selectHabitViewController: SelectHabitViewController?
    private var selectTimeViewController: SelectTimeViewController?
    
    // track onboarding state
    private var onboardingState: OnboardingState = .initial
    private var onboardingHabitData: HabitData?
    
    enum OnboardingState {
        case initial
        case meetingMaow
        case switchToHabits
        case habitCreation
        case habitModification
        case switchToMaow
        case saveMaow
        case complete
    }
    
    init(navigationController: UINavigationController, window: UIWindow) {
        self.navigationController = navigationController
        self.window = window
    }
    
    func start() {
        startOnboardingSequence()
        onboardingState = .initial
    }
    
    // MARK: - Setup
    
    private func showOnboardingTabBarController() {
        let onboardingTabBarController = OnboardingTabBarController()
        
        // Create the view controllers
        let towerVC = TowerDefenseViewController()
        let towerNav = UINavigationController(rootViewController: towerVC)
        
        let onboardingVC = createOnboardingViewController()
        let onboardingNav = UINavigationController(rootViewController: onboardingVC)
        
        let habitListVC = createHabitListViewController()
        let habitListNav = UINavigationController(rootViewController: habitListVC)
        
        // Configure tab bar items
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
        
        // Set tab bar
        onboardingTabBarController.viewControllers = [towerNav, onboardingNav, habitListNav]
        onboardingTabBarController.tabBar.tintColor = UIConfiguration.tintColor
        onboardingTabBarController.tabBar.unselectedItemTintColor = .gray
        onboardingTabBarController.selectedIndex = 1
        
        // Store reference
        self.onboardingTabBarController = onboardingTabBarController
        
        // Set as root view controller
        window.rootViewController = onboardingTabBarController
        window.makeKeyAndVisible()
    }
    
    private func createOnboardingViewController() -> OnboardingViewController {
        let onboardingVC = OnboardingViewController()
        onboardingVC.coordinator = self
        self.onboardingViewController = onboardingVC
        return onboardingVC
    }
    
    private func createHabitListViewController() -> HabitListViewController {
        let habitListVC = HabitListViewController()
        habitListVC.coordinator = self
        self.habitListViewController = habitListVC
        return habitListVC
    }
    
    func saveHabit(habitData: HabitData) {
        // save the habitData
        let habitDate = TimeFormatter.hourMinuteToDate(hour: habitData.hour ?? 9, minute: habitData.minute ?? 0)
        let newHabit = Habit(id: UUID(),
                             name: habitData.name!,
                             description: "",
                             time: habitDate!,
                             daysOfTheWeek: habitData.selectedDays!,
                             accountabilityMetric: habitData.accountabilityMetric ?? .selfTracking,
                             location: habitData.location,
                             incentive: habitData.incentive ?? .none,
                             notificationEnabled: false,
                             totalDone: 0,
                             totalFailed: 0,
                             streaks: 0,
                             lastUpdateDate: Date())
        
        HabitRepository.shared.addHabit(newHabit)
    }
    
    // MARK: - Navigation
    func startOnboardingSequence() {
        let onboardingVC = createOnboardingViewController()
        window.rootViewController = onboardingVC
        window.makeKeyAndVisible()
        
        onboardingState = .meetingMaow
        
        Task {
            await onboardingVC.startOnboardingSequence()
        }
    }
    
    @MainActor
    func showHabitsScreen() async {
        print("show habits scree")
        showOnboardingTabBarController()
        guard let tabBarController = onboardingTabBarController else { return }
        tabBarController.view.alpha = 0
        
        onboardingState = .switchToHabits
        
        // block all interactions during transition from onboarding to habitlist
        await InteractionBlocker.shared.blockInteractions(on: tabBarController.view)
        
        // animate in the tab bar controller
        await withCheckedContinuation { continuation in
            UIView.animate(withDuration: 0.3) {
                print("animating")
                tabBarController.view.alpha = 1
            } completion: { finished in
                continuation.resume()
            }
        }
        
        // wait for formatting
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        // create and show focus view on tab Bar
        await focusOnTabBarItem(in: tabBarController, for: 2, with: "Maow's health is linked with your habits")
    }
    
    func showHabitListFocus() {
        guard let tabBarController = onboardingTabBarController else { return }
        onboardingState = .habitCreation
        
        if let habitListNav = tabBarController.viewControllers?[2] as? UINavigationController,
           let habitListVC = habitListNav.topViewController as? HabitListViewController {
            habitListVC.coordinator = self
            habitListVC.setupOnboarding()
            habitListVC.showOnboardingFocus()
            
            Task {
                await InteractionBlocker.shared.unblockInteractions()
            }
        }
    }
    
    func showHabitCreation() {
        guard let tabBarController = onboardingTabBarController else { return }
        guard let habitListVC = habitListViewController else { return }
        
        let selectHabitVC = SelectHabitViewController()
        selectHabitVC.coordinator = self
        selectHabitViewController = selectHabitVC
        
        // prepare timevc in advance
        let timeVC = SelectTimeViewController()
        timeVC.coordinator = self
        selectTimeViewController = timeVC
        
        // present
        if let habitListNav = tabBarController.viewControllers?[2] as? UINavigationController {
            let navController = UINavigationController(rootViewController: selectHabitVC)
            navController.modalPresentationStyle = .pageSheet
            habitListNav.present(navController, animated: true, completion: nil)
        }
    }
    
    func showHabitTime(habitData: HabitData) {
        guard let timeVC = selectTimeViewController else { return }
        guard let selectHabitVC = selectHabitViewController else { return }
        
        timeVC.habitData = habitData
        selectHabitVC.navigationController?.pushViewController(timeVC, animated: true)
        
        // wait
        Task {
            try? await Task.sleep(nanoseconds: 500_000_000)
            await timeVC.onboardingSequence()
        }
    }
    
    func finishHabitCreation(habitData: HabitData) {
        saveHabit(habitData: habitData)
        dismissHabitCreationFlow(didCompleteHabitCreation: true)
    }
    
    func dismissHabitCreationFlow(didCompleteHabitCreation: Bool) {
        Task {
            try? await Task.sleep(nanoseconds: 500_000_000) // wait for animation
        }
        
        if !didCompleteHabitCreation { // this realistically shouldn't really happen
            showHabitListFocus()
        } else {
            self.onboardingState = .habitModification
            showHabitModification()
        }
    }
    
    func showHabitModification() {
        guard let habitListVC = habitListViewController else { return }
        
        Task {
            await habitListVC.showDeletion()
        }
    }
    
    func switchToMaow() {
        guard let tabBarController = onboardingTabBarController else { return }
        onboardingState = .switchToMaow
        
        Task {
            await focusOnTabBarItem(in: tabBarController, for: 1, with: "Let's go check back in on Maow")
        }
    }
    
    func showSaveMaow() {
        
    }
    
    func completeOnboarding() {
        delegate?.onboardingCoordinatorDidFinish(self)
    }
    
    // MARK: - Focus View Methods
    
    @MainActor
    private func focusOnTabBarItem(in tabBarController: OnboardingTabBarController, for position: Int, with text: String) async {
        // Calculate the frame of the second tab item based on the tab bar's width
        let tabBarWidth = tabBarController.tabBar.bounds.width
        let numberOfItems = CGFloat(tabBarController.tabBar.items?.count ?? 0)
        let tabWidth = tabBarWidth / numberOfItems
        
        // make sure that the number provided in the function doesn't exceed the number of items in the tab
        if CGFloat(position) > numberOfItems {
            return
        }
        let tabX = CGFloat(position) * tabWidth
        let tabBarHeight = tabBarController.tabBar.bounds.height
        
        // Create a frame for the third tab item
        let tabFrame = CGRect(
            x: tabX,
            y: 0,
            width: tabWidth,
            height: tabBarHeight
        )
        
        // Convert this frame to the tab bar controller's view coordinates
        let buttonFrame = tabBarController.tabBar.convert(tabFrame, to: tabBarController.view)
        
        // Create and configure the focus view
        let focusView = FocusView()
        focusView.translatesAutoresizingMaskIntoConstraints = false
        focusView.shapeType = .circle
        focusView.alpha = 0
        focusView.isUserInteractionEnabled = true
        
        let instructionLabel = UILabel()
        instructionLabel.font = .systemFont(ofSize: 20, weight: .medium)
        instructionLabel.textColor = .white
        instructionLabel.textAlignment = .center
        instructionLabel.numberOfLines = 0
        instructionLabel.text = text
        instructionLabel.translatesAutoresizingMaskIntoConstraints = false
        instructionLabel.alpha = 0
        
        tabBarController.view.addSubview(focusView)
        tabBarController.view.addSubview(instructionLabel)
        
        NSLayoutConstraint.activate([
            focusView.topAnchor.constraint(equalTo: tabBarController.view.topAnchor, constant: -20),
            focusView.leadingAnchor.constraint(equalTo: tabBarController.view.leadingAnchor),
            focusView.trailingAnchor.constraint(equalTo: tabBarController.view.trailingAnchor),
            focusView.bottomAnchor.constraint(equalTo: tabBarController.view.bottomAnchor, constant: -20),
            
            instructionLabel.bottomAnchor.constraint(equalTo: tabBarController.tabBar.topAnchor, constant: -40),
            instructionLabel.centerXAnchor.constraint(equalTo: tabBarController.tabBar.centerXAnchor, constant: tabWidth/2),
            instructionLabel.leadingAnchor.constraint(greaterThanOrEqualTo: tabBarController.view.leadingAnchor, constant: 40),
            instructionLabel.trailingAnchor.constraint(lessThanOrEqualTo: tabBarController.view.trailingAnchor, constant: -40)
        ])
        
        // Set the focus area
        let paddedFrame = buttonFrame.insetBy(dx: -10, dy: -10)
        focusView.ovalRect = paddedFrame
        
        // Animate the focus view appearance
        UIView.animate(withDuration: 0.3) {
            focusView.alpha = 1.0
            instructionLabel.alpha = 1.0
        }
        
        // Add tap gesture recognizer to the focus view
        let tapGesture = UITapGestureRecognizer(target: nil, action: nil)
        
        // Use closure-based handler for the tap gesture
        tapGesture.addTarget { [weak tabBarController, weak focusView, weak instructionLabel] _ in
            // Check if we still have the tab bar controller
            guard let tabBarController = tabBarController else { return }
            
            // Get the tap location
            let location = tapGesture.location(in: focusView)
            
            // Check if the tap is within the highlighted area
            let isInHighlightedArea: Bool
            switch focusView?.shapeType {
            case .circle:
                // For circle, check if distance from center is less than radius
                if let focusView = focusView {
                    let diameter = min(paddedFrame.width, paddedFrame.height)
                    let radius = diameter / 2
                    let centerX = paddedFrame.midX
                    let centerY = paddedFrame.midY
                    
                    let dx = location.x - centerX
                    let dy = location.y - centerY
                    let distance = sqrt(dx*dx + dy*dy)
                    
                    isInHighlightedArea = distance <= radius
                } else {
                    isInHighlightedArea = false
                }
                
            case .roundedRect:
                // For rounded rect, check if point is inside the rect
                isInHighlightedArea = paddedFrame.contains(location)
                
            default:
                isInHighlightedArea = false
            }
            
            // If tap is in the highlighted area, select the second tab
            if isInHighlightedArea {
                // Switch to the habits tab
                tabBarController.selectedIndex = position
                
                // Animate out the focus view and instruction label
                UIView.animate(withDuration: 0.3, animations: {
                    focusView?.alpha = 0
                    instructionLabel?.alpha = 0
                }, completion: { _ in
                    focusView?.removeFromSuperview()
                    instructionLabel?.removeFromSuperview()
                    
                    self.tabBarItemTapped()
                })
            }
        }
        
        focusView.addGestureRecognizer(tapGesture)
    }
    
    private func tabBarItemTapped() {
        if onboardingState == .switchToHabits {
            showHabitListFocus()
        } else if onboardingState == .switchToMaow {
            showSaveMaow()
        }
    }
}
