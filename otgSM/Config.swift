//
//  Config.swift
//  otgSM
//
//  Created by Yongsung on 11/14/17.
//  Copyright © 2017 Delta. All rights reserved.
//

import UIKit

struct Config {
    static let DEBUG = true
    static var URL = ""
    public static let sharedConfig = Config()
    
    init() {
        if Config.DEBUG {
            Config.URL = "http://10.105.201.112:5000"
//            Config.URL = "http://supplyman-datacollection.herokuapp.com"
        } else {
            Config.URL = "http://supplyman-datacollection.herokuapp.com"
        }
    }
}
