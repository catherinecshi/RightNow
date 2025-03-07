import UIKit

class OnboardingViewController: UIViewController, OnboardingViewDelegate {
    private let onboardingView: OnboardingView
    
    private var isFirstImage = false
    private var steps = 1
    
    init() {
        self.onboardingView = OnboardingView()
        super.init(nibName: nil, bundle: nil)
        
        setupDelegates()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented yet")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        setupView()
        initialViewSetup() // since timemodel stores the user preferences for how long
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // don't execute following code if in tab bar controller already - avoid infinite loop
        guard tabBarController == nil else { return }
        
        if UserDefaults.standard.bool(forKey: "hasSeenMaowFocus") == false {
            Task {
                await startOnboardingSequence()
            }
        } else {
            Task {
                await showHabitsScreen()
            }
        }
    }
    
    private func setupView() {
        onboardingView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(onboardingView)
        
        NSLayoutConstraint.activate([
            onboardingView.topAnchor.constraint(equalTo: view.topAnchor),
            onboardingView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            onboardingView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            onboardingView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupDelegates() {
        onboardingView.delegate = self
    }
    
    func onboardingViewDidTapCharacter() {
        isFirstImage.toggle()
        onboardingView.updateCharacterState(isAsleep: isFirstImage)
    }
    
    func onboardingViewDidAdjustTime(_ minutes: Int) {
        timerModelDidUpdateTime()
    }
    
    func timerModelDidUpdateTime() {
        let minutes = TimerModel.shared.remainingSeconds / 60
        let seconds = TimerModel.shared.remainingSeconds % 60
        onboardingView.updateTimeDisplay(minutes: minutes, seconds: seconds)
    }
    
    func initialViewSetup() {
        timerModelDidUpdateTime()
    }
    
    // MARK: - Onboarding Animation
    func startOnboardingSequence() async {
        // make sure all labels are initially hidden
        onboardingView.hideAllOnboardingLabels()
        
        // 1 - say hi!
        onboardingView.animateAppearance(of: onboardingView.hiLabel)
        
        // 2 - meet maow :)
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay
        onboardingView.animateAppearance(of: onboardingView.meetMaowLabel)
        
        // 3 - happy maow!
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 2 seconds delay
        onboardingViewDidTapCharacter()
        
        try? await Task.sleep(nanoseconds: 700_000_000) // 0,7 second delay
        onboardingViewDidTapCharacter()
        
        // show button
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 second delay
        onboardingView.showResponseButton(title: "Hi Maow!")
    }
    
    func secondOnboardingSequence() async {
        // 4 - introduce maow
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay
        onboardingView.animateDisappearance(of: onboardingView.hiLabel)
        onboardingView.animateDisappearance(of: onboardingView.meetMaowLabel)
        
        try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 second delay
        onboardingView.animateAppearance(of: onboardingView.maowDescriptionLabel)
        
        try? await Task.sleep(nanoseconds: 2_000_000_000) // 1 second delay
        onboardingView.animateAppearance(of: onboardingView.descriptionPSLabel)
        
        // show button
        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 second delay
        onboardingView.showResponseButton(title: "Oh...")
    }
    
    func thirdOnboardingSequence() async {
        // 5 - explain previous circumstances
        try? await Task.sleep(nanoseconds: 1_000_000) // 1 second delay
        onboardingView.animateDisappearance(of: onboardingView.maowDescriptionLabel)
        onboardingView.animateDisappearance(of: onboardingView.descriptionPSLabel)
        
        try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 second delay
        onboardingView.animateAppearance(of: onboardingView.lastOwnerLabel)
        
        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 second delay
        onboardingView.animateAppearance(of: onboardingView.neglectLabel)
        
        try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 second delay
        onboardingView.showResponseButton(title: "I would never do that!")
    }
    
    func fourthOnboardingSequence() async {
        try? await Task.sleep(nanoseconds: 1_000_000) // 1 second delay
        onboardingView.animateDisappearance(of: onboardingView.lastOwnerLabel)
        onboardingView.animateDisappearance(of: onboardingView.neglectLabel)
        
        try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 second delay
        onboardingView.animateAppearance(of: onboardingView.tauntLabel)
        
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay
        onboardingView.animateAppearance(of: onboardingView.keepUpLabel)
        
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay
        onboardingView.showResponseButton(title: "...")
    }
    
    func fifthOnboardingSequence() async {
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay
        onboardingView.animateDisappearance(of: onboardingView.tauntLabel)
        onboardingView.animateDisappearance(of: onboardingView.keepUpLabel)
        
        try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 second delay
        onboardingView.animateAppearance(of: onboardingView.newOwnerLabel)
        
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay
        onboardingView.showResponseButton(title: "How can I do that?")
    }
    
    func showHabitsScreen() async {
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay
        onboardingView.animateDisappearance(of: onboardingView.newOwnerLabel)
        
        // transition into the tab bar controller
        let tabBarController = OnboardingTabBarController()
        
        // replace root view controller
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            await MainActor.run {
                window.rootViewController = tabBarController
                tabBarController.selectedIndex = 0
                window.makeKeyAndVisible()
            }
            
            // animate
            tabBarController.view.alpha = 0
            
            UIView.animate(withDuration: 0.3) {
                tabBarController.view.alpha = 1
            }
            
            // wait for formatting
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            
            // create and show focus view on tab Bar
            await focusOnHabitsTabBarItem(in: tabBarController)
        }
    }
    
    // calculates position of second tab based on tab bar width and number of items
    @MainActor
    private func focusOnHabitsTabBarItem(in tabBarController: OnboardingTabBarController) async {
        // Make sure we have at least 2 tab items
        guard tabBarController.tabBar.items?.count ?? 0 >= 2 else {
            print("Not enough tab items")
            return
        }
        
        // Calculate the frame of the second tab item based on the tab bar's width
        let tabBarWidth = tabBarController.tabBar.bounds.width
        let numberOfItems = CGFloat(tabBarController.tabBar.items?.count ?? 0)
        let tabWidth = tabBarWidth / numberOfItems
        
        // The second tab should be at index 1, so its x position starts at 1 * tabWidth
        let secondTabX = tabWidth
        let tabBarHeight = tabBarController.tabBar.bounds.height
        
        // Create a frame for the second tab item
        let secondTabFrame = CGRect(
            x: secondTabX,
            y: 0,
            width: tabWidth,
            height: tabBarHeight
        )
        
        // Convert this frame to the tab bar controller's view coordinates
        let buttonFrame = tabBarController.tabBar.convert(secondTabFrame, to: tabBarController.view)
        
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
        instructionLabel.text = "Tap here to manage your habits!"
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
        
        // Save flag that user has seen this
        UserDefaults.standard.set(true, forKey: "hasSeenMaowFocus")
        
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
                tabBarController.selectedIndex = 1
                
                // Animate out the focus view and instruction label
                UIView.animate(withDuration: 0.3, animations: {
                    focusView?.alpha = 0
                    instructionLabel?.alpha = 0
                }, completion: { _ in
                    focusView?.removeFromSuperview()
                    instructionLabel?.removeFromSuperview()
                })
            }
        }
        
        focusView.addGestureRecognizer(tapGesture)
    }
    
