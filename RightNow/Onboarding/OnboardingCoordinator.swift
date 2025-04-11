import UIKit

protocol OnboardingCoordinatorDelegate: AnyObject {
    func onboardingCoordinatorDidFinish(_ coordinator: OnboardingCoordinator)
}

/// Handles navigation and flow logic during onboarding
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
    private var centralGameViewController: CentralGameViewController?
    private var numberFactoryViewController: NumberFactoryViewController?
    private var numberFactoryOnboardingViewController: NumberFactoryOnboardingViewController?
    
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
        case switchToGame
        case gameIntroduction
        case numberFactory
        case complete
    }
    
    init(navigationController: UINavigationController, window: UIWindow) {
        self.navigationController = navigationController
        self.window = window
    }
    
    /// this starts the sequence in the onboarding view
    func start() {
        startOnboardingSequence()
        onboardingState = .initial
    }
    
    // MARK: - Setup
    
    /// creates the onboarding tab bar controller after the onboarding view sequence is done
    private func showOnboardingTabBarController() {
        let onboardingTabBarController = OnboardingTabBarController()
        
        // Create the view controllers
        let gameVC = createGameViewController()
        let gameNav = UINavigationController(rootViewController: gameVC)
        
        let onboardingVC = createOnboardingViewController()
        let onboardingNav = UINavigationController(rootViewController: onboardingVC)
        
        let habitListVC = createHabitListViewController()
        let habitListNav = UINavigationController(rootViewController: habitListVC)
        
        // Configure tab bar items
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
        
        // Set tab bar
        onboardingTabBarController.viewControllers = [gameNav, onboardingNav, habitListNav]
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
    
    private func createGameViewController() -> CentralGameViewController {
        let gameVC = CentralGameViewController()
        gameVC.coordinator = self
        self.centralGameViewController = gameVC
        return gameVC
    }
    
    // MARK: - How to make a habit
    func startOnboardingSequence() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            let onboardingVC = createOnboardingViewController()
            
            guard self.window != nil else {
                print("Error window is nil in startonboardingsequence")
                return
            }
            
            self.window.rootViewController = onboardingVC
            self.window.makeKeyAndVisible()
            
            self.onboardingState = .meetingMaow
            
            Task {
                await onboardingVC.startOnboardingSequence()
            }
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
        print("habit creation finished")
        saveHabit(habitData: habitData)
        dismissHabitCreationFlow(didCompleteHabitCreation: true)
    }
    
    func dismissHabitCreationFlow(didCompleteHabitCreation: Bool) {
        print("habit creation flow being dismissed")
        Task {
            try? await Task.sleep(nanoseconds: 500_000_000) // wait for animation
            
            if !didCompleteHabitCreation { // this realistically shouldn't really happen
                print("did not finish habit creation")
                showHabitListFocus()
            } else {
                print("trying to show habit modification")
                self.onboardingState = .habitModification
                showHabitModification()
            }
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
    
    func showMaowHealth() {
        guard let onboardingVC = onboardingViewController else { return }
        guard let tabBarController = onboardingTabBarController else { return }
        onboardingState = .saveMaow
        
        Task {
            await InteractionBlocker.shared.blockInteractions(on: tabBarController.view)
            await onboardingVC.sixthOnboardingSequence()
        }
    }
    
    // MARK: - How to make numbers
    func switchToGame() {
        guard let tabBarController = onboardingTabBarController else { return }
        onboardingState = .switchToGame
        
        Task {
            await InteractionBlocker.shared.unblockInteractions()
            await focusOnTabBarItem(in: tabBarController, for: 0, with: "You can use the coupons at the number factory")
        }
    }
    
    func showGameIntroduction() {
        guard let tabBarController = onboardingTabBarController else { return }
        onboardingState = .gameIntroduction
        
        if let gameNav = tabBarController.viewControllers?[0] as? UINavigationController,
           let gameVC = gameNav.topViewController as? CentralGameViewController {
            gameVC.coordinator = self
            gameVC.setupOnboarding()
            gameVC.showOnboardingFocus()
        }
    }
    
    func showNumberFactory() {
        guard let tabBarController = onboardingTabBarController else { return }
        guard let gameVC = centralGameViewController else { return }
        
        onboardingState = .numberFactory
        
        let numberFactoryVC = NumberFactoryViewController()
        numberFactoryVC.coordinator = self
        numberFactoryViewController = numberFactoryVC
        
        // present
        if let gameNav = tabBarController.viewControllers?[0] as? UINavigationController {
            let navController = UINavigationController(rootViewController: numberFactoryVC)
            navController.modalPresentationStyle = .overFullScreen
            gameNav.present(navController, animated: true, completion: nil)
        }
    }
    
    func presentNumberFactoryOnboarding(completion: (() -> Void)? = nil) {
        guard let numberFactoryVC = numberFactoryViewController else {
            print("no numberfactory view controller")
            return
        }
        // present onboarding alert
        let steps = [
            OnboardingStep(mediaName: "gifset_1",
                           mediaType: .mp4,
                           caption: "Swipe to combine numbers"),
            OnboardingStep(mediaName: "dontfalloff",
                           mediaType: .staticImage,
                           caption: "Don't fall off when the game scrolls"),
            OnboardingStep(mediaName: "bomb",
                           mediaType: .staticImage,
                           caption: "The game ends when you hit a bomb"),
            OnboardingStep(mediaName: "avoid",
                           mediaType: .staticImage,
                           caption: "Or when you merge into a number in the avoid box"),
            OnboardingStep(mediaName: "goal",
                           mediaType: .staticImage,
                           caption: "Hit the goal to add that amount to your score"),
            OnboardingStep(mediaName: "🎟️",
                           mediaType: .emoji,
                           caption: "It takes one coupon to play one round!")
        ]
        
        let numberFactoryOnboardingVC = NumberFactoryOnboardingViewController(steps: steps)
        numberFactoryOnboardingVC.onComplete = completion
        self.numberFactoryOnboardingViewController = numberFactoryOnboardingVC
        
        numberFactoryVC.present(numberFactoryOnboardingVC, animated: true)
    }
    
    func dismissNumberFactory() async {
        guard let gameVC = centralGameViewController else { return }
        
        onboardingState = .complete
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1second
        
        // Move completeOnboarding to execute only after alert is dismissed
        await MainActor.run {
            gameVC.showCompletionAlert { [weak self] in
                guard let self = self else { return }
                self.completeOnboarding()
            }
        }
    }
    
    func completeOnboarding() {
        // Ensure we're on the main thread when handling UI
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.cleanUpViewHierarchy {
                self.delegate?.onboardingCoordinatorDidFinish(self)
            }
        }
    }

    private func cleanUpViewHierarchy(completion: @escaping () -> Void) {
        // Create a dispatch group to track all dismissals
        let group = DispatchGroup()
        
        // Dismiss any presented view controllers
        if let numberFactoryVC = numberFactoryViewController,
           numberFactoryVC.presentedViewController != nil {
            group.enter()
            numberFactoryVC.dismiss(animated: false) {
                group.leave()
            }
        }
        
        if let centralGameVC = centralGameViewController,
           centralGameVC.presentedViewController != nil {
            group.enter()
            centralGameVC.dismiss(animated: false) {
                group.leave()
            }
        }
        
        // Wait for all dismissals to complete
        group.notify(queue: .main) {
            // Release strong references to view controllers
            self.onboardingTabBarController = nil
            self.onboardingViewController = nil
            self.habitListViewController = nil
            self.selectHabitViewController = nil
            self.selectTimeViewController = nil
            self.centralGameViewController = nil
            self.numberFactoryViewController = nil
            self.numberFactoryOnboardingViewController = nil
            
            // Clear any other cached data
            self.onboardingHabitData = nil
            
            // Call completion
            completion()
        }
    }
    
    // MARK: - Focus View Methods
     
    /// focuses on tab bar item without crashes by blocking all other tap gestures
    @MainActor
    private func focusOnTabBarItem(in tabBarController: OnboardingTabBarController, for position: Int, with text: String) async {
        print("--- Focus Debug ---")
        print("Device: \(UIDevice.current.userInterfaceIdiom == .pad ? "iPad" : "iPhone")")
        
        // Calculate frame metrics
        let tabBarWidth = tabBarController.tabBar.bounds.width
        let numberOfItems = CGFloat(tabBarController.tabBar.items?.count ?? 0)
        let tabWidth = tabBarWidth / numberOfItems
        
        print("Tab bar width: \(tabBarWidth), Items: \(numberOfItems), Tab width: \(tabWidth)")
        print("Target position: \(position)")
        
        // Validate position
        if CGFloat(position) >= numberOfItems {
            print("Error: Position \(position) exceeds number of items \(numberOfItems)")
            return
        }
        
        let tabX = CGFloat(position) * tabWidth
        let tabBarHeight = tabBarController.tabBar.bounds.height
        
        print("Tab X: \(tabX), Tab bar height: \(tabBarHeight)")
        
        // Create the frame
        let tabFrame = CGRect(
            x: tabX,
            y: 0,
            width: tabWidth,
            height: tabBarHeight
        )
        
        print("Tab frame in tab bar: \(tabFrame)")
        
        // Convert to controller's view coordinates
        let buttonFrame = tabBarController.tabBar.convert(tabFrame, to: tabBarController.view)
        
        print("Button frame in controller view: \(buttonFrame)")
        
        // Create focus view and label
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
        
        // Set the focus area
        let paddedFrame = buttonFrame.insetBy(dx: -10, dy: -10)
        print("Padded frame for focus: \(paddedFrame)")
        focusView.ovalRect = paddedFrame
        
        // Log focus view bounds
        print("Focus view initial bounds: \(focusView.bounds)")
        
        // Setup constraints with device-specific adjustments
        if UIDevice.current.userInterfaceIdiom == .pad {
            print("Using iPad constraints")
            NSLayoutConstraint.activate([
                focusView.topAnchor.constraint(equalTo: tabBarController.view.topAnchor),
                focusView.leadingAnchor.constraint(equalTo: tabBarController.view.leadingAnchor),
                focusView.trailingAnchor.constraint(equalTo: tabBarController.view.trailingAnchor),
                focusView.bottomAnchor.constraint(equalTo: tabBarController.view.bottomAnchor),
                
                instructionLabel.bottomAnchor.constraint(equalTo: tabBarController.tabBar.topAnchor, constant: -40),
                // Fix for iPad - position label properly above the correct tab
                instructionLabel.centerXAnchor.constraint(equalTo: tabBarController.view.leadingAnchor, constant: tabX + tabWidth/2),
                instructionLabel.leadingAnchor.constraint(greaterThanOrEqualTo: tabBarController.view.leadingAnchor, constant: 40),
                instructionLabel.trailingAnchor.constraint(lessThanOrEqualTo: tabBarController.view.trailingAnchor, constant: -40)
            ])
        } else {
            print("Using iPhone constraints")
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
        }
        
        // Force layout update
        tabBarController.view.layoutIfNeeded()
        
        print("Focus view after layout bounds: \(focusView.bounds)")
        print("Focus view after layout frame: \(focusView.frame)")
        
        // Animate appearance
        UIView.animate(withDuration: 0.3) {
            focusView.alpha = 1.0
            instructionLabel.alpha = 1.0
        }
        
        // Add tap gesture with proper weak references
        let tapGesture = UITapGestureRecognizer(target: nil, action: nil)
        
        tapGesture.addTarget { [weak self, weak tabBarController, weak focusView, weak instructionLabel] _ in
            guard let self = self else {
                print("Error: self is nil in tap gesture handler")
                return
            }
            
            guard let tabBarController = tabBarController, let focusView = focusView else {
                print("Error: tabBarController or focusView is nil in tap gesture handler")
                return
            }
            
            // Get tap location and convert to the proper coordinate space
            let location = tapGesture.location(in: focusView)
            print("Tap location in focus view: \(location)")
            
            // Check if tap is within highlighted area
            let isInHighlightedArea: Bool
            
            switch focusView.shapeType {
            case .circle:
                // For circle, check distance from center
                let diameter = min(paddedFrame.width, paddedFrame.height)
                let radius = diameter / 2
                let centerX = paddedFrame.midX - focusView.frame.origin.x
                let centerY = paddedFrame.midY - focusView.frame.origin.y
                
                let dx = location.x - centerX
                let dy = location.y - centerY
                let distance = sqrt(dx*dx + dy*dy)
                
                print("Circle center: (\(centerX), \(centerY)), Radius: \(radius), Distance: \(distance)")
                
                isInHighlightedArea = distance <= radius
                
            case .roundedRect:
                // Adjust for coordinate space differences
                let localPaddedFrame = CGRect(
                    x: paddedFrame.origin.x - focusView.frame.origin.x,
                    y: paddedFrame.origin.y - focusView.frame.origin.y,
                    width: paddedFrame.width,
                    height: paddedFrame.height
                )
                print("Checking if point \(location) is in rect \(localPaddedFrame)")
                isInHighlightedArea = localPaddedFrame.contains(location)
                
            default:
                print("Unknown shape type")
                isInHighlightedArea = false
            }
            
            print("Is tap in highlighted area: \(isInHighlightedArea)")
            
            if isInHighlightedArea {
                print("Tab at position \(position) selected")
                
                // Switch to tab first, then do cleanup
                tabBarController.selectedIndex = position
                
                // Animate out and clean up
                UIView.animate(withDuration: 0.3, animations: {
                    focusView.alpha = 0
                    instructionLabel?.alpha = 0
                }, completion: { _ in
                    print("Animation completed, removing focus view")
                    focusView.removeFromSuperview()
                    instructionLabel?.removeFromSuperview()
                    
                    print("Calling tabBarItemTapped() with state: \(self.onboardingState)")
                    self.tabBarItemTapped()
                })
            } else {
                print("Tap outside highlighted area - no action")
            }
        }
        
        focusView.addGestureRecognizer(tapGesture)
        print("--- End Focus Debug ---")
    }
    
    private func tabBarItemTapped() {
        if onboardingState == .switchToHabits {
            showHabitListFocus()
        } else if onboardingState == .switchToMaow {
            showMaowHealth()
        } else if onboardingState == .switchToGame {
            showGameIntroduction()
        }
    }
    
    // MARK: - Utility Functions
    func saveHabit(habitData: HabitData) {
        // save the habitData
        let habitDate = TimeFormatter.hourMinuteToDate(hour: habitData.hour ?? 9, minute: habitData.minute ?? 0)
        let newHabit = Habit(id: UUID(),
                             name: habitData.name!,
                             description: "",
                             time: habitDate!,
                             daysOfTheWeek: habitData.selectedDays!,
                             notificationEnabled: false,
                             totalDone: 0,
                             totalFailed: 0,
                             streaks: 0,
                             lastUpdateDate: Date())
        
        HabitRepository.shared.addHabit(newHabit)
    }
}
