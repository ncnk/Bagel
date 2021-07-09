//
//  ViewController.swift
//  Bagel
//
//  Created by Yagiz Gurgul on 30/07/2018.
//  Copyright © 2018 Yagiz Lab. All rights reserved.
//

import Cocoa
import macOSThemeKit

class ViewController: NSViewController {

    var projectsViewController: ProjectsViewController?
    var devicesViewController: DevicesViewController?
    var packetsViewController: PacketsViewController?
    var detailVeiwController: DetailViewController?
    var lastDeviceID: String?
    
    var deviceInfoCache = [String: NSMutableAttributedString]()
    
    @IBOutlet weak var projectsBackgroundBox: NSBox!
    @IBOutlet weak var devicesBackgroundBox: NSBox!
    @IBOutlet weak var packetsBackgroundBox: NSBox!
    @IBOutlet weak var deviceInfoView: NSView!
    @IBOutlet weak var deviceInfoScrollView: NSScrollView!
    @IBOutlet var deviceInfoTextView: NSTextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        _ = BagelController.shared
        
        self.projectsBackgroundBox.fillColor = ThemeColor.projectListBackgroundColor
        self.devicesBackgroundBox.fillColor = ThemeColor.deviceListBackgroundColor
        self.packetsBackgroundBox.fillColor = ThemeColor.packetListAndDetailBackgroundColor
        
        self.deviceInfoView.layer?.backgroundColor = ThemeColor.projectListBackgroundColor.cgColor
        self.deviceInfoTextView.backgroundColor = ThemeColor.projectListBackgroundColor
        
        NotificationCenter.default.addObserver(self, selector: #selector(updateDeviceExtendInfo(notification:)), name: BagelNotifications.didGetPacket, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateDeviceExtendInfo(notification:)), name: BagelNotifications.didUpdatePacket, object: nil)
    }

    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {

        if let destinationVC = segue.destinationController as? ProjectsViewController {
            
            self.projectsViewController = destinationVC
            self.projectsViewController?.viewModel = ProjectsViewModel()
            self.projectsViewController?.viewModel?.register()
            
            self.projectsViewController?.onProjectSelect = { (selectedProjectController) in
                
                BagelController.shared.selectedProjectController = selectedProjectController
            }
            
        }
        

        if let destinationVC = segue.destinationController as? DevicesViewController {
            
            self.devicesViewController = destinationVC
            self.devicesViewController?.viewModel = DevicesViewModel()
            self.devicesViewController?.viewModel?.register()
            
//            self.devicesViewController?.deviceInfoRefreshBlock = { [weak self] (selectedDeviceController) in
//                self?.updateDeviceExtendInfo(device: selectedDeviceController)
//            }
            self.devicesViewController?.onDeviceSelect = { [weak self] (selectedDeviceController) in
                if let deviceID = selectedDeviceController.deviceId {
                    self?.refreUI(deviceID: deviceID)
                }
                BagelController.shared.selectedProjectController?.selectedDeviceController = selectedDeviceController
            }
            
        }
        

        if let destinationVC = segue.destinationController as? PacketsViewController {
            
            self.packetsViewController = destinationVC
            self.packetsViewController?.viewModel = PacketsViewModel()
            self.packetsViewController?.viewModel?.register()
            
            self.packetsViewController?.onPacketSelect = { (selectedPacket) in
            BagelController.shared.selectedProjectController?.selectedDeviceController?.select(packet: selectedPacket)
            }
            
        }
        

        if let destinationVC = segue.destinationController as? DetailViewController {
            
            self.detailVeiwController = destinationVC
            self.detailVeiwController?.viewModel = DetailViewModel()
            self.detailVeiwController?.viewModel?.register()
            
        }
    }
    
    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    lazy var formatter: DateFormatter = {
        let formatter = DateFormatter.init()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()
    
    @objc func updateDeviceExtendInfo(notification: Notification) {
        guard let packet = notification.userInfo?["packet"] as? BagelPacket else {
            return
        }
        
        guard let deviceId = packet.device?.deviceId else {
            return
        }
        
        let newInfoString = NSMutableAttributedString.init()
        
        if let infoString = deviceInfoCache[deviceId] {
            newInfoString.append(infoString)
        }
        else {
            let attString = TextStyles.descAttributedString(string: "\n↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓\n")
            newInfoString.append(attString)
            
            let deviceName = packet.device?.deviceName ?? "Unknown"
            let deviceAttString = TextStyles.deviceNameAttributedString(string: "> " + deviceName + "\n")
            newInfoString.append(deviceAttString)
        }
        
        let params: [String: String]? = packet.device?.extendInfo
        
        if let keys = params?.keys {
            let attString = TextStyles.descAttributedString(string: "----------------------------------\n")
            newInfoString.append(attString)
            
            let timeAttString = TextStyles.timeAttributedString(string: formatter.string(from: Date()) + "\n")
            newInfoString.append(timeAttString)
            for key in keys {
                let value = (params?[key] ?? "") + "\n"
                let keyAttString = TextStyles.descAttributedString(string: "\(key): ")
                let valueAttString = TextStyles.codeAttributedString(string: value)
                newInfoString.append(keyAttString)
                newInfoString.append(valueAttString)
            }
        }
        deviceInfoCache[deviceId] = newInfoString
        refreUI(deviceID: deviceId)
    }
    
    func refreUI(deviceID: String) {
        self.deviceInfoTextView.textStorage?.mutableString.setString("")
        guard let infoString = deviceInfoCache[deviceID] else {
            return
        }
        self.deviceInfoTextView.textStorage?.append(infoString)
        self.deviceInfoTextView.scrollRangeToVisible(.init(location: self.deviceInfoTextView.string.count, length: 0))
    }

}

