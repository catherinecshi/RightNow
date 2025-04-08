import UIKit
import Firebase
import FirebaseAuth
import FirebaseFirestore

/// Defines possible errors that can occur during Firebase operations
enum FirebaseError: Error {
    case notConfigured // Firebase has not been configured yet
    case userNotAuthenticated // no authenticated user for operation
    case networkError
    case documentNotFound // couldn't find requested document
    case serializationFailed // failed to serialize or deserialize data
    case operationFailed(Error) // specific underlying error
}

/// Defines Firebase configuration and operations
protocol FirebaseConfigurable {
    var isConfigured: Bool { get }
    var auth: Auth { get }
    var firestore: Firestore { get }
    var currentUserId: String? { get }
    
    func configure()
    
    func getDocument<T: Decodable>(
        collection: String,
        subcollection: String?,
        subdocument: String?
    ) async throws -> T?
    
    func getDocuments<T: Decodable>(
        collection: String,
        subcollection: String?
    ) async throws -> [T]
    
    // replaces the entire document with new data (or creates it if it doesn't exist)
    func setDocument<T: Encodable>(
        data: T,
        collection: String,
        subcollection: String?,
        subdocument: String?
    ) async throws
    
    // updates just a couple of specified fields in the file
    func updateDocument<T: Encodable>(
        data: T,
        collection: String,
        subcollection: String?,
        subdocument: String?
    ) async throws
    
    func deleteDocument(
        collection: String,
        subcollection: String?,
        subdocument: String?
    ) async throws
}

/// Manages all firebase operations
///
/// # Features:
/// - Get a specific habit
/// - Get all habits
/// - Update habits
/// - Set habit
/// - Delete a specific habit
///
/// - Retry logic
/// - Error handling
/// - Consistent API
class FirebaseManager: FirebaseConfigurable {
    static let shared: FirebaseConfigurable = FirebaseManager()
    
    /// Defines all collection names
    enum FirestoreCollection: String {
        case users = "users"
        
        static var allCollections: [FirestoreCollection] {
            return [.users]
        }
    }
    
    private(set) var isConfigured = false
    
    private init() {}
    
    /// Firebase authentication service
    var auth: Auth {
        guard isConfigured else {
            fatalError("Firebase must be configured before accessing it")
        }
        return Auth.auth()
    }
    
    /// Firebase firestore service
    var firestore: Firestore {
        guard isConfigured else {
            fatalError("Firebase must be configured before accessing it")
        }
        return Firestore.firestore()
    }
    
    /// Returns current authenticated user ID, if available
    var currentUserId: String? {
        return auth.currentUser?.uid
    }
    
    /// Configures firebase services for use
    func configure() {
        guard !isConfigured else { return }
        FirebaseApp.configure()
        isConfigured = true
    }
    
    // MARK: - Firestore Operations
    /// Retrieves a document from Firestore and decodes it to specified type
    ///
    /// Creates docRef from parameters and tries to retrieve document with exponential backoff
    ///
    /// - Parameters:
    ///     - collections: Firestore collection to query
    ///     - subcollection: Optional subcollection within a user document
    ///     - subdocument: Optional document ID within subcollection
    ///
    /// - Returns: decoded document or nil if not found
    /// - Throws: FirebaseError if the operation fails after retries
    func getDocument<T: Decodable>(
        collection: String,
        subcollection: String? = nil,
        subdocument: String? = nil
    ) async throws -> T? where T: Decodable {
        guard isConfigured else {
            throw FirebaseError.notConfigured
        }
        
        guard let userId = currentUserId else {
            throw FirebaseError.userNotAuthenticated
        }
        
        // get user document
        let docRef: DocumentReference
        
        if let subcollection = subcollection,
           let subdocument = subdocument {
            docRef = firestore.collection(collection)
                              .document(userId)
                              .collection(subcollection)
                              .document(subdocument)
        } else {
            docRef = firestore.collection(collection).document(userId)
        }
        
        let maxRetries: Int = 3
        var currentRetry = 0
        var lastError: Error? = nil
        
        while currentRetry <= maxRetries {
            do {
                let document = try await docRef.getDocument()
                
                if document.exists, let data = document.data() {
                    let jsonData = try JSONSerialization.data(withJSONObject: data)
                    return try JSONDecoder().decode(T.self, from: jsonData)
                } else {
                    return nil
                }
            } catch {
                lastError = error
                currentRetry += 1
                
                if currentRetry <= maxRetries {
                    // wait in exponential manner
                    let delay = pow(2.0, Double(currentRetry))
                    try await Task.sleep(nanoseconds: 1_000_000_000 * UInt64(delay))
                }
            }
        }
        
        if let error = lastError {
            throw FirebaseError.operationFailed(error)
        }
        
        return nil
    }
    
