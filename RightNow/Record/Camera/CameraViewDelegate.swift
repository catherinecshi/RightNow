import Foundation

protocol CameraViewDelegate: AnyObject {
    func cameraViewDidTapCapture(_ view: CameraView)
    func cameraViewDidTapSwitchCamera(_ view: CameraView)
    func cameraViewDidDismiss(_ view: CameraView)
}
