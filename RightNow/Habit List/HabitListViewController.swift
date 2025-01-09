import UIKit
import UserNotifications

class HabitListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    struct LevelSection {
        let header: String
        let rows: [Habit]
    }
    
    let habitListView = HabitListView(frame: UIScreen.main.bounds)
    let viewModel = HabitListViewModel.shared
    var sections = [LevelSection]()
    
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
        viewModel.onDataLoaded = { [weak self] in
            DispatchQueue.main.async {
                self?.updateSections()
                self?.habitListView.tableView.reloadData()
                self?.habitsPresent()
            }
        }
        
        habitListView.tableView.reloadData()
        habitListView.tableView.register(HabitTableViewCell.self, forCellReuseIdentifier: "HabitCell")
        habitListView.tableView.allowsSelectionDuringEditing = true //capable of editing mode
        
        setupAddButton()
        setupSwipes()
        habitsPresent()
        
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
        print("Grouped habits: \(groupedHabits)")
        
        // sort by order cases are established in Level enum
        sections = groupedHabits.map { key, value in
            return LevelSection(header: key, rows: value)
        }.sorted(by: { Level.allCases.firstIndex(of: Level(rawValue: $0.header.lowercased())!)! < Level.allCases.firstIndex(of: Level(rawValue: $1.header.lowercased())!)! })
        print("Updated Sections: \(sections.count) sections")
    }
    
    func updateTitle() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy/MM/dd"
        let formattedDate = dateFormatter.string(from: viewModel.currentDay)
        habitListView.titleLabel.text = formattedDate
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
        let creationVC = SelectHabitViewController()
        let navController = UINavigationController(rootViewController: creationVC)
        navController.modalPresentationStyle = .pageSheet
        present(navController, animated: true, completion: nil)
    }
    
    // MARK: Notification Methods
    
    func cancelNotification(for habit: Habit) {
        let center = UNUserNotificationCenter.current()
        
        for day in habit.daysOfTheWeek.keys {
            let identifier = "\(habit.id)_\(day)"
            center.removePendingNotificationRequests(withIdentifiers: [identifier])
        }
    }
    
    // MARK: TableView
    
    func numberOfSections(in tableView: UITableView) -> Int {
        print("Number of sections: \(sections.count)")
        return sections.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section].header
    }
    
    //this is for making the right number of rows
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print("Number of rows in section \(section): \(sections[section].rows.count)")
        return sections[section].rows.count
        //return viewModel.habitsForCurrentDay.count
    }
    
    //this is for calling cell view
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        print("Configuring cell at section \(indexPath.section), row \(indexPath.row)")
        let cell = tableView.dequeueReusableCell(withIdentifier: "HabitCell", for: indexPath) as! HabitTableViewCell
        let habit = sections[indexPath.section].rows[indexPath.row]
        print("Habit for cell: \(habit.name)")
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
            
            //delete firestore habit
            self.viewModel.deleteHabit(habit: habitToDelete)
            self.cancelNotification(for: habitToDelete)
            
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