    /// Retrieves a collection from Firestore and decodes it to specified type
    ///
    /// Creates docRef from parameters and tries to retrieve document with exponential backoff
    ///
    /// - Parameters:
    ///     - collections: Firestore collection to query
    ///     - subcollection: Optional subcollection within a user document
    ///
    /// - Returns: An array of decoded documents
    /// - Throws: FirebaseError if the operation fails after retries
    func getDocuments<T: Decodable>(
        collection: String,
        subcollection: String? = nil
    ) async throws -> [T] {
        guard isConfigured else {
            throw FirebaseError.notConfigured
        }
        
        guard let userId = currentUserId else {
            throw FirebaseError.userNotAuthenticated
        }
        
        let colRef: CollectionReference
        
        if let subcollection = subcollection {
            colRef = firestore.collection(collection)
                              .document(userId)
                              .collection(subcollection)
        } else {
            colRef = firestore.collection(collection)
        }
        
        let maxRetries: Int = 3
        var currentRetry = 0
        var lastError: Error? = nil
        
        while currentRetry <= maxRetries {
            do {
                let snapshot = try await colRef.getDocuments()
                var results: [T] = []
                
                for document in snapshot.documents {
                    let jsonData = try JSONSerialization.data(withJSONObject: document.data())
                    let decodedObject = try JSONDecoder().decode(T.self, from: jsonData)
                    results.append(decodedObject)
                }
                
                return results
            } catch {
                lastError = error
                currentRetry += 1
                
                if currentRetry <= maxRetries {
                    // Exponential backoff
                    let delay = TimeInterval(pow(2.0, Double(currentRetry)))
                    try await Task.sleep(nanoseconds: 1_000_000_000 * UInt64(delay))
                }
            }
        }
        
        if let error = lastError {
            throw FirebaseError.operationFailed(error)
        }
        
        return []
    }
    
    /// Replaces entire documents with new data
    ///
    /// Creates docRef from parameters and tries to retrieve document with exponential backoff
    ///
    /// - Parameters:
    ///     - data: The data to store
    ///     - collections: Firestore collection
    ///     - subcollection: Optional subcollection within a user document
    ///     - subdocument: Optional document ID within subcollection
    ///
    /// - Throws: FirebaseError if the operation fails after retries
    func setDocument<T: Encodable>(
        data: T,
        collection: String,
        subcollection: String? = nil,
        subdocument: String? = nil
    ) async throws where T : Encodable {
        guard isConfigured else {
            throw FirebaseError.notConfigured
        }
        
        guard let userId = currentUserId else {
            throw FirebaseError.userNotAuthenticated
        }
        
        // get user document
        let docRef: DocumentReference
        
        if let subcollection = subcollection,
           let subdocument = subdocument {
            docRef = firestore.collection(collection)
                              .document(userId)
                              .collection(subcollection)
                              .document(subdocument)
        } else {
            docRef = firestore.collection(collection).document(userId)
        }
        
        let maxRetries: Int = 3
        var currentRetry = 0
        var lastError: Error? = nil
        
        while currentRetry <= maxRetries {
            do {
                let jsonData = try JSONEncoder().encode(data)
                var dataDict = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] ?? [:]
                
                // Handle nil values for Firestore
                for (key, value) in dataDict {
                    if value is NSNull {
                        dataDict[key] = NSNull()
                    }
                }
                
                try await docRef.setData(dataDict)
                return
            } catch {
                lastError = error
                currentRetry += 1
                
                if currentRetry <= maxRetries {
                    // Exponential backoff
                    let delay = TimeInterval(pow(2.0, Double(currentRetry)))
                    try await Task.sleep(nanoseconds: 1_000_000_000 * UInt64(delay))
                }
            }
        }
        
