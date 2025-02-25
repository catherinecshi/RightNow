import UIKit
import CoreML
import Vision
import AVFoundation

class ObjectDetectionViewController: UIViewController {
    var habitData = HabitData()
    private var frameCounter = 0
    
    private let videoPreviewLayer = AVCaptureVideoPreviewLayer()
    private let captureSession = AVCaptureSession()
    
    private var detectionBoxes: [UIView] = []
    private var objectDetectionModel: VNCoreMLModel?
    
    private lazy var previewView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupObjectDetection()
        setupCamera()
        debugBundle()
    }
    
    private func setupUI() {
        view.addSubview(previewView)
        
        NSLayoutConstraint.activate([
            previewView.topAnchor.constraint(equalTo: view.topAnchor),
            previewView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            previewView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            previewView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        videoPreviewLayer.frame = view.bounds
        previewView.layer.addSublayer(videoPreviewLayer)
    }
    
    private func setupCamera() {
        // check authorization status
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            self.configureCaptureSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted {
                    DispatchQueue.main.async {
                        self.configureCaptureSession()
                    }
                }
            }
        case .denied, .restricted:
            let alert = CustomAlertViewController(title: "Camera Access Required", message: "Please enable camera access in Settings")
            
            DispatchQueue.main.async {
                self.present(alert, animated: true)
            }
        @unknown default:
            break
        }
    }
    
    private func configureCaptureSession() {
        captureSession.beginConfiguration()
        
        captureSession.sessionPreset = .high
        
        guard let backCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            print("Failed to get back camera")
            captureSession.commitConfiguration()
            return
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: backCamera)
            
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
            } else {
                print("Could not add camera input to session")
                captureSession.commitConfiguration()
                return
            }
            
            let videoOutput = AVCaptureVideoDataOutput()
            videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
            
            if captureSession.canAddOutput(videoOutput) {
                captureSession.addOutput(videoOutput)
                
                if let connection = videoOutput.connection(with: .video) {
                    connection.videoOrientation = .portrait
                    connection.isVideoMirrored = false
                }
            } else {
                print("Could not add video output to session")
                captureSession.commitConfiguration()
                return
            }
            
            videoPreviewLayer.session = captureSession
            videoPreviewLayer.videoGravity = .resizeAspectFill
            
            captureSession.commitConfiguration()
            
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.captureSession.startRunning()
            }
            
            // ensure video preview layer is right size
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.videoPreviewLayer.frame = self.previewView.bounds
            }
        } catch {
            print("Error setting up camera input: \(error.localizedDescription)")
            captureSession.commitConfiguration()
        }
    }
    
    private func setupObjectDetection() {
        print("📱 Attempting to load YOLOv8 model...")
        guard let modelURL = Bundle.main.url(forResource: "yolov8s", withExtension: "mlmodelc") else {
            print("❌ Error: yolov8s.mlmodel not found in Bundle")
            return
        }
        
        do {
            let model = try MLModel(contentsOf: modelURL)
            objectDetectionModel = try VNCoreMLModel(for: model)
            print("Vision model created successfully")
        } catch {
            print("Error loading model: \(error.localizedDescription)")
            
            // try with .mlmodel insetad of .mlmodelc bc it seems weird
            if let sourceModelURL = Bundle.main.url(forResource: "yolov8s", withExtension: "mlmodel") {
                do {
                    print("attempting to compile and load model from .mlmodel")
                    let compiledUrl = try MLModel.compileModel(at: sourceModelURL)
                    let model = try MLModel(contentsOf: compiledUrl)
                    objectDetectionModel = try VNCoreMLModel(for: model)
                    
                    print("Vision model compiled and created from .mlmodel")
                } catch {
                    print("Error compiling and loading model: \(error.localizedDescription)")
                }
            } else {
                print("No .mlmodel file found either")
            }
        }
    }
    
    private func processDetections(_ detections: [VNRecognizedObjectObservation]) {
        print("Processing \(detections.count) detections for UI")
        
        // remove previous detection boxes
        detectionBoxes.forEach { $0.removeFromSuperview() }
        detectionBoxes.removeAll()
        
        var visibleDetections = 0
        
        let confidenceThreshold: Float = 0.7
        let highConfidenceDetections = detections.filter { $0.confidence > confidenceThreshold }
        let finalDetections = applyNonMaximumSuppression(to: highConfidenceDetections)
        
        for detection in finalDetections {
            let box = detection.boundingBox
            
            visibleDetections += 1
            let label = detection.labels.first?.identifier ?? "Unknown"
            print("adding box for \(label) at \(box) with confidence \(detection.confidence)")
            
            let boxView = createBoxView(for: box, label: detection.labels.first?.identifier ?? "Unknown")
            previewView.addSubview(boxView)
            detectionBoxes.append(boxView)
        }
        
        print("added \(visibleDetections) detection boxes to view")
        
        // check if everythign is just being filtered out because of confidence
        if detections.count > 0 && visibleDetections == 0 {
            print("All \(detections.count) detections were filtered due to confidence threshold")
        }
    }
    
    // this takes overlapping boxes and removes the one that has a lower confidence value
    private func applyNonMaximumSuppression(to detections: [VNRecognizedObjectObservation],
                                            overlapThreshold: Float = 0.1) -> [VNRecognizedObjectObservation] {
        // highest to lowest confidence
        let sortedDetections = detections.sorted { $0.confidence > $1.confidence }
        var selected: [VNRecognizedObjectObservation] = []
        
        for detection in sortedDetections {
            var shouldSelect = true
            
            for selectedDetection in selected {
                let overlap = calculateIoU(detection.boundingBox, selectedDetection.boundingBox)
                if overlap > overlapThreshold {
                    shouldSelect = false
                    break
                }
            }
            
            if shouldSelect {
                selected.append(detection)
            }
        }
        
        return selected
    }
    
    private func calculateIoU(_ boxA: CGRect, _ boxB: CGRect) -> Float {
        let intersection = boxA.intersection(boxB)
        let intersectionArea = intersection.width * intersection.height
        
        let unionArea = (boxA.width * boxA.height) +
                        (boxB.width * boxB.height) -
                        intersectionArea
        
        return unionArea > 0 ? Float(intersectionArea / unionArea) : 0
    }
    
    private func createBoxView(for boundingBox: CGRect, label: String) -> UIView {
        let boxView = UIView()
        boxView.layer.borderColor = UIColor.green.cgColor
        boxView.layer.borderWidth = 2
        boxView.frame = VNImageRectForNormalizedRect(boundingBox,
                                                     Int(previewView.frame.width),
                                                     Int(previewView.frame.height))
        
        let labelView = UILabel()
        labelView.text = label
        labelView.textColor = .white
        labelView.backgroundColor = .green
        labelView.sizeToFit()
        boxView.addSubview(labelView)
        
        return boxView
    }
    
    private func debugBundle() {
        print("Application Bundle Path: \(Bundle.main.bundlePath)")
        
        // List all files in the bundle
        if let enumerator = FileManager.default.enumerator(atPath: Bundle.main.bundlePath) {
            var mlmodels: [String] = []
            var mlmodelcs: [String] = []
            
            for case let file as String in enumerator {
                if file.hasSuffix(".mlmodel") {
                    mlmodels.append(file)
                }
                if file.hasSuffix(".mlmodelc") {
                    mlmodelcs.append(file)
                }
            }
            
            print("MLModel files in bundle: \(mlmodels)")
            print("Compiled MLModel files in bundle: \(mlmodelcs)")
        }
    }
}

