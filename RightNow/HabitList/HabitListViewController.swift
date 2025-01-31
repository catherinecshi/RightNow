import UIKit
import UserNotifications
import LocalAuthentication

class HabitListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    // to section off different levels
    struct LevelSection {
        let header: String
        let rows: [Habit]
    }
    
    let habitListView = HabitListView(frame: UIScreen.main.bounds)
    let viewModel = HabitListViewModel.shared
    var sections = [LevelSection]()
    
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
    
    override func loadView() {
        self.view = habitListView
        
        //setup delegates
        habitListView.tableView.delegate = self
        habitListView.tableView.dataSource = self
    }
    
    // MARK: Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("viewDidLoad - Direct check of habits:")
            viewModel.habitsForCurrentDay.forEach { habit in
                print("Habit: \(habit.name), Level: \(habit.currentLevel.displayName)")
            }
        
        //receives callback
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
                
                // make sure the  notifications matches with the habits
                PushNotificationDelegate.shared.auditNotifications()
            }
        }
        
        habitListView.tableView.reloadData()
        habitListView.tableView.register(HabitTableViewCell.self, forCellReuseIdentifier: "HabitCell")
        habitListView.tableView.allowsSelectionDuringEditing = true //capable of editing mode
        
        setupAddButton()
        setupSwipes()
        
        if FirstLaunchManager.shared.shouldShowWelcomeAlert {
            DispatchQueue.main.asyncAfter(deadline: .now()) { [weak self] in
                let alert = CustomAlertViewController(
                    title: "Welcome!",
                    message: "Welcome to Right Now! To get you situated, let's make your first habit."
                )

                alert.completionOk = { [weak self] in
                    if FirstLaunchManager.shared.shouldShowOnboarding {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
                            self?.setupOnboarding()
                            self?.showOnboardingFocus()
                            FirstLaunchManager.shared.markOnboardingAsShown()
                            print("habit creation onboarding shown")
                        }
                    }
                }
                
                print("presenting welcome alert")
                self?.present(alert, animated: true)
                FirstLaunchManager.shared.markWelcomeAsShown()
            }
        } else if FirstLaunchManager.shared.shouldShowOnboarding {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
                self?.setupOnboarding()
                self?.showOnboardingFocus()
                FirstLaunchManager.shared.markOnboardingAsShown()
                print("habit creation onboarding shown without welcome alert")
            }
        }
        
        FirstLaunchManager.shared.markAsLaunched()
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
        //handle swipe
        applyPushAnimation(from: sender.direction)
        viewModel.handleSwipe(direction: sender.direction)
        
        //update
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
        
        //add a plus sign
        addButton.setTitle("+", for: .normal)
        addButton.setTitleColor(.white, for: .normal)
        addButton.titleLabel?.font = UIFont.systemFont(ofSize: (size / 2), weight: .bold)
        
        //add action for button
        addButton.addTarget(self, action: #selector(addHabitTapped), for: .touchUpInside)
        
        //add to view
        view.addSubview(addButton)
        
        NSLayoutConstraint.activate([
            addButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            addButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            addButton.widthAnchor.constraint(equalToConstant: size),
            addButton.heightAnchor.constraint(equalToConstant: size)
        ])
    }
    
    @objc func addHabitTapped() {
        hideOnboardingFocus()
        
        let creationVC = SelectHabitViewController()
        let navController = UINavigationController(rootViewController: creationVC)
        navController.modalPresentationStyle = .pageSheet
        present(navController, animated: true, completion: nil)
    }
    
    // MARK: Alert Methods
    
    // in the future makes sure this only fires in cases where it makes sense - like if someone frequents a location, don't fire it everytime they go to a place
    // checks if the habit has already been done for the appropriate number of times that day
    func isHabitDone(for habit: inout Habit) {
        if viewModel.isHabitForToday(habit) {
            print("habit is for today")
            
            #if DEBUG
            viewModel.habitCompleted(&habit)
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
    
    // MARK: TableView
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section].header
    }
    
    //this is for making the right number of rows
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].rows.count
        //return viewModel.habitsForCurrentDay.count
    }
    
    //this is for calling cell view
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "HabitCell", for: indexPath) as! HabitTableViewCell
        let habit = sections[indexPath.section].rows[indexPath.row]
        cell.configure(with: habit)
        
        return cell
    }
    
    //indicates that all rows are editable
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    //specify editing style for a particular row
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }
    
    //for swipe from right to left -> deletion
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { (action, view, completionHandler) in
            //fetch habit to delete
            let habitToDelete = self.sections[indexPath.section].rows[indexPath.row]
            
            //delete habit from firestore + locally, also delete notification
            self.viewModel.deleteHabit(habit: habitToDelete)
            
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
            
            //check if there are still habits
            self.habitsPresent()
            
            completionHandler(true)
        }
        
        //create swipe action config
        let configuration = UISwipeActionsConfiguration(actions: [deleteAction])
        return configuration
    }
    
    //for tapping on the container
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true) // for visual feedback
        let selectedHabit = sections[indexPath.section].rows[indexPath.row]
        
        //action sheet
        let actionSheet = UIAlertController(title: nil, message: "Choose an action", preferredStyle: .actionSheet)
        
        //edit action
        let editAction = UIAlertAction(title: "Edit Habit", style: .default) { _ in
            let editingVC = HabitEditingViewController(habit: selectedHabit)
            let navController = UINavigationController(rootViewController: editingVC)
            editingVC.modalPresentationStyle = .pageSheet
            self.present(navController, animated: true, completion: nil)
        }
        
        actionSheet.addAction(editAction)
        
        //record
        let recordAction = UIAlertAction(title: "Record Habit", style: .default) { _ in
            let recordVC = CameraController(habit: selectedHabit)
            recordVC.modalPresentationStyle = .fullScreen
            self.present(recordVC, animated: true, completion: nil)
        }
        
        actionSheet.addAction(recordAction)
        
        //track
        let trackAction = UIAlertAction(title: "Track Habit", style: .default) { _ in
            let trackVC = TimerController(habit: selectedHabit)
            trackVC.modalPresentationStyle = .fullScreen
            self.present(trackVC, animated: true, completion: nil)
        }
        
        actionSheet.addAction(trackAction)
        
        // check off habit
        let checkAction = UIAlertAction(title: "Check Off Habit", style: .default) { _ in
            let checkInVC = CheckInController(habit: selectedHabit)
            checkInVC.delegate = self
            checkInVC.modalPresentationStyle = .fullScreen
            self.present(checkInVC, animated: true, completion: nil)
        }
        
        actionSheet.addAction(checkAction)
        
        //cancel
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        actionSheet.addAction(cancelAction)
        
        //for ipad users
        if let popOverController = actionSheet.popoverPresentationController {
            popOverController.sourceView = tableView.cellForRow(at: indexPath)
            popOverController.sourceRect = tableView.cellForRow(at: indexPath)!.bounds
        }
        
        //present
        present(actionSheet, animated: true, completion: nil)
    }
}

extension HabitListViewController: HabitCompleteDelegate {
    func completeHabit(for habit: inout Habit) {
        isHabitDone(for: &habit)
    }
}

// for onboarding process
extension HabitListViewController {
    func setupOnboarding() {
        view.addSubview(focusView)
        view.addSubview(onboardingLabel)
        
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
        view.bringSubviewToFront(focusView)
        view.bringSubviewToFront(onboardingLabel)
        view.bringSubviewToFront(addButton)
        
        // make focus oval around add button
        focusView.ovalRect = addButton.frame.insetBy(dx: -10, dy: -10)
        
        focusView.isHidden = false
        onboardingLabel.isHidden = false
        
        UIView.animate(withDuration: 0.3) {
            self.focusView.alpha = 1.0
            self.onboardingLabel.alpha = 1.0
        }
    }
    
    func hideOnboardingFocus() {
        UIView.animate(withDuration: 0.3, animations: {
            self.focusView.alpha = 0.0
            self.onboardingLabel.alpha = 0.0
        }, completion: { _ in
            self.focusView.isHidden = true
            self.onboardingLabel.isHidden = true
        })
    }
}
