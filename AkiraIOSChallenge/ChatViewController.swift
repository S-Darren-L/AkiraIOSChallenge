//
//  ChatViewController.swift
//  AkiraIOSChallenge
//
//  Created by Darren on 2017-06-01.
//  Copyright © 2017 Daren. All rights reserved.
//

import UIKit
import OpenTok
import SlackTextViewController

class ChatViewController: SLKTextViewController {
    
    override var tableView: UITableView {
        return super.tableView!
    }
    
    lazy var messages = [Message]()
    
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
        getSessionCredentials()
        self.navigationItem.title = UIDevice.current.name
        initChatView()
    }
    
    func getSessionCredentials() {
        var urlPath: String = Constants.SAMPLE_SERVER_BASE_URL
        urlPath = urlPath + ("/session")
        let url = URL(string: urlPath)
        let request = NSMutableURLRequest(url: url!, cachePolicy: NSURLRequest.CachePolicy(rawValue: 4)!, timeoutInterval: 10)
        request.httpMethod = "GET"
        
        let session = URLSession.shared
        
        let task = session.dataTask(with: request as URLRequest, completionHandler: {data, response, error -> Void in
            print("Response: \(String(describing: response))")
            
            if error != nil {
                print("Error,\(String(describing: error?.localizedDescription)), URL: \(urlPath)")
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
    }
    
    func initChatView() {
        isInverted = false
        shakeToClearEnabled = true
        shouldScrollToBottomAfterKeyboardShows = true
        
        tableView.estimatedRowHeight = 44
        tableView.tableHeaderView = UIView()
        tableView.tableFooterView = UIView()
        
        textInputbar.autoHideRightButton = false
        textInputbar.backgroundColor = .lightGray
        textInputbar.rightButton.tintColor = .black
        
        textView.backgroundColor = .white
        textView.layer.borderWidth = 0
    }
    
    // MARK: - OpenTok methods
    func doConnect() {
        // Initialize a new instance of OTSession and begin the connection process.
        appSession = OTSession(apiKey: apiKey, sessionId: sessionId, delegate: self as?OTSessionDelegate)
        let error: AutoreleasingUnsafeMutablePointer<OTError?>? = nil
        try? appSession?.connect(withToken: token, error: error)
        if error != nil {
            print("Unable to connect to session (\(String(describing: error)))")
        }
    }
    
    func sendChatMessage(message: String) {
        let error: AutoreleasingUnsafeMutablePointer<OTError?>? = nil
        try? appSession?.signal(withType: "chat", string: message, connection: nil, error: error)
        if error != nil {
            print("Signal error: \(String(describing: error))")
        }
        else {
            print("Signal sent: \(String(describing: message))")
        }
    }
    
    func logSignal(_ message: Message) {
        print("received message is: \(message.messageText)")
        messages.append(message)
        self.tableView.reloadData()
    }
}

// MARK: - SlackTextViewController
extension ChatViewController {
    
    override class func tableViewStyle(for decoder: NSCoder) -> UITableViewStyle {
        return .plain
    }
    
    override func didPressRightButton(_ sender: Any?) {
        textView.refreshFirstResponder()
        let text = textView.text
        sendChatMessage(message: text!)
        super.didPressRightButton(sender)
    }
}

// MARK: - UITableViewDataSource
extension ChatViewController {
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let message = messages[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") ?? UITableViewCell(style: .default , reuseIdentifier: "Cell")
        if message.fromSelf == true {
            cell.textLabel?.textAlignment = .right
        } else {
            cell.textLabel?.textAlignment = .left
        }

        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.text = message.messageText
        cell.selectionStyle = .none
        cell.transform = tableView.transform
        return cell
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
    
    func session(_ session: OTSession, receivedSignalType type: String?, from connection: OTConnection?, with messageText: String?) {
        print("Received signal \(String(describing: messageText))")
        var fromSelf = false
        if (connection?.connectionId == session.connection?.connectionId) {
            fromSelf = true
        }
        let message = Message(messageText: messageText!, senderID: (connection?.connectionId)!, fromSelf: fromSelf)
        logSignal(message)
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
