//
//  progressVC.swift
//  otgSM
//
//  Created by Yongsung on 11/13/17.
//  Copyright © 2017 Delta. All rights reserved.
//

import UIKit
import MessageUI

class progressVC: UIViewController, MFMessageComposeViewControllerDelegate {

    var currentTask: Task?
    let center = NotificationCenter.default
    
    let defaults = UserDefaults.standard
    
    let timeFilter = 60.0 * 10.0

    @IBOutlet weak var requesterField: UILabel!
    @IBOutlet weak var taskDescriptionField: UILabel!
    
    @IBOutlet weak var pickUpLocationField: UILabel!
    @IBOutlet weak var dropOffLocationField: UILabel!
    
    @IBOutlet weak var helpButton: UIButton!
    
    @IBOutlet weak var declineButton: UIButton!
    
    var decisionActivityId: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Pretracker.sharedManager.locationManager!.startUpdatingLocation()
//        Pretracker.sharedManager.locationManager!.startMonitoringSignificantLocationChanges()
        
        // add observer for task notification.
        center.addObserver(forName: NSNotification.Name(rawValue: "getTaskNotification"), object: nil, queue: OperationQueue.main, using: getTaskNotification)

        center.addObserver(forName: NSNotification.Name(rawValue: "getTask"), object: nil, queue: OperationQueue.main, using: getTaskInfo)

