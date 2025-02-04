import Foundation
import UIKit

class MaowViewController: UIViewController {
    private var imageView = UIImageView()
    private var isFirstImage = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        setupImageView()
        
        // add tap gesture recognizer
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        view.addGestureRecognizer(tapGesture)
    }
    
    private func setupImageView() {
        if let frontImage = UIImage(named: "patamon_front") {
            print("Successfully loaded patamon front")
            imageView.image = frontImage
        } else {
            print("Failed to load patamon front")
        }
        
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(imageView)
        
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            imageView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.3),
            imageView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.3)
        ])
    }
    
    @objc private func handleTap() {
        // create new image
        guard let newImage = UIImage(named: isFirstImage ? "patamon_asleep" : "patamon_front") else {
            print("failed to load image for transition")
            return
        }
        
        // perform animation
        UIView.transition(with: imageView,
                          duration: 0.2,
                          options: .transitionCrossDissolve,
                          animations: { [weak self] in
            self?.imageView.image = newImage
        })
        
        isFirstImage.toggle()
    }
}
