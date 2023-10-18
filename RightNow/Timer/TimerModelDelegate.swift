import Foundation

protocol TimerModelDelegate: AnyObject {
    func timerModelDidUpdateTime(_ timerModel: TimerModel)
}
