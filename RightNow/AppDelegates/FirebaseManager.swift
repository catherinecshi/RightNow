import UIKit
import Firebase
import FirebaseAuth
import FirebaseFirestore

enum FirebaseError: Error {
    case notConfigured
    case userNotAuthenticated
    case networkError
    case documentNotFound
    case serializationFailed
    case operationFailed(Error)
}

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

class FirebaseManager: FirebaseConfigurable {
    static let shared: FirebaseConfigurable = FirebaseManager()
    
    enum FirestoreCollection: String {
        case habits = "habits"
        
        static var allCollections: [FirestoreCollection] {
            return [.habits]
        }
    }
    
    private(set) var isConfigured = false
    
    private init() {}
    
    var auth: Auth {
        guard isConfigured else {
            fatalError("Firebase must be configured before accessing it")
        }
        return Auth.auth()
    }
    
    var firestore: Firestore {
        guard isConfigured else {
            fatalError("Firebase must be configured before accessing it")
        }
        return Firestore.firestore()
    }
    
    var currentUserId: String? {
        return auth.currentUser?.uid
    }
    
    func configure() {
        guard !isConfigured else { return }
        FirebaseApp.configure()
        isConfigured = true
        
        Task {
            //Database.database().isPersistenceEnabled = true
        }
    }
    
    // MARK: - Firestore Operations
    
    func getDocument<T: Decodable>(
        collection: String,
        subcollection: String? = nil,
        subdocument: String? = nil
    ) async throws -> T? where T : Decodable {
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
    
    // MARK: - Debugging
    #if DEBUG
    func forceDatabaseAccess() -> Firestore {
        return firestore
    }
    #endif
}
