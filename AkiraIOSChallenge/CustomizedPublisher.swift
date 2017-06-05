//
//  CustomizedPublisher.swift
//  AkiraIOSChallenge
//
//  Created by Darren on 2017-06-04.
//  Copyright © 2017 Daren. All rights reserved.
//

import Foundation
import OpenTok

class CustomizedPublisher: OTPublisher {
    // Video capturer is not "retained" by the capturer so it is important
    // to save it as an instance variable
    var exampleCapturer: CustomizedVideoCapture?
    var exampleRenderer: CustomizedVideoRender?
    
    override init?(delegate: OTPublisherKitDelegate!, name: String!, audioTrack: Bool, videoTrack: Bool) {
        let settings = OTPublisherSettings()
        settings.name = name
        settings.videoTrack = videoTrack
        settings.audioTrack = audioTrack
        super.init(delegate: delegate, settings: settings)
    }
    override init?(delegate: OTPublisherKitDelegate!, name: String!) {
        let settings = OTPublisherSettings()
        settings.name = name
        super.init(delegate: delegate, settings: settings)
        exampleCapturer = CustomizedVideoCapture()
        exampleRenderer = CustomizedVideoRender()
        videoCapture = exampleCapturer!
        videoRender = exampleRenderer!
    }
    
    override var view: UIView {
        get {
            return exampleRenderer!
        }
    }
}
