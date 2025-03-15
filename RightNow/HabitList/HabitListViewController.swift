import UIKit
import Combine
import UserNotifications
import LocalAuthentication

class HabitListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, SelectHabitViewControllerDelegate, SelectTimeDelegate {
    
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
    
    // MARK: Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupSubscriptions() // setup combine subscriptions
        
        print("viewDidLoad - Direct check of habits:")
            viewModel.habitsForCurrentDay.forEach { habit in
                print("Habit: \(habit.name), Level: \(habit.currentLevel.displayName)")
            }
        
        // receives callback
        viewModel.addObserver { [weak self] changedType in
            switch changedType {
            case .levelChanged(let habitId, let oldLevel, let newLevel):
                // find the habit
                for section in self?.sections ?? [] {
                    if let habit = section.rows.first(where: { $0.id == habitId }) {
                        let alert = CustomAlertViewController(
                            title: "Congratulations!",
                            message: "Your habit to \(habit.name) has just leveled up from a \(oldLevel) to \(newLevel) level!"
                        )
                        
                        self?.present(alert, animated: true)
                        break
                    }
                }
            case .streakChanged(let habitId, let newStreak):
                // handle streak changes
                break
            case .habitCRUD:
                self?.updateSections()
                self?.habitListView.tableView.reloadData()
                self?.habitsPresent()
                self?.updateTitle()
            }
        }
        
        habitListView.tableView.reloadData()
        habitListView.tableView.register(HabitTableViewCell.self, forCellReuseIdentifier: "HabitCell")
        habitListView.tableView.allowsSelectionDuringEditing = true //capable of editing mode
        
        setupAddButton()
        setupSwipes()
        
        self.definesPresentationContext = true
        
        // checks through location permissions
        //isLocationPermissionDenied()
        
        //addDebugButton()
        
