//
//  Config.swift
//  otgSM
//
//  Created by Yongsung on 11/14/17.
//  Copyright © 2017 Delta. All rights reserved.
//

import UIKit

struct Config {
    static let DEBUG = false
    static var URL = ""
    public static let sharedConfig = Config()
    
    init() {
        if Config.DEBUG {
            Config.URL = "http://10.105.184.224:5000"
        } else {
            Config.URL = "http://supplyman.herokuapp.com"
        }
    }
}
