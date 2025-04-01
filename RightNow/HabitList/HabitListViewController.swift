import UIKit
import Combine
import UserNotifications
import LocalAuthentication

class HabitListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    // to section off different levels
    struct LevelSection {
        let header: String
        let rows: [Habit]
    }
    
    let habitListView = HabitListView(frame: UIScreen.main.bounds)
    let viewModel = HabitListViewModel()
    private var cancellables = Set<AnyCancellable>()
    var sections = [LevelSection]()
    
    // for onboarding
    private var isDeletionOnboardingActive = false
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
    
    override func loadView() {
        self.view = habitListView
        
        // setup delegates
        habitListView.tableView.delegate = self
        habitListView.tableView.dataSource = self
    }
    
    // MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupSubscriptions() // setup combine subscriptions
        
        habitListView.tableView.reloadData()
        habitListView.tableView.register(HabitCell.self, forCellReuseIdentifier: "HabitCell")
        habitListView.tableView.allowsSelectionDuringEditing = true //capable of editing mode
        
        setupAddButton()
        setupSwipes()
        
        self.definesPresentationContext = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
        
        updateSections()
        habitListView.tableView.reloadData()
        habitsPresent()
        updateTitle()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // hide navigation bar when leaving this view
        // this ensures other views in the navigation stack have a navigation bar
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // adjust bottom constraint for add button to account for tab bar
        if let existingConstraint = addButton.constraints.first(where: { $0.firstAttribute == .bottom }) {
            existingConstraint.constant = -(view.safeAreaInsets.bottom + 20)
        }
    }
    
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
    
    func updateSections() {
        let groupedHabits = Dictionary(grouping: viewModel.habitsForCurrentDay, by: { $0.currentLevel.displayName })
        
        // sort by order cases are established in Level enum
        sections = groupedHabits.map { key, value in
            return LevelSection(header: key, rows: value)
        }.sorted(by: { Level.allCases.firstIndex(of: Level(rawValue: $0.header.lowercased())!)! < Level.allCases.firstIndex(of: Level(rawValue: $1.header.lowercased())!)! })
    }
    
    func updateTitle() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy/MM/dd"
        let formattedDate = dateFormatter.string(from: viewModel.currentDay)
        let dayOfWeek = TimeFormatter.weekdayToString(viewModel.currentDay)
        habitListView.titleLabel.text = "\(formattedDate) - \(dayOfWeek)"
    }
    
    // MARK: - Swipe Methods
    
    func setupSwipes() {
        let leftSwipe = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipes(_:)))
        let rightSwipe = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipes(_:)))
        
        leftSwipe.direction = .left
        rightSwipe.direction = .right
        
        view.addGestureRecognizer(leftSwipe)
        view.addGestureRecognizer(rightSwipe)
    }
    
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
    
    func applyPushAnimation(from direction: UISwipeGestureRecognizer.Direction) {
        let transition = CATransition()
        transition.duration = 0.3
        transition.type = CATransitionType.push
        transition.subtype = direction == .left ? CATransitionSubtype.fromRight : CATransitionSubtype.fromLeft
        transition.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        habitListView.tableView.layer.add(transition, forKey: "transition")
    }
    
    // MARK: - Communicate with Model
    func completeHabit(for habit: inout Habit) async {
        await isHabitDone(for: &habit)
        
        // reload table ot update button state
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.habitListView.tableView.reloadData()
        }
    }
    
    // MARK: - Creation Button Methods
    
    var addButton: UIButton!
    
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
    // checks if the habit has already been done for that day
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
    // MARK: - TableView
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section].header
    }
    
    // this is for making the right number of rows
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].rows.count
        //return viewModel.habitsForCurrentDay.count
    }
    
    // this is for calling cell view
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "HabitCell", for: indexPath) as? HabitCell else {
            // return a basic cell as fallback to avoid crashes
            return UITableViewCell(style: .default, reuseIdentifier: "FallbackCell")
        }
        
        let habit = sections[indexPath.section].rows[indexPath.row]
        cell.configure(with: habit)
        
        return cell
    }
    
    // indicates that all rows are editable
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    // specify editing style for a particular row
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }
    
    // for swipe from right to left -> deletion
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
    
    // MARK: - Onboarding Pt 2
    
    class InteractionBlockerView: UIView {
        var cutoutRect: CGRect = .zero
        
        override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
            // Return false for points inside the cutout (passing touch through)
            // Return true for points outside the cutout (capturing the touch)
            return !cutoutRect.contains(point)
        }
    }
    
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
