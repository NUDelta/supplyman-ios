//
//  User.swift
//  otgSM
//
//  Created by Yongsung on 11/13/17.
//  Copyright © 2017 Delta. All rights reserved.
//

import UIKit

class User: NSObject {
    let username: String
    let tokenId: String
    init(username: String, tokenId: String) {
        self.username = username
        self.tokenId = tokenId
    }
}
