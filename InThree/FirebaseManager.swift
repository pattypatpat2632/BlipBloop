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
    let locationRef = FIRDatabase.database().reference().child("locations")
    var allBlipUsers = [BlipUser]()
    var inviteableUsers = [BlipUser]()
    
    var allLocationScores = [Score]()
    var currentBlipUser: BlipUser? = nil
    var locationDelegate: LocationManagerDelegate?
    
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
                    self.fetchCurrentBlipUser(uid: newBlipUser.uid, completion: {
                    })
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
                    completion(.success("Logged in user: \(FirebaseManager.sharedInstance.currentBlipUser?.name)"))
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
    
    func checkForCurrentUser(completion: @escaping (Bool) -> Void) {
        print("checking if there is a current user logged in")
        if let uid = FIRAuth.auth()?.currentUser?.uid {
            self.fetchCurrentBlipUser(uid: uid, completion: {
                completion(true)
            })
        } else {
            completion(false)
        }
    }
    
    fileprivate func fetchCurrentBlipUser(uid: String, completion: @escaping () -> Void) {
        userRef.child(uid).observeSingleEvent(of: .value, with: { (snapshot) in
            let userProperties = snapshot.value as? [String: Any] ?? [:]
            self.currentBlipUser = BlipUser(uid: uid, dictionary: userProperties)
            completion()
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

//MARK: City mode functions
extension FirebaseManager {
    
    func send(score: Score, toUUID uuid: String) {
        guard let uid = FIRAuth.auth()?.currentUser?.uid else {return}
        locationRef.child(uuid).child(uid).updateChildValues(score.asDictionary())
    }
    
    func observeAllScoresIn(locationID lid: String) {
        locationRef.observe(.value, with: { (snapshot) in
            self.allLocationScores.removeAll()
            let allLocations = snapshot.value as? [String: Any] ?? [:]
            for location in allLocations {
                if location.key == lid {
                    let allUsersInLocation = location.value as? [String: Any] ?? [:]
                    for user in allUsersInLocation {
                        if user.key != self.currentBlipUser?.uid {
                            let scoreDict = user.value as? [String: Any] ?? [:]
                            if let newScore = Score(dictionary: scoreDict) {
                                self.allLocationScores.append(newScore)
                            }
                        }
                    }
                }
            }
            self.locationDelegate?.updateLocationScores()
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

protocol LocationManagerDelegate {
    func updateLocationScores()
}




