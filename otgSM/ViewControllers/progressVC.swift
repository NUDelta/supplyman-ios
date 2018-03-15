//
//  progressVC.swift
//  otgSM
//
//  Created by Yongsung on 11/13/17.
//  Copyright © 2017 Delta. All rights reserved.
//

import UIKit

class progressVC: UIViewController {

    var currentTask: Task?
    let center = NotificationCenter.default
    
    let defaults = UserDefaults.standard
    
    let timeFilter = 60.0 * 5.0

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
        
        // add observer for task notification.
        center.addObserver(forName: NSNotification.Name(rawValue: "getTaskNotification"), object: nil, queue: OperationQueue.main, using: getTaskNotification)

        // add observer for updating the fields.
        center.addObserver(forName: NSNotification.Name(rawValue: "updateDetail"), object: nil, queue: OperationQueue.main, using: updateFields)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        let showTask = didReceiveTaskNotification()
        if (showTask) {
            getTask()
            helpButton.isHidden = false
            declineButton.isHidden = false
        } else {
            helpButton.isHidden = true
            declineButton.isHidden = true
            requesterField.text = "No request yet"
            taskDescriptionField.text = "No request yet"
            pickUpLocationField.text = "No request yet"
            dropOffLocationField.text = "No request yet"
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func didReceiveTaskNotification()->Bool{
        print(defaults.value(forKey: "lastNotified"))
        let currentTime = Date().timeIntervalSince1970 as Double
        let lastNotified = defaults.value(forKey: "lastNotified") as! Double
        let timeElapsed = currentTime - lastNotified
        print(timeElapsed)
        if(timeElapsed <= timeFilter) {
            return true
        } else {
            return false
        }
    }
    
    func getTask() {
        // such a hacky way send get request when there is no parameter needed...
        CommManager.instance.getRequest(route: "getTask", parameters:["foo":"bar"]) {
            json in
            print (json)
            
//            let requester: String
//            let taskLocation: String
//            let dropOffLocation: String
//            let taskDescription: String
//            let requestTime: Int
//            let deadline: Int
//            let taskId: String
            
            let requester = json["user"]
            let taskLocation = json["taskLocation"]
            let dropOffLocation = json["dropoff"]
            let taskDescription = json["description"]
            let requestTime = json["requestTime"]
            let deadline = json["deadline"]
            let oid = json["_id"] as! [String: Any]
            let taskId = oid["$oid"]
            
            self.currentTask = Task(requester: requester as! String, taskLocation: taskLocation as! String, dropOffLocation: dropOffLocation as! String, taskDescription: taskDescription as! String, requestTime: requestTime as! Int, deadline: deadline as! Int, taskId: taskId as! String)
            self.center.post(name: NSNotification.Name(rawValue: "updateDetail"), object: nil, userInfo: nil)
        }
    }
    
    func getTaskNotification(notification: Notification) -> Void {
        getTask()
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
            print("yes")
        }
        
        let notFoundAction = UIAlertAction(title: "NO", style: UIAlertActionStyle.destructive) {
            act in
            self.didDecline()
//            self.switchToNextTab()
            print("no")
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel) {
            act in
            print("no")
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
            print("thanks")
        })
        switchToNextTab()
    }
    
    func didDecline() {
        print("did decline")
        let param = ["user":(CURRENT_USER?.username)! ?? "", "taskId": currentTask?.taskId, "didHelp": false, "date":Date().timeIntervalSince1970, "decisionActivityId": decisionActivityId] as [String : Any]
        
        CommManager.instance.urlRequest(route: "helpActivity", parameters: param, completion: {
            json in
            print("thanks")
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
