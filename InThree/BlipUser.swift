//
//  BlipUser.swift
//  InThree
//
//  Created by Patrick O'Leary on 4/26/17.
//  Copyright © 2017 Patrick O'Leary. All rights reserved.
//

import Foundation

//Model for BlipBloop user
struct BlipUser {
    
    let name: String
    let uid: String
    let email: String
    var isInParty: Bool = false
    var invitesEnabled: Bool = false
}
//MARK: database functions
extension BlipUser {
    
    init(uid: String, dictionary: [String: Any]) {
        self.uid = uid
        self.name = dictionary["name"] as? String ?? "No Name"
        self.email = dictionary["email"] as? String ?? "No Email"
        self.invitesEnabled = dictionary["invitesEnabled"] as? Bool ?? false
        self.isInParty = dictionary["isInParty"] as? Bool ?? false
    }
    
    init?(jsonData: Data) {
        do {
            guard let json = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: [String: String]] else {return nil}
            self.init(dictionary: json)
        } catch {
            return nil
        }
    }
    
    init?(dictionary: [String: [String: Any]]) {
        guard let uid = dictionary.keys.first else {return nil}
        self.uid = uid
        let properties = dictionary[uid] ?? [:]
        self.name = properties["name"] as? String ?? "No name"
        self.email = properties["email"] as? String ?? "No email"
        self.invitesEnabled = properties["invitesEnabled"] as? Bool ?? false
        self.isInParty = properties["isInParty"] as? Bool ?? false
    }
    
    func jsonData() -> Data? {
        let jsonDict = self.asDictionary()
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: jsonDict, options: [])
            return jsonData
        } catch {
            print("unable to write user as JSON data")
            return nil
        }
    }
    
    func asDictionary() -> [String: Any] {
        let dictionary: [String: Any] = [
            self.uid: [
                "name": self.name,
                "email": self.email,
                "isInParty": self.isInParty,
                "invitesEnabled": self.invitesEnabled
            ]
        ]
        return dictionary
    }
}
