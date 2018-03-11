//
//  loginVC.swift
//  otgSM
//
//  Created by Yongsung on 11/14/17.
//  Copyright © 2017 Delta. All rights reserved.
//

import UIKit

class loginVC: UIViewController {

    @IBOutlet weak var usernameTextField: UITextField!
    
    var uuid = UUID().uuidString
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        uuid = uuid.replacingOccurrences(of: "-", with: "")

        
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func loginButton(_ sender: Any) {
        // check if username textfield is not empty.
        if let username = usernameTextField.text {
            let defaults = UserDefaults.standard
            let tokenId:String = defaults.value(forKey: "tokenId") as! String
            postUserInfo(username, tokenId)
        }
    }
    
    func postUserInfo(_ username: String, _ tokenId: String) {
        // this is all get
        let config = URLSessionConfiguration.default
        let session: URLSession = URLSession(configuration: config)
        
        let url : String = "\(Config.URL)/user?username=\(username)&tokenId=\(tokenId)"
        let urlStr : String = url.addingPercentEncoding(withAllowedCharacters:NSCharacterSet.urlQueryAllowed)!
        let searchURL : URL = URL(string: urlStr as String)!
        do {
            let task = session.dataTask(with: searchURL, completionHandler: {
                (data, response, error) in
                if error != nil {
                    print(error?.localizedDescription)
                }
                if data != nil {
                    do {
                        if let json = try JSONSerialization.jsonObject(with: data!, options: .allowFragments) as? [String: Any] {
                            print(json)
                            if json["result"] as! String == "success" {
                                print("success")
                                self.pushSegue(username,tokenId)
                            } else if json["result"] as! String == "failed" {
                                print("failed")
                                self.failAlert(username)
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
    
    func pushSegue(_ username: String, _ tokenId: String) {
        DispatchQueue.main.async {
            self.performSegue(withIdentifier: "Login Segue", sender: self)
            CURRENT_USER = User(username: username, tokenId: tokenId)
            let defaults = UserDefaults.standard
            defaults.set(username,forKey: "username")
        }
        
    }
    
    func failAlert(_ username: String) {
        DispatchQueue.main.async {
            let msg = "Username \(username) already exists"
            let alert = UIAlertController(title: "Login Error", message: msg, preferredStyle: UIAlertControllerStyle.alert)
            let okAction = UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.default)
            alert.addAction(okAction)
            self.present(alert, animated: true, completion: nil)
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