        Task {
            await determineCurrentTabBarController()
        }
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
            //habitListView.tableView.separatorStyle = .none
        } else {
            habitListView.tableView.backgroundView = nil
            //habitListView.tableView.separatorStyle = .none
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
    
    // MARK: Swipe Methods
    
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
    
    // MARK: Creation Button Methods
    
    var addButton: UIButton!
    
    func setupAddButton() {
        let size: CGFloat = 80
        
        addButton = UIButton(frame: CGRect(x: 0, y: 0, width: size, height: size))
        addButton.backgroundColor = UIColor(hexString: "#ff5a66")
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
        
        let creationVC = SelectHabitViewController()
        creationVC.delegate = self
        
        if isOnboarding {
            creationVC.isOnboarding = true
            
            let timeVC = SelectTimeViewController()
            timeVC.delegate = self
            creationVC.selectTimeVC = timeVC
        }
        
        let navController = UINavigationController(rootViewController: creationVC)
        navController.modalPresentationStyle = .pageSheet
        present(navController, animated: true, completion: nil)
    }
    
    // MARK: - Alert Methods
    
    // in the future makes sure this only fires in cases where it makes sense - like if someone frequents a location, don't fire it everytime they go to a place
    // checks if the habit has already been done for the appropriate number of times that day
    func isHabitDone(for habit: inout Habit) async {
        if viewModel.isHabitForToday(habit) {
            print("habit is for today")
            
            #if DEBUG
            await viewModel.habitCompleted(&habit)
            #else
            // normal user interface
            if viewModel.isHabitCompletedForDay(habit) {
                print("habit already completed for today")
                let alertController = CustomAlertViewController(title: "Habit already completed!", message: "You've already \(habit.name) today!")
                
                present(alertController, animated: true, completion: nil)
            } else {
                print("habit not completed yet")
                viewModel.habitCompleted(&habit)
            }
            #endif
        } else {
            print("trying to present alert for habit not today")
            let currentDayString = TimeFormatter.weekdayToString(viewModel.currentDay)
            let alertController = CustomAlertViewController(title: "Habit not for today", message: "You don't have to \(habit.name) on \(currentDayString)!")
            
            present(alertController, animated: true, completion: nil)
        }
    }
    
    /*
    // for when there is a location habit but the user turned location permissions off
    func isLocationPermissionDenied() {
        switch LocationManager.shared.authorizationStatus {
        case .denied, .restricted:
            print("user denied or restricted location authorization but has lcoation based habits")
            let locationBasedHabits = viewModel.locationBasedHabits()
            
            if locationBasedHabits.count > 3 {
                print("display alert for 3+ lcoation based habits")
                let alert = CustomAlertViewController(
                    title: "Your Location-based Habits need Location Authorization!",
                    message: "Do you want to keep tracking your habits based on their locations?",
                    okButtonTitle: "Yes, how can I change my settings?",
                    cancelButtonTitle: "No, don't track my habits with their locations anymore")
                
                alert.completionOk = {
                    print("user is trying to change settings to allow for location authorization (3+)")
                    let guideAlert = CustomAlertViewController.createLocationSettingsAlert { [weak self] in
                        print("user indicated that they have changed their settings for lcoation authorization (3+)")
                        self?.checkLocationAuthorization()
                    }
                    
                    self.present(guideAlert, animated:true)
                }
                
                alert.completionCancel = {
                    print("user indicated that they don't want to change their settings for location authoriation (3+)")
                    self.locationToSelfTrackAlert()
                    self.viewModel.changeLocationToSelfTrack(habits: locationBasedHabits)
                }
                
                present(alert, animated: true)
            } else if !locationBasedHabits.isEmpty {
                print("display alert for <3 location based habits")
                let names = locationBasedHabits.map { $0.name }
                let habitNames: String
                if names.count > 1 {
                    let allButLast = names.dropLast().joined(separator: ", ")
                    habitNames = "\(allButLast) and \(names.last!)"
                } else {
                    habitNames = names.first ?? "your habits"
                }
                
                let alert = CustomAlertViewController(
                    title: "Your Location-based Habits need Location Authorization!",
                    message: "Do you want to keep tracking \(habitNames) based on their locations?",
                    okButtonTitle: "Yes, how can I change my settings?",
                    cancelButtonTitle: "No, don't track my habits with their locations anymore")
                
                alert.completionOk = {
                    print("user is trying to change settings to allow for lcoation authorization (3-)")
                    let guideAlert = CustomAlertViewController.createLocationSettingsAlert { [weak self] in
                        print("user indicated that they have changed their settings for lcoation authorization (3-)")
                        self?.checkLocationAuthorization()
                    }
                    
                    self.present(guideAlert, animated: true)
                }
                
                alert.completionCancel = {
                    print("user indicated that they don't want to change their settings for lcoation authorization (3-)")
                    self.locationToSelfTrackAlert()
                    self.viewModel.changeLocationToSelfTrack(habits: locationBasedHabits)
                }
                
                present(alert, animated: true)
            }
        case .authorizedWhenInUse:
            print("user has only authorized location tracking during app usage")
            if !LocationManager.shared.hasShownWhenInUseAlert {
                showWhenInUseAlert()
            }
        default:
            break
        }
    }
    
    private func showWhenInUseAlert() {
        print("this is the first time that the user has logged into the app since changing their settings to location only being tracked during use")
        
        LocationManager.shared.hasShownWhenInUseAlert = true
        let alert = CustomAlertViewController(
            title: "Locations Currently Only Authorized During App Use!",
            message: "Your habits will only get tracked if you go on RightNow with each habit, so we can check your location. If you change your authorization to Always Allow, we can check your location without you going on RightNow.",
            okButtonTitle: "How do I switch my authorization status?",
            cancelButtonTitle: "OK, I'll log onto RightNow every time for my location habits to get tracked!")
        
        alert.completionOk = { [weak self] in
            print("the user wants to change their location authorization from when in use -> always")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
                let guideAlert = CustomAlertViewController.createLocationSettingsAlert { [weak self] in
                    print("the user has indicated that they have changed their settings to when in use -> always")
                    self?.checkLocationAuthorization()
                }
                
                self?.present(guideAlert, animated: true)
            }
        }
        
        present(alert, animated: true)
    }
    
    private func locationToSelfTrackAlert() {
        print("presenting alert informing user that we've changed habit tracking to self tracking instead")
        let alert = CustomAlertViewController(title: "OK, sounds good!", 
                                              message: "We've turned all of your habits being tracked with locations to be self-tracked insetad. Don't forget to check them off!")
        
        present(alert, animated: true)
    }
    
    private func checkLocationAuthorization() {
        print("checking location authorization (listVC)")
        switch LocationManager.shared.authorizationStatus {
        case .restricted, .denied:
            print("location authorization still gone despite user indicating otherwise. inform user of changing their habits to self tracking insetad")
            let alert = CustomAlertViewController(title: "Uh Oh!", 
                                                  message: "We still don't have location authorization! We've turned your location-tracked habits into self-tracking habits for now.")
            self.present(alert, animated: true)
            
            self.viewModel.changeLocationToSelfTrack(habits: nil)
        case .authorizedWhenInUse:
            print("this should only happen when the user turned off location with location based habits -> changed to when in use only, but not always")
            showWhenInUseAlert()
        default:
            print("user has changed settings successfully for location tracking (listVC)")
            break
        }
    }
    */
    
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
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "HabitCell", for: indexPath) as? HabitTableViewCell else {
            print("Failed to dequeue HabitTableViewCell - check cell registration")
            
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
    
    // for tapping on the container
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true) // for visual feedback
        let selectedHabit = sections[indexPath.section].rows[indexPath.row]
        
        // action sheet
        let actionSheet = UIAlertController(title: nil, message: "Choose an action", preferredStyle: .actionSheet)
        
        // edit action
        let editAction = UIAlertAction(title: "Edit Habit", style: .default) { _ in
            let editingVC = HabitEditingViewController(habit: selectedHabit)
            let navController = UINavigationController(rootViewController: editingVC)
            editingVC.modalPresentationStyle = .pageSheet
            self.present(navController, animated: true, completion: nil)
        }
        
        actionSheet.addAction(editAction)
        
        // record
        let recordAction = UIAlertAction(title: "Record Habit", style: .default) { _ in
            let recordVC = CameraController(habit: selectedHabit)
            recordVC.modalPresentationStyle = .fullScreen
            self.present(recordVC, animated: true, completion: nil)
        }
        
        actionSheet.addAction(recordAction)
        
        // check off habit
        let checkAction = UIAlertAction(title: "Check Off Habit", style: .default) { _ in
            let checkInVC = CheckInController(habit: selectedHabit)
            checkInVC.delegate = self
            checkInVC.modalPresentationStyle = .fullScreen
            self.present(checkInVC, animated: true, completion: nil)
        }
        
        actionSheet.addAction(checkAction)
        
        // cancel
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        actionSheet.addAction(cancelAction)
        
        // for ipad users
        if let popOverController = actionSheet.popoverPresentationController {
            popOverController.sourceView = tableView.cellForRow(at: indexPath)
            popOverController.sourceRect = tableView.cellForRow(at: indexPath)!.bounds
        }
        
        // present
        present(actionSheet, animated: true, completion: nil)
    }
}

