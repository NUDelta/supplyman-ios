//
//  Pretracker.swift
//  otgSM
//
//  Created by Yongsung on 3/10/18.
//  Copyright © 2018 Delta. All rights reserved.
//

import Foundation
import UIKit
import CoreLocation
import UserNotifications

class Pretracker: NSObject, CLLocationManagerDelegate, UNUserNotificationCenterDelegate, ESTBeaconManagerDelegate{
    var currentLat:Double = 0.0
    var currentLng: Double = 0.0
    var previousLocation: CLLocation?
    var currentLocation: CLLocation?
    
    var hasPosted = false
    
    // 40-50 meters = road segment change
    let distanceUpdate = 10.0
    var clLocationList = [CLLocation]()
    
    var locationManager:CLLocationManager?
    var beaconManager: ESTBeaconManager?
    var hasNotified:Bool = false
    
    var username:String = ""
    
    let defaults = UserDefaults.standard
    
    let taskLocationLat = 42.058334
    let taskLocationLon = -87.683653
    let notificationRadius = 300.0
    
    public static let sharedManager = Pretracker()
    
    override init() {
        super.init()
        
        self.locationManager = CLLocationManager()
        self.beaconManager = ESTBeaconManager()

        
        guard let locationManager = self.locationManager else {
            return
        }
        
        guard let beaconManager = self.beaconManager else {
            return
        }

        // beacon manager initialization
        beaconManager.delegate = self
        beaconManager.requestAlwaysAuthorization()

        // location manager initialization
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = CLLocationDistance(distanceUpdate)
        
        
        // MUST DO! location manager authorization
        locationManager.requestAlwaysAuthorization()
        locationManager.requestWhenInUseAuthorization()
        
        if CLLocationManager.authorizationStatus() == .notDetermined {
            locationManager.requestAlwaysAuthorization()
            locationManager.requestWhenInUseAuthorization()
        }
        
        // We should always enable this for background location tracking.
        locationManager.allowsBackgroundLocationUpdates = true
        //        locationManager.pausesLocationUpdatesAutomatically = true
        locationManager.startUpdatingLocation()
        
        // geofence for coffee lab.
        let center = CLLocationCoordinate2D(latitude: taskLocationLat, longitude: taskLocationLon)
        let taskRegion = CLCircularRegion(center: center, radius: notificationRadius, identifier: "coffee lab 300")
        
        // Beacon region for cofffee lab.
        let beaconRegion = CLBeaconRegion(proximityUUID: UUID(uuidString:"B9407F30-F5F8-466E-AFF9-25556B57FE6D")!, major: 60911, minor: 25867, identifier: "coffee lab beacon")
        
        let taskRegion200 = CLCircularRegion(center: center, radius: 200, identifier: "coffee lab 200")
        
        let taskRegion150 = CLCircularRegion(center: center, radius: 150, identifier: "coffee lab 150")

        let taskRegion100 = CLCircularRegion(center: center, radius: 100, identifier: "coffee lab 100")
        
        let leftCenter = CLLocationCoordinate2D(latitude: 42.058456, longitude: -87.684264)

        let taskRegionLeft = CLCircularRegion(center: leftCenter, radius: 110, identifier: "coffee lab left")
        
        let rightCenter = CLLocationCoordinate2D(latitude: 42.058441, longitude: -87.683076)
        
        let taskRegionRight = CLCircularRegion(center: rightCenter, radius: 110, identifier: "coffee lab right")
        
        locationManager.startMonitoring(for: taskRegion)
        locationManager.startMonitoring(for: taskRegion200)
        locationManager.startMonitoring(for: taskRegion150)
        locationManager.startMonitoring(for: taskRegion100)
        locationManager.startMonitoring(for: taskRegionLeft)
        locationManager.startMonitoring(for: taskRegionRight)

        beaconManager.startMonitoring(for: beaconRegion)
        beaconRegion.notifyEntryStateOnDisplay = true
        
        UNUserNotificationCenter.current().delegate = self
        
        let nc = NotificationCenter.default
        nc.addObserver(forName: NSNotification.Name(rawValue: "isPretrack"), object: nil, queue: OperationQueue.main, using: pretrackUpdate)
    }
    
