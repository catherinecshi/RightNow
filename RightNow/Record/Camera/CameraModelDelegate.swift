import Foundation
import UIKit

protocol CameraModelDelegate: AnyObject {
    func cameraModel(_ model: CameraModel, didCapturePhotoData photoData: Data?)
}
