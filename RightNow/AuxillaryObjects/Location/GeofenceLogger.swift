import Foundation

/// Persistent logging capabilities for geofence-related operations
///
/// Writes timestamped log entries to text file in app's documents directory
/// Allows for debugging even across app launches and environments with no printing
///
/// # Features:
/// - Centralized logging for geofence operations
/// - Timestamp prefixing for all log entries
/// - Persistent storage of logs across app sessions
/// - Methods to clear logs and retrieve full log contents
///
/// # Example Usage:
/// ```swift
/// // Log a geofence event
/// GeofenceLogger.shared.log("Started monitoring geofence: Coffee Shop")
///
/// // Retrieve all logs for debugging
/// let logContents = GeofenceLogger.shared.getLogContents()
/// print(logContents)
///
/// // Clear logs when no longer needed
/// GeofenceLogger.shared.clearLog()
/// `
class GeofenceLogger {
    static let shared = GeofenceLogger()
    private let logFileName = "geofence_log.txt"
    
    /// Returns computed URL for log file in app's documents directory
    /// Returns nil if file cannot be accessed
    private var logFileURL: URL? {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent(logFileName)
    }
    
    /// Logs a message with the current timestamp to the geofence log file.
    ///
    /// The message is appended to the existing log file or creates a new file if none exists.
    /// Each log entry is formatted as: "{timestamp}: {message}\n"
    ///
    /// Parameters:
    /// - message : String
    ///     - the message to be logged
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
    
    /// Removes log file
    func clearLog() {
        guard let logFileURL = logFileURL else { return }
        try? FileManager.default.removeItem(at: logFileURL)
    }
    
    /// Returns a string containing all current log entries
    /// Returns "No log file found" if no current entries
    func getLogContents() -> String {
        guard let logFileURL = logFileURL,
              let contents = try? String(contentsOf: logFileURL, encoding: .utf8) else {
            return "No log file found"
        }
        return contents
    }
}
