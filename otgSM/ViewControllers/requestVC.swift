//
//  requestVC.swift
//  otgSM
//
//  Created by Yongsung on 11/13/17.
//  Copyright © 2017 Delta. All rights reserved.
//

import UIKit

class requestVC: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource, UITextFieldDelegate {

    @IBOutlet weak var placePicker: UIPickerView!
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var descriptionTextField: UITextField!
    
    let pickerData = ["tomate", "coffee lab"]
    
    var place:String?
    var dueDate:Int?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        Pretracker.sharedManager.locationManager!.startUpdatingLocation()
        self.placePicker.delegate  = self
        self.placePicker.dataSource = self
        place = pickerData[0]
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: picker delegate methods
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerData.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return pickerData[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        print(pickerData[row])
        place = pickerData[row]
    }

    @IBAction func valueChanged(_ sender: UIDatePicker) {
        print(sender.date.timeIntervalSince1970)
        dueDate = Int(sender.date.timeIntervalSince1970)
    }
    
    @IBAction func orderButton(_ sender: Any) {
        // request order.
        if let orderDescription = descriptionTextField.text {
            let params = ["place": place!, "description": orderDescription, "due": dueDate!, "user": "yk"] as [String : Any]
            
            CommManager.instance.urlRequest(route: "task", parameters: params) {
                json in
                if let result = json["result"] as? String {
                    if result == "not requester" {
                        self.showNotRequesterAlert()
                    } else if result == "success" {
                        self.showSuccessAlert()
                    }
                }
            }
        }
        
    }
    
    //MARK: Request Success or Failure Alerts.
    func showNotRequesterAlert() {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: "Sorry", message: "Only authorized requesters can request.", preferredStyle: UIAlertControllerStyle.alert)
            let okAction = UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.default)
            
            alert.addAction(okAction)
            self.present(alert, animated: true, completion: nil)
            self.descriptionTextField.text = ""
        }
    }
    
    
    func showSuccessAlert() {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: "Thanks!", message: "Finding helpers.", preferredStyle: UIAlertControllerStyle.alert)
            let okAction = UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.default)
            
            alert.addAction(okAction)
            self.present(alert, animated: true, completion: nil)
            
            self.descriptionTextField.text = ""

        }
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
