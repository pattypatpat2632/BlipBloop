//
//  FirebaseManager.swift
//  InThree
//
//  Created by Patrick O'Leary on 4/26/17.
//  Copyright © 2017 Patrick O'Leary. All rights reserved.
//

import Foundation
import FirebaseAuth
import FirebaseDatabase


//Singleton handles all authorization and user calls to Firebase
final class FirebaseManager {
    
    static let sharedInstance = FirebaseManager()
    
    let dataRef = FIRDatabase.database().reference()
    let userRef = FIRDatabase.database().reference().child("users")
    let locationRef = FIRDatabase.database().reference().child("locations")
    var allBlipUsers = [BlipUser]()
    var inviteableUsers = [BlipUser]()
    var currentBlipUser: BlipUser? = nil
    
    private init() {}
    
    func observeAllBlipUsers(completion: @escaping (FirebaseResponse) -> Void) {
        dataRef.child("users").observe(.value, with: { (snapshot) in
            self.allBlipUsers.removeAll()
            if let userDictionary = snapshot.value as? [String: [String: Any]] {
                for user in userDictionary {
                    let newBlipUser = BlipUser(uid: user.key, dictionary: user.value)
                    self.allBlipUsers.append(newBlipUser)
                }
                completion(.success("Updated all Blip users"))
            } else {
                completion(.failure("Could not observe Blip users"))
            }
            MultipeerManager.sharedInstance.updateAvailablePeers()
        })
    }
    
    func createUser(fromEmail email: String, name: String, andPassword password: String, completion: @escaping (FirebaseResponse) -> Void) {
        FIRAuth.auth()?.createUser(withEmail: email, password: password, completion: { (firUser, error) in
            if let error = error {
                completion(.failure(error.localizedDescription))
            } else {
                guard let firUser = firUser else {
                    completion(.failure("Lost connection"))
                    return
                }
                let newBlipUser = BlipUser(name: name, uid: firUser.uid, email: email, isInParty: false, invitesEnabled: false)
                self.storeNew(blipUser: newBlipUser) {
                    completion(.success("New user created: \(newBlipUser.name)"))
                    self.fetchCurrentBlipUser(uid: newBlipUser.uid, completion: nil)
                }
            }
        })
    }
    
    private func storeNew(blipUser: BlipUser, completion: () -> Void) {
        let post = [
            "name": blipUser.name,
            "email": blipUser.email,
            "invitesEnabled": blipUser.invitesEnabled,
            "isInParty": blipUser.isInParty
            ] as [String : Any]
        dataRef.child("users").child(blipUser.uid).updateChildValues(post)
        completion()
    }
    
}
//MARK: Login manager
extension FirebaseManager {
    func loginUser(fromEmail email: String, password: String, completion: @escaping (FirebaseResponse) -> Void) {
        FIRAuth.auth()?.signIn(withEmail: email, password: password, completion: { (firUser, error) in
            if let error = error {
                completion(.failure(error.localizedDescription))
            } else {
                guard let uid = firUser?.uid else {
                    completion(.failure("Could not log in user"))
                    return
                }
                self.fetchCurrentBlipUser(uid: uid, completion: {
                    completion(.success("Logged in user: \(String(describing: FirebaseManager.sharedInstance.currentBlipUser?.name))"))
                })
            }
        })
    }
 
    func logoutUser(completion: @escaping (FirebaseResponse) -> Void) {
        do {
            try FIRAuth.auth()?.signOut()
            completion(.success("Logged out user"))
        } catch {
            completion(.failure("Could not log out user"))
        }
    }
    
//checks to see if there is a current user logged in. If there is, set it to the current user property
    func checkForCurrentUser(completion: @escaping (Bool) -> Void) {
        if let uid = FIRAuth.auth()?.currentUser?.uid {
            self.fetchCurrentBlipUser(uid: uid, completion: {
                completion(true)
            })
        } else {
            completion(false)
        }
    }

    //helper function - fetches current user and sets it to current user property
    fileprivate func fetchCurrentBlipUser(uid: String, completion: (() -> Void)?) {
        userRef.child(uid).observeSingleEvent(of: .value, with: { (snapshot) in
            let userProperties = snapshot.value as? [String: Any] ?? [:]
            self.currentBlipUser = BlipUser(uid: uid, dictionary: userProperties)
            if let completion = completion {
                completion()
            }
        })
    }
    
    func resetPassword(from email: String, completion: @escaping (FirebaseResponse) -> Void) {
        FIRAuth.auth()?.sendPasswordReset(withEmail: email, completion: { (error) in
            if error == nil {
                completion(.success("Check your email to reset your password"))
            } else {
                completion(.failure("Sorry, could not reset your password"))
            }
        })
    }
}

//MARK: Local Peers Functions
extension FirebaseManager {
    
    func updateInviteable(user: BlipUser, with state: Bool) {
        userRef.child(user.uid).child("invitesEnabled").setValue(state)
    }
    
    func updateIsInParty(user: BlipUser, with state: Bool) {
        userRef.child(user.uid).child("isInParty").setValue(state)
    }
    
}




