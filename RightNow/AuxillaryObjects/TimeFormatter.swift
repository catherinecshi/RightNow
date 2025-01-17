import Foundation

enum TimeFormatter {
    // MARK: - Static Properties
    static let allDays = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    
    // MARK: - Private Formatters
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
    private static let weekdayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter
    }()
    
    // MARK: - Conversions
    static func weekdayToString(_ date: Date) -> String {
        return weekdayFormatter.string(from: date)
    }
    
    static func stringToWeekday(_ string: String) -> Date? {
        return weekdayFormatter.date(from: string)
    }
    
    static func dateToString(_ date: Date) -> String {
        return dateFormatter.string(from: date)
    }
    
    static func stringToDate(_ string: String) -> Date? {
        return dateFormatter.date(from: string)
    }
    
    static func intToWeekdayString(fromWeekday weekday: Int) -> String {
        return allDays[weekday - 1] // minus 1 since weekday is a 1-based index
    }
    
    static func weekdayStringToInt(from string: String) -> Int? {
        return allDays.firstIndex(of: string).map { $0 + 1 }
    }
    
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
    static func getTodayWeekday() -> String {
        return weekdayToString(Date())
    }
    
    static func isSameDay(_ date1: Date, _ date2: Date) -> Bool {
        let calendar = Calendar.current
        return calendar.isDate(date1, inSameDayAs: date2)
    }
    
    static func isToday(_ date: Date) -> Bool {
        return isSameDay(date, Date())
    }
    
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
