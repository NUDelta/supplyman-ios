//
//  NotificationManager.swift
//  otgSM
//
//  Created by Yongsung on 11/13/17.
//  Copyright © 2017 Delta. All rights reserved.
//

import UIKit

class NotificationManager: NSObject {
    
    public static let sharedManager = NotificationManager()
    
    override init() {
        super.init()
    }
    
    func handlePeriodicSilentPush() {
        Pretracker.sharedManager.locationManager?.requestLocation()
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
            } else {
                let params = ["user": "", "lat": lat, "lon": lon, "date":date, "accuracy":accuracy, "speed":speed] as [String : Any]
                CommManager.instance.urlRequest(route: "currentLocation", parameters: params, completion: {
                    json in
                    // need to add this for handling background fetch.
                })
            }
            
        }
    }
}
