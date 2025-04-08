import UIKit

/// takes user through multi step onboarding process
class OnboardingViewController: UIViewController, OnboardingViewDelegate {
    private let onboardingView: OnboardingView
    weak var coordinator: OnboardingCoordinator?
    
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
        onboardingView.updateCharacterState(isHappy: isFirstImage)
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
        onboardingView.showResponseButton(title: "What? Why would they do that?")
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
        
        try? await Task.sleep(nanoseconds: 1_500_000_000) // 1 second delay
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
    
    /// switch to habit list view controller
    func showHabitsScreen() async {
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay
        onboardingView.animateDisappearance(of: onboardingView.newOwnerLabel)
        
        await coordinator?.showHabitsScreen()
    }
    
    // MARK: - Onboarding Responses
    func onboardingViewDidTapResponseButton() {
        onboardingView.hideResponseButton()
        steps += 1
        print(steps)
        
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
    
    // MARK: - Onboarding Pt 2
    func sixthOnboardingSequence() async {
        onboardingView.showFocusView(withInstructions: "Maow's health depends on whether you finish your habits on time")
        
        await withCheckedContinuation { continuation in
            onboardingView.startEmojiTransitionSequence {
                // stop focus vew
                self.onboardingView.hideFocusView()
                
                continuation.resume()
            }
        }
        
        await showTimer()
    }
    
    /// animate appearance of timer and coupons
    private func showTimer() async {
        onboardingView.showTimer()
        onboardingView.showCoupons()
        
        try? await Task.sleep(nanoseconds: 500_000_000)
        onboardingView.showFocusViewCoupons(withInstructions: "Maow will also give you coupons if you lock your phone away and spend time with her")
        
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        onboardingView.hideFocusView()
        
        try? await Task.sleep(nanoseconds: 200_000_000)
        await showGameScreen()
    }
    
    /// switch to central game view controller
    private func showGameScreen() async {
        coordinator?.switchToGame()
    }
}