    func pretrackUpdate(notification: Notification) -> Void {
        if let isPretrack = notification.userInfo?["isPretrack"] as? Bool{
            if isPretrack {
                self.locationManager?.desiredAccuracy = kCLLocationAccuracyBest
                self.locationManager?.distanceFilter = 1.0
            } else {
                self.locationManager?.desiredAccuracy = kCLLocationAccuracyBest
                self.locationManager?.distanceFilter = 1.0
            }
            
        }
        
    }
    
    //MARK: notification methods
    func showNotification(road: String, decision: String) {
        // TODO: modify contents for the request
        let content = UNMutableNotificationContent()
        content.title = "A lost item is nearby!"
        content.body = "Can you help me look for a lost item?\n It is on \(road)"
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1,
                                                        repeats: false)
        
        let request = UNNotificationRequest(identifier: "local", content: content, trigger: trigger)
        
        let notiCenter = UNUserNotificationCenter.current()
        
        notiCenter.add(request) { (error) in
            if let theError = error {
                print(theError.localizedDescription)
            }
        }
    }
    

    func checkLocationAccuracy(_ location: CLLocation) -> Bool {
        let age = -location.timestamp.timeIntervalSinceNow
        if (location.horizontalAccuracy < 0 || location.horizontalAccuracy > 65 || age > 30) {
            return false
        }
        return true
    }
    
    func calculateDistance(currentLocation: CLLocation) -> Double{
        if previousLocation == nil {
            previousLocation = currentLocation
        }
        
        var locationDistance = currentLocation.distance(from: previousLocation!)
//        print(locationDistance)
        previousLocation = currentLocation
        return locationDistance
    }
    
    
    func addtoLocationList(_ location: CLLocation) {
        if !checkLocationAccuracy(location) {
            return
        }
        clLocationList.append(location)
    }
    
    func addRegion(_ regionInfo: [AnyHashable: Any]) {
        let lat = regionInfo["lat"]
        let lon = regionInfo["lon"]
        let regionName = regionInfo["regionName"]
        let radius = regionInfo["radius"]
        let center = CLLocationCoordinate2D(latitude: lat as! CLLocationDegrees, longitude: lon as! CLLocationDegrees)
        let region = CLCircularRegion(center: center, radius: radius as! CLLocationDistance, identifier: regionName as! String)
        locationManager?.startMonitoring(for: region)
    }
    
    func addBeaconRegion(_ regionInfo: [AnyHashable: Any]) {
        let uuid = regionInfo["uuid"]
        let major = regionInfo["major"]
        let minor = regionInfo["minor"]
        let regionName = regionInfo["regionName"]
            
        let beaconRegion = CLBeaconRegion(proximityUUID: UUID(uuidString:uuid as! String)!, major: major as! CLBeaconMajorValue, minor: minor as! CLBeaconMinorValue, identifier: regionName as! String)
        beaconManager!.startMonitoring(for: beaconRegion)
        beaconRegion.notifyEntryStateOnDisplay = true
        
    }
    
    func removeAllRegions() {
        for monitoredRegion in locationManager!.monitoredRegions {
            locationManager!.stopMonitoring(for: monitoredRegion)
        }
    }
    
    
    // MARK: beacon manager delegate methods
    
    func beaconManager(_ manager: Any, didEnter region: CLBeaconRegion) {
//        print(region)
        
        // TODO: gotta move all the notification logic to the backend
        
        let date = Date().timeIntervalSince1970

        let params = ["user": (CURRENT_USER?.username)! ?? "", "date":date, "didEnterRegion": true, "region": region.identifier] as [String : Any]
        CommManager.instance.urlRequest(route: "beaconRegion", parameters: params, completion: {
            json in
            print(json)
//            print(json["description"])
//            let notification = UILocalNotification()
//            notification.alertBody =
//            "Beacon Notification!"
//            UIApplication.shared.presentLocalNotificationNow(notification)
//            NotificationManager.sharedManager.handleTaskNotification()
            // need to add this for handling background fetch.
        })
//        print("didEnter")
    }
    
    func beaconManager(_ manager: Any, didExitRegion region: CLBeaconRegion) {
        let date = Date().timeIntervalSince1970

        let params = ["user": (CURRENT_USER?.username)! ?? "", "date":date, "didEnterRegion": false, "region": region.identifier] as [String : Any]
            CommManager.instance.urlRequest(route: "beaconRegion", parameters: params, completion: {
            json in
//            print(json)
            // need to add this for handling background fetch.
            })
    }
    
    func beaconManager(_ manager: Any, didFailWithError error: Error) {
        print(error)
    }
    
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let lastLocation = locations.last!
        //call CommManager POST method