extension HabitListViewController: HabitCompleteDelegate {
    func completeHabit(for habit: inout Habit) async {
        await isHabitDone(for: &habit)
    }
}

// MARK: - Onboarding
extension HabitListViewController {
    func setupOnboarding() {
        // this makes sure that the focusview is added on top of everything, including the tab bar controller, because there were issues where only putting on top of the current view controller creates additional tab bar controller that causes crashes if tapped on when focus view was up
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootViewController = window.rootViewController else {
            print("Failed to get window or root view controller")
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
            print("Failed to get window or root view controller")
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
    
    func determineCurrentTabBarController() async {
        if let onboardingTabBar = parentTabBarController(ofType: OnboardingTabBarController.self) {
            print("onboarding")
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay
            setupOnboarding()
            showOnboardingFocus()
        } else if let mainTabBar = parentTabBarController(ofType: TabBarController.self) {
            // normal - nothing happens
            print("main")
        } else {
            print("Not in any tab bar controller???")
        }
    }
    
    func selectHabitViewControllerDidDismiss(_ viewController: SelectHabitViewController) {
        if viewModel.getHabits().isEmpty {
            setupOnboarding()
            showOnboardingFocus()
        }
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
    
    func didCompleteOnboarding() {
        Task {
            try? await Task.sleep(nanoseconds: 1_000_000_000) // wait to make sure everything consolidates
            await showDeletion()
        }
    }
    
    private func showDeletion() async {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootViewController = window.rootViewController else {
            print("Failed to get window or root view controller")
            return
        }
        
        let containerView = rootViewController.view!
        
        // check if there are any habit sin the table view
        guard !sections.isEmpty && !sections[0].rows.isEmpty else {
            print("onboarding but somehow there are no habits??")
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
        } completion: { success in
            print("completed \(success)")
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
        
        // Optional: You can also animate the deletion label to provide a hint
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
        if let tabBarController = parentTabBarController(ofType: OnboardingTabBarController.self) {
            let tabBarWidth = tabBarController.tabBar.bounds.width
            let numberOfItems = CGFloat(tabBarController.tabBar.items?.count ?? 0)
            let tabWidth = tabBarWidth / numberOfItems
            
            // The second tab should be at index 1, so its x position starts at 1 * tabWidth
            let secondTabX = 1 * tabWidth
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
            instructionLabel.text = "Let's go check back in on Maow"
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
                    // Switch to the maow tab
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
    }
}

// MARK: - Debugging
extension HabitListViewController {
    func addDebugButton() {
        let button = UIButton(frame: CGRect(x: 20, y: 100, width: 120, height: 40))
        button.setTitle("View Logs", for: .normal)
        button.backgroundColor = .systemBlue
        button.layer.cornerRadius = 8
        button.addTarget(self, action: #selector(showLogs), for: .touchUpInside)
        view.addSubview(button)
    }

    @objc func showLogs() {
        let logContents = GeofenceLogger.shared.getLogContents()
        let alert = UIAlertController(title: "Geofence Logs", message: logContents, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Clear Logs", style: .destructive) { _ in
            GeofenceLogger.shared.clearLog()
        })
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

extension UIViewController {
    func parentTabBarController<T: UITabBarController>(ofType type: T.Type) -> T? {
        // check if direct parent is the desired tab bar controller type
        if let tabBarController = tabBarController as? T {
            return tabBarController
        }
        
        // walk up the hierarchy
        var parent = self.parent
        while parent != nil {
            if let tabBarController = parent as? T {
                return tabBarController
            }
            parent = parent?.parent
        }
        
        return nil
    }
}
