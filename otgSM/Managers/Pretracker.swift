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
    
    // default distanceUpdateFilter and locationManagerAccuracy
    let distanceUpdate = 500
    let accuracy:CLLocationAccuracy = kCLLocationAccuracyHundredMeters
    
    // when pretracking
    let pretrackDistanceUpdate = 30
    let pretrackAccuracy:CLLocationAccuracy = kCLLocationAccuracyNearestTenMeters
    let pretrackRadius = 300.0
    
    var clLocationList = [CLLocation]()
    
    var locationManager:CLLocationManager?
    var beaconManager: ESTBeaconManager?
    
    var hasNotified:Bool = false
    
    var username:String = ""
    
    let defaults = UserDefaults.standard
    
    // latitude and longitude for coffee lab.
    let taskLocationLat = 42.058334
    let taskLocationLon = -87.683653
    
    // task radius is set to 100 meters for this study.
    let taskRadius = 100.0

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
        locationManager.activityType = .other

        // default initialization for location manager accuracy and distance filter.
        // for pretracking, when increase the desiredAccuracy and decrease the distanceFilter
        // upon entering a geofence.
        locationManager.desiredAccuracy = accuracy
        locationManager.distanceFilter = CLLocationDistance(distanceUpdate)
        
//        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
//        locationManager.distanceFilter = CLLocationDistance(distanceUpdate)
        
        // MUST DO! location manager authorization
        locationManager.requestAlwaysAuthorization()
        locationManager.requestWhenInUseAuthorization()
        
        if CLLocationManager.authorizationStatus() == .notDetermined {
            locationManager.requestAlwaysAuthorization()
            locationManager.requestWhenInUseAuthorization()
        }
        
        // ***** We should always enable this for background location tracking. ***** //
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
        // ************************************************************************* //
        
        locationManager.startMonitoringSignificantLocationChanges()
        locationManager.startUpdatingLocation()
        
        let center = CLLocationCoordinate2D(latitude: taskLocationLat, longitude: taskLocationLon)
        
        // geofence for pretracking region
        let pretrackRegion = CLCircularRegion(center: center, radius: pretrackRadius, identifier: "pretrackRegion")
    
        // geofence for task region
        let taskRegion = CLCircularRegion(center: center, radius: taskRadius, identifier: "taskRegion")
        
        // Beacon region for cofffee lab.
        // beacon name: Pickup1
//        let beaconRegion = CLBeaconRegion(proximityUUID: UUID(uuidString:"B9407F30-F5F8-466E-AFF9-25556B57FE6D")!, major: 40740, minor: 56013, identifier: "taskBeacon")
        
        
        // beacon name: Pickup2
        let beaconRegion = CLBeaconRegion(proximityUUID: UUID(uuidString:"B9407F30-F5F8-466E-AFF9-25556B57FE6D")!, major: 63530, minor: 47088, identifier: "taskBeacon")
        
        
        // this is yk geofence for testing.
        let ykcenter = CLLocationCoordinate2D(latitude: 42.053867, longitude: -87.682034)
        let ykRegion = CLCircularRegion(center: ykcenter, radius: taskRadius, identifier: "ykHome")
        
        locationManager.startMonitoring(for: pretrackRegion)
        locationManager.startMonitoring(for: taskRegion)
        
        // comment this for actual deployment
//        locationManager.startMonitoring(for: ykRegion)

        beaconManager.startMonitoring(for: beaconRegion)
//        beaconRegion.notifyEntryStateOnDisplay = true
        
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
    
    func addtoLocationList(_ location: CLLocation) {
        if !checkLocationAccuracy(location) {
            return
        }
        clLocationList.append(location)
    }
    
    // MARK: adding or removing regions for monitoring.
    
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

        let params = ["user": CURRENT_USER?.username ?? "", "date":date, "didEnterRegion": true, "region": region.identifier] as [String : Any]
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
        
        let params = ["user": CURRENT_USER?.username ?? "", "date":date, "didEnterRegion": false, "region": region.identifier] as [String : Any]
            CommManager.instance.urlRequest(route: "beaconRegion", parameters: params, completion: {
            json in
//            print(json)
            // need to add this for handling background fetch.
            })
    }
    
    func beaconManager(_ manager: Any, didFailWithError error: Error) {
        print(error)
    }
    
    // MARK: Location manager delegate methods
    
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let lastLocation = locations.last!
//        if checkLocationAccuracy(lastLocation) {
        self.currentLocation = lastLocation
        let lat = lastLocation.coordinate.latitude
        let lon = lastLocation.coordinate.longitude
        let speed = lastLocation.speed
        let date = Date().timeIntervalSince1970
        let accuracy = lastLocation.horizontalAccuracy

        let params = ["user": CURRENT_USER?.username ?? "", "lat": lat, "lon": lon, "date":date, "accuracy":accuracy, "speed":speed] as [String : Any]
        CommManager.instance.urlRequest(route: "currentLocation", parameters: params, completion: {
            json in
            print(json)
        })
    }
    
    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // TODO: send error messages to DB
        
        print("Location manager failed with error: \(error)")
        let params = ["user": CURRENT_USER?.username ?? "", "errorMessage": error.localizedDescription] as [String : Any]
        CommManager.instance.urlRequest(route: "postErrors", parameters: params, completion: {
            json in
            print(json)
        })
    }
    
    
    public func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        if(!(region is CLBeaconRegion)){
            let date = Date().timeIntervalSince1970
            
            // need to add speed and age.
//            self.currentLocation = nil
//            let age = -(self.currentLocation?.timestamp.timeIntervalSinceNow)! ?? 0
//
//            let speed = (self.currentLocation?.speed)! ?? 0.0
            
            var age = 0.0
            var speed = 0.0
            
            var lat = 0.0
            var lon = 0.0
            
            if let currLocation = self.currentLocation {
                age = -(currLocation.timestamp.timeIntervalSinceNow)
                speed = currLocation.speed
                lat = currLocation.coordinate.latitude
                lon = currLocation.coordinate.longitude
            }
                        
            // send the age annd speed of the last location update
            // so that we don't send notifications if speed is greater than the speed threshold.
            
            let params = ["user": CURRENT_USER?.username ?? "", "date":date, "isPretrack":true, "region":region.identifier, "lat":lat,"lon":lon, "age": age, "speed": speed] as [String : Any]
            CommManager.instance.urlRequest(route: "pretrackRegion", parameters: params, completion: {
                json in
                print(json)
            })
            
            if(region.identifier == "pretrackRegion") {
                // start pretracking
                self.locationManager!.desiredAccuracy = pretrackAccuracy
                self.locationManager!.distanceFilter = CLLocationDistance(pretrackDistanceUpdate)
            }
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        if(!(region is CLBeaconRegion)){
            let date = Date().timeIntervalSince1970
            let lat = currentLocation?.coordinate.latitude ?? 0.0
            let lon = currentLocation?.coordinate.longitude ?? 0.0
            
//            activeRegions()
            
            let params = ["user": CURRENT_USER?.username ?? "" , "date":date, "isPretrack":false, "region": region.identifier, "lat":lat,"lon":lon] as [String : Any]
            CommManager.instance.urlRequest(route: "pretrackRegion", parameters: params, completion: {
                json in
                print(json)
            })
            
            if(region.identifier=="pretrackRegion") {
                // stop pretracking
                self.locationManager!.desiredAccuracy = accuracy
                self.locationManager!.distanceFilter = CLLocationDistance(distanceUpdate)
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
    
}
