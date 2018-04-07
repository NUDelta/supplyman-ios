//
//  AppDelegate.swift
//  otgSM
//
//  Created by Yongsung on 11/13/17.
//  Copyright © 2017 Delta. All rights reserved.
//

import UIKit
import UserNotifications
import CoreLocation

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate, CLLocationManagerDelegate {

    var window: UIWindow?

    // user defauls to store tokenId.
    let defaults = UserDefaults.standard
    
    let center = NotificationCenter.default
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        _  = Config()
        
        // *** copy the following code block for notifications *** //
        //TODO: there might be some changes for iOS 11.
        if #available(iOS 11, *) {
            UNUserNotificationCenter.current().requestAuthorization(options:[.badge, .alert, .sound]){ (granted, error) in }
            application.registerForRemoteNotifications()
        }
        
        if #available(iOS 10, *) {
            UNUserNotificationCenter.current().requestAuthorization(options:[.badge, .alert, .sound]){ (granted, error) in }
            application.registerForRemoteNotifications()
        }
            // iOS 9 support
        else if #available(iOS 9, *) {
            UIApplication.shared.registerUserNotificationSettings(UIUserNotificationSettings(types: [.badge, .sound, .alert], categories: nil))
            UIApplication.shared.registerForRemoteNotifications()
        }
            // iOS 8 support
        else if #available(iOS 8, *) {
            UIApplication.shared.registerUserNotificationSettings(UIUserNotificationSettings(types: [.badge, .sound, .alert], categories: nil))
            UIApplication.shared.registerForRemoteNotifications()
        }
            // iOS 7 support
        else {
            application.registerForRemoteNotifications(matching: [.badge, .sound, .alert])
        }
        
        // *** end here *** //
        
        // if there exists username, instantiate with tab bar
        if (defaults.object(forKey: "username") != nil) {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let tabbarVC = storyboard.instantiateViewController(withIdentifier: "tabbarVC")
            self.window?.makeKeyAndVisible()
            self.window?.rootViewController?.present(tabbarVC, animated: true, completion: nil)
            CURRENT_USER = User(username: defaults.value(forKey: "username") as! String, tokenId: defaults.value(forKey: "tokenId") as! String)
            
        // otherwise, instantiate with login view controller.
        } else {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let tabbarVC = storyboard.instantiateViewController(withIdentifier: "loginVC")
            self.window?.makeKeyAndVisible()
            self.window?.rootViewController?.present(tabbarVC, animated: true, completion: nil)
        }
        
        return true
    }
    
    func application(_ application: UIApplication, didRegister notificationSettings: UIUserNotificationSettings) {
        if notificationSettings.types != .none {
            application.registerForRemoteNotifications()
        }
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let deviceTokenString = deviceToken.reduce("", {$0 + String(format: "%02X", $1)})
//        print(deviceTokenString)
        defaults.set(deviceTokenString, forKey: "tokenId")
        
        // also set lastNotified to 0
        defaults.set(0, forKey: "lastNotified")

    }
    
    func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError error: Error) {
        // The token is not currently available.
        print("Remote notification support is unavailable due to error: \(error.localizedDescription)")
    }
    
    // Handle data received from push.
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
        // Handling silent push for location updates.
        if (userInfo.index(forKey: "locationUpdate") != nil) {
            Pretracker.sharedManager.locationManager!.requestLocation()
            
            if let currentLocation = Pretracker.sharedManager.currentLocation {
                let lat = currentLocation.coordinate.latitude
                let lon = currentLocation.coordinate.longitude
                let speed = currentLocation.speed
                let date = Date().timeIntervalSince1970
                let accuracy = currentLocation.horizontalAccuracy
                let params = ["user": (CURRENT_USER?.username)! ?? "", "lat": lat, "lon": lon, "date":date, "accuracy":accuracy, "speed":speed] as [String : Any]
                CommManager.instance.urlRequest(route: "currentLocation", parameters: params, completion: {
                    json in
                    print(json)
                    // need to add this for handling background fetch.
                    completionHandler(UIBackgroundFetchResult.noData)
                })
            }
        }
        
        // store last task notification time to show task details and button.
        if (userInfo.index(forKey: "taskNotification") != nil) {
            let date = Date().timeIntervalSince1970
            defaults.set(date, forKey: "lastNotified")
            // get task details when gets a notification.
            self.center.post(name: NSNotification.Name(rawValue: "getTaskNotification"), object: nil, userInfo: nil)
            
            if(userInfo.index(forKey: "decisionActivityId") != nil) {
                let decisionActivityId = userInfo["decisionActivityId"] as! String
                NotificationManager.sharedManager.handleTaskNotification(decisionActivityId)
            }
            completionHandler(UIBackgroundFetchResult.noData)
        }
        
        // Adding beacon region or geofence based on region type.
        if (userInfo.index(forKey: "regionType") != nil) {
            let regionType = userInfo["regionType"] as! String
            
            if (regionType == "beacon") {
                Pretracker.sharedManager.addBeaconRegion(userInfo)
            }
            
            if (regionType == "geofence") {
                Pretracker.sharedManager.addRegion(userInfo)
            }
        }
        
        // remove all the regions.
        if (userInfo.index(forKey: "removeAllRegions") != nil) {
            Pretracker.sharedManager.removeAllRegions()
        }
        
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        
        // Update the task fields whenever a user re-enters the app.
        self.center.post(name: NSNotification.Name(rawValue: "getTask"), object: nil, userInfo: nil)
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        UIApplication.shared.applicationIconBadgeNumber = 0
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

