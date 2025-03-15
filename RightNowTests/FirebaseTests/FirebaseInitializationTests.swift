import XCTest
@testable import RightNow

class FirebaseInitializationTests: XCTestCase {
    var mockFirebaseManager: MockFirebaseManager!
    var habitDataService: HabitDataService!
    var appDelegate: AppDelegate!
    
    override func setUp() {
        super.setUp()
        mockFirebaseManager = MockFirebaseManager()
        
        habitDataService = HabitDataService(firebaseManager: mockFirebaseManager)
        
        // inject the mock into appdelegate
        appDelegate = AppDelegate()
        appDelegate.firebaseManager = mockFirebaseManager
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
        
        Task {
            do {
                let habits = try await habitService.loadHabitsLocally()
            } catch {
                XCTFail("loadHabitsLocally() threw an unexpected error: \(error)")
            }
        }
    }
}