//        if checkLocationAccuracy(lastLocation) {
        self.currentLocation = lastLocation
        let lat = lastLocation.coordinate.latitude
        let lon = lastLocation.coordinate.longitude
        let speed = lastLocation.speed
        let date = Date().timeIntervalSince1970
        let accuracy = lastLocation.horizontalAccuracy

        let params = ["user": (CURRENT_USER?.username) ?? "", "lat": lat, "lon": lon, "date":date, "accuracy":accuracy, "speed":speed] as [String : Any]
        CommManager.instance.urlRequest(route: "currentLocation", parameters: params, completion: {
            json in
            print(json)
        })
    }
    
    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // TODO: send error messages to DBs
        
        print("Location manager failed with error: \(error)")
    }
    
    public func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        if(!(region is CLBeaconRegion)){            
            let date = Date().timeIntervalSince1970
            let lat = currentLocation?.coordinate.latitude ?? 0.0
            let lon = currentLocation?.coordinate.longitude ?? 0.0
            
            let params = ["user": (CURRENT_USER?.username)! ?? "", "date":date, "isPretrack":true, "region":region.identifier, "lat":lat,"lon":lon] as [String : Any]
            CommManager.instance.urlRequest(route: "pretrackRegion", parameters: params, completion: {
                json in
                print(json)
            })
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        if(!(region is CLBeaconRegion)){
            
            if(region.identifier=="coffee lab 300") {
                let date = Date().timeIntervalSince1970
                let lat = currentLocation?.coordinate.latitude ?? 0.0
                let lon = currentLocation?.coordinate.longitude ?? 0.0
                
                let params = ["user": (CURRENT_USER?.username)! , "date":date, "isPretrack":false, "region": region.identifier, "lat":lat,"lon":lon] as [String : Any]
                
                //            print(params)
                
                CommManager.instance.urlRequest(route: "pretrackRegion", parameters: params, completion: {
                    json in
                    print(json)
                })
                
//                self.locationManager!.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
//                self.locationManager!.distanceFilter = CLLocationDistance(50)
//            } else {
//                let date = Date().timeIntervalSince1970
//                let lat = currentLocation?.coordinate.latitude ?? 0.0
//                let lon = currentLocation?.coordinate.longitude ?? 0.0
//                
//                // we still want to pretrack but log the data.
//                let params = ["user": (CURRENT_USER?.username)! , "date":date, "isPretrack":true, "region": region.identifier, "lat":lat,"lon":lon] as [String : Any]
//                
//                CommManager.instance.urlRequest(route: "pretrackRegion", parameters: params, completion: {
//                    json in
//                    print(json)
//                })
            }
        }
    }
    
    func activeRegions() {
        print(self.locationManager!.monitoredRegions)
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler(.alert)
    }
    
    
    //MARK: Utils
    func changeAccuracy(accuracy: Double, distanceFilter: Double) {
        locationManager?.desiredAccuracy = accuracy
        locationManager?.distanceFilter = distanceFilter
    }
    
}
