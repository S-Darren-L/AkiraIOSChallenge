//
//  ChatViewController.swift
//  AkiraIOSChallenge
//
//  Created by Darren on 2017-06-01.
//  Copyright © 2017 Daren. All rights reserved.
//

import UIKit
import OpenTok

class ChatViewController: UIViewController {
    
    @IBOutlet var chatReceivedTextView: UITextView!
    @IBOutlet var chatInputTextField: UITextField!
    @IBOutlet var sendButton: UIButton!
    
    private var appSession: OTSession?
    private var publisher: OTPublisher?
    private var subscriber: OTSubscriber?
    private var archiveId: String = ""
    private var apiKey: String = ""
    private var sessionId: String = ""
    private var token: String = ""
    
    // MARK: - View lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        chatInputTextField.delegate = self
        getSessionCredentials()
    }
    
    func getSessionCredentials() {
        var urlPath: String = Constants.SAMPLE_SERVER_BASE_URL
        urlPath = urlPath + ("/session")
        let url = URL(string: urlPath)
        let request = NSMutableURLRequest(url: url!, cachePolicy: NSURLRequest.CachePolicy(rawValue: 4)!, timeoutInterval: 10)
        request.httpMethod = "GET"
        
        let session = URLSession.shared
        
        
//        let params = ["username":"username", "password":"password"] as Dictionary<String, String>
//        
//        request.httpBody = try? JSONSerialization.data(withJSONObject: params, options: [])
//        
//        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
//        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        let task = session.dataTask(with: request as URLRequest, completionHandler: {data, response, error -> Void in
            print("Response: \(String(describing: response))")
            
            if error != nil {
                print("Error,\(error?.localizedDescription), URL: \(urlPath)")
            }
            else {
                let roomInfo: [AnyHashable: Any]? = try? JSONSerialization.jsonObject(with: data!) as! [String:Any]
                self.apiKey = (roomInfo?["apiKey"] as? String)!
                self.token = (roomInfo?["token"] as? String)!
                self.sessionId = (roomInfo?["sessionId"] as? String)!
                if self.apiKey == nil || self.token == nil || self.sessionId == nil {
                    print("Error invalid response from server, URL: \(urlPath)")
                }
                else {
                    self.doConnect()
                }
            }
        })
        
        task.resume()
        
//        NSURLConnection.sendAsynchronousRequest(request, queue: OperationQueue.main, completionHandler: {(_ response: URLResponse, _ data: Data, _ error: Error?) -> Void in
//            if error != nil {
//                print("Error,\(error?.localizedDescription), URL: \(urlPath)")
//            }
//            else {
//                let roomInfo: [AnyHashable: Any]? = try? JSONSerialization.jsonObject(withData: data, options: kNilOptions)
//                self.apiKey = (roomInfo?["apiKey"] as? String)
//                self.token = (roomInfo?["token"] as? String)
//                self.sessionId = (roomInfo?["sessionId"] as? String)
//                if !self.apiKey || !self.token || !self.sessionId {
//                    print("Error invalid response from server, URL: \(urlPath)")
//                }
//                else {
//                    self.doConnect()
//                }
//            }
//        })
    }
    
//    func shouldAutorotate(to interfaceOrientation: UIInterfaceOrientation) -> Bool {
//        // Return YES for supported orientations
//        if .phone == UIDevice.current.userInterfaceIdiom {
//            return false
//        }
//        else {
//            return true
//        }
//    }
    
    // MARK: - OpenTok methods
    func doConnect() {
        // Initialize a new instance of OTSession and begin the connection process.
        appSession = OTSession(apiKey: apiKey, sessionId: sessionId, delegate: self as?OTSessionDelegate)
        var error: AutoreleasingUnsafeMutablePointer<OTError?>? = nil
        try? appSession?.connect(withToken: token, error: error)
        if error != nil {
//            print("Unable to connect to session (\(error?.localizedDescription))")
        }
    }
    
    func sendChatMessage() {
        var error: AutoreleasingUnsafeMutablePointer<OTError?>? = nil
        try? appSession?.signal(withType: "chat", string: chatInputTextField.text!, connection: nil, error: error)
        if error != nil {
            print("Signal error: \(String(describing: error))")
        }
        else {
            print("Signal sent: \(String(describing: chatInputTextField.text))")
        }
        chatInputTextField.text = ""
    }
    
    func logSignal(_ string: String, fromSelf: Bool) {
        print("received message is: \(string)")
        let prevLength: Int = chatReceivedTextView.text.characters.count - 1
        chatReceivedTextView.insertText(string)
        chatReceivedTextView.insertText("\n")
        if fromSelf {
            let formatDict: [AnyHashable: Any] = [NSForegroundColorAttributeName: UIColor.blue]
            let textRange = NSRange(location: prevLength + 1, length:
                (string.characters.count))
            chatReceivedTextView.textStorage.setAttributes(formatDict as? [String : Any], range: textRange)
        }
        chatReceivedTextView.setContentOffset(chatReceivedTextView.contentOffset, animated: false)
        chatReceivedTextView.scrollRangeToVisible(NSRange(location: chatReceivedTextView.text.characters.count, length: 0))
    }
}

// MARK: - OTSessionDelegate callbacks
extension ChatViewController: OTSessionDelegate {
    // MARK: - OTSession delegate callbacks
    func sessionDidConnect(_ session: OTSession) {
    }
    
    func sessionDidDisconnect(_ session: OTSession) {
        let alertMessage: String = "Session disconnected: (\(session.sessionId))"
        print("sessionDidDisconnect (\(alertMessage))")
    }
    
    func session(_ session: OTSession, connectionCreated connection: OTConnection) {
        print("session connectionCreated (\(connection.connectionId))")
    }
    
    func session(_ session: OTSession, connectionDestroyed connection: OTConnection) {
        print("session connectionDestroyed (\(connection.connectionId))")
    }
    
    func session(_ session: OTSession, didFailWithError error: OTError) {
        print("didFailWithError: (\(error))")
    }
    
    func session(_ session: OTSession, streamCreated stream: OTStream) {
        print("A stream was created in the session.")
    }
    
    func session(_ session: OTSession, streamDestroyed stream: OTStream) {
        print("A stream was destroyed in the session.")
    }
    
    func session(_ session: OTSession, receivedSignalType type: String?, from connection: OTConnection?, with string: String?) {
        print("Received signal \(string)")
        var fromSelf: Bool = false
        if (connection?.connectionId == session.connection?.connectionId) {
            fromSelf = true
        }
        logSignal(string!, fromSelf: fromSelf)
    }
}

// MARK: - OTPublisherDelegate callbacks
extension ChatViewController: OTPublisherDelegate {
    func publisher(_ publisher: OTPublisherKit, didFailWithError error: OTError) {
        print("publisher didFailWithError \(error)")
    }
}

// MARK: - OTSubscriberDelegate callbacks
extension ChatViewController: OTSubscriberDelegate {
    func subscriberDidConnect(toStream subscriber: OTSubscriberKit) {
        print("subscriberDidConnectToStream (\(String(describing: subscriber.stream?.connection.connectionId)))")
    }
    
    func subscriber(_ subscriber: OTSubscriberKit, didFailWithError error: OTError) {
        print("subscriber \(String(describing: subscriber.stream?.streamId)) didFailWithError \(error)")
    }
}

// MARK: - UITextFieldDelegate callbacks
extension ChatViewController: UITextFieldDelegate{
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        chatInputTextField.text = ""
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        sendChatMessage()
        view.endEditing(true)
        return true
    }
}
