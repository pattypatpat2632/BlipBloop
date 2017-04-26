//
//  BlipUser.swift
//  InThree
//
//  Created by Patrick O'Leary on 4/26/17.
//  Copyright © 2017 Patrick O'Leary. All rights reserved.
//

import Foundation

struct BlipUser {
    
    let name: String
    let userName: String
    let email: String
    
}

extension BlipUser {
    
    init(dictionary: [String: Any]) {
        self.name = dictionary["name"] as? String ?? "No Name"
        self.userName = dictionary["userName"] as? String ?? "No User Name"
        self.email = dictionary["email"] as? String ?? "No Email"
    }
}
