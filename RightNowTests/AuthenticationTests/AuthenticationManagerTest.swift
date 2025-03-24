import XCTest
import Combine
@testable import RightNow

class AuthenticationManagerTests: XCTestCase {
    var authManager: MockAuthenticationManager!
    var cancellables = Set<AnyCancellable>()
    
    override func setUp() {
        super.setUp()
        MockFirebaseAuth.shared.reset()
        MockGoogleSignIn.shared.reset()
        authManager = MockAuthenticationManager()
    }
    
    override func tearDown() {
        cancellables.removeAll()
        super.tearDown()
    }
    
    // MARK: - Login Tests
    
    func testLoginSuccess() {
        // Given
        let expectation = XCTestExpectation(description: "Login Success")
        var resultUser: User?
        
        // When
        authManager.login(email: "test@example.com", password: "password")
            .sink { completion in
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    XCTFail("Expected successful login but got error: \(error)")
                }
                expectation.fulfill()
            } receiveValue: { user in
                resultUser = user
            }
            .store(in: &cancellables)
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertNotNil(resultUser)
        XCTAssertEqual(resultUser?.email, "test@example.com")
        XCTAssertEqual(resultUser?.loginType, .email)
        XCTAssertFalse(resultUser?.isAnonymous ?? true)
    }
    
    func testLoginFailure() {
        // Given
        let expectation = XCTestExpectation(description: "Login Failure")
        MockFirebaseAuth.shared.shouldFailSignIn = true
        var receivedError: Error?
        
        // When
        authManager.login(email: "test@example.com", password: "wrong-password")
            .sink { completion in
                switch completion {
                case .finished:
                    XCTFail("Expected login failure but completed successfully")
                case .failure(let error):
                    receivedError = error
                }
                expectation.fulfill()
            } receiveValue: { _ in }
            .store(in: &cancellables)
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertNotNil(receivedError)
        XCTAssertEqual((receivedError as NSError?)?.domain, "auth")
    }
    
    // MARK: - Sign Up Tests
    
    func testSignUpSuccess() {
        // Given
        let expectation = XCTestExpectation(description: "Sign Up Success")
        var resultUser: User?
        
        // When
        authManager.signUp(email: "new@example.com", password: "password123")
            .sink { completion in
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    XCTFail("Expected successful sign up but got error: \(error)")
                }
                expectation.fulfill()
            } receiveValue: { user in
                resultUser = user
            }
            .store(in: &cancellables)
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertNotNil(resultUser)
        XCTAssertEqual(resultUser?.email, "new@example.com")
        XCTAssertEqual(resultUser?.loginType, .email)
        XCTAssertFalse(resultUser?.isAnonymous ?? true)
    }
    
    func testSignUpFailure() {
        // Given
        let expectation = XCTestExpectation(description: "Sign Up Failure")
        MockFirebaseAuth.shared.shouldFailSignUp = true
        var receivedError: Error?
        
        // When
        authManager.signUp(email: "existing@example.com", password: "password123")
            .sink { completion in
                switch completion {
                case .finished:
                    XCTFail("Expected sign up failure but completed successfully")
                case .failure(let error):
                    receivedError = error
                }
                expectation.fulfill()
            } receiveValue: { _ in }
            .store(in: &cancellables)
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertNotNil(receivedError)
        XCTAssertEqual((receivedError as NSError?)?.domain, "auth")
    }
    
    // MARK: - Google Sign In Tests
    
    func testGoogleSignInSuccess() {
        // Given
        let expectation = XCTestExpectation(description: "Google Sign In Success")
        var resultUser: User?
        let mockViewController = UIViewController()
        
        // When
        authManager.googleSignIn(presentingViewController: mockViewController)
            .sink { completion in
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    XCTFail("Expected successful Google sign in but got error: \(error)")
                }
                expectation.fulfill()
            } receiveValue: { user in
                resultUser = user
            }
            .store(in: &cancellables)
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertNotNil(resultUser)
        XCTAssertEqual(resultUser?.loginType, .google)
        XCTAssertFalse(resultUser?.isAnonymous ?? true)
    }
    
    func testGoogleSignInCancelled() {
        // Given
        let expectation = XCTestExpectation(description: "Google Sign In Cancelled")
        MockGoogleSignIn.shared.shouldFailSignIn = true
        var receivedError: Error?
        let mockViewController = UIViewController()
        
        // When
        authManager.googleSignIn(presentingViewController: mockViewController)
            .sink { completion in
                switch completion {
                case .finished:
                    XCTFail("Expected Google sign in failure but completed successfully")
                case .failure(let error):
                    receivedError = error
                }
                expectation.fulfill()
            } receiveValue: { _ in }
            .store(in: &cancellables)
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertNotNil(receivedError)
        XCTAssertEqual((receivedError as NSError?)?.domain, "GIDSignIn")
    }
    
    // MARK: - Anonymous Sign In Tests
    
    func testAnonymousSignInSuccess() {
        // Given
        let expectation = XCTestExpectation(description: "Anonymous Sign In Success")
        var resultUser: User?
        
        // When
        authManager.signInAnonymously()
            .sink { completion in
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    XCTFail("Expected successful anonymous sign in but got error: \(error)")
                }
                expectation.fulfill()
            } receiveValue: { user in
                resultUser = user
            }
            .store(in: &cancellables)
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertNotNil(resultUser)
        XCTAssertEqual(resultUser?.loginType, .guest)
        XCTAssertTrue(resultUser?.isAnonymous ?? false)
    }
    
    func testAnonymousSignInFailure() {
        // Given
        let expectation = XCTestExpectation(description: "Anonymous Sign In Failure")
        MockFirebaseAuth.shared.shouldFailAnonymousSignIn = true
        var receivedError: Error?
        
        // When
        authManager.signInAnonymously()
            .sink { completion in
                switch completion {
                case .finished:
                    XCTFail("Expected anonymous sign in failure but completed successfully")
                case .failure(let error):
                    receivedError = error
                }
                expectation.fulfill()
            } receiveValue: { _ in }
            .store(in: &cancellables)
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertNotNil(receivedError)
        XCTAssertEqual((receivedError as NSError?)?.domain, "auth")
    }
    
    // MARK: - Convert Anonymous User Tests
    
    func testConvertAnonymousUserWithEmailSuccess() {
        // Given
        let expectation = XCTestExpectation(description: "Convert Anonymous User Success")
        var resultUser: User?
        MockFirebaseAuth.shared.currentUser = MockFirebaseUser(uid: "anon-uid", email: nil, isAnonymous: true, providers: [])
        
        // When
        authManager.convertAnonymousUserWithEmail(email: "converted@example.com", password: "password123")
            .sink { completion in
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    XCTFail("Expected successful conversion but got error: \(error)")
                }
                expectation.fulfill()
            } receiveValue: { user in
                resultUser = user
            }
            .store(in: &cancellables)
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertNotNil(resultUser)
        XCTAssertEqual(resultUser?.email, "linked@example.com")
        XCTAssertEqual(resultUser?.loginType, .email)
        XCTAssertFalse(resultUser?.isAnonymous ?? true)
    }
    
    func testConvertAnonymousUserWithEmailFailure_NotAnonymous() {
        // Given
        let expectation = XCTestExpectation(description: "Convert Non-Anonymous User Failure")
        MockFirebaseAuth.shared.currentUser = MockFirebaseUser(uid: "regular-uid", email: "existing@example.com", isAnonymous: false, providers: ["password"])
        var receivedError: Error?
        
        // When
        authManager.convertAnonymousUserWithEmail(email: "new@example.com", password: "password123")
            .sink { completion in
                switch completion {
                case .finished:
                    XCTFail("Expected conversion failure but completed successfully")
                case .failure(let error):
                    receivedError = error
                }
                expectation.fulfill()
            } receiveValue: { _ in }
            .store(in: &cancellables)
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertNotNil(receivedError)
        XCTAssertEqual((receivedError as NSError?)?.domain, "RightNow.AuthError")
    }
    
    // MARK: - Sign Out Tests
    
    func testSignOutSuccess() {
        // Given
        let expectation = XCTestExpectation(description: "Sign Out Success")
        MockFirebaseAuth.shared.currentUser = MockFirebaseUser(uid: "user-uid", email: "user@example.com", isAnonymous: false, providers: ["password"])
        
        // When
        authManager.signOut()
            .sink { completion in
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    XCTFail("Expected successful sign out but got error: \(error)")
                }
                expectation.fulfill()
            } receiveValue: { _ in }
            .store(in: &cancellables)
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertNil(MockFirebaseAuth.shared.currentUser)
    }
    
    func testSignOutFailure() {
        // Given
        let expectation = XCTestExpectation(description: "Sign Out Failure")
        MockFirebaseAuth.shared.shouldFailSignOut = true
        var receivedError: Error?
        
        // When
        authManager.signOut()
            .sink { completion in
                switch completion {
                case .finished:
                    XCTFail("Expected sign out failure but completed successfully")
                case .failure(let error):
                    receivedError = error
                }
                expectation.fulfill()
            } receiveValue: { _ in }
            .store(in: &cancellables)
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertNotNil(receivedError)
        XCTAssertEqual((receivedError as NSError?)?.domain, "auth")
    }
    
    // MARK: - Anonymous to Google Tests
    
    func testConvertAnonymousUserWithGoogleAsync() async {
        // Given
        // Set up anonymous user in mock auth
        MockFirebaseAuth.shared.currentUser = MockFirebaseUser(uid: "anon-uid", email: nil, isAnonymous: true, providers: [])
        let mockViewController = await UIViewController()
        
        // When
        do {
            let resultUser = try await authManager.convertAnonymousUserWithGoogle(presentingViewController: mockViewController)
            
            // Then
            XCTAssertEqual(resultUser.email, "linked@example.com")
            XCTAssertEqual(resultUser.loginType, .google)
            XCTAssertFalse(resultUser.isAnonymous)
        } catch {
            XCTFail("Expected successful conversion but got error: \(error)")
        }
    }
    
    func testConvertAnonymousUserWithGoogleAsyncFailure() async {
        // Given
        // Set up anonymous user in mock auth
        MockFirebaseAuth.shared.currentUser = MockFirebaseUser(uid: "anon-uid", email: nil, isAnonymous: true, providers: [])
        MockGoogleSignIn.shared.shouldFailSignIn = true
        let mockViewController = await UIViewController()
        
        // When/Then
        do {
            _ = try await authManager.convertAnonymousUserWithGoogle(presentingViewController: mockViewController)
            XCTFail("Expected failure but conversion succeeded")
        } catch {
            XCTAssertEqual((error as NSError).domain, "google")
        }
    }
}
