import UIKit

/// A custom view that displays a spinning wheel of values with animation effects.
///
/// `SpinnerWheelView` creates a vertically scrolling list of values that can be animated
/// to create a slot machine or spinner wheel effect. It handles:
/// - Configuring possible values based on upgrade type and level
/// - Animating the spinning motion with acceleration and deceleration
/// - Selecting a random or specified final value
/// - Providing visual feedback during spinning
///
/// Example usage:
/// ```
/// let spinnerView = SpinnerWheelView(upgradeType: .d6, level: 2)
/// containerView.addSubview(spinnerView)
///
/// // Start spinning animation
/// spinnerView.startSpinning()
///
/// // Later, stop spinning and get the final value
/// spinnerView.stopSpinning { finalValue in
///     print("Selected value: \(finalValue)")
/// }
/// ```
class SpinnerWheelView: UIView {
    // MARK: - Properties
    private let upgradeType: UpgradeType
    private let level: Int
    private var possibleValues: [Int] = []
    
    // UI components
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let selectionIndicator = UIView() // visual indicator that highlights current value
    private var valueLabels: [UILabel] = []
    
    // Animation
    private var displayLink: CADisplayLink?
    private var spinningSpeed: CGFloat = 20.0
    private var spinStartTime: TimeInterval = 0
    private var lastUpdateTime: TimeInterval = 0
    private var isDecelerating = false
    private var totalRotationDistance: CGFloat = 0
    private var targetValue: Int?
    private var completionHandler: ((Int) -> Void)?
    
    // Configuration
    private let valueHeight: CGFloat = 40
    private let minimumRotations = 5
    private let minimumSpinTime: TimeInterval = 2.0
    
    // MARK: - Initialization
    
