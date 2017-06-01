//
//  ViewController.swift
//  AkiraIOSChallenge
//
//  Created by Darren on 2017-05-31.
//  Copyright © 2017 Daren. All rights reserved.
//

import UIKit
import OpenTok

// Replace with your OpenTok API key
let kApiKey = "45880472"
// Replace with your generated session ID
let kSessionId = "1_MX40NTg4MDQ3Mn5-MTQ5NjI5MDA1MDM1Mn5ZeGNRbTQ1QVRWUHoxdUdWMHU3bk1LVDd-fg"
// Replace with your generated token
let kToken = "T1==cGFydG5lcl9pZD00NTg4MDQ3MiZzaWc9MmQ5ZmQ1MjU0ZmM3Y2RlNTJiNzgwNWExZTNhMDExNTQ5NTdlNThkODpzZXNzaW9uX2lkPTFfTVg0ME5UZzRNRFEzTW41LU1UUTVOakk1TURBMU1ETTFNbjVaZUdOUmJUUTFRVlJXVUhveGRVZFdNSFUzYmsxTFZEZC1mZyZjcmVhdGVfdGltZT0xNDk2MjkwMDgwJm5vbmNlPTAuMjAwNTIyNTc4NzkyMzY4MTImcm9sZT1wdWJsaXNoZXImZXhwaXJlX3RpbWU9MTQ5ODg4MjA4MA=="

class VideoViewController: UIViewController {
    
    var session: OTSession?
    var publisher: OTPublisher?
    var subscriber: OTSubscriber?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        connectToAnOpenTokSession()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    func connectToAnOpenTokSession() {
        session = OTSession(apiKey: kApiKey, sessionId: kSessionId, delegate: self)
        var error: OTError?
        session?.connect(withToken: kToken, error: &error)
        if error != nil {
            print(error!)
        }
    }
}

// MARK: - OTSessionDelegate callbacks
extension VideoViewController: OTSessionDelegate {
    func sessionDidConnect(_ session: OTSession) {
        print("The client connected to the OpenTok session.")
        
        let settings = OTPublisherSettings()
        settings.name = UIDevice.current.name
        guard let publisher = OTPublisher(delegate: self, settings: settings) else {
            return
        }
        
        var error: OTError?
        session.publish(publisher, error: &error)
        guard error == nil else {
            print(error!)
            return
        }
        
        guard let publisherView = publisher.view else {
            return
        }
        let screenBounds = UIScreen.main.bounds
        publisherView.frame = CGRect(x: screenBounds.width - 150 - 20, y: screenBounds.height - 150 - 20, width: 150, height: 150)
        view.addSubview(publisherView)
    }
    
    func sessionDidDisconnect(_ session: OTSession) {
        print("The client disconnected from the OpenTok session.")
    }
    
    func session(_ session: OTSession, didFailWithError error: OTError) {
        print("The client failed to connect to the OpenTok session: \(error).")
    }
    
    func session(_ session: OTSession, streamCreated stream: OTStream) {
        print("A stream was created in the session.")
        subscriber = OTSubscriber(stream: stream, delegate: self)
        guard let subscriber = subscriber else {
            return
        }
        
        var error: OTError?
        session.subscribe(subscriber, error: &error)
        guard error == nil else {
            print(error!)
            return
        }
        
        guard let subscriberView = subscriber.view else {
            return
        }
        subscriberView.frame = UIScreen.main.bounds
        view.insertSubview(subscriberView, at: 0)
    }
    
    func session(_ session: OTSession, streamDestroyed stream: OTStream) {
        print("A stream was destroyed in the session.")
    }
}

// MARK: - OTPublisherDelegate callbacks
extension VideoViewController: OTPublisherDelegate {
    func publisher(_ publisher: OTPublisherKit, didFailWithError error: OTError) {
        print("The publisher failed: \(error)")
    }
}

// MARK: - OTSubscriberDelegate callbacks
extension VideoViewController: OTSubscriberDelegate {
    public func subscriberDidConnect(toStream subscriber: OTSubscriberKit) {
        print("The subscriber did connect to the stream.")
    }
    
    public func subscriber(_ subscriber: OTSubscriberKit, didFailWithError error: OTError) {
        print("The subscriber failed to connect to the stream.")
    }
}
