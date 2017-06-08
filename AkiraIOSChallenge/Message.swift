//
//  Message.swift
//  AkiraIOSChallenge
//
//  Created by Darren on 2017-06-08.
//  Copyright © 2017 Daren. All rights reserved.
//

import Foundation
import UIKit

class Message {
    var messageText: String
    var senderID: String
    var fromSelf: Bool
    
    init(messageText: String, senderID: String, fromSelf: Bool) {
        self.messageText = messageText
        self.senderID = senderID
        self.fromSelf = fromSelf
    }
    
}