    /// Creates a new spinner wheel view for the specified upgrade type and level
    ///
    /// - Parameters:
    ///   - upgradeType: The type of upgrade this spinner represents
    ///   - level: The level of the upgrade, affecting available values
    init(upgradeType: UpgradeType, level: Int) {
        self.upgradeType = upgradeType
        self.level = level
        super.init(frame: .zero)
        
        setupPossibleValues()
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// ensure display link is invalidated when view is deallocated
    deinit {
        stopDisplayLink()
    }
    
    // MARK: - Setup
    
    /// Generates the array of possible values based on upgrade type and level
    ///
    /// This method:
    /// - Determines the range of values from the upgrade type
    /// - Multiplies each value by the level to get the final values
    private func setupPossibleValues() {
        // Calculate all possible values based on upgrade type and level
        let range = Int(upgradeType.range)
        possibleValues = (1...range).map { $0 * level }
    }
    
    /// Configures the view's visual appearance and layout
    private func setupUI() {
        // Container styling
        backgroundColor = .systemGray6
        layer.cornerRadius = 8
        layer.borderWidth = 1
        layer.borderColor = UIColor.systemGray4.cgColor
        clipsToBounds = true
        
        // Scroll view setup
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.clipsToBounds = true
        scrollView.isUserInteractionEnabled = false
        scrollView.bounces = false
        addSubview(scrollView)
        
        // Content view for all number labels
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        
        // Selection indicator (highlight band)
        selectionIndicator.translatesAutoresizingMaskIntoConstraints = false
        selectionIndicator.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.2)
        addSubview(selectionIndicator)
        
        // Layout constraints
        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            selectionIndicator.centerYAnchor.constraint(equalTo: centerYAnchor),
            selectionIndicator.leadingAnchor.constraint(equalTo: leadingAnchor),
            selectionIndicator.trailingAnchor.constraint(equalTo: trailingAnchor),
            selectionIndicator.heightAnchor.constraint(equalToConstant: valueHeight)
        ])
        
        // Add the content - triple the values for continuous scrolling effect
        let extendedValues = possibleValues + possibleValues + possibleValues
        populateContentView(with: extendedValues)
        
        // Important: Set content size explicitly
        let contentHeight = CGFloat(extendedValues.count) * valueHeight
        contentView.heightAnchor.constraint(equalToConstant: contentHeight).isActive = true
        
        // Set initial position to middle section after layout is complete
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let middleOffset = CGFloat(self.possibleValues.count) * self.valueHeight
            self.scrollView.contentOffset = CGPoint(x: 0, y: middleOffset)
        }
    }
    
    /// Creates and adds value labels to the content view
    ///
    /// - Parameter values: Array of integer values to display in the spinner
    private func populateContentView(with values: [Int]) {
        var previousLabel: UILabel?
        
        for (index, value) in values.enumerated() {
            let label = UILabel()
            label.translatesAutoresizingMaskIntoConstraints = false
            label.text = "\(value)"
            label.textAlignment = .center
            label.font = .boldSystemFont(ofSize: 20)
            contentView.addSubview(label)
            valueLabels.append(label)
            
            NSLayoutConstraint.activate([
                label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                label.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
                label.heightAnchor.constraint(equalToConstant: valueHeight)
            ])
            
            if let previous = previousLabel {
                label.topAnchor.constraint(equalTo: previous.bottomAnchor).isActive = true
            } else {
                label.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
            }
            
            previousLabel = label
            
            // Add divider line between values
            if index < values.count - 1 {
                let divider = UIView()
                divider.translatesAutoresizingMaskIntoConstraints = false
                divider.backgroundColor = UIColor.systemGray5
                contentView.addSubview(divider)
                
                NSLayoutConstraint.activate([
                    divider.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
                    divider.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
                    divider.topAnchor.constraint(equalTo: label.bottomAnchor),
                    divider.heightAnchor.constraint(equalToConstant: 1)
                ])
            }
        }
        
        // Set the last label's bottom constraint
        if let lastLabel = previousLabel {
            lastLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
        }
    }
    
    // MARK: - Animation Controls
    
    /// Begins the spinning animation
    ///
    /// This method:
    /// - Stops any existing animation
    /// - Initializes animation variables with type-specific settings
    /// - Creates and starts a display link for smooth animation
    /// - Positions the spinner at a known starting point
    func startSpinning() {
        // Ensure any previous animation is stopped
        stopDisplayLink()
        
        // Special handling for dice (which has fewer possible values)
        let isDice = (upgradeType == .d6)
        
        // Initialize animation variables with dice-specific adjustments
        spinStartTime = CACurrentMediaTime()
        lastUpdateTime = spinStartTime
        spinningSpeed = isDice ? 10.0 : 15.0 // Slightly slower for dice
        isDecelerating = false
        totalRotationDistance = 0
        targetValue = nil
        
        // Extra logging for dice spinner
        if isDice {
            print("Dice spinner starting with speed: \(spinningSpeed)")
        }
        
        // Ensure we're on the main thread
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Reset scroll position to ensure clean animation start
            if isDice {
                let middleOffset = CGFloat(self.possibleValues.count) * self.valueHeight
                self.scrollView.contentOffset = CGPoint(x: 0, y: middleOffset)
            }
            
            // Create and start display link
            self.displayLink = CADisplayLink(target: self, selector: #selector(self.updateSpinning))
            self.displayLink?.preferredFramesPerSecond = 60 // Ensure consistent frame rate
            self.displayLink?.add(to: .main, forMode: .common)
            
            if isDice {
                print("Dice spinner display link added to run loop")
            }
        }
    }
    
    /// Begins the process of stopping the spinning animation
    ///
    /// - Parameter completion: Closure to be called when spinning animation completes,
    ///   receiving the final selected value as an integer parameter
    ///
    /// This method:
    /// - Stores the completion handler for later invocation
    /// - Randomly selects a target value if none is specified
    /// - Marks the spinner for deceleration
    /// - The actual stopping occurs gradually through the display link updates
    func stopSpinning(completion: @escaping (Int) -> Void) {
        // Store the completion handler
        self.completionHandler = completion
        
        // Choose a random value if we don't already have one
        if targetValue == nil {
            targetValue = possibleValues.randomElement() ?? possibleValues[0]
        }
        
        // Mark for deceleration - will be picked up in the next display link cycle
        isDecelerating = true
    }
    
    /// invalidates and removes the display link
    /// called when animation is no longer needed
    /// prevents unnecessary CPU usage and memory leaks
    private func stopDisplayLink() {
        displayLink?.invalidate()
        displayLink = nil
    }
    
    // MARK: - Animation Update
    
    /// Updates the spinner animation for each frame
    ///
    /// This method is called by the display link for each frame update and handles:
    /// - Calculating time deltas for smooth animation
    /// - Applying different animation phases (acceleration, constant speed, deceleration)
    /// - Updating scroll position to create spinning effect
    /// - Tracking total rotation distance
    /// - Applying visual effects to labels
    /// - Special handling for dice spinner
    @objc private func updateSpinning() {
        // Get current time and calculate delta
        let currentTime = CACurrentMediaTime()
        let deltaTime = currentTime - lastUpdateTime
        lastUpdateTime = currentTime
        
        let isDice = (upgradeType == .d6)
        
        // Special debugging for dice spinner
        if isDice && currentTime - spinStartTime < 0.5 {
            print("Dice spinner updating at speed: \(spinningSpeed), offset: \(scrollView.contentOffset.y)")
        }
        
        // Animation logic
        if isDecelerating {
            // Deceleration for dice might need to be gentler
            let decelerationRate = isDice ? 0.97 : 0.95
            spinningSpeed = max(spinningSpeed * decelerationRate, 0.5)
            
            // Log dice deceleration
            if isDice && currentTime - spinStartTime.truncatingRemainder(dividingBy: 0.5) < 0.01 {
                print("Dice spinner decelerating: \(spinningSpeed)")
            }
            
            // When almost stopped, finalize position and call completion
            if spinningSpeed < 0.8 {
                if isDice {
                    print("Dice spinner stopping animation loop")
                }
                stopDisplayLink()
                finalizePosition()
                return
            }
        } else {
            // Track total distance and calculate rotations completed
            let timeElapsed = currentTime - spinStartTime
            let rotationHeight = CGFloat(possibleValues.count) * valueHeight
            
            // Dice needs more rotation cycles due to fewer values
            let minimumRotationsForType = isDice ? minimumRotations + 1 : minimumRotations
            
            totalRotationDistance += spinningSpeed
            let rotationsCompleted = totalRotationDistance / rotationHeight
            
            // Check if we've spun enough
            if rotationsCompleted >= CGFloat(minimumRotationsForType) && timeElapsed >= minimumSpinTime {
                if isDecelerating {
                    // Apply different deceleration rates based on spinner type
                    spinningSpeed *= isDice ? 0.97 : 0.95
                }
            }
            
            // Vary speed for realistic effect - different acceleration for dice
            if timeElapsed < 0.5 {
                let accelerationRate = isDice ? 1.04 : 1.05
                let maxSpeed = isDice ? 40.0 : 50.0
                spinningSpeed = min(spinningSpeed * accelerationRate, maxSpeed)
            }
        }
        
        // Update scroll position - ensure we're actually moving
        if spinningSpeed > 0.1 {
            var newOffset = scrollView.contentOffset
            newOffset.y += spinningSpeed
            
            // Handle wrapping differently for dice to avoid stopping at seams
            let contentHeight = scrollView.contentSize.height
            let visibleHeight = scrollView.bounds.height
            
            if newOffset.y >= contentHeight - visibleHeight {
                // For dice, add a small offset when wrapping to avoid exact boundary
                newOffset.y = isDice ?
                    (CGFloat(possibleValues.count) * valueHeight + 0.5) :
                    (CGFloat(possibleValues.count) * valueHeight)
            }
            
            // Apply new offset and force layout if needed
            scrollView.contentOffset = newOffset
            if isDice && currentTime - spinStartTime < 0.2 {
                scrollView.layoutIfNeeded() // Force layout update for dice spinner
            }
        }
        
        // Apply visual effects
        updateLabelEffects()
    }
    
    /// Applies visual effects to labels based on their distance from center
    ///
    /// This method:
    /// - Calculates each label's distance from the center of the view
    /// - Adjusts opacity and scale to create a focus effect on the central value
    /// - Creates a 3D-like appearance with values further from center appearing smaller
    private func updateLabelEffects() {
        // Apply visual effects to each visible label based on distance from center
        for label in valueLabels {
            let labelCenter = label.convert(label.bounds.center, to: self)
            let distanceFromCenter = abs(labelCenter.y - bounds.midY)
            let maxDistance = bounds.height / 2
            
            // Calculate scale and alpha
            let scale = 1.0 - min(distanceFromCenter / maxDistance, 0.3)
            let alpha = 1.0 - min(distanceFromCenter / maxDistance, 0.5)
            
            // Apply effects
            label.alpha = alpha
            label.transform = CGAffineTransform(scaleX: scale, y: scale)
        }
    }
    
    /// Finalizes the spinner position to show the selected value
    ///
    /// This method:
    /// - Ensures a valid target value is selected
    /// - Calculates the exact offset needed to center the target value
    /// - Animates the scroll view to the final position
    /// - Provides visual feedback by highlighting the selection indicator
    /// - Calls the completion handler with the final value
    private func finalizePosition() {
        // Ensure we have a target value
        guard let targetValue = targetValue, !possibleValues.isEmpty else {
            let defaultValue = possibleValues.first ?? 1
            print("Using default value for \(upgradeType.rawValue): \(defaultValue)")
            completionHandler?(defaultValue)
            return
        }
        
        let isDice = (upgradeType == .d6)
        if isDice {
            print("Finalizing dice position to value: \(targetValue)")
        }
        
        // Find index of target value in the middle section
        let middleSetStart = possibleValues.count
        let targetIndex = possibleValues.firstIndex(of: targetValue) ?? 0
        let finalIndex = middleSetStart + targetIndex
        let finalOffset = CGFloat(finalIndex) * valueHeight
        
        // Log the transition for dice
        if isDice {
            print("Dice final offset: \(finalOffset), current: \(scrollView.contentOffset.y)")
        }
        
        // Animate to exact position with special handling for dice
        let animationDuration = isDice ? 0.4 : 0.3 // Longer animation for dice
        UIView.animate(withDuration: animationDuration, delay: 0, options: .curveEaseOut, animations: {
            self.scrollView.contentOffset = CGPoint(x: 0, y: finalOffset)
            if isDice {
                // For dice, force layout during animation
                self.scrollView.layoutIfNeeded()
            }
        }) { _ in
            // Flash the selection indicator
            UIView.animate(withDuration: 0.3, animations: {
                self.selectionIndicator.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.5)
            }) { _ in
                UIView.animate(withDuration: 0.2) {
                    self.selectionIndicator.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.2)
                }
            }
            
            // Call completion handler
            if isDice {
                print("Dice spinner animation complete, calling completion with value: \(targetValue)")
            }
            self.completionHandler?(targetValue)
        }
    }
}

extension CGRect {
    var center: CGPoint {
        return CGPoint(x: midX, y: midY)
    }
}
