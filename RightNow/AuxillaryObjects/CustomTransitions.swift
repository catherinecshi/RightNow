import UIKit

class CustomSlideInTransition: NSObject, UIViewControllerTransitioningDelegate {
    // Keep track of whether we're currently presenting
    private var isPresenting = true
    
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        return CustomPresentationController(presentedViewController: presented, presenting: presenting)
    }
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        isPresenting = true
        return self
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        isPresenting = false
        return self
    }
}

// Make our transition delegate also implement the animation controller
extension CustomSlideInTransition: UIViewControllerAnimatedTransitioning {
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.4
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        // Get the proper view controller and view based on whether we're presenting or dismissing
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

class CustomPresentationController: UIPresentationController {
    private let dimmingView = UIView()
    
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
    
    override func dismissalTransitionWillBegin() {
        super.dismissalTransitionWillBegin()
        
        // Fade out the dimming view with the dismissal
        presentedViewController.transitionCoordinator?.animate(alongsideTransition: { _ in
            self.dimmingView.alpha = 0
        })
    }
    
    override func containerViewWillLayoutSubviews() {
        super.containerViewWillLayoutSubviews()
        dimmingView.frame = containerView?.bounds ?? .zero
        presentedView?.frame = frameOfPresentedViewInContainerView
    }
    
    override var frameOfPresentedViewInContainerView: CGRect {
        guard let containerView = containerView else { return .zero }
        return containerView.bounds
    }
}
