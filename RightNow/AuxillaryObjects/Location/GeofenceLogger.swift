import Foundation

class GeofenceLogger {
    static let shared = GeofenceLogger()
    private let logFileName = "geofence_log.txt"
    
    private var logFileURL: URL? {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent(logFileName)
    }
    
    func log(_ message: String) {
        guard let logFileURL = logFileURL else { return }
        
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .medium)
        let logMessage = "\(timestamp): \(message)\n"
        
        if let data = logMessage.data(using: .utf8) {
            if FileManager.default.fileExists(atPath: logFileURL.path) {
                if let fileHandle = try? FileHandle(forWritingTo: logFileURL) {
                    fileHandle.seekToEndOfFile()
                    fileHandle.write(data)
                    fileHandle.closeFile()
                }
            } else {
                try? data.write(to: logFileURL)
            }
        }
    }
    
    func clearLog() {
        guard let logFileURL = logFileURL else { return }
        try? FileManager.default.removeItem(at: logFileURL)
    }
    
    func getLogContents() -> String {
        guard let logFileURL = logFileURL,
              let contents = try? String(contentsOf: logFileURL, encoding: .utf8) else {
            return "No log file found"
        }
        return contents
    }
}
