import UIKit
import Firebase
import FirebaseAuth
import FirebaseFirestore
@testable import RightNow

class MockFirebaseManager: FirebaseConfigurable {
    static let shared: FirebaseConfigurable = MockFirebaseManager()
    
    var isConfigured = false
    var configureCallCount = 0
    private var mockUser: MockUser?
    private var documentStorage: [String: Any] = [:]
    
    // Configuration to simulate errors during testing
    var shouldSimulateNetworkError = false
    var shouldSimulateAuthError = false
    var shouldSimulateSerializationError = false
    
    init() {}
    
    // MARK: - FirebaseConfigurable Protocol
    
    var auth: Auth {
        // Since we can't create a real Auth object, we'll use a trick to satisfy the protocol
        // In tests, use the methods like signIn() instead of directly accessing this
        return Auth.auth()
    }
    
    var firestore: Firestore {
        // Similar to auth, we return the real type but tests should avoid using this directly
        return Firestore.firestore()
    }
    
    var currentUserId: String? {
        return mockUser?.uid
    }
    
    func configure() {
        configureCallCount += 1
        isConfigured = true
    }
    
    // MARK: - Mock Authentication
    
    func signIn(uid: String, email: String = "test@example.com") {
        mockUser = MockUser(uid: uid, email: email)
    }
    
    func signOut() {
        mockUser = nil
    }
    
    // MARK: - Document Operations
    
    func getDocument<T: Decodable>(
        collection: String,
        subcollection: String? = nil,
        subdocument: String? = nil
    ) async throws -> T? {
        // Simulate errors for testing
        if shouldSimulateNetworkError {
            throw FirebaseError.networkError
        }
        
        if shouldSimulateAuthError {
            throw FirebaseError.userNotAuthenticated
        }
        
        guard isConfigured else {
            throw FirebaseError.notConfigured
        }
        
        guard let userId = currentUserId else {
            throw FirebaseError.userNotAuthenticated
        }
        
        let path = buildPath(collection: collection, userId: userId, subcollection: subcollection, subdocument: subdocument)
        
        guard let documentData = getDocumentAtPath(path) else {
            return nil
        }
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: documentData)
            return try JSONDecoder().decode(T.self, from: jsonData)
        } catch {
            if shouldSimulateSerializationError {
                throw FirebaseError.serializationFailed
            }
            throw FirebaseError.operationFailed(error)
        }
    }
    
    func getDocuments<T: Decodable>(
        collection: String,
        subcollection: String? = nil
    ) async throws -> [T] {
        if shouldSimulateNetworkError {
            throw FirebaseError.networkError
        }
        
        guard isConfigured else {
            throw FirebaseError.notConfigured
        }
        
        guard let userId = currentUserId else {
            throw FirebaseError.userNotAuthenticated
        }
        
        // Base path to look for documents
        let basePath: String
        if let subcollection = subcollection {
            basePath = "\(collection)/\(userId)/\(subcollection)/"
        } else {
            basePath = "\(collection)/"
        }
        
        var results: [T] = []
        
        // Find all documents that match the base path
        for (path, data) in documentStorage {
            if path.hasPrefix(basePath), let documentData = data as? [String: Any] {
                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: documentData)
                    let decodedObject = try JSONDecoder().decode(T.self, from: jsonData)
                    results.append(decodedObject)
                } catch {
                    if shouldSimulateSerializationError {
                        throw FirebaseError.serializationFailed
                    }
                    throw FirebaseError.operationFailed(error)
                }
            }
        }
        
        return results
    }
    
    func setDocument<T: Encodable>(
        data: T,
        collection: String,
        subcollection: String? = nil,
        subdocument: String? = nil
    ) async throws {
        if shouldSimulateNetworkError {
            throw FirebaseError.networkError
        }
        
        guard isConfigured else {
            throw FirebaseError.notConfigured
        }
        
        guard let userId = currentUserId else {
            throw FirebaseError.userNotAuthenticated
        }
        
        let path = buildPath(collection: collection, userId: userId, subcollection: subcollection, subdocument: subdocument)
        
        do {
            let jsonData = try JSONEncoder().encode(data)
            let dataDict = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] ?? [:]
            setDocumentAtPath(path, data: dataDict)
        } catch {
            if shouldSimulateSerializationError {
                throw FirebaseError.serializationFailed
            }
            throw FirebaseError.operationFailed(error)
        }
    }
    
    func updateDocument<T: Encodable>(
        data: T,
        collection: String,
        subcollection: String? = nil,
        subdocument: String? = nil
    ) async throws {
        if shouldSimulateNetworkError {
            throw FirebaseError.networkError
        }
        
        guard isConfigured else {
            throw FirebaseError.notConfigured
        }
        
        guard let userId = currentUserId else {
            throw FirebaseError.userNotAuthenticated
        }
        
        let path = buildPath(collection: collection, userId: userId, subcollection: subcollection, subdocument: subdocument)
        
        // Check if document exists
        guard var existingData = getDocumentAtPath(path) as? [String: Any] else {
            throw FirebaseError.documentNotFound
        }
        
        do {
            let jsonData = try JSONEncoder().encode(data)
            if let updateData = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
                // Merge the update data with existing data
                for (key, value) in updateData {
                    existingData[key] = value
                }
                setDocumentAtPath(path, data: existingData)
            }
        } catch {
            if shouldSimulateSerializationError {
                throw FirebaseError.serializationFailed
            }
            throw FirebaseError.operationFailed(error)
        }
    }
    
    func deleteDocument(
        collection: String,
        subcollection: String? = nil,
        subdocument: String? = nil
    ) async throws {
        if shouldSimulateNetworkError {
            throw FirebaseError.networkError
        }
        
        guard isConfigured else {
            throw FirebaseError.notConfigured
        }
        
        guard let userId = currentUserId else {
            throw FirebaseError.userNotAuthenticated
        }
        
        let path = buildPath(collection: collection, userId: userId, subcollection: subcollection, subdocument: subdocument)
        documentStorage.removeValue(forKey: path)
    }
    
    // MARK: - Helper Methods
    
    private func buildPath(collection: String, userId: String, subcollection: String?, subdocument: String?) -> String {
        if let subcollection = subcollection, let subdocument = subdocument {
            return "\(collection)/\(userId)/\(subcollection)/\(subdocument)"
        } else {
            return "\(collection)/\(userId)"
        }
    }
    
    private func getDocumentAtPath(_ path: String) -> [String: Any]? {
        return documentStorage[path] as? [String: Any]
    }
    
    private func setDocumentAtPath(_ path: String, data: [String: Any]) {
        documentStorage[path] = data
    }
    
    // MARK: - Testing Helpers
    
    func resetStorage() {
        documentStorage.removeAll()
    }
    
    // MARK: - Mock User
    
    class MockUser {
        let uid: String
        let email: String
        
        init(uid: String, email: String) {
            self.uid = uid
            self.email = email
        }
    }
}
