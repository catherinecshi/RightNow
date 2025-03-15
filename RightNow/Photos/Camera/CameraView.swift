import UIKit
import AVFoundation

protocol CameraViewDelegate: AnyObject {
    func cameraViewDidTapCapture(_ view: CameraView)
    func cameraViewDidTapSwitchCamera(_ view: CameraView)
    func cameraViewDidDismiss(_ view: CameraView)
}

class CameraView: UIView {
    weak var delegate: CameraViewDelegate?
    
    // MARK: - variables
    // image view
    var previewLayer: AVCaptureVideoPreviewLayer?
    
    var previewImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.backgroundColor = .lightGray
        return imageView
    }()
    
    // button to take photo
    lazy var captureButton: UIButton = {
        let button = UIButton(type: .system) // Creates a standard system button
        button.setTitle("Capture", for: .normal)
        button.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 5
        button.addTarget(self, action: #selector(captureButtonTapped), for: .touchUpInside)
        return button
    }()
    
    // switch camera
    lazy var switchCameraButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Switch", for: .normal)
        button.setImage(UIImage(systemName: "arrow.triangle.2.circlepath.camera")?.withTintColor(.white, renderingMode: .alwaysOriginal), for: .normal)
        button.backgroundColor = .clear
        button.layer.cornerRadius = 5
        button.addTarget(self, action: #selector(switchCameraButtonTapped), for: .touchUpInside)
        return button
    }()
    
    // dismiss button
    lazy var dismissButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("x", for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 24)
        button.setTitleColor(.white, for: .normal)
        button.addTarget(self, action: #selector(dismissSelf), for: .touchUpInside)
        return button
    }()
    
    // MARK: - Initialisation
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        //setup subviews
        setupDismissButton()
        setupCaptureButton()
        setupSwitchCameraButton()
        setupPreviewImageView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - setup UI
    // called when view's bounds changes
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // update frame of preview layer after changes
        previewLayer?.frame = previewImageView.bounds
    }
    
    // for camera + preview layer
    func configureCamera(with session: AVCaptureSession) {
        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer?.videoGravity = .resizeAspectFill
        previewLayer?.frame = previewImageView.bounds
        previewImageView.layer.addSublayer(previewLayer!)
    }
    
    // for handling bound changes
    func updatePreviewLayerFrame() {
        previewImageView.layer.layoutIfNeeded()
        previewLayer?.frame = previewImageView.bounds
    }
    
    private func setupPreviewImageView() {
        addSubview(previewImageView)
        
        previewImageView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            previewImageView.topAnchor.constraint(equalTo: dismissButton.bottomAnchor, constant: 10),
            previewImageView.bottomAnchor.constraint(equalTo: self.safeAreaLayoutGuide.bottomAnchor, constant: -120),
            previewImageView.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            
            // encompasses whole screen
            previewImageView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            previewImageView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            
        ])
        
        let cornerRadius: CGFloat = 15.0
        previewImageView.layer.cornerRadius = cornerRadius
        previewImageView.clipsToBounds = true
    }
    
    // setting up capture button
    func setupCaptureButton() {
        addSubview(captureButton)
        
        // auto layout
        captureButton.translatesAutoresizingMaskIntoConstraints = false
        
        // make button circle
        let buttonSize: CGFloat = 70
        
        captureButton.layer.cornerRadius = buttonSize / 2
        captureButton.setTitle(nil, for: .normal) //removing title
        captureButton.backgroundColor = UIColor.white
        captureButton.setImage(UIImage(named: "cameraIcon"), for: .normal)
        
        // constraints
        NSLayoutConstraint.activate([
            captureButton.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            captureButton.bottomAnchor.constraint(equalTo: self.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            captureButton.widthAnchor.constraint(equalToConstant: buttonSize),
            captureButton.heightAnchor.constraint(equalToConstant: buttonSize)
        ])
    }
    
    // setting up switch button
    func setupSwitchCameraButton() {
        addSubview(switchCameraButton)
        
        switchCameraButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            switchCameraButton.leadingAnchor.constraint(equalTo: captureButton.trailingAnchor, constant: 30),
            switchCameraButton.centerYAnchor.constraint(equalTo: captureButton.centerYAnchor),
            switchCameraButton.widthAnchor.constraint(equalToConstant: 50),
            switchCameraButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    // setting up dismissal button
    func setupDismissButton() {
        addSubview(dismissButton)
        
        dismissButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            dismissButton.topAnchor.constraint(equalTo: self.safeAreaLayoutGuide.topAnchor, constant: 10),
            dismissButton.leadingAnchor.constraint(equalTo: self.safeAreaLayoutGuide.leadingAnchor, constant: 10),
            dismissButton.widthAnchor.constraint(equalToConstant: 40),
            dismissButton.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
    
    // MARK: - Delegate Methods
    @objc private func captureButtonTapped() {
        delegate?.cameraViewDidTapCapture(self)
    }
    
    @objc private func switchCameraButtonTapped() {
        delegate?.cameraViewDidTapSwitchCamera(self)
    }
    
    @objc func dismissSelf() {
        delegate?.cameraViewDidDismiss(self)
    }
}
