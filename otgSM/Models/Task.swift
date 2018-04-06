//
//  Task.swift
//  otgSM
//
//  Created by Yongsung on 11/13/17.
//  Copyright © 2017 Delta. All rights reserved.
//

import UIKit

class Task: NSObject {
    let requester: String
    let taskLocation: String
    let dropOffLocation: String
    let taskDescription: String
    let requestTime: NSNumber
    let deadline: NSNumber
    let taskId: String
    
    init(requester: String, taskLocation: String, dropOffLocation: String, taskDescription: String, requestTime: NSNumber, deadline: NSNumber, taskId: String) {
        self.requester = requester
        self.taskLocation = taskLocation
        self.dropOffLocation = dropOffLocation
        self.taskDescription = taskDescription
        self.requestTime = requestTime
        self.deadline = deadline
        self.taskId = taskId
    }
    
}