    // MARK: - Onboarding Responses
    func onboardingViewDidTapResponseButton() {
        onboardingView.hideResponseButton()
        steps += 1
        
        if steps == 2 {
            Task {
                await secondOnboardingSequence()
            }
        } else if steps == 3 {
            Task {
                await thirdOnboardingSequence()
            }
        } else if steps == 4 {
            Task {
                await fourthOnboardingSequence()
            }
        } else if steps == 5 {
            Task {
                await fifthOnboardingSequence()
            }
        } else if steps == 6 {
            Task {
                await showHabitsScreen()
            }
        }
    }
}

// Extension to make it easier to use closures with gesture recognizers
extension UIGestureRecognizer {
    func addTarget(closure: @escaping (UIGestureRecognizer) -> Void) {
        self.addTarget(ClosureGestureHandler.shared, action: #selector(ClosureGestureHandler.handle(gesture:)))
        ClosureGestureHandler.shared.add(closure, for: self)
    }
}

// Singleton to handle gesture recognizer closures
class ClosureGestureHandler: NSObject {
    static let shared = ClosureGestureHandler()
    private var closures = [ObjectIdentifier: (UIGestureRecognizer) -> Void]()
    
    func add(_ closure: @escaping (UIGestureRecognizer) -> Void, for gesture: UIGestureRecognizer) {
        let id = ObjectIdentifier(gesture)
        closures[id] = closure
    }
    
    @objc func handle(gesture: UIGestureRecognizer) {
        let id = ObjectIdentifier(gesture)
        if let closure = closures[id] {
            closure(gesture)
        }
    }
    
    func remove(for gesture: UIGestureRecognizer) {
        let id = ObjectIdentifier(gesture)
        closures.removeValue(forKey: id)
    }
}
