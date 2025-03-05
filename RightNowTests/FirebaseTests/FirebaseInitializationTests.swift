import XCTest
@testable import RightNow

class FirebaseInitializationTests: XCTestCase {
    var mockFirebaseManager: MockFirebaseManager!
    var appDelegate: AppDelegate!
    
    override func setUp() {
        super.setUp()
        mockFirebaseManager = MockFirebaseManager()
        
        // inject the mock into appdelegate
        appDelegate = AppDelegate()
        appDelegate.firebaseManager = mockFirebaseManager
        
        // inject the mock into habit data service
        HabitDataService.firebaseManager = mockFirebaseManager
    }
    
    override func tearDown() {
        //FatalErrorUtil.restoreFatalError()
        super.tearDown()
    }
    
    func testFirebaseConfiguredBeforeFirestoreAccess() {
        // simulate app startup
        let application = UIApplication.shared
        
        // trigger firebase configuration
        _ = appDelegate.application(application, didFinishLaunchingWithOptions: nil)
        
        // verify firebase was configured
        XCTAssertTrue(mockFirebaseManager.isConfigured, "Firebase should be configured during app launch")
        XCTAssertEqual(mockFirebaseManager.configureCallCount, 1, "Firebase should only be configured once")
        
        // try to access habit data service to verify it doesn't crash
        let habitService = HabitDataService.shared
        XCTAssertNoThrow(habitService.loadHabitsLocally(), "Should not throw error from habit service")
    }
    
    /*
    func testFirestoreAccessBeforeFirebaseConfiguration() {
        // reset mock to unconfigured state
        mockFirebaseManager.isConfigured = false
        
        HabitDataService.firebaseManager = mockFirebaseManager
        
        // forcibly access firestore before configuration - make sure it leads to fatal error
        XCTAssertFatalError(expectedMessage: "Firebase must be configured before accessing Firestore") {
            let habitService = HabitDataService.shared
            
            // force access to dbproperty (expose it for testing)
            _ = habitService.forceDatabaseAccess()
        }
    }
     */
}

/*
 extension XCTestCase {
 func XCTAssertFatalError(expectedMessage: String = "",
 file: StaticString = #file,
 line: UInt = #line,
 testCase: @escaping () -> Void) {
 // expectation for fatal error
 let expectation = self.expectation(description: "Fatal error occurred")
 var actualMessage: String? = nil
 
 // replace fatalError implementation
 FatalErrorUtil.replaceFatalError { message, _, _ in
 actualMessage = message
 expectation.fulfill()
 InfiniteLoop.run()
 }
 
 // run code that should trigger fatalError in background thread
 DispatchQueue.global(qos: .userInitiated).async {
 testCase()
 }
 
 waitForExpectations(timeout: 5.0) { error in
 if let error = error {
 XCTFail("Test timed out: \(error)", file: file, line: line)
 }
 }
 
 // check message if expected
 if !expectedMessage.isEmpty {
 XCTAssertEqual(actualMessage, expectedMessage, "Fatal error didn't match expected message", file: file, line: line)
 }
 }
 }
 */
