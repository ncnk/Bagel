//
//  DataJSONViewController.swift
//  Bagel
//
//  Created by Yagiz Gurgul on 2.10.2018.
//  Copyright © 2018 Yagiz Lab. All rights reserved.
//

import Cocoa
import WebKit
import macOSThemeKit

class DataJSONViewController: BaseViewController {

    var viewModel: DataJSONViewModel?
    
    var isRaw: Bool = false
    
    @IBOutlet weak var webView: WebView!
    @IBOutlet var rawTextView: NSTextView!
    
    @IBOutlet weak var rawTextScrollView: NSScrollView!
    
    @IBOutlet weak var rawButton: NSButton!
    @IBOutlet weak var copyToClipboardButton: NSButton!
    
    override func setup() {
        
        self.copyToClipboardButton.image = ThemeImage.copyToClipboardIcon
        
        self.setupJSONViewer()
        
        NotificationCenter.default.addObserver(self, selector: #selector(changedTheme(_:)), name: .didChangeTheme, object: nil)
        
        self.viewModel?.onChange = { [weak self] in
            
            self?.refresh()
        }
        
        self.refresh()
    }
    
    
    func setupJSONViewer() {
        
        let filePath = Bundle.main.path(forResource: "jsonviewer", ofType: "html")!
        let fileURL = URL(fileURLWithPath: filePath)
        let htmlRequest = URLRequest(url: fileURL)
        
        self.webView.frameLoadDelegate = self
        self.webView.drawsBackground = false
        self.webView.mainFrame.load(htmlRequest)
        self.refreshJSONEditorTheme()
    }
    
    
    func refresh() {
        
        if let jsonString = self.viewModel?.dataRepresentation?.rawString {
            
            self.webView.windowScriptObject.callWebScriptMethod("renderJSONString", withArguments: [jsonString])
            self.rawTextView.textStorage?.setAttributedString(TextStyles.codeAttributedString(string: jsonString ))
        }
        
        if self.isRaw {
            
            self.rawTextScrollView.isHidden = false
            self.webView.isHidden = true
            self.rawButton.state = .on
            
        }else {
            
            self.rawTextScrollView.isHidden = true
            self.webView.isHidden = false
            self.rawButton.state = .off
            
        }
    }
    
    func refreshJSONEditorTheme() {
        
        if ThemeManager.shared.effectiveTheme === ThemeManager.lightTheme {
            
            self.webView.windowScriptObject.callWebScriptMethod("changeThemeToLight", withArguments: [])
            
        }else if ThemeManager.shared.effectiveTheme === ThemeManager.darkTheme {
            
            self.webView.windowScriptObject.callWebScriptMethod("changeThemeToDark", withArguments: [])

        }
    }
    
    @objc private func changedTheme(_ notification: Notification) {
        
        self.refreshJSONEditorTheme()
    }
    
    @IBAction func rawButtonAction(_ sender: Any) {
        
        self.isRaw = !self.isRaw
        self.refresh()
    }
    
    @IBAction func copyButtonAction(_ sender: Any) {
        
        self.viewModel?.copyToClipboard()
    }
    
}

extension DataJSONViewController: WebFrameLoadDelegate {
    
    func webView(_ sender: WebView!, didFinishLoadFor frame: WebFrame!) {
        
        self.refreshJSONEditorTheme()
    }
}
