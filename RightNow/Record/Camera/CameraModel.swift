import Foundation
import AVFoundation
import UIKit

class CameraModel: NSObject {
    weak var delegate: CameraModelDelegate?
    
    var captureSession: AVCaptureSession?
    var photoOutput: AVCapturePhotoOutput?
    
    //initialisation
    override init() {
        super.init()
        setupCaptureSession()
    }
    
    //setup and manage capture session and photo output
    private func setupCaptureSession() {
        captureSession = AVCaptureSession()
        captureSession?.sessionPreset = .photo
        
        //add inputs
        if let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .unspecified),
           let cameraInput = try? AVCaptureDeviceInput(device: camera),
           captureSession?.canAddInput(cameraInput) == true {
            captureSession?.addInput(cameraInput)
        }
        
        //add outputs
        photoOutput = AVCapturePhotoOutput()
        if let photoOutput = photoOutput, captureSession?.canAddOutput(photoOutput) == true {
            captureSession?.addOutput(photoOutput)
        }
    }
    
    func startSession() {
        if captureSession?.isRunning == false {
            //user initiated is a quality of service
            DispatchQueue.global(qos: .userInitiated).async {
                self.captureSession?.startRunning()
            }
        }
    }
    
    func stopSession() {
        if captureSession?.isRunning == true {
            captureSession?.stopRunning()
        }
    }
    
    //button methods
    func capturePhoto() {
        let settings = AVCapturePhotoSettings()
        photoOutput?.capturePhoto(with: settings, delegate: self)
        
        //delegate?.cameraModel(self, didCapturePhoto: capturedImage)
    }
    
    func switchCamera() {
        if let currentInput = captureSession?.inputs.first as? AVCaptureDeviceInput {
            let newCameraPosition: AVCaptureDevice.Position = currentInput.device.position == .front ? .back : .front
            setupCameraPosition(for: newCameraPosition)
        }
    }
    
    private func setupCameraPosition(for position: AVCaptureDevice.Position) {
        guard let session = captureSession else {
            print("no capture session available")
            return
        }
        
        session.beginConfiguration()
        
        for input in session.inputs {
            session.removeInput(input)
        }
        
        //find a new camera
        guard let newCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position) else {
            print("Camera not available for position: \(position)")
            session.commitConfiguration()
            return
        }
        
        //add a new input
        do {
            let newInput = try AVCaptureDeviceInput(device: newCamera)
            if session.canAddInput(newInput) {
                session.addInput(newInput)
            } else {
                print("Cannot add new input: \(newInput) to session: \(session)")
            }
        } catch {
            print("Error adding camera input: \(error)")
        }
        
        //commit changes
        session.commitConfiguration()
    }
}

extension CameraModel: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        /*
        if let error = error {
            delegate?.cameraModel(self, didFailToCaptureImageWithError: error)
            return
        }
         */
        
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            print("Error capturing photo: \(String(describing: error))")
            return
        }
        
        delegate?.cameraModel(self, didCapturePhotoData: imageData)
    }
}

