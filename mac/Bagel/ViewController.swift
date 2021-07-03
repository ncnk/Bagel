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
    
    @IBOutlet weak var projectsBackgroundBox: NSBox!
    @IBOutlet weak var devicesBackgroundBox: NSBox!
    @IBOutlet weak var packetsBackgroundBox: NSBox!
    @IBOutlet weak var deviceInfoView: NSView!
    @IBOutlet var deviceInfoTextView: NSTextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        _ = BagelController.shared
        
        self.projectsBackgroundBox.fillColor = ThemeColor.projectListBackgroundColor
        self.devicesBackgroundBox.fillColor = ThemeColor.deviceListBackgroundColor
        self.packetsBackgroundBox.fillColor = ThemeColor.packetListAndDetailBackgroundColor
        
        self.deviceInfoView.layer?.backgroundColor = ThemeColor.projectListBackgroundColor.cgColor
        self.deviceInfoTextView.backgroundColor = ThemeColor.projectListBackgroundColor
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
            
            self.devicesViewController?.currentDeviceBlock = { [weak self] (selectedDeviceController) in
                
                self?.setDeviceExtendInfo(params: selectedDeviceController.extendInfo)
            }
            self.devicesViewController?.onDeviceSelect = { [weak self] (selectedDeviceController) in
                
                self?.setDeviceExtendInfo(params: selectedDeviceController.extendInfo)
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

    
    func setDeviceExtendInfo(params: [String: String]?) {
        self.deviceInfoTextView.textStorage?.mutableString.setString("")
        
        guard let keys = params?.keys else {
            return
        }
        for key in keys {
            let value = (params?[key] ?? "") + "\n"
            let keyAttString = TextStyles.descAttributedString(string: "\(key): ")
            let valueAttString = TextStyles.codeAttributedString(string: value)
            self.deviceInfoTextView.textStorage?.append(keyAttString)
            self.deviceInfoTextView.textStorage?.append(valueAttString)
        }
    }

}

