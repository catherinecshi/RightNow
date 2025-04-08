import UIKit
import Combine
import UserNotifications
import LocalAuthentication

/// Displays list of habits organised by their level
///
/// ## Features
/// - organize habits by levels and time
/// - navigation between days
/// - completion of habits
/// - CRUD operations with model
/// - onboarding for new users
/// - error conditions
class HabitListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    /// to section off habits with different levels
    struct LevelSection {
        let header: String
        let rows: [Habit]
    }
    
    // MARK: - Properties
    
    let habitListView = HabitListView(frame: UIScreen.main.bounds)
    let viewModel = HabitListViewModel()
    private var cancellables = Set<AnyCancellable>()
    let errorOccurred = PassthroughSubject<DataServiceError, Never>() // publisher that emits data service errors
    weak var sceneDelegate: SceneDelegate?
    let appState: AppState = .shared
    
    var sections = [LevelSection]()
    
    // for onboarding
    private var isDeletionOnboardingActive = false // whether deletion step of onboarding is currently active
    private var interactionBlocker: UIView?
    weak var coordinator: OnboardingCoordinator?
    
    private lazy var focusView: FocusView = {
        let view = FocusView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true
        view.alpha = 0.0
        return view
    }()
    
    private lazy var onboardingLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 20, weight: .medium)
        label.textColor = .white
        label.textAlignment = .center
        label.numberOfLines = 0
        label.text = "Tap here to create your first habit!"
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isHidden = true
        label.alpha = 0.0
        return label
    }()
    
    private lazy var deletionLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 20, weight: .medium)
        label.textColor = .white
        label.textAlignment = .center
        label.numberOfLines = 0
        label.text = "You can delete your habits by swiping left"
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isHidden = true
        label.alpha = 0.0
        return label
    }()
    
    // MARK: - Lifecycle Methods
    
    /// Sets up view hierarchy by assigning view & configuring delegates
    override func loadView() {
        self.view = habitListView
        
        // setup delegates
        habitListView.tableView.delegate = self
        habitListView.tableView.dataSource = self
    }
    
    /// configures subscriptions, registers cell types, and sets up UI
    override func viewDidLoad() {
        super.viewDidLoad()
        self.sceneDelegate = getSceneDelegate()
        
        setupSubscriptions() // setup combine subscriptions
        
        habitListView.tableView.reloadData()
        habitListView.tableView.register(HabitCell.self, forCellReuseIdentifier: "HabitCell")
        habitListView.tableView.allowsSelectionDuringEditing = true //capable of editing mode
        
        setupAddButton()
        setupSwipes()
        
        self.definesPresentationContext = true
    }
    
    /// Updates UI when view is about to appear
    /// This makes sure UI is updated after data has been loaded
    /// Hides navigation bar, updates sections, refreshes table view
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
        
        updateSections()
        habitListView.tableView.reloadData()
        habitsPresent()
        updateTitle()
    }
    
    /// Handles navigation bar visibility when view is able to disappear
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // hide navigation bar when leaving this view
        // this ensures other views in the navigation stack have a navigation bar
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    /// Adjusts add button constraints based on safe area insets after layout
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // adjust bottom constraint for add button to account for tab bar
        if let existingConstraint = addButton.constraints.first(where: { $0.firstAttribute == .bottom }) {
            existingConstraint.constant = -(view.safeAreaInsets.bottom + 20)
        }
    }
    
    // MARK: - Private Helpers
    
    /// Returns scene delegate from current window scene if available, nil otherwise
    private func getSceneDelegate() -> SceneDelegate? {
        guard let windowScene = self.view.window?.windowScene,
              let sceneDelegate = windowScene.delegate as? SceneDelegate else {
            return nil
        }
        return sceneDelegate
    }
    
    /// Handles changes from habit model based on type of change
    /// - Parameter changeType: the type of change that occurred
    private func handleModelChange(_ changedType: HabitRepository.HabitChangeType) {
        switch changedType {
        case .levelChanged(let habitId, let oldLevel, let newLevel):
            // find the habit
            for section in self.sections {
                if let habit = section.rows.first(where: { $0.id == habitId }) {
                    let alert = CustomAlertViewController(
                        title: "Congratulations!",
                        message: "Your habit to \(habit.name) has just leveled up from a \(oldLevel) to \(newLevel) level!"
                    )
                    
                    self.present(alert, animated: true)
                    break
                }
            }
        case .streakChanged(let habitId, let newStreak):
            // handle streak changes
            break
        case .habitCRUD:
            self.updateSections()
            self.habitListView.tableView.reloadData()
            self.habitsPresent()
            self.updateTitle()
        }
    }
    
    /// Sets up combine subscriptions to react to habit changes
    private func setupSubscriptions() {
        // subscribe to habit changes
        viewModel.habitChangePublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] changeType in
                guard let self = self else { return }
                
                switch changeType {
                case .levelChanged(let habitId, let oldLevel, let newLevel):
                    // find habit
                    for section in self.sections {
                        if let habit = section.rows.first(where: { $0.id == habitId }) {
                            let alert = CustomAlertViewController(
                                title: "Congratulations!",
                                message: "Your habit to \(habit.name) has just leveled up from \(oldLevel) to \(newLevel)"
                            )
                            
                            self.present(alert, animated: true)
                            break
                        }
                    }
                case .streakChanged:
                    // handle streak changes
                    break
                case .habitCRUD:
                    self.updateSections()
                    self.habitListView.tableView.reloadData()
                    self.habitsPresent()
                    self.updateTitle()
                }
            }
            .store(in: &cancellables)
    }
    
    /// displays message when no habits are available for current displayed day
    func habitsPresent() {
        if viewModel.habitsForCurrentDay.isEmpty {
            let emptyLabel = UILabel(frame: CGRect(x: 0, y: 0, width: self.view.bounds.size.width, height: self.view.bounds.size.height))
            emptyLabel.text = "No habits yet!"
            emptyLabel.textAlignment = .center
            emptyLabel.font = UIFont.systemFont(ofSize: 20)
            emptyLabel.textColor = .gray
            
            habitListView.tableView.backgroundView = emptyLabel
        } else {
            habitListView.tableView.backgroundView = nil
        }
    }
    
    /// Updates section array by grouping habits by their level
    func updateSections() {
        let groupedHabits = Dictionary(grouping: viewModel.habitsForCurrentDay, by: { $0.currentLevel.displayName })
        
        // sort by order cases are established in Level enum
        sections = groupedHabits.map { key, value in
            return LevelSection(header: key, rows: value)
        }.sorted(by: { Level.allCases.firstIndex(of: Level(rawValue: $0.header.lowercased())!)! < Level.allCases.firstIndex(of: Level(rawValue: $1.header.lowercased())!)! })
    }
    
    /// updates title label with current date and day of week
    func updateTitle() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy/MM/dd"
        let formattedDate = dateFormatter.string(from: viewModel.currentDay)
        let dayOfWeek = TimeFormatter.weekdayToString(viewModel.currentDay)
        habitListView.titleLabel.text = "\(formattedDate) - \(dayOfWeek)"
    }
    
    // MARK: - Swipe Methods
    
    /// Sets up swipe gesture recognizers for navigating between days
    func setupSwipes() {
        let leftSwipe = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipes(_:)))
        let rightSwipe = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipes(_:)))
        
        leftSwipe.direction = .left
        rightSwipe.direction = .right
        
        view.addGestureRecognizer(leftSwipe)
        view.addGestureRecognizer(rightSwipe)
    }
    
    /// Handles gesture to navigate between days
    /// - Parameter sender: The swipe gesture recognizer that triggered it
    @objc func handleSwipes(_ sender: UISwipeGestureRecognizer) {
        // handle swipe
        applyPushAnimation(from: sender.direction)
        viewModel.handleSwipe(direction: sender.direction)
        
        // update
        updateSections()
        habitListView.tableView.reloadData()
        habitsPresent()
        updateTitle()
    }
    
    /// applies push animation to table view when swiping
    /// - Parameter direction: direction of swipe gesture
    func applyPushAnimation(from direction: UISwipeGestureRecognizer.Direction) {
        let transition = CATransition()
        transition.duration = 0.3
        transition.type = CATransitionType.push
        transition.subtype = direction == .left ? CATransitionSubtype.fromRight : CATransitionSubtype.fromLeft
        transition.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        habitListView.tableView.layer.add(transition, forKey: "transition")
    }
    
    // MARK: - Communicate with Model
    
    /// Completes habit for current day if conditions are met
    /// - Parameter habit: the habit to mark as completed
    func completeHabit(for habit: inout Habit) async {
        await isHabitDone(for: &habit)
        
        // reload table ot update button state
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.habitListView.tableView.reloadData()
        }
    }
    
    // MARK: - Creation Button Methods
    
    var addButton: UIButton!
    
    /// creates and configures add button for creating new habits
    func setupAddButton() {
        let size: CGFloat = 80
        
        addButton = UIButton(frame: CGRect(x: 0, y: 0, width: size, height: size))
        addButton.backgroundColor = UIConfiguration.tintColor
        addButton.layer.cornerRadius = size / 2
        addButton.translatesAutoresizingMaskIntoConstraints = false
        
        // add a plus sign
        addButton.setTitle("+", for: .normal)
        addButton.setTitleColor(.white, for: .normal)
        addButton.titleLabel?.font = UIFont.systemFont(ofSize: (size / 2), weight: .bold)
        
        // add action for button
        addButton.addTarget(self, action: #selector(addHabitTapped), for: .touchUpInside)
        
        // add to view
        view.addSubview(addButton)
        
        NSLayoutConstraint.activate([
            addButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            addButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            addButton.widthAnchor.constraint(equalToConstant: size),
            addButton.heightAnchor.constraint(equalToConstant: size)
        ])
    }
    
    /// Presents habit creation flow after tap on add button
    ///
    /// if normal -> just show first VC in creation flow
    /// if onboarding -> call coordinator method
    ///
    /// - Parameter isOnboarding: flag indicating whether onboarding right now
    @objc func addHabitTapped(isOnboarding: Bool = false) {
        hideOnboardingFocus()
        
        if let coordinator = coordinator { // currently onboarding if there is a coordinator
            coordinator.showHabitCreation()
        } else {
            let creationVC = SelectHabitViewController()
            
            let navController = UINavigationController(rootViewController: creationVC)
            navController.modalPresentationStyle = .pageSheet
            present(navController, animated: true, completion: nil)
        }
    }
    
    // MARK: - Alert Methods
    
    /// checks if the habit has already been done for that day
    /// presents appropriate alert depending on completion status and date
    /// - Parameter habit: habit to check and potentially complete
    func isHabitDone(for habit: inout Habit) async {
        if viewModel.isCurrentDayToday() {
            if viewModel.isHabitCompletedForDay(habit) {
                let alertController = CustomAlertViewController(title: "Habit already completed!", message: "You've already \(habit.name) today!")
                
                present(alertController, animated: true, completion: nil)
            } else {
                await viewModel.habitCompleted(&habit)
            }
        } else {
            let currentDayString = TimeFormatter.weekdayToString(viewModel.currentDay)
            let alertController = CustomAlertViewController(title: "Habit not for today", message: "You don't have to \(habit.name) on \(currentDayString)!")
            
            present(alertController, animated: true, completion: nil)
        }
    }
    
    // MARK: - TableView DataSource & Delegate
    
    /// Returns number of sections in the table view
    /// - Parameter tableView: the table view requesting this information
    /// - Returns: number of sections (level groups)
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    /// Returns title for section header in table view
    /// - Parameters:
    ///     - tableView: the table view requesting the information
    ///     - section: the index of the section
    /// - Returns: title for section header
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section].header
    }
    
    /// Returns the number of rows in a section
    /// - Parameters:
    ///     - tableView: the tableview requesting the information
    ///     - section: index of the section
    /// - Returns: the number of habits in the section
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].rows.count
    }
    
    /// Configures and returns habit cell for a given index path
    /// - Parameters:
    ///     - tableView: table view requesting the cell
    ///     - indexPath: index path of cell
    /// - Returns: a configured UITableViewCell
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "HabitCell", for: indexPath) as? HabitCell else {
            // return a basic cell as fallback to avoid crashes
            return UITableViewCell(style: .default, reuseIdentifier: "FallbackCell")
        }
        
        let habit = sections[indexPath.section].rows[indexPath.row]
        cell.configure(with: habit)
        
        return cell
    }
    
    /// Returns true for everything - all rows can be edited
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    /// returns editing style for the row
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }
    
    /// configures swipes from right to left -> deletion
    /// - Parameters:
    ///     - tableView: the table view requesting the information
    ///     - indexPath: index path of the row
    /// - Returns: configuration object containing swipe actions
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { (action, view, completionHandler) in
            // fetch habit to delete
            let habitToDelete = self.sections[indexPath.section].rows[indexPath.row]
            
            // delete habit from firestore + locally, also delete notification
            Task {
                await self.viewModel.deleteHabit(habitToDelete)
                
                // ensures the check for no habits left happens after deletion finishes
                DispatchQueue.main.async {
                    if self.sections.isEmpty {
                        self.habitsPresent()
                    }
                }
            }
            
            // remove from local sections data
            var updatedSectionRows = self.sections[indexPath.section].rows
            updatedSectionRows.remove(at: indexPath.row)
            
            // remove the entire section if this was the last row in a section
            if updatedSectionRows.isEmpty {
                self.sections.remove(at: indexPath.section)
                tableView.deleteSections(IndexSet(integer: indexPath.section), with: .automatic)
            } else {
                self.sections[indexPath.section] = LevelSection(header: self.sections[indexPath.section].header, rows: updatedSectionRows)
                tableView.deleteRows(at: [indexPath], with: .automatic)
            }
            
            // check if there are still habits
            self.habitsPresent()
            
            // check if onboarding
            if self.isDeletionOnboardingActive {
                self.backToMaow()
            }
            
            completionHandler(true)
        }
        
        // create swipe action config
        let configuration = UISwipeActionsConfiguration(actions: [deleteAction])
        return configuration
    }
}

