import Foundation
import UIKit

class SelectHabitViewController: UIViewController, UITextFieldDelegate {
    // MARK: Declaration
    let selectNameView = SelectNameView()
    let selectTimeView = SelectTimeView()
    let selectCueView = SelectCueView()
    
    // might be artifacts of trying to fix the problem with equalorlessthan - don't delete tho
    private var selectViewHeightConstraint: NSLayoutConstraint?
    
    // some generic habit variables
    var habitData = HabitData()
    
    //initiate labels
    let viewTitle: UILabel = {
        let label = UILabel()
        label.text = "Create Habit"
        label.font = UIConfiguration.titleFont
        label.textColor = .white
        label.textAlignment = .center
        return label
    }()
    
    let containerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    let timeOrCueLabel: UILabel = {
        let label = UILabel()
        label.text = "Do you prefer to be reminded at a specific time or after a cue?"
        label.font = UIConfiguration.subtitleFont
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let timeOrCue: UISegmentedControl = {
        let segmentedControl = UISegmentedControl(items: ["Time", "Cue"])
        segmentedControl.backgroundColor = .lightGray
        segmentedControl.selectedSegmentTintColor = .white

        // Set white text for all segments
        let normalAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIConfiguration.tintColor,
            .font: UIFont.systemFont(ofSize: 16)
        ]
        segmentedControl.setTitleTextAttributes(normalAttributes, for: .normal)
        segmentedControl.setTitleTextAttributes(normalAttributes, for: .selected)
        
        segmentedControl.selectedSegmentIndex = 0 // defaults to time
        
        return segmentedControl
    }()
    
