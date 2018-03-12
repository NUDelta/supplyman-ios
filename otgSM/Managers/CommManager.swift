//
//  CommManager.swift
//  otgSM
//
//  Created by Yongsung on 11/14/17.
//  Copyright © 2017 Delta. All rights reserved.
//

import UIKit
import Foundation

class CommManager: NSObject {
    let config:URLSessionConfiguration
    let session: URLSession
    let url: String
    
    public static let instance = CommManager()
    
    private override init() {
        self.config = URLSessionConfiguration.default
        self.session = URLSession(configuration: config)
        self.url = Config.URL
    }
    
    func getRequest(route: String, parameters: [String: Any], completion: @escaping ([String: Any]) -> ()) {
        let config = URLSessionConfiguration.default
        let session: URLSession = URLSession(configuration: config)
        let params = parameters.stringFromHttpParameters()
        let urlString = URL(string: "\(Config.URL)/\(route)?\(params)")!
        let task = session.dataTask(with: urlString, completionHandler: {
            (data, response, error) in
            if error != nil {
                print(error?.localizedDescription as Any)
            } else {
                do {
                    if let json = try JSONSerialization.jsonObject(with: data!, options: .allowFragments) as? [String: Any] {
                        completion(json)
                    }
                } catch {
                    print("error in JSONSerialization")
                }
            }
        })
        task.resume()
    }
    
    func urlRequest(route: String, parameters: [String: Any]? = nil, completion: @escaping ([String:Any])->()) {
        var request = URLRequest(url: URL(string: "\(Config.URL)/\(route)")!)
        
        // POST
        request.httpMethod = "POST"
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        
        let json = parameters!
        print(json)
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
            request.httpBody = jsonData
            
            let task = session.dataTask(with: request, completionHandler: {
                (data, response, error) in
                if error != nil {
                    print(error?.localizedDescription)
                }
                if data != nil {
                    do {
                        if let json = try JSONSerialization.jsonObject(with: data!, options: .allowFragments) as? [String: Any] {
                            print(json)
                            completion(json)
                        }
                    } catch {
                        print("serialization error")
                    }
                }
            })
            task.resume()
            
        } catch let error as NSError {
            //TODO: wherever there is an error, log it to the server.
            print(error)
        }
    }
}

// TODO: come back later to change this
// copied from the below stackoverflow answer.
// http://stackoverflow.com/questions/27723912/swift-get-request-with-parameters

extension Dictionary {
    
    /// Build string representation of HTTP parameter dictionary of keys and objects
    ///
    /// This percent escapes in compliance with RFC 3986
    ///
    /// http://www.ietf.org/rfc/rfc3986.txt
    ///
    /// :returns: String representation in the form of key1=value1&key2=value2 where the keys and values are percent escaped
    
    func stringFromHttpParameters() -> String {
        let parameterArray = self.map { (key, value) -> String in
            let percentEscapedKey = (key as! String).addingPercentEncodingForURLQueryValue()!
            let percentEscapedValue = (value as! String).addingPercentEncodingForURLQueryValue()!
            return "\(percentEscapedKey)=\(percentEscapedValue)"
        }
        
        return parameterArray.joined(separator: "&")
    }
    
}

extension String {
    
    /// Percent escapes values to be added to a URL query as specified in RFC 3986
    ///
    /// This percent-escapes all characters besides the alphanumeric character set and "-", ".", "_", and "~".
    ///
    /// http://www.ietf.org/rfc/rfc3986.txt
    ///
    /// :returns: Returns percent-escaped string.
    
    func addingPercentEncodingForURLQueryValue() -> String? {
        let allowedCharacters = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~")
        
        return self.addingPercentEncoding(withAllowedCharacters: allowedCharacters)
    }
    
}