        if let error = lastError {
            throw FirebaseError.operationFailed(error)
        }
    }
    
    /// Updates specific fields with provided data
    ///
    /// Creates docRef from parameters and tries to retrieve document with exponential backoff
    ///
    /// - Parameters:
    ///     - data: The fields to update
    ///     - collections: Firestore collection to query
    ///     - subcollection: Optional subcollection within a user document
    ///     - subdocument: Optional document ID within subcollection
    ///
    /// - Throws: FirebaseError if the operation fails after retries
    func updateDocument<T: Encodable>(
        data: T,
        collection: String,
        subcollection: String?,
        subdocument: String?
    ) async throws where T : Encodable {
        guard isConfigured else {
            throw FirebaseError.notConfigured
        }
        
        guard let userId = currentUserId else {
            throw FirebaseError.userNotAuthenticated
        }
        
        let docRef: DocumentReference
        
        if let subcollection = subcollection,
           let subdocument = subdocument {
            docRef = firestore.collection(collection)
                              .document(userId)
                              .collection(subcollection)
                              .document(subdocument)
        } else {
            docRef = firestore.collection(collection).document(userId)
        }
        
        let maxRetries: Int = 3
        var currentRetry = 0
        var lastError: Error? = nil
            
        while currentRetry <= maxRetries {
            do {
                let jsonData = try JSONEncoder().encode(data)
                var dataDict = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] ?? [:]
                
                // Handle nil values for Firestore
                for (key, value) in dataDict {
                    if value is NSNull {
                        dataDict[key] = NSNull()
                    }
                }
                
                try await docRef.updateData(dataDict)
                return
            } catch {
                lastError = error
                currentRetry += 1
                
                if currentRetry <= maxRetries {
                    // Exponential backoff
                    let delay = TimeInterval(pow(2.0, Double(currentRetry)))
                    try await Task.sleep(nanoseconds: 1_000_000_000 * UInt64(delay))
                }
            }
        }
        
        if let error = lastError {
            throw FirebaseError.operationFailed(error)
        }
    }
    
    /// Deletes a specified document from Firestore
    ///
    /// Creates docRef from parameters and tries to retrieve document with exponential backoff
    ///
    /// - Parameters:
    ///     - collections: Firestore collection to query
    ///     - subcollection: Optional subcollection within a user document
    ///     - subdocument: Optional document ID within subcollection
    ///
    /// - Throws: FirebaseError if the operation fails after retries
    func deleteDocument(
        collection: String,
        subcollection: String? = nil,
        subdocument: String? = nil
    ) async throws {
        guard isConfigured else {
            throw FirebaseError.notConfigured
        }
        
        guard let userId = currentUserId else {
            throw FirebaseError.userNotAuthenticated
        }
        
        let documentRef: DocumentReference
        
        if let subcollection = subcollection, let subdocument = subdocument {
            documentRef = firestore.collection(collection)
                                   .document(userId)
                                   .collection(subcollection)
                                   .document(subdocument)
        } else {
            documentRef = firestore.collection(collection).document(userId)
        }
        
        let maxRetries: Int = 3
        var currentRetry = 0
        var lastError: Error? = nil
        
        while currentRetry <= maxRetries {
            do {
                try await documentRef.delete()
                return
            } catch {
                lastError = error
                currentRetry += 1
                
                if currentRetry <= maxRetries {
                    // Exponential backoff
                    let delay = TimeInterval(pow(2.0, Double(currentRetry)))
                    try await Task.sleep(nanoseconds: 1_000_000_000 * UInt64(delay))
                }
            }
        }
        
        if let error = lastError {
            throw FirebaseError.operationFailed(error)
        }
    }
}