    //button to go to the next step
    private let nextButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Next", for: .normal)
        button.isEnabled = false //button is disabled until a habit is selected
        return button
    }()
    
    //button to x out
    private let dismissButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("x", for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 24)
        button.setTitleColor(.white, for: .normal)
        return button
    }()
    
    // stack + scroll for subviews
    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 20
        stack.distribution = .fill
        return stack
    }()
    
    private let scrollView = UIScrollView()
    
    // MARK: Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIConfiguration.tintColor
        
        setupTitle()
        setupNextButton()
        setupDismissButton()
        setupScroll()
        setupNameView()
        setupSegmentedControl()
        setupContainerView()
        setupSubviews()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        setupInset()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        //showUseDeviceFocus()
    }
    
    // MARK: Setup UI
    
    private func setupTitle() {
        view.addSubview(viewTitle)
        viewTitle.translatesAutoresizingMaskIntoConstraints = false
        
        //make sure it can go to multiple lines if squished
        viewTitle.numberOfLines = 0 //allows line breaks
        viewTitle.lineBreakMode = .byWordWrapping //breaks lines by words, not characters
        
        self.navigationItem.titleView = viewTitle
    }
    
    private func setupNextButton() {
        //add to view
        view.addSubview(nextButton)
        nextButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            nextButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            nextButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            nextButton.heightAnchor.constraint(equalToConstant: 100),
            nextButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -30)
        ])
        
        //appearance
        nextButton.backgroundColor = .white
        nextButton.setTitleColor(UIConfiguration.tintColor, for: .normal)
        nextButton.setTitleColor(UIColor.gray, for: .disabled)
        nextButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 32)
        nextButton.layer.cornerRadius = 20
        nextButton.clipsToBounds = true
        
        //add action
        nextButton.addTarget(self, action: #selector(nextButtonTapped), for: .touchUpInside)
    }
    
    private func setupDismissButton() {
        dismissButton.translatesAutoresizingMaskIntoConstraints = false
        
        let dismissBarButton = UIBarButtonItem(customView: dismissButton)
        self.navigationItem.leftBarButtonItem = dismissBarButton
        
        // add action
        dismissButton.addTarget(self, action: #selector(dismissSelf), for: .touchUpInside)
    }
    
    private func setupScroll() {
        //setup stack view
        scrollView.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            stackView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor)
        ])
        
        //setup scroll view
        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: nextButton.topAnchor)
        ])
    }
    
    private func setupNameView() {
        stackView.addArrangedSubview(selectNameView)
        selectNameView.delegate = self
        
        NSLayoutConstraint.activate([
            selectNameView.leadingAnchor.constraint(equalTo: stackView.leadingAnchor),
            selectNameView.trailingAnchor.constraint(equalTo: stackView.trailingAnchor)
        ])
    }
    
    private func setupSegmentedControl() {
        stackView.addArrangedSubview(timeOrCueLabel)
        stackView.addArrangedSubview(timeOrCue)
        
        NSLayoutConstraint.activate([
            timeOrCueLabel.topAnchor.constraint(equalTo: selectNameView.bottomAnchor, constant: 20),
            timeOrCueLabel.leadingAnchor.constraint(equalTo: stackView.leadingAnchor, constant: 20),
            timeOrCueLabel.trailingAnchor.constraint(equalTo: stackView.trailingAnchor, constant: -20),
            
            timeOrCue.topAnchor.constraint(equalTo: timeOrCueLabel.bottomAnchor, constant: 20),
            timeOrCue.leadingAnchor.constraint(equalTo: stackView.leadingAnchor, constant: 20),
            timeOrCue.trailingAnchor.constraint(equalTo: stackView.trailingAnchor, constant: -20),
        ])
        
        timeOrCue.addTarget(self, action: #selector(segmentChanged(_:)), for: .valueChanged)
        
        // initially hidden
        timeOrCueLabel.isHidden = true
        timeOrCue.isHidden = true
    }
    
    private func setupContainerView() {
        stackView.addArrangedSubview(containerView)
        
        NSLayoutConstraint.activate([
            containerView.leadingAnchor.constraint(equalTo: stackView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: stackView.trailingAnchor),
            containerView.topAnchor.constraint(equalTo: timeOrCue.bottomAnchor, constant: 20),
            containerView.heightAnchor.constraint(equalToConstant: 400)
        ])
    }
    
    private func setupSubviews() {
        // add subviews
        containerView.addSubview(selectTimeView)
        containerView.addSubview(selectCueView)
        
        selectTimeView.delegate = self
        selectCueView.delegate = self
        selectTimeView.translatesAutoresizingMaskIntoConstraints = false
        selectCueView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            selectTimeView.topAnchor.constraint(equalTo: containerView.topAnchor),
            selectTimeView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            selectTimeView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            selectTimeView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            
            selectCueView.topAnchor.constraint(equalTo: containerView.topAnchor),
            selectCueView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            selectCueView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            selectCueView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
        containerView.isHidden = true
        selectTimeView.isHidden = true
        selectCueView.isHidden = true
        
        // dynamic height for first subview (bc it has a scrollview)
        selectViewHeightConstraint = selectNameView.heightAnchor.constraint(equalToConstant: 300)
        selectViewHeightConstraint?.isActive = true
        
        //adjust height based on scrollview
        adjustHabitSelectionViewHeight()
    }
    
    // MARK: Supplemental methods
    
    private func adjustHabitSelectionViewHeight() {
        view.layoutIfNeeded()
        
        let maxPossibleHeight = nextButton.frame.origin.y - scrollView.frame.origin.y - 20 //where 20 is padding
        let contentHeight = selectNameView.calculateContentHeight()
        
        //reset height for selectview
        selectViewHeightConstraint?.constant = min(contentHeight, maxPossibleHeight) // select whichever one is smaller
        selectViewHeightConstraint?.isActive = true
        
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    private func setupInset() {
        // make sure stuff isn't being covered by the next button
        let bottomInset = nextButton.frame.size.height
        scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: bottomInset, right: 0)
    }
    
    // MARK: Detect Actions
    
    @objc private func segmentChanged(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0: // time
            UIView.animate(withDuration: 0.3) {
                self.selectTimeView.isHidden = false
                self.selectCueView.isHidden = true
            }
            //removeWakingUpFocus()
        case 1: // cue
            UIView.animate(withDuration: 0.3) {
                self.selectTimeView.isHidden = true
                self.selectCueView.isHidden = false
            }
            //showWakingUpFocus()
        default:
            break
        }
    }
    
    //activate the next button if appropriate
    private func updateNextButtonState() {
        //check if habit & day have been selected
        let isHabitSelected = !(habitData.name?.isEmpty ?? true)
        let isDaySelected = habitData.selectedDays?.contains(where: { $0.value }) ?? false
        
        nextButton.isEnabled = isHabitSelected && isDaySelected
    }
    
    private func disableNextButtonState() {
        nextButton.isEnabled = false
    }
    
    private func enableNextButtonState() {
        nextButton.isEnabled = true
    }
    
    @objc private func nextButtonTapped() {
        //create and push the next view controller
        let accountabilityVC = AccountabilityViewController()
        
        // back button
        let backButton = UIBarButtonItem(title: "", style: .plain, target: self, action: #selector(backButtonTapped))
        navigationItem.backBarButtonItem = backButton
        self.navigationController?.navigationBar.tintColor = .white
        
        // send info forward
        accountabilityVC.habitData = habitData
        navigationController?.pushViewController(accountabilityVC, animated: true)
    }
    
    @objc func backButtonTapped() {
        self.navigationController?.popViewController(animated: true)
    }
    
    @objc private func dismissSelf() {
        print("trying to dismiss")
        self.dismiss(animated: true, completion: nil)
    }
    
}

