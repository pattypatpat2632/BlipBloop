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

final class FirebaseManager {
    
    static let sharedInstance = FirebaseManager()
    
    let dataRef = FIRDatabase.database().reference()
    let userRef = FIRDatabase.database().reference().child("users")
    var allBlipUsers = [BlipUser]()
    var currentBlipUser: BlipUser? = nil
    
    private init() {}
    
    private func observeAllBlipUsers(completion: @escaping (FirebaseResponse) -> Void) {
        dataRef.child("users").observe(.value, with: { (snapshot) in
            self.allBlipUsers.removeAll()
            if let userDictionary = snapshot.value as? [String: Any] {
                for key in userDictionary.keys {
                    let propertyDictionary = userDictionary[key] as? [String: Any] ?? [:]
                    let newBlipUser = BlipUser(uid: key, dictionary: propertyDictionary)
                    self.allBlipUsers.append(newBlipUser)
                }
                completion(.success("Updated all Blip users"))
            } else {
                completion(.failure("Could not observe Blip users"))
            }
        })
    }
    
    func createUser(fromEmail email: String, name: String, andPassword password: String, completion: @escaping (FirebaseResponse) -> Void) {
        print("create user called")
        FIRAuth.auth()?.createUser(withEmail: email, password: password, completion: { (firUser, error) in
            print("response from attempt to create user received")
            guard let firUser = firUser else {completion(.failure("Could not create new user")); return} //TODO: handle possibility off different error types eg. invalid email or password
            let newBlipUser = BlipUser(name: name, uid: firUser.uid, email: email)
            self.storeNew(blipUser: newBlipUser) {
                completion(.success("New user created: \(newBlipUser.name)"))
                self.observeCurrentBlipUser(uid: newBlipUser.uid, completion: {
                    print("Observing current blip user: \(self.currentBlipUser?.uid)")
                })
                
            }
        })
    }
    
    private func storeNew(blipUser: BlipUser, completion: () -> Void) {
        let post = [
            "name": blipUser.name,
            "email": blipUser.email
        ]
        dataRef.child("users").child(blipUser.uid).updateChildValues(post)
        completion()
    }
    
}
//MARK: Login manager
extension FirebaseManager {
    func loginUser(fromEmail email: String, password: String, completion: @escaping (FirebaseResponse) -> Void) {
        FIRAuth.auth()?.signIn(withEmail: email, password: password, completion: { (firUser, error) in
            if error == nil {
                guard let uid = firUser?.uid else {
                    completion(.failure("Could not log in user"))
                    return
                }
                self.observeCurrentBlipUser(uid: uid, completion: {
                    completion(.success("Login successful for user: \(FirebaseManager.sharedInstance.currentBlipUser?.name ?? "No Name")"))
                })
            } else {
                completion(.failure("Could not log in user"))
            }
        })
    }
    
    func checkForCurrentUser(completion: @escaping (Bool) -> Void) {
        guard let uid = FIRAuth.auth()?.currentUser?.uid else {
            completion(false)
            return
        }
        self.observeCurrentBlipUser(uid: uid) { 
            completion(true)
        }
    }
    
    fileprivate func observeCurrentBlipUser(uid: String, completion: @escaping () -> Void) {
        userRef.child("uid").observe(.value, with: { (snapshot) in
            let userProperties = snapshot.value as? [String: Any] ?? [:]
            self.currentBlipUser = BlipUser(uid: uid, dictionary: userProperties)
            completion()
        })
    }
}
