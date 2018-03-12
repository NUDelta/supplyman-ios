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
//            CURRENT_USER = User(username: defaults.value(forKey: "username") as! String, tokenId: defaults.value(forKey: "tokenId") as! String)
            
        // otherwise, instantiate with login view controller.
        } else {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let tabbarVC = storyboard.instantiateViewController(withIdentifier: "loginVC")
            self.window?.makeKeyAndVisible()
            self.window?.rootViewController?.present(tabbarVC, animated: true, completion: nil)
            CURRENT_USER = User(username: defaults.value(forKey: "username") as! String, tokenId: defaults.value(forKey: "tokenId") as! String)
        }
        
        Pretracker.sharedManager.locationManager!.startUpdatingLocation()

        return true
    }
    
    func application(_ application: UIApplication, didRegister notificationSettings: UIUserNotificationSettings) {
        if notificationSettings.types != .none {
            application.registerForRemoteNotifications()
        }
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let deviceTokenString = deviceToken.reduce("", {$0 + String(format: "%02X", $1)})
        print(deviceTokenString)
        defaults.set(deviceTokenString, forKey: "tokenId")
    }
    
    func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError error: Error) {
        // The token is not currently available.
        print("Remote notification support is unavailable due to error: \(error.localizedDescription)")
    }
    
    // Handle data received from push.
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
        for monitoredRegion in (Pretracker.sharedManager.locationManager?.monitoredRegions)! {
            print(monitoredRegion)
        }
        
        if (userInfo.index(forKey: "regionType") != nil) {
            let regionType = userInfo["regionType"] as! String
            
            if (regionType == "beacon") {
                Pretracker.sharedManager.addBeaconRegion(userInfo)
            }
            
            if (regionType == "geofence") {
                Pretracker.sharedManager.addRegion(userInfo)
            }
        }
        
        if (userInfo.index(forKey: "removeAllRegions") != nil) {
            Pretracker.sharedManager.removeAllRegions()
        }
        
        if (userInfo.index(forKey: "inRegion") != nil) {
            print("it is here")
            print(userInfo["inRegion"]!)
            let inRegion = userInfo["inRegion"] as! Int
            if(inRegion==1){
                Pretracker.sharedManager.locationManager?.startUpdatingLocation()
                print(Pretracker.sharedManager.locationManager?.desiredAccuracy)
                print(Pretracker.sharedManager.locationManager?.distanceFilter)
            } else {
                Pretracker.sharedManager.activeRegions()
                Pretracker.sharedManager.locationManager!.stopUpdatingLocation()
                Pretracker.sharedManager.locationManager!.startMonitoringSignificantLocationChanges()
                Pretracker.sharedManager.locationManager!.distanceFilter = CLLocationDistance(80)

                print(Pretracker.sharedManager.locationManager?.desiredAccuracy)
                print(Pretracker.sharedManager.locationManager?.distanceFilter)
            }
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
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