// MARK: Delegates from UIViews

extension SelectHabitViewController: SelectNameDelegate {
    func habitSelected(_ habit: String) {
        habitData.name = habit
        timeOrCueLabel.isHidden = false
        timeOrCue.isHidden = false
        containerView.isHidden = false
        selectTimeView.isHidden = false
        updateNextButtonState()
        
        //removeUseDeviceFocus()
    }
    
    func shouldAdjustHeight() {
        adjustHabitSelectionViewHeight()
    }
}

extension SelectHabitViewController: SelectTimeDelegate {
    func hourSelected(_ hour: Int) {
        habitData.hour = hour
    }
    
    func minuteSelected(_ minute: Int){
        habitData.minute = minute
    }
    
    func daySelected(_ days: [String: Bool]) {
        habitData.selectedDays = days
        updateNextButtonState()
    }
}

extension SelectHabitViewController: SelectCueDelegate {
    func cueSelected(_ cue: String) {
        habitData.cue = cue
        
        // check if days of week match up so you can't select a cue that doesn't exist during the day you want to do your new habit
        if let chainedHabit = HabitListViewModel.shared.habits.first(where: { $0.name == cue }), let daysOfWeek = habitData.selectedDays {
            let isSubset = TimeFormatter.isSubsetOfDays(sub: daysOfWeek, whole: chainedHabit.daysOfTheWeek)
            
            if isSubset {
                updateNextButtonState()
            } else {
                disableNextButtonState()
            }
        }
    }
    
    func daySelectedCues(_ days: [String: Bool]) {
        habitData.selectedDays = days
        updateNextButtonState()
        
        // check if days of week match up so you can't select a cue that doesn't exist during the day you want to do your new habit
        if let cue = habitData.cue,
           let chainedHabit = HabitListViewModel.shared.habits.first(where: { $0.name == cue }),
           let daysOfWeek = habitData.selectedDays {
            let isSubset = TimeFormatter.isSubsetOfDays(sub: daysOfWeek, whole: chainedHabit.daysOfTheWeek)
            
            if isSubset {
                updateNextButtonState()
            } else {
                disableNextButtonState()
            }
        }
    }
}

extension SelectHabitViewController {
    func showUseDeviceFocus() {
        selectNameView.showFocusOnUseDevice()
    }
    
    func removeUseDeviceFocus() {
        selectNameView.removeFocus()
    }
    
    func showWakingUpFocus() {
        selectCueView.showFocusOnTextField()
    }
    
    func removeWakingUpFocus() {
        selectCueView.removeFocus()
    }
}
