import UIKit

/// Handles custom slide-in animations for presenting VCs
/// Presentation controller & animation controllers
class CustomSlideInTransition: NSObject, UIViewControllerTransitioningDelegate {
    // Keep track of whether we're currently presenting
    private var isPresenting = true
    
    /// Returns a custom presentation controller to manage the dimming background effect.
    /// - Parameters:
    ///   - presented: The view controller being presented.
    ///   - presenting: The view controller that is presenting.
    ///   - source: The view controller that initiated the presentation.
    /// - Returns: A custom presentation controller instance.
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        return CustomPresentationController(presentedViewController: presented, presenting: presenting)
    }
    
    /// Provides an animation controller for the presentation transition.
    /// - Parameters:
    ///   - presented: The view controller being presented.
    ///   - presenting: The view controller that is presenting.
    ///   - source: The view controller that initiated the presentation.
    /// - Returns: This instance as the animation controller.
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        isPresenting = true
        return self
    }
    
    /// Provides an animation controller for the dismissal transition.
    /// - Parameter dismissed: The view controller being dismissed.
    /// - Returns: This instance as the animation controller.
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        isPresenting = false
        return self
    }
}

// MARK: - Animation Controller Implementation

/// Extension that implements the animation controller methods for CustomSlideInTransition.
extension CustomSlideInTransition: UIViewControllerAnimatedTransitioning {
    /// Specifies the duration of the transition animation.
    /// - Parameter transitionContext: The context containing information about the transition.
    /// - Returns: The duration in seconds.
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.4
    }
    
    /// Performs the transition animation.
    /// For presentation: slides the view in from the left to the center.
    /// For dismissal: slides the view out to the left.
    /// - Parameter transitionContext: The context containing information about the transition.
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        // Get the container view from the transition context
        let containerView = transitionContext.containerView
        
        if isPresenting {
            // PRESENTING ANIMATION
            guard let toVC = transitionContext.viewController(forKey: .to),
                  let toView = transitionContext.view(forKey: .to) else {
                transitionContext.completeTransition(false)
                return
            }
            
            // Add the view to the hierarchy
            containerView.addSubview(toView)
            
            // Set initial position - off screen to the left
            toView.frame = containerView.bounds
            toView.transform = CGAffineTransform(translationX: -containerView.bounds.width, y: 0)
            
            // Animate in from left to center
            UIView.animate(withDuration: transitionDuration(using: transitionContext),
                           delay: 0,
                           usingSpringWithDamping: 0.8,
                           initialSpringVelocity: 0.0,
                           options: [.curveEaseInOut],
                           animations: {
                toView.transform = .identity
            }, completion: { finished in
                transitionContext.completeTransition(finished)
            })
        } else {
            // DISMISSING ANIMATION
            guard let fromVC = transitionContext.viewController(forKey: .from),
                  let fromView = transitionContext.view(forKey: .from) else {
                transitionContext.completeTransition(false)
                return
            }
            
            // Animate out to the left (not down)
            UIView.animate(withDuration: transitionDuration(using: transitionContext),
                           delay: 0,
                           usingSpringWithDamping: 0.8,
                           initialSpringVelocity: 0.0,
                           options: [.curveEaseInOut],
                           animations: {
                // This is the critical part - animate BACK to the left
                fromView.transform = CGAffineTransform(translationX: -containerView.bounds.width, y: 0)
            }, completion: { finished in
                // Only remove from superview after the animation finishes
                if finished {
                    fromView.removeFromSuperview()
                }
                transitionContext.completeTransition(finished)
            })
        }
    }
}

/// A custom presentation controller that manages a dimming background effect during presentation.
class CustomPresentationController: UIPresentationController {
    /// The view that dims the background content during presentation.
    private let dimmingView = UIView()
    
    /// Called when the presentation transition is about to begin.
    /// Sets up and animates in the dimming view.
    override func presentationTransitionWillBegin() {
        super.presentationTransitionWillBegin()
        
        // Set up a semi-transparent black background
        dimmingView.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        dimmingView.alpha = 0
        containerView?.insertSubview(dimmingView, at: 0)
        dimmingView.frame = containerView?.bounds ?? .zero
        
        // Fade in the dimming view with the presentation
        presentedViewController.transitionCoordinator?.animate(alongsideTransition: { _ in
            self.dimmingView.alpha = 1
        })
    }
    
    /// Called when the dismissal transition is about to begin.
    /// Animates out the dimming view.
    override func dismissalTransitionWillBegin() {
        super.dismissalTransitionWillBegin()
        
        // Fade out the dimming view with the dismissal
        presentedViewController.transitionCoordinator?.animate(alongsideTransition: { _ in
            self.dimmingView.alpha = 0
        })
    }
    
    /// Called when the container view layout is about to change.
    /// Updates the frames of the dimming view and the presented view.
    override func containerViewWillLayoutSubviews() {
        super.containerViewWillLayoutSubviews()
        dimmingView.frame = containerView?.bounds ?? .zero
        presentedView?.frame = frameOfPresentedViewInContainerView
    }
    
    /// Returns the frame rectangle to use when positioning the presented view.
    /// In this implementation, the presented view occupies the entire container view.
    override var frameOfPresentedViewInContainerView: CGRect {
        guard let containerView = containerView else { return .zero }
        return containerView.bounds
    }
}
