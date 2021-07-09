//
//  PeertablPublisher.swift
//  Bagel
//
//  Created by chengqihang on 2021/7/8.
//  Copyright © 2021 Yagiz Lab. All rights reserved.
//

import Cocoa
import PeerTalk

protocol PeertablPublisherDelegate: NSObject{
    func didReceiveNewPacketData(packetData: Data)
}

class PeertablPublisher: NSObject {
    
    static let shared = PeertablPublisher()
    var channels = [NSNumber: PTChannel]()
    var deviceIDs = [NSNumber]()
    weak var delegate: PeertablPublisherDelegate?
    var isRunning: Bool = false
    
    func startListener() {
        if isRunning {
            return
        }
        isRunning = true
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name.deviceDidAttach, object: PTUSBHub.shared(), queue: nil) { notification in
            guard let deviceID = notification.userInfo?[PTUSBHubNotificationKey.deviceID] as? NSNumber else {
                return
            }
            self.deviceIDs.append(deviceID)
            DispatchQueue.main.async {
                self.connect(deviceID: deviceID)
            }
        }
        NotificationCenter.default.addObserver(forName: NSNotification.Name.deviceDidDetach, object: PTUSBHub.shared(), queue: nil) { notification in
            guard let deviceID = notification.userInfo?[PTUSBHubNotificationKey.deviceID] as? NSNumber else {
                return
            }
            let channel = self.channels[deviceID]
            channel?.close()
            self.channels.removeValue(forKey: deviceID)
            if let index = self.deviceIDs.index(of: deviceID) {
                self.deviceIDs.remove(at: index)
            }
        }

        let timer = Timer.init(timeInterval: 2, repeats:true) { (timer) in
            self.loop()
        }
        RunLoop.current.add(timer, forMode: .default)
        timer.fire()
        
    }
    
    private func loop() {
        for deviceID in deviceIDs {
            if let channel = channels[deviceID], channel.isConnected {
                continue
            }
            connect(deviceID: deviceID)
        }
    }

    private func connect(deviceID: NSNumber) {
        if channels[deviceID] != nil {
            return
        }
        let channel = PTChannel.init(protocol: nil, delegate: self)
        channel.userInfo = deviceID
        channel.connect(to: 43210, over: PTUSBHub.shared(), deviceID: deviceID) { error in
            if error == nil {
                self.channels[deviceID] = channel
            }
            else {
//                debugPrint("")
            }
        }
    }
}

extension PeertablPublisher: PTChannelDelegate {
    
    func channel(_ channel: PTChannel, didAcceptConnection otherChannel: PTChannel, from address: PTAddress) {
    }
    
    func channel(_ channel: PTChannel, shouldAcceptFrame type: UInt32, tag: UInt32, payloadSize: UInt32) -> Bool {
        return true
    }
    
    func channel(_ channel: PTChannel, didRecieveFrame type: UInt32, tag: UInt32, payload: Data?) {
        if let data = payload {
            delegate?.didReceiveNewPacketData(packetData: data)
        }
    }
    
    func channelDidEnd(_ channel: PTChannel, error: Error?) {
        channel.close()
        if let deviceID = channel.userInfo as? NSNumber {
            channels.removeValue(forKey: deviceID)
        }
    }
    
}
