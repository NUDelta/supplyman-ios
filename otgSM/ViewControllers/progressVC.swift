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

    @IBOutlet weak var requesterField: UILabel!
    @IBOutlet weak var taskDescriptionField: UILabel!
    
    @IBOutlet weak var pickUpLocationField: UILabel!
    @IBOutlet weak var dropOffLocationField: UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        getTask()
        Pretracker.sharedManager.locationManager!.startUpdatingLocation()

        center.addObserver(forName: NSNotification.Name(rawValue: "updateDetail"), object: nil, queue: OperationQueue.main, using: updateFields)
        
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func getTask() {
        // If received a notification.
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
            
//            self.updateFields()
            // if there is no nearby search region with the item not found yet, server returns {"result":0}
//            if json.index(forKey: "found") != nil {
//                let loc = json["loc"] as! [String:Any]
//                let coord = loc["coordinates"] as! [Double]
//                let id = json["_id"] as! [String:Any]
//                if regionId == id["$oid"] as! String {
//
//                    //TODO: check if current location is within distance threshold.
//                    self.searchRegion = LostItemRegion(requesterName: json["user"] as! String, item: json["item"] as! String, itemDetail: json["detail"] as! String, lat: coord[1], lon: coord[0], id: id["$oid"] as! String)
//                    self.center.post(name: NSNotification.Name(rawValue: "updatedDetail"), object: nil, userInfo:nil)
//                }
//            }
        }
    }
    
    func updateFields(notification: Notification) -> Void{
//        DispatchQueue.main.async(){
        if let task = currentTask {
            requesterField.text = task.requester
            taskDescriptionField.text = task.taskDescription
            pickUpLocationField.text = task.taskLocation
            dropOffLocationField.text = task.dropOffLocation
        }
        
//        }
        
    }

    @IBAction func clickAcceptButton(_ sender: UIButton) {
        showPopUp()
    }
    
    func didHelp() {
//        let param = ["user":(CURRENT_USER?.username)!,"lat":String(describing: (Pretracker.sharedManager.currentLocation?.coordinate.latitude)!) ?? 0.0,"lon":String(describing: (Pretracker.sharedManager.currentLocation?.coordinate.longitude)!) ?? 0.0,"region_id":regionId,"decision_activity_id": defaults.value(forKey: "decision_activity_id") ?? "", "search_road": defaults.value(forKey: "search_road") ?? "", "timestamp":Date().timeIntervalSince1970] as [String : Any]
        
        
        // need help activity id.
//        CommManager.instance.urlRequest(route: "startHelping", parameters: param, completion: {
//            json in
//            print("thanks")
//        })
//        switchToNextTab()
    }
    
    @IBAction func clickDeclineButton(_ sender: Any) {
        didDecline()
        
        // go to another tab.
//        switchToNextTab()
    }
    
    func switchToNextTab() {
        tabBarController?.selectedIndex = 1
    }
    
    func showPopUp() {
        let alert = UIAlertController(title: "Can you help deliver the item?", message: "Thank you in advance for your help!", preferredStyle: UIAlertControllerStyle.alert)
        let foundAction = UIAlertAction(title: "YES", style: UIAlertActionStyle.default) {
            act in
            self.didHelp()
            self.switchToNextTab()
            print("yes")
        }
        
        let notFoundAction = UIAlertAction(title: "NO", style: UIAlertActionStyle.destructive) {
            act in
            self.switchToNextTab()
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
    
    func didDecline() {
        print("did decline")
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
