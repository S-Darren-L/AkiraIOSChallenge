//
//  ViewController.swift
//  AkiraIOSChallenge
//
//  Created by Darren on 2017-05-31.
//  Copyright © 2017 Daren. All rights reserved.
//

import UIKit
import OpenTok


class VideoViewController: UIViewController {
    
    @IBOutlet var endCallButton: UIButton!
    @IBOutlet var swapCameraButton: UIButton!
    @IBOutlet var muteMicButton: UIButton!
    @IBOutlet var userName: UILabel!
    @IBOutlet var collectionView: UICollectionView!
    @IBOutlet var topLableView: UIView!
    @IBOutlet var bottomControlView: UIView!
    
    var subscribers: [IndexPath: OTSubscriber] = [:]
    lazy var session: OTSession = {
        return OTSession(apiKey: Constants.kApiKey, sessionId: Constants.kSessionId, delegate: self)!
    }()
    lazy var publisher: OTPublisher = {
        let settings = OTPublisherSettings()
        settings.name = UIDevice.current.name
        return OTPublisher(delegate: self, settings: settings)!
    }()
    var error: OTError?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        doConnect()
        userName.text = UIDevice.current.name
    }
    
    override func viewDidAppear(_ animated: Bool) {
//        guard let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout else {
//            return
//        }
//        layout.itemSize = CGSize(width: collectionView.bounds.size.width / 2,
//                                 height: collectionView.bounds.size.height / 2)
    }
    
    @IBAction func swapCameraAction(_ sender: UIButton) {
        if publisher.cameraPosition == .front {
            publisher.cameraPosition = .back
        } else {
            publisher.cameraPosition = .front
        }
    }
    
    @IBAction func muteMicAction(_ sender: UIButton) {
        publisher.publishAudio = !publisher.publishAudio
        
        let buttonImage: UIImage  = {
            if !publisher.publishAudio {
                return #imageLiteral(resourceName: "mic_muted-24")
            } else {
                return #imageLiteral(resourceName: "mic-24")
            }
        }()
        
        muteMicButton.setImage(buttonImage, for: .normal)
    }
    
    @IBAction func endCallAction(_ sender: UIButton) {
        session.disconnect(&error)
    }
    
    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        reloadCollectionView()
    }
    
    func reloadCollectionView() {
        collectionView.isHidden = subscribers.count == 0
        collectionView.reloadData()
    }
    
    func isPortrait() -> Bool{
        if UIDevice.current.orientation == UIDeviceOrientation.portrait {
            return true
        }else{
            return false
        }
    }
}

extension VideoViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return subscribers.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "subscriberCell", for: indexPath) as! SubscriberCollectionCell
        cell.subscriber = subscribers[indexPath]
        return cell
    }
}

extension VideoViewController: UICollectionViewDelegate {
}

// MARK: - Subscriber Cell
class SubscriberCollectionCell: UICollectionViewCell {
    @IBOutlet var muteButton: UIButton!
    
    var subscriber: OTSubscriber?
    
    @IBAction func muteSubscriberAction(_ sender: UIButton) {
        subscriber?.subscribeToAudio = !(subscriber?.subscribeToAudio ?? true)
        
        let buttonImage: UIImage  = {
            if !(subscriber?.subscribeToAudio ?? true) {
                return #imageLiteral(resourceName: "Subscriber-Speaker-Mute-35")
            } else {
                return #imageLiteral(resourceName: "Subscriber-Speaker-35")
            }
        }()
        
        muteButton.setImage(buttonImage, for: .normal)
    }
    
    override func layoutSubviews() {
        if let sub = subscriber, let subView = sub.view {
            subView.frame = bounds
            contentView.insertSubview(subView, belowSubview: muteButton)
            
            muteButton.isEnabled = true
            muteButton.isHidden = false
        }
    }
}

// MARK: - OpenTok Methods
extension VideoViewController{/**
     * Asynchronously begins the session connect process. Some time later, we will
     * expect a delegate method to call us back with the results of this action.
     */
    fileprivate func doConnect() {
        var error: OTError?
        defer {
            processError(error: error)
        }
        session.connect(withToken: Constants.kToken, error: &error)
    }
    
