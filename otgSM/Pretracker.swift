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

class Pretracker: NSObject, CLLocationManagerDelegate, UNUserNotificationCenterDelegate{
        var currentLat:Double = 0.0
    var currentLng: Double = 0.0
    var previousLocation: CLLocation?
    var currentLocation: CLLocation?
    
    var hasPosted = false
    
    // 40-50 meters = road segment change
    let distanceUpdate = 10.0
    var clLocationList = [CLLocation]()
    
    var locationManager:CLLocationManager?
    var hasNotified:Bool = false
    
    let regionLat = 42.058377
    let regionLng = -87.679203
    var regionLocation:CLLocation?
    
    var didEnterRegion:Bool?

    var username:String = ""
    
    let defaults = UserDefaults.standard
    
    public static let sharedManager = Pretracker()
    
    override init() {
        super.init()
        
        self.locationManager = CLLocationManager()
        
        guard let locationManager = self.locationManager else {
            return
        }
        
        // location manager initialization
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.distanceFilter = CLLocationDistance(distanceUpdate)
        
        locationManager.requestAlwaysAuthorization()
        locationManager.requestWhenInUseAuthorization()
        
        if CLLocationManager.authorizationStatus() == .notDetermined {
            locationManager.requestAlwaysAuthorization()
            locationManager.requestWhenInUseAuthorization()
        }
        
        // We should always enable this for background location tracking.
        locationManager.allowsBackgroundLocationUpdates = true
        //        locationManager.pausesLocationUpdatesAutomatically = true
        //        locationManager.startUpdatingLocation()
        
        // TODO: need to change the logic for finding lost item region.
        // call getNearbySearchRegions
        //        let center = CLLocationCoordinate2D(latitude: regionLat, longitude: regionLng)
        //        let region = CLCircularRegion(center: center, radius: 300, identifier: "region")
        
        // region 1
        // 42.058400, -87.680636
        let center1 = CLLocationCoordinate2D(latitude: 42.058400, longitude: -87.680636)
        let region1 = CLCircularRegion(center: center1, radius: 100, identifier: "noyes1")
        
        // region 2
        // 42.058387, -87.678826
        let center2 = CLLocationCoordinate2D(latitude: 42.058387, longitude: -87.678826)
        let region2 = CLCircularRegion(center: center2, radius: 100, identifier: "noyes2")
        
        // region 3
        // 42.057995, -87.678015
        let center3 = CLLocationCoordinate2D(latitude: 42.057995, longitude: -87.678015)
        let region3 = CLCircularRegion(center: center3, radius: 100, identifier: "noyes3")
        
        // noyes 4
        // 42.059053, -87.677120
        let center7 = CLLocationCoordinate2D(latitude: 42.059053, longitude: -87.677120)
        let region7 = CLCircularRegion(center: center7, radius: 100, identifier: "noyes4")
        
        // foster 1
        // 42.053864, -87.680771
        let center4 = CLLocationCoordinate2D(latitude: 42.053864, longitude: -87.680771)
        let region4 = CLCircularRegion(center: center4, radius: 100, identifier: "foster1")
        
        // foster 2
        // 42.053868, -87.679536
        let center5 = CLLocationCoordinate2D(latitude: 42.053868, longitude: -87.679536)
        let region5 = CLCircularRegion(center: center5, radius: 100, identifier: "foster2")
        
        // foster 3
        // 42.053882, -87.678355
        let center6 = CLLocationCoordinate2D(latitude: 42.053882, longitude: -87.678355)
        let region6 = CLCircularRegion(center: center6, radius: 150, identifier: "foster3")
        
        regionLocation = CLLocation(latitude: regionLat, longitude: regionLng)
        
        locationManager.startMonitoring(for: region1)
        locationManager.startMonitoring(for: region2)
        locationManager.startMonitoring(for: region3)
        locationManager.startMonitoring(for: region4)
        locationManager.startMonitoring(for: region5)
        locationManager.startMonitoring(for: region6)
        
        didEnterRegion = false
        
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
        print(locationDistance)
        previousLocation = currentLocation
        return locationDistance
    }
    
    
    func addtoLocationList(_ location: CLLocation) {
        if !checkLocationAccuracy(location) {
            return
        }
        clLocationList.append(location)
    }
    
    
    // MARK: location manager delegate methods
    //    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
    //        locationManager?.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
    //        locationManager?.distanceFilter = CLLocationDistance(distanceUpdate)
    //
    //        //TODO: change accuracy timer interval
    ////        accuracyTimer = Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(changeAccuracy), userInfo: nil, repeats: false)
    //    }
    //
    //    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
    //        //        changeAccuracy(accuracy: kCLLocationAccuracyHundredMeters, distanceFilter: 300)
    //    }
    
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let lastLocation = locations.last!
        print("speed is: \(lastLocation.speed)")
        
        //call CommManager POST method
        if checkLocationAccuracy(lastLocation) {
            self.currentLocation = lastLocation
        }
        
        let lat = lastLocation.coordinate.latitude
        let lon = lastLocation.coordinate.longitude
        let speed = lastLocation.speed
        let date = Date().timeIntervalSince1970
        let accuracy = lastLocation.horizontalAccuracy
        let params = ["user": (CURRENT_USER?.username) ?? "", "lat": lat, "lon": lon, "date":date, "accuracy":accuracy, "speed":speed] as [String : Any]
        CommManager.instance.urlRequest(route: "currentLocation", parameters: params, completion: {
            json in
            print(json)
            // need to add this for handling background fetch.
//            completionHandler(UIBackgroundFetchResult.noData)
        })
        
        print(lastLocation)
        
        // receive observers with LocationUpdate
        let nc = NotificationCenter.default
        let userInfo = ["lat": lastLocation.coordinate.latitude,"lng": lastLocation.coordinate.longitude,"road": ["no road"]] as [String : Any]
        nc.post(name: NSNotification.Name(rawValue: "LocationUpdate"), object: nil, userInfo: userInfo)
        
        
        let distance = calculateDistance(currentLocation: lastLocation)
        
        if distance >= distanceUpdate {
            addtoLocationList(lastLocation)
            //lastUpdated()
        }
        
    }
    
    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // TODO: send error messages to DBs
        
        print("Location manager failed with error: \(error)")
    }
    
    public func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        let date = Date().timeIntervalSince1970
        let lat = currentLocation?.coordinate.latitude ?? 0.0
        let lon = currentLocation?.coordinate.longitude ?? 0.0
//        let params = ["user": (CURRENT_USER?.username)! ?? "", "date":date, "isPretrack":true, "region":region.identifier, "lat":lat,"lon":lon] as [String : Any]
//        CommManager.instance.urlRequest(route: "pretrackRegion", parameters: params, completion: {
//            json in
//            print(json)
//            // need to add this for handling background fetch.
//        })
        print("didEnter")
    }
    
    public func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        let date = Date().timeIntervalSince1970
        let lat = currentLocation?.coordinate.latitude ?? 0.0
        let lon = currentLocation?.coordinate.longitude ?? 0.0
        
//        let params = ["user": (CURRENT_USER?.username)! ?? "", "date":date, "isPretrack":false, "region": region.identifier] as [String : Any]
//        CommManager.instance.urlRequest(route: "pretrackRegion", parameters: params, completion: {
//            json in
//            print(json)
//            // need to add this for handling background fetch.
//        })
        print("didExit")
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