// MARK: - Onboarding
extension HabitListViewController {
    
    /// sets up focus view and label at the top of view hierarchy
    func setupOnboarding() {
        // this makes sure that the focusview is added on top of everything, including the tab bar controller, because there were issues where only putting on top of the current view controller creates additional tab bar controller that causes crashes if tapped on when focus view was up
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootViewController = window.rootViewController else {
            return
        }
        
        // Get the appropriate container view (should be the tab bar controller)
        let containerView = rootViewController.view!
        
        // Clean up any existing focus views (to prevent duplicates)
        containerView.subviews.forEach { subview in
            if subview is FocusView {
                subview.removeFromSuperview()
            }
        }
        
        containerView.addSubview(focusView)
        containerView.addSubview(onboardingLabel)
        
        NSLayoutConstraint.activate([
            focusView.topAnchor.constraint(equalTo: view.topAnchor),
            focusView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            focusView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            focusView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // position label above add button
            onboardingLabel.bottomAnchor.constraint(equalTo: addButton.topAnchor, constant: -20),
            onboardingLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            onboardingLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            onboardingLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40)
        ])
    }
    
    /// shows onboarding focus view highlighting add button
    /// configures tap gesture to allow user to interact with add button
    func showOnboardingFocus() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootViewController = window.rootViewController else {
            return
        }
        
        let containerView = rootViewController.view!
        
        containerView.bringSubviewToFront(focusView)
        containerView.bringSubviewToFront(onboardingLabel)
        //containerView.bringSubviewToFront(addButton)
        
        // make focus oval around add button
        let convertedButtonFrame = view.convert(addButton.frame, to: containerView)
        focusView.shapeType = .circle
        
        let paddedFrame = addButton.frame.insetBy(dx: -20, dy: -20)
        focusView.ovalRect = paddedFrame
        
        focusView.isHidden = false
        onboardingLabel.isHidden = false
        
        UIView.animate(withDuration: 0.3) {
            self.focusView.alpha = 1.0
            self.onboardingLabel.alpha = 1.0
        }
        
        // add tap gesture recogniser to the focus view - makes sure user can only tap within focus view highlight
        let tapGesture = UITapGestureRecognizer()
        
        tapGesture.addTarget { [weak self, weak focusView] gesture in
            guard let self = self, let focusView = focusView else { return }
            
            // Get the tap location
            let location = gesture.location(in: focusView)
            
            // Check if the tap is within the highlighted area
            let isInHighlightedArea: Bool
            
            switch focusView.shapeType {
            case .circle:
                // For circle, check if distance from center is less than radius
                let diameter = min(paddedFrame.width, paddedFrame.height)
                let radius = diameter / 2
                let centerX = paddedFrame.midX
                let centerY = paddedFrame.midY
                
                let dx = location.x - centerX
                let dy = location.y - centerY
                let distance = sqrt(dx*dx + dy*dy)
                
                isInHighlightedArea = distance <= radius
                
            case .roundedRect(let cornerRadius):
                // For rounded rect, check if point is inside the rect
                isInHighlightedArea = paddedFrame.contains(location)
            }
            
            // Only trigger the button tap if the gesture is within the highlight area
            if isInHighlightedArea {
                Task {
                    await InteractionBlocker.shared.unblockInteractions()
                }
                addHabitTapped(isOnboarding: true)
            }
        }
        
        focusView.addGestureRecognizer(tapGesture)
    }
    
    /// hides focus view and label and removes gesture recognizers
    func hideOnboardingFocus() {
        UIView.animate(withDuration: 0.3, animations: {
            self.focusView.alpha = 0.0
            self.onboardingLabel.alpha = 0.0
        }, completion: { _ in
            self.focusView.isHidden = true
            self.onboardingLabel.isHidden = true
            
            // remove gesture recognizers when hiding
            if let existingGestures = self.focusView.gestureRecognizers {
                for gesture in existingGestures {
                    self.focusView.removeGestureRecognizer(gesture)
                }
            }
        })
    }
    
    // MARK: - Onboarding Pt 2 (deletion)
    
    /// view that blocks interaction except for specified cutout
    class InteractionBlockerView: UIView {
        var cutoutRect: CGRect = .zero
        
        /// Determines whether a touch should be handled by view
        /// - Parameters:
        ///     - point: the point to test
        ///     - event: the event contaning the touch
        /// - Returns true if touch should be handled
        override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
            // Return false for points inside the cutout (passing touch through)
            // Return true for points outside the cutout (capturing the touch)
            return !cutoutRect.contains(point)
        }
    }
    
    /// shows focus view on first habit cell and displays label
    func showDeletion() async {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootViewController = window.rootViewController else {
            return
        }
        
        updateSections()
        
        let containerView = rootViewController.view!
        
        // check if there are any habit sin the table view
        guard !sections.isEmpty && !sections[0].rows.isEmpty else {
            return
        }
        
        isDeletionOnboardingActive = true
        
        // index path for first cell
        let firstCellIndexPath = IndexPath(row: 0, section: 0)
        
        // make sure table view is loaded and first cell is visible
        habitListView.tableView.scrollToRow(at: firstCellIndexPath, at: .top, animated: false)
        
        // makes sure everything is rendered
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // get first cell
        guard let firstCell = habitListView.tableView.cellForRow(at: firstCellIndexPath) else { return }
        
        focusView.shapeType = .roundedRect(cornerRadius: 12)
        
        // convert frame to coords
        let cellFrame = firstCell.convert(firstCell.bounds, to: containerView)
        let paddedCellFrame = cellFrame.insetBy(dx: -4, dy: -4)
        focusView.ovalRect = paddedCellFrame
        
        focusView.isUserInteractionEnabled = false // taps to interactionblocker will go past focusview
        
        // makes sure that the highlighted part is interactable
        let blocker = InteractionBlockerView(frame: window.bounds)
        blocker.cutoutRect = paddedCellFrame
        blocker.backgroundColor = .clear
        interactionBlocker = blocker
        
        containerView.addSubview(focusView)
        containerView.addSubview(deletionLabel)
        containerView.addSubview(blocker)
        
        // add label to window
        deletionLabel.isUserInteractionEnabled = false
        
        // position label
        NSLayoutConstraint.activate([
            deletionLabel.topAnchor.constraint(equalTo: window.safeAreaLayoutGuide.topAnchor, constant: cellFrame.maxY + 20),
            deletionLabel.centerXAnchor.constraint(equalTo: window.centerXAnchor),
            deletionLabel.leadingAnchor.constraint(equalTo: window.leadingAnchor, constant: 20),
            deletionLabel.trailingAnchor.constraint(equalTo: window.trailingAnchor, constant: -20)
        ])
        
        // animate appearance
        deletionLabel.alpha = 0.0
        deletionLabel.isHidden = false
        focusView.alpha = 0.0
        focusView.isHidden = false
        
        UIView.animate(withDuration: 0.3) {
            self.deletionLabel.alpha = 1.0
            self.focusView.alpha = 1.0
        }
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(blockerTapped(_:)))
        focusView.addGestureRecognizer(tapGesture)
    }
    
    /// handles tap on blocker view during deletion onboarding step
    /// provides visual feedback to guide the user
    /// - Parameter gesture: the tap gesture recognizer
    @objc func blockerTapped(_ gesture: UITapGestureRecognizer) {
        // Provide feedback that the user should interact with the highlighted cell
        UIView.animate(withDuration: 0.2, animations: {
            self.focusView.alpha = 0.7
        }, completion: { _ in
            UIView.animate(withDuration: 0.2) {
                self.focusView.alpha = 1.0
            }
        })
        
        // animate the deletion label to provide a hint
        UIView.animate(withDuration: 0.5, animations: {
            self.deletionLabel.transform = CGAffineTransform(translationX: -30, y: 0)
        }, completion: { _ in
            UIView.animate(withDuration: 0.5) {
                self.deletionLabel.transform = .identity
            }
        })
    }
    
    /// completes deletion onboarding and transitions back to maow view via coordinator
    private func backToMaow() {
        isDeletionOnboardingActive = false
        
        //disappear
        UIView.animate(withDuration: 0.3, animations: {
            self.focusView.alpha = 0.0
            self.deletionLabel.alpha = 0.0
        }, completion: { _ in
            self.focusView.isHidden = true
            self.focusView.removeFromSuperview()
            self.deletionLabel.isHidden = true
            self.deletionLabel.removeFromSuperview()
            self.interactionBlocker?.removeFromSuperview()
            self.interactionBlocker = nil
        })
        
        Task {
            try? await Task.sleep(nanoseconds: 500_000_000)
        }
        
        // let's go back to maow!
        guard let coordinator = coordinator else { return }
        coordinator.switchToMaow()
    }
}

