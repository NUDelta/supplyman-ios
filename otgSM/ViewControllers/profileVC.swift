//
//  profileVC.swift
//  otgSM
//
//  Created by Yongsung on 3/13/18.
//  Copyright © 2018 Delta. All rights reserved.
//

import UIKit

class profileVC: UIViewController {

    @IBOutlet weak var userNameLabel: UILabel!
    
    @IBOutlet weak var numHelpLabel: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        getUserInfo()
    }

    func getUserInfo() {
        let config = URLSessionConfiguration.default
        let session: URLSession = URLSession(configuration: config)
        
        let defaults = UserDefaults.standard

        let username = defaults.value(forKey: "username") as! String
        let url : String = "\(Config.URL)/getUserInfo?username=\(username)"
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
//                            print(json)
                            if let numHelp = json["numHelp"]{
                                DispatchQueue.main.async {
                                    self.userNameLabel.text = (username as! String)
                                    self.numHelpLabel.text = String(describing: numHelp)
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
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