    /**
     * Sets up an instance of OTPublisher to use with this session. OTPubilsher
     * binds to the device camera and microphone, and will provide A/V streams
     * to the OpenTok session.
     */
    fileprivate func doPublish() {
        
        swapCameraButton.isEnabled = true
        muteMicButton.isEnabled = true
        endCallButton.isEnabled = true
        
        if let pubView = publisher.view {
            var publisherDimensions = CGSize()
            if isPortrait(){
                publisherDimensions = CGSize(width: view.bounds.size.height / 6,
                                                 height: view.bounds.size.height / 4)
            }else{
                publisherDimensions = CGSize(width: view.bounds.size.width / 6,
                                             height: view.bounds.size.width / 4)
            }
            pubView.frame = CGRect(origin: CGPoint(x:collectionView.bounds.size.width - publisherDimensions.width,
                                                   y:collectionView.bounds.size.height - publisherDimensions.height + collectionView.frame.origin.y),
                                   size: publisherDimensions)
            view.addSubview(pubView)
            
        }
        
        session.publish(publisher, error: &error)
    }
    
    fileprivate func doSubscribe(_ stream: OTStream) {
        if let subscriber = OTSubscriber(stream: stream, delegate: self) {
            let indexPath = IndexPath(item: subscribers.count, section: 0)
            subscribers[indexPath] = subscriber
            session.subscribe(subscriber, error: &error)
            
            reloadCollectionView()
        }
    }
    
    func findSubscriber(byStreamId id: String) -> (IndexPath, OTSubscriber)? {
        for (_, entry) in subscribers.enumerated() {
            if let stream = entry.value.stream, stream.streamId == id {
                return (entry.key, entry.value)
            }
        }
        return nil
    }
    
    func findSubscriberCell(byStreamId id: String) -> SubscriberCollectionCell? {
        for cell in collectionView.visibleCells {
            if let subscriberCell = cell as? SubscriberCollectionCell,
                let subscriberOfCell = subscriberCell.subscriber,
                (subscriberOfCell.stream?.streamId ?? "") == id
            {
                return subscriberCell
            }
        }
        
        return nil
    }
    
    fileprivate func processError(error: OTError?) {
        if let error = error {
            showAlert(errorStr: error.localizedDescription)
        }
    }
    
    fileprivate func showAlert(errorStr err: String) {
        DispatchQueue.main.async {
            let controller = UIAlertController(title: "Error", message: err, preferredStyle: .alert)
            controller.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
            self.present(controller, animated: true, completion: nil)
        }
    }
}

// MARK: - OTSessionDelegate callbacks
extension VideoViewController: OTSessionDelegate {
    func sessionDidConnect(_ session: OTSession) {
        print("The client connected to the OpenTok session.")
        doPublish()
    }
    
    func sessionDidDisconnect(_ session: OTSession) {
        print("The client disconnected from the OpenTok session.")
        subscribers.removeAll()
        reloadCollectionView()
    }
    
    func session(_ session: OTSession, streamCreated stream: OTStream) {
        print("Session streamCreated: \(stream.streamId)")
        doSubscribe(stream)
    }
    
    func session(_ session: OTSession, streamDestroyed stream: OTStream) {
        print("Session streamDestroyed: \(stream.streamId)")
        
        guard let (index, subscriber) = findSubscriber(byStreamId: stream.streamId) else {
            return
        }
        subscriber.view?.removeFromSuperview()
        subscribers.removeValue(forKey: index)
        reloadCollectionView()
    }
    
    func session(_ session: OTSession, didFailWithError error: OTError) {
        print("session Failed to connect: \(error.localizedDescription)")
    }
}

// MARK: - OTPublisherDelegate callbacks
extension VideoViewController: OTPublisherDelegate {
    func publisher(_ publisher: OTPublisherKit, streamCreated stream: OTStream) {
    }
    
    func publisher(_ publisher: OTPublisherKit, streamDestroyed stream: OTStream) {
    }
    
    func publisher(_ publisher: OTPublisherKit, didFailWithError error: OTError) {
        print("Publisher failed: \(error.localizedDescription)")
    }
}

// MARK: - OTSubscriberDelegate callbacks
extension VideoViewController: OTSubscriberDelegate {
    func subscriberDidConnect(toStream subscriberKit: OTSubscriberKit) {
        print("Subscriber connected")
        reloadCollectionView()
    }
    
    func subscriber(_ subscriber: OTSubscriberKit, didFailWithError error: OTError) {
        print("Subscriber failed: \(error.localizedDescription)")
    }
    
    func subscriberVideoDataReceived(_ subscriber: OTSubscriber) {
    }
}
