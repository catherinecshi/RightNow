import UIKit
import PhotosUI
import AVFoundation
import Firebase

class CameraController: UIViewController, CameraViewDelegate, CameraModelDelegate {
    private var cameraModel = CameraModel()
    private var cameraView = CameraView()
    
    var habit: Habit!
    
    // MARK: Lifecycle Methods
    
    init(habit: Habit) {
        self.habit = habit
        super.init(nibName: nil, bundle: nil)
    }
    
    // Required initializer when subclassing UIViewController
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        
        //title
        title = "RightNow"
        navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        
        // permission for camera
        requestAccessToCamera { granted in
            if granted {
                self.cameraModel.startSession()
                
                //configure cameraView with session
                if let session = self.cameraModel.captureSession {
                    self.cameraView.configureCamera(with: session)
                }
            } else {
                print("Camera permission is denied.")
                self.showCameraPermissionDeniedAlert()
            }
        }
        
        //delegates
        cameraModel.delegate = self
        cameraView.delegate = self
        
        //add view
        view.addSubview(cameraView)
        setupCameraViewConstraints()
    }
    
    //for resetting the capturesession if the user cancels phototakenvc and renavigates back
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        cameraModel.startSession()
    }
    
    //stop capture session when view disappears
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        cameraModel.stopSession()
    }
    
    // MARK: View Constraints
    private func setupCameraViewConstraints() {
        cameraView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            cameraView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            cameraView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            cameraView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            cameraView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }
    
    // MARK: Request Access
    
    //access granted 11/9/2023
    func requestAccessToCamera(completion: @escaping (Bool) -> Void) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: //grants access
            completion(true)
        case .notDetermined: //not yet been asked for access
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    completion(granted)
                }
            }
        case .denied, .restricted:
            completion(false)
        default:
            completion(false)
        }
    }
    
    func showCameraPermissionDeniedAlert() {
        let alert = UIAlertController(title: "Camera Access Denied", message: "The camera is essential for this feature. Please enable camera access in Settings", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        alert.addAction(UIAlertAction(title: "Settings", style: .default, handler: { _ in
            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsURL)
            }
        }))
        
        present(alert, animated: true)
    }
    
    // MARK: CameraModel Methods
    
    func cameraModel(_ model: CameraModel, didCapturePhotoData photoData: Data?) {
        //handle captured image data, update UI, navigate to next screen here
        
        if let data = photoData, let image = UIImage(data: data) {
            cameraView.previewImageView.image = image
            let photoTakenVC = PhotoTakenViewController()
            photoTakenVC.previewImageView.image = image
            self.navigationController?.pushViewController(photoTakenVC, animated: true)
        }
    }
    
    func cameraModel(_ model: CameraModel, didFailToCaptureImageWithError error: Error) {
        //handle error, update UI, show alerts, etc
        print("failed to capture image: \(error)")
        
        let alertController = UIAlertController(title: "Error", message: "Failed to capture image", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)
        
        //additional error handling?
    }
    
    // MARK: Delegate Methods
    
    func cameraViewDidTapCapture(_ view: CameraView) {
        cameraModel.capturePhoto()
    }
    
    func cameraViewDidTapSwitchCamera(_ view: CameraView) {
        cameraModel.switchCamera()
    }
    
    func cameraViewDidDismiss(_ view: CameraView) {
        self.dismiss(animated: true, completion: nil)
    }
}

/*
 extension CameraController: AVCapturePhotoCaptureDelegate {
 func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
 guard let imageData = photo.fileDataRepresentation(),
 let image = UIImage(data: imageData) else {
 print("Error capturing photo: \(String(describing: error))")
 return
 }
 
 // ... (use image as needed)
 }
 }
 */
