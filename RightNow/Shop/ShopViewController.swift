import Foundation
import UIKit

class ShopViewController: UIViewController {
    // MARK: - Initiation
    let viewTitle: UILabel = {
        let label = UILabel()
        label.text = "Shop"
        label.font = UIConfiguration.subtitleFont
        label.textColor = .white
        label.textAlignment = .center
        return label
    }()
    
    private let itemsLabel: UILabel = {
       let label = UILabel()
        label.text = "Your Items"
        label.font = UIConfiguration.titleFont
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let itemsScrollView: UIScrollView = {
        let scroll = UIScrollView()
        scroll.showsVerticalScrollIndicator = false
        scroll.translatesAutoresizingMaskIntoConstraints = false
        return scroll
    }()
    
    private let itemsStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    private let items: [String] = ["1", "2", "3", "4"]
    private var itemButtons: [UIButton] = []
    
    private let dismissButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("x", for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 24)
        button.setTitleColor(.white, for: .normal)
        return button
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIConfiguration.tintColor
        
        setupTitle()
        setupItemLabel()
        setupItems()
        setupDismissButton()
    }
    
    // MARK: - Setup UI
    
    private func setupTitle() {
        view.addSubview(viewTitle)
        viewTitle.translatesAutoresizingMaskIntoConstraints = false
        
        //make sure it can go to multiple lines if squished
        viewTitle.numberOfLines = 0 //allows line breaks
        viewTitle.lineBreakMode = .byWordWrapping //breaks lines by words, not characters
        
        self.navigationItem.titleView = viewTitle
    }
    
    private func setupItemLabel() {
        view.addSubview(itemsLabel)
        
        NSLayoutConstraint.activate([
            itemsLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            itemsLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            itemsLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
    }
    
    private func setupItems() {
        view.addSubview(itemsScrollView)
        itemsScrollView.addSubview(itemsStackView)
        
        NSLayoutConstraint.activate([
            itemsScrollView.topAnchor.constraint(equalTo: itemsLabel.bottomAnchor, constant: 20),
            itemsScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            itemsScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            itemsScrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20),
            
            itemsStackView.topAnchor.constraint(equalTo: itemsScrollView.topAnchor),
            itemsStackView.leadingAnchor.constraint(equalTo: itemsScrollView.leadingAnchor),
            itemsStackView.trailingAnchor.constraint(equalTo: itemsScrollView.trailingAnchor),
            itemsStackView.widthAnchor.constraint(equalTo: itemsScrollView.widthAnchor),
            itemsStackView.bottomAnchor.constraint(equalTo: itemsStackView.bottomAnchor)
        ])
        
        // create the buttons
        for (index, _) in items.enumerated() {
            let containerView = createItemButton(index: index)
            itemsStackView.addArrangedSubview(containerView)
        }
    }
    
    private func createItemButton(index: Int) -> UIView {
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.heightAnchor.constraint(equalToConstant: 80).isActive = true
        containerView.backgroundColor = .systemGray6
        containerView.layer.cornerRadius = 12
        
        // Icon
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage(systemName: "star.fill")
        imageView.tintColor = .systemBlue
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        // Labels stack
        let labelsStack = UIStackView()
        labelsStack.axis = .vertical
        labelsStack.spacing = 4
        labelsStack.translatesAutoresizingMaskIntoConstraints = false
        
        let titleLabel = UILabel()
        titleLabel.text = "Item \(index + 1)"
        titleLabel.font = .systemFont(ofSize: 16, weight: .medium)
        
        let subtextLabel = UILabel()
        subtextLabel.text = "Subtext"
        subtextLabel.font = .systemFont(ofSize: 12)
        subtextLabel.textColor = .systemGray
        
        labelsStack.addArrangedSubview(titleLabel)
        labelsStack.addArrangedSubview(subtextLabel)
        
        // Coin stack (similar to your MaowViewController implementation)
        let coinStack = UIStackView()
        coinStack.axis = .horizontal
        coinStack.spacing = 4
        coinStack.alignment = .center
        coinStack.translatesAutoresizingMaskIntoConstraints = false
        
        let coinImageView = UIImageView()
        coinImageView.image = UIImage(systemName: "centsign.circle.fill")
        coinImageView.tintColor = UIConfiguration.tintColor
        coinImageView.contentMode = .scaleAspectFit
        
        let coinLabel = UILabel()
        coinLabel.text = "100"
        coinLabel.font = UIConfiguration.subtitleFont
        
        coinStack.addArrangedSubview(coinImageView)
        coinStack.addArrangedSubview(coinLabel)
        
        // Add all elements to container
        containerView.addSubview(imageView)
        containerView.addSubview(labelsStack)
        containerView.addSubview(coinStack)
        
        // Constraints
        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            imageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 32),
            imageView.heightAnchor.constraint(equalToConstant: 32),
            
            labelsStack.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 16),
            labelsStack.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            
            coinStack.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            coinStack.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            coinStack.leadingAnchor.constraint(greaterThanOrEqualTo: labelsStack.trailingAnchor, constant: 16)
        ])
        
        // Add tap gesture
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(itemTapped(_:)))
        containerView.addGestureRecognizer(tapGesture)
        containerView.tag = index
        containerView.isUserInteractionEnabled = true
        
        return containerView
    }
    
    private func setupDismissButton() {
        dismissButton.translatesAutoresizingMaskIntoConstraints = false
        
        let dismissBarButton = UIBarButtonItem(customView: dismissButton)
        self.navigationItem.leftBarButtonItem = dismissBarButton
        
        // add action
        dismissButton.addTarget(self, action: #selector(dismissSelf), for: .touchUpInside)
    }
    
    // MARK: - Action Methods
    @objc private func itemTapped(_ sender: UITapGestureRecognizer) {
        guard let index = sender.view?.tag else { return }
        print("Tapped item at index: \(index)")
    }
    
    @objc private func dismissSelf() {
        self.dismiss(animated: true, completion: nil)
    }
}