        // add observer for updating the fields.
        center.addObserver(forName: NSNotification.Name(rawValue: "updateDetail"), object: nil, queue: OperationQueue.main, using: updateFields)

    }
    
    @IBAction func textButtonClicked(_ sender: Any) {
//        UIApplication.shared.openURL(NSURL(string: "telprompt://8472190252") as! URL)

        let messageVC = MFMessageComposeViewController()
        
        messageVC.body = "";
        messageVC.recipients = ["8472190252"]
        messageVC.messageComposeDelegate = self
    
        self.present(messageVC, animated: false, completion: nil)
    }
    
    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        switch (result.rawValue) {
        case MessageComposeResult.cancelled.rawValue:
//            print("Message was cancelled")
            self.dismiss(animated: true, completion: nil)
        case MessageComposeResult.failed.rawValue:
//            print("Message failed")
            self.dismiss(animated: true, completion: nil)
        case MessageComposeResult.sent.rawValue:
//            print("Message was sent")
            self.dismiss(animated: true, completion: nil)
        default:
            break;
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        getTask()
//        let showTask = didReceiveTaskNotification()
//        if (showTask) {
////            getTask()
//            helpButton.isHidden = false
//            declineButton.isHidden = false
//        } else {
//            helpButton.isHidden = true
//            declineButton.isHidden = true
//            requesterField.text = "No request yet"
//            taskDescriptionField.text = "No request yet"
//            pickUpLocationField.text = "No request yet"
//            dropOffLocationField.text = "No request yet"
//        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func didReceiveTaskNotification()->Bool{
        let currentTime = Date().timeIntervalSince1970 as Double
        let lastNotified = defaults.value(forKey: "lastNotified") as? Double ?? currentTime
        let timeElapsed = currentTime - lastNotified
//        print(timeElapsed)
        if(timeElapsed <= timeFilter) {
            return true
        } else {
            return false
        }
    }
    
    func getTask() {
        // such a hacky way send get request when there is no parameter needed...
        let defaults = UserDefaults.standard
        
        if let username = defaults.value(forKey: "username") as? String {
            CommManager.instance.getRequest(route: "getTask", parameters:["user":username]) {
                json in
                print (json)
                
                //            let requester: String
                //            let taskLocation: String
                //            let dropOffLocation: String
                //            let taskDescription: String
                //            let requestTime: Int
                //            let deadline: Int
                //            let taskId: String
                if let requester = json["user"] {
                    let requester = json["user"]
                    let taskLocation = json["taskLocation"]
                    let dropOffLocation = json["dropoff"]
                    let taskDescription = json["description"]
                    let requestTime = json["requestTime"]
                    let deadline = json["deadline"]
                    let oid = json["_id"] as! [String: Any]
                    let taskId = oid["$oid"]
                    
                    self.currentTask = Task(requester: requester as! String, taskLocation: taskLocation as! String, dropOffLocation: dropOffLocation as! String, taskDescription: taskDescription as! String, requestTime: requestTime as! NSNumber, deadline: deadline as! NSNumber, taskId: taskId as! String)
                    self.getUserInfo()
//                    self.center.post(name: NSNotification.Name(rawValue: "updateDetail"), object: nil, userInfo: nil)
                }
            }
        }
    }
    
    func getTaskInfo(notification: Notification) -> Void {
        getTask()
    }
    
    func getTaskNotification(notification: Notification) -> Void {
//        getTask()
    }
    
    func getUserInfo() {
        let config = URLSessionConfiguration.default
        let session: URLSession = URLSession(configuration: config)
        
        let defaults = UserDefaults.standard
        
        let username = defaults.value(forKey: "username") as! String
        let url : String = "\(Config.URL)/userLastNotified?username=\(username)"
        let urlStr : String = url.addingPercentEncoding(withAllowedCharacters:NSCharacterSet.urlQueryAllowed)!
        let searchURL : URL = URL(string: urlStr as String)!
        do {
            print(searchURL)
            let task = session.dataTask(with: searchURL, completionHandler: {
                (data, response, error) in
                if error != nil {
                    print(error?.localizedDescription)
                }
                if data != nil {
                    do {
                        if let json = try JSONSerialization.jsonObject(with: data!, options: .allowFragments) as? [String: Any] {
                            //                            print(json)
                            let currentTime = Date().timeIntervalSince1970 as Double
                            let lastNotified = json["lastNotified"] as? Double ?? currentTime
                            let timeElapsed = currentTime - lastNotified
                            if(timeElapsed <= self.timeFilter) {
                                DispatchQueue.main.async {
                                    if let task = self.currentTask {
                                        self.decisionActivityId = defaults.value(forKey: "decisionActivityId") as? String ?? ""
                                        
                                        self.requesterField.text = task.requester
                                        self.taskDescriptionField.text = task.taskDescription
                                        self.pickUpLocationField.text = task.taskLocation
                                        self.dropOffLocationField.text = task.dropOffLocation
                                        self.helpButton.isHidden = false
                                        self.declineButton.isHidden = false
                                    }
                                }
                            } else {
                                DispatchQueue.main.async {
                                    self.helpButton.isHidden = true
                                    self.declineButton.isHidden = true
                                    self.requesterField.text = "No request yet"
                                    self.taskDescriptionField.text = "No request yet"
                                    self.pickUpLocationField.text = "No request yet"
                                    self.dropOffLocationField.text = "No request yet"
                                }
                            }
                            
                        }
                    } catch let error as NSError {
                        print(error)
                    }
                }
            })
            task.resume()
            
        } catch let error as NSError{
            print(error)
        }
        
    }
    
    func updateFields(notification: Notification) -> Void{
//        DispatchQueue.main.async(){

        let showTask = didReceiveTaskNotification()
        if (showTask) {
            if let task = currentTask {
                decisionActivityId = defaults.value(forKey: "decisionActivityId") as? String ?? ""

                requesterField.text = task.requester
                taskDescriptionField.text = task.taskDescription
                pickUpLocationField.text = task.taskLocation
                dropOffLocationField.text = task.dropOffLocation
                helpButton.isHidden = false
                declineButton.isHidden = false
            }
        } else {
            helpButton.isHidden = true
            declineButton.isHidden = true
            requesterField.text = "No request yet"
            taskDescriptionField.text = "No request yet"
            pickUpLocationField.text = "No request yet"
            dropOffLocationField.text = "No request yet"
        }
//        }
    }

    @IBAction func clickAcceptButton(_ sender: UIButton) {
        showPopUp()
    }
    
    @IBAction func clickDeclineButton(_ sender: Any) {
        didDecline()
        switchToNextTab()
    }
    
    func switchToNextTab() {
        tabBarController?.selectedIndex = 1
    }
    
    func showPopUp() {
        let alert = UIAlertController(title: "Can you help deliver the item?", message: "Thank you in advance for your help!", preferredStyle: UIAlertControllerStyle.alert)
        let foundAction = UIAlertAction(title: "YES", style: UIAlertActionStyle.default) {
            act in
            self.didHelp()
//            self.switchToNextTab()
//            print("yes")
        }
        
        let notFoundAction = UIAlertAction(title: "NO", style: UIAlertActionStyle.destructive) {
            act in
            self.didDecline()
//            self.switchToNextTab()
//            print("no")
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel) {
            act in
//            print("no")
        }
        
        alert.addAction(foundAction)
        alert.addAction(notFoundAction)
        alert.addAction(cancelAction)
        self.present(alert, animated: true, completion: nil)
    }
    
    func didHelp() {
        decisionActivityId = defaults.value(forKey: "decisionActivityId") as! String ?? ""

        let param = ["user":(CURRENT_USER?.username)! ?? "", "taskId": currentTask?.taskId, "didHelp": true, "date":Date().timeIntervalSince1970, "decisionActivityId": decisionActivityId] as [String : Any]
        
        CommManager.instance.urlRequest(route: "helpActivity", parameters: param, completion: {
            json in
//            print("thanks")
        })
        switchToNextTab()
    }
    
    func didDecline() {
//        print("did decline")
        let param = ["user":(CURRENT_USER?.username)! ?? "", "taskId": currentTask?.taskId, "didHelp": false, "date":Date().timeIntervalSince1970, "decisionActivityId": decisionActivityId] as [String : Any]
        
        CommManager.instance.urlRequest(route: "helpActivity", parameters: param, completion: {
            json in
//            print("thanks")
        })
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
