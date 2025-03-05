/// For testing purposes only. Utility to override the default fatalError during unit tests
import Foundation

// store original fatalError to be reinserted later
private let originalFatalError: (String, StaticString, UInt) -> Never = { message, file, line in
    Swift.fatalError(message, file: file, line: line)
}

// override the global fatalerror
func fatalError(_ message: @autoclosure () -> String = "", file: StaticString = #file, line: UInt = #line) -> Never {
    let msg = message()
    print("custom fatal error called with message: \(msg)")
    FatalErrorUtil.fatalErrorClosure(message(), file, line)
}

struct FatalErrorUtil {
    static var fatalErrorClosure: (String, StaticString, UInt) -> Never = originalFatalError // replace original
    private static var isOverridden = false // flag to make sure replacement doesn't happen more than once
    
    static func replaceFatalError(with replacement: @escaping (String, StaticString, UInt) -> Never) {
        guard !isOverridden else { return }
        fatalErrorClosure = replacement
        isOverridden = true
    }
    
    static func restoreFatalError() {
        guard isOverridden else { return }
        fatalErrorClosure = originalFatalError
        isOverridden = false
    }
}

enum InfiniteLoop {
    static func run() -> Never {
        repeat {
            RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
        } while true
    }
}
