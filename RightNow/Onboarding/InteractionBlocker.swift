/// A blank transparent view that can be placed on top of anything and will block user interactions with the view.
import UIKit

class InteractionBlocker {
    static let shared = InteractionBlocker()
    private var blockingView: UIView?
    
    func blockInteractions(on rootView: UIView) async {
        await MainActor.run {
            // create view
            let blocker = UIView(frame: rootView.bounds)
            blocker.backgroundColor = .clear
            blocker.isUserInteractionEnabled = true
            blocker.tag = 999 // for identification
            
            // add on top of hierarchy
            rootView.addSubview(blocker)
            
            blocker.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                blocker.topAnchor.constraint(equalTo: rootView.topAnchor),
                blocker.leadingAnchor.constraint(equalTo: rootView.leadingAnchor),
                blocker.trailingAnchor.constraint(equalTo: rootView.trailingAnchor),
                blocker.bottomAnchor.constraint(equalTo: rootView.bottomAnchor)
            ])
            
            self.blockingView = blocker
        }
    }
    
    func unblockInteractions() async {
        await blockingView?.removeFromSuperview()
        blockingView = nil
    }
}
