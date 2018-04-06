//
//  NotificationManager.swift
//  otgSM
//
//  Created by Yongsung on 11/13/17.
//  Copyright © 2017 Delta. All rights reserved.
//

import UIKit
import Foundation

class NotificationManager: NSObject {
    
    public static let sharedManager = NotificationManager()
    let defaults = UserDefaults.standard
    let center = NotificationCenter.default

    override init() {
        super.init()
    }
    
    func handleTaskNotification(_ decisionActivityId: String) {
//        print(defaults.value(forKey:"lastNotified"))
        let date = Date().timeIntervalSince1970
        defaults.set(date, forKey: "lastNotified")
        defaults.set(decisionActivityId, forKey:"decisionActivityId")
        
        // get task details when gets a notification.
//        self.center.post(name: NSNotification.Name(rawValue: "getTaskNotification"), object: nil, userInfo: nil)
    }
    
    func handlePeriodicSilentPush() {
        Pretracker.sharedManager.locationManager?.startUpdatingLocation()
        if let currentLocation = Pretracker.sharedManager.currentLocation {
            let lat = currentLocation.coordinate.latitude
            let lon = currentLocation.coordinate.longitude
            let speed = currentLocation.speed
            let date = Date().timeIntervalSince1970
            let accuracy = currentLocation.horizontalAccuracy
            if let user = CURRENT_USER?.username {
                let params = ["user": user, "lat": lat, "lon": lon, "date":date, "accuracy":accuracy, "speed":speed] as [String : Any]
                CommManager.instance.urlRequest(route: "currentLocation", parameters: params, completion: {
                    json in
                    // need to add this for handling background fetch.
                })
            }
        }
    }
}