// MARK: - Error Handling
extension HabitListViewController {
    
    /// Sets up subscriptions to handle errors from repository
    func setupErrorHandling() {
        HabitRepository.shared.errorPublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] error in
                self?.showError(error)
            }
            .store(in: &cancellables)
    }
    
    /// shows appropriate response based on the type of error
    /// - Parameter error: the data service error to handle
    private func showError(_ error: DataServiceError) {
        switch error {
        case .authenticationRequired:
            navigateToWelcome()
        default:
            print(error.localizedDescription)
        }
    }
    
    /// Handles navigation for sending the user to initial welcome view
    /// Uses custom transition to present WelcomeViewController
    /// Removes current view from root view controller
    private func navigateToWelcome() {
        if let sceneDelegate = self.sceneDelegate, let window = sceneDelegate.window {
            let welcomeVC = WelcomeViewController(state: appState)
            
            // Create a navigation controller with the sign-in VC as the root
            let navigationController = UINavigationController(rootViewController: welcomeVC)
            
            // Create a transition animation
            let transition = CATransition()
            transition.duration = 0.3
            transition.type = CATransitionType.push
            transition.subtype = CATransitionSubtype.fromLeft
            transition.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
            
            // Set the window's root view controller to the navigation controller
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                window.layer.add(transition, forKey: nil)
                window.rootViewController = navigationController
            }
        }
    }
}
