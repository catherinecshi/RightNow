import Foundation

/// Utility structure for formatting time-related operations
enum TimeFormatter {
    // MARK: - Static Properties
    /// Array of 3 letter abbreviations for days of the week
    static let allDays = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    
    // MARK: - Private Formatters
    /// Formatter configured for 'yyyy-MM-dd' date strings
    /// Converts between Date and Strings
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
    /// Formatter configured for 3 letter abbreviations for weekdays
    /// Converts between Date and weekday Strings
    private static let weekdayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter
    }()
    
    // MARK: - Conversions
    /// Converts a date to its 3-letter weekday abbreviation
    static func weekdayToString(_ date: Date) -> String {
        return weekdayFormatter.string(from: date)
    }
    
    /// Converts a 3-letter weekday string to a Date
    /// Note that there are missing information in the resulting Date
    static func stringToWeekday(_ string: String) -> Date? {
        return weekdayFormatter.date(from: string)
    }
    
    /// Converts a date to a string in 'yyyy-MM-dd' format
    static func dateToString(_ date: Date) -> String {
        return dateFormatter.string(from: date)
    }
    
    /// Converts a string in 'yyyy-MM-dd' format to a Date
    static func stringToDate(_ string: String) -> Date? {
        return dateFormatter.date(from: string)
    }
    
    /// Converts a weekday index to its 3-letter weekday
    /// 1 is Sunday
    static func intToWeekdayString(fromWeekday weekday: Int) -> String {
        return allDays[weekday - 1] // minus 1 since weekday is a 1-based index
    }
    
    /// Converts a 3-letter weekday to corresponding Int
    /// 1 is Sunday
    static func weekdayStringToInt(from string: String) -> Int? {
        return allDays.firstIndex(of: string).map { $0 + 1 }
    }
    
    /// Takes a 3-letter weekday and finds next Date with that weekday
    static func weekdayToDate(_ weekdayString: String) -> Date? {
        guard let weekdayIndex = allDays.firstIndex(of: weekdayString) else {
            return nil
        }
        
        let calendar = Calendar.current
        let today = Date()
        let todayWeekday = calendar.component(.weekday, from: today)
        let targetWeekday = weekdayIndex + 1 // because weekday is 1-based index
        
        var dateComponents = calendar.dateComponents([.year, .month, .day], from: today)
        dateComponents.weekday = targetWeekday
        
        if let date = calendar.nextDate(after: today, matching: dateComponents, matchingPolicy: .nextTime) {
            return date
        }
        
        return nil
    }
    
    /// Creates a date form specific hour and minute components
    /// Resulting Date uses current day
    ///
    /// Parameters:
    /// - hour : hour component from 0 - 23
    /// - minute : minute component from 0 - 59
    ///
    /// Returns:
    /// - date with specified hour and minute
    ///     - nil if conversion fails
    static func hourMinuteToDate(hour: Int, minute: Int) -> Date? {
        let calendar = Calendar.current
        let currentDate = Date()
        
        let components = calendar.dateComponents([.year, .month, .day], from: currentDate)
        
        var dateComponents = DateComponents()
        dateComponents.year = components.year
        dateComponents.month = components.month
        dateComponents.day = components.day
        dateComponents.hour = hour
        dateComponents.minute = minute
        
        return calendar.date(from: dateComponents)
    }
    
    // MARK: - Helper Functions
    /// Returns 3-letter abbreviation of current day
    static func getTodayWeekday() -> String {
        return weekdayToString(Date())
    }
    
    /// Returns true if two dates occur on the same calendar day
    static func isSameDay(_ date1: Date, _ date2: Date) -> Bool {
        let calendar = Calendar.current
        return calendar.isDate(date1, inSameDayAs: date2)
    }
    
    /// Returns true if date is the current date (like today)
    static func isToday(_ date: Date) -> Bool {
        return isSameDay(date, Date())
    }
    
    /// Returns true if the sub's weekday settings is a subset of the whole
    static func isSubsetOfDays(sub: [String: Bool], whole: [String: Bool]) -> Bool {
        for (day, isEnabled) in sub {
            // if this day is true in sub, it must also be true in whole
            if isEnabled && !(whole[day] ?? false) {
                return false
            }
        }
        
        return true
    }
}
