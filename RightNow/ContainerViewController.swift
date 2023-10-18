import UIKit

class ContainerViewController: UIViewController {
    var viewControllers: [UIViewController] = []
    var currentIndex: Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //add camera view
        let cameraVC = CameraController()
        viewControllers.append(cameraVC)
        
        //add clock view
        let clockVC = TimerController()
        viewControllers.append(clockVC)
        
        //add more here
        
        //show first view controller
        updateDisplayedViewController(at: currentIndex)
    }
    
    func updateDisplayedViewController(at index: Int) {
        for vc in children {
            vc.willMove(toParent: nil)
            vc.view.removeFromSuperview()
            vc.removeFromParent()
        }
        
        let vc = viewControllers[index]
        addChild(vc)
        vc.view.frame = view.bounds
        view.addSubview(vc.view)
        vc.didMove(toParent: self)
    }
    
    //call this to move to the next view controller
    func moveToNextViewController() {
        currentIndex += 1
        if currentIndex >= viewControllers.count {
            currentIndex = 0
        }
        updateDisplayedViewController(at: currentIndex)
    }
    
    //previous view controller
    func moveToPreviousViewController() {
        currentIndex -= 1
        if currentIndex < 0 {
            currentIndex = viewControllers.count - 1
        }
        
        updateDisplayedViewController(at: currentIndex)
    }
}
