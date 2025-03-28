import Foundation
import Combine
import FirebaseAuth

protocol AuthAPI {
    func login(email: String, password: String) -> Future<User?, Never>
    func signUp(email: String, password: String) -> Future<User?, Never>
    func signInAnonymously() -> Future<User?, Never>
}

class AuthService: AuthAPI {
    func login(email: String, password: String) -> Future<User?, Never> {
        return Future<User?, Never> { promise in
            Auth.auth().signIn(withEmail: email, password: password) {(authResult, _) in
                guard let id = authResult?.user.uid,
                    let email = authResult?.user.email else {
                        promise(.success(nil))
                        return
                }
                let user = User(id: id, email: email)
                promise(.success(user))
            }
        }
    }
    
    func signUp(email: String, password: String) -> Future<User?, Never> {
        return Future<User?, Never> { promise in
            Auth.auth().createUser(withEmail: email, password: password) { (authResult, _) in
                guard let id = authResult?.user.uid,
                    let email = authResult?.user.email else {
                        promise(.success(nil))
                        return
                }
                let user = User(id: id, email: email)
                promise(.success(user))
            }
        }
    }
    
    func signInAnonymously() -> Future<User?, Never> {
        return Future<User?, Never> { promise in
            Auth.auth().signInAnonymously { (authResult, error) in
                guard let id = authResult?.user.uid else {
                    promise(.success(nil))
                    return
                }
                
                let email = authResult?.user.email ?? ""
                let user = User(id: id, email: email, isAnonymous: true)
                promise(.success(user))
            }
        }
    }
}