extension ObjectDetectionViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // avoid flooding the console
        frameCounter += 1
        
        // print every 30 frames (~1s)
        let shouldLog = frameCounter % 10000 == 0
        if shouldLog {
            print("Processing frame #\(frameCounter)")
        }
        
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            print("Failed to get pixel buffer from sample buffer")
            return
        }
        
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .right)
        
        guard let visionModel = objectDetectionModel else {
            if shouldLog {
                print("Vision model not available")
            }
            return
        }
        
        let request = VNCoreMLRequest(model: visionModel) { [weak self] request, error in
            if let error = error {
                print("Vision request error: \(error.localizedDescription)")
                return
            }
            
            let observations = request.results as? [VNRecognizedObjectObservation] ?? []
            
            if !observations.isEmpty {
                print("Detected \(observations.count) objects!")
                for (index, observation) in observations.enumerated() {
                    if let label = observation.labels.first?.identifier {
                        print("   - Object #\(index): \(label) (confidence: \(observation.confidence))")
                    }
                }
            } else if shouldLog {
                print("No objects detected in this frame")
            }
            
            DispatchQueue.main.async {
                self?.processDetections(request.results as? [VNRecognizedObjectObservation] ?? [])
            }
        }
        
        request.imageCropAndScaleOption = .scaleFit
        
        do {
            try imageRequestHandler.perform([request])
        } catch {
            print("Failed to perform image request: \(error.localizedDescription)")
        }
    }
}
