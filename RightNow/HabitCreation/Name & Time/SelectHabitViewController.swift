import Foundation
import UIKit

class SelectHabitViewController: UIViewController, UITextFieldDelegate {
    // MARK: Declaration
    let selectNameView = SelectNameView()
    let selectTimeView = SelectTimeView()
    
    // might be artifacts of trying to fix the problem with equalorlessthan - don't delete tho
    private var nextButtonBottomConstraint: NSLayoutConstraint!
    private var selectViewHeightConstraint: NSLayoutConstraint?
    private var setTimeViewTopConstraint: NSLayoutConstraint?
    
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
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        setupInset()
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
        
        // add subviews
        stackView.addArrangedSubview(selectNameView)
        stackView.addArrangedSubview(selectTimeView)
        
        //assign delegates
        selectNameView.delegate = self
        selectTimeView.delegate = self
        
        NSLayoutConstraint.activate([
            selectNameView.topAnchor.constraint(equalTo: scrollView.topAnchor)
        ])
        
        // dynamic height for first subview (bc it has a scrollview)
        selectViewHeightConstraint = selectNameView.heightAnchor.constraint(equalToConstant: 300)
        selectViewHeightConstraint?.isActive = true
        
        //adjust height based on scrollview
        adjustHabitSelectionViewHeight()
        
        // set non-first views as initially hidden
        selectTimeView.isHidden = true
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
    
    //activate the next button if appropriate
    private func updateNextButtonState() {
        //check if habit & day have been selected
        let isHabitSelected = !(habitData.name?.isEmpty ?? true)
        let isDaySelected = habitData.selectedDays?.contains(where: { $0.value }) ?? false
        
        nextButton.isEnabled = isHabitSelected && isDaySelected
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
        selectTimeView.isHidden = false
        updateNextButtonState()
    }
    
    func shouldAdjustHeight() {
        adjustHabitSelectionViewHeight()
    }
}

extension SelectHabitViewController: SelectTimeDelegate {
    func hourSelected(_ hour: Int) {
        habitData.hour = hour
    }
    
    func minuteSelected(_ minute: Int) {
        habitData.minute = minute
    }
    
    func daySelected(_ days: [String: Bool]) {
        habitData.selectedDays = days
        updateNextButtonState()
    }
}
