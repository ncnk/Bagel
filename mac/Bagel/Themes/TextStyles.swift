//
//  TextStyles.swift
//  Bagel
//
//  Created by Yagiz Gurgul on 8.10.2018.
//  Copyright © 2018 Yagiz Lab. All rights reserved.
//

import Cocoa
import macOSThemeKit

class TextStyles {
    
    static let codeAttributes = [NSAttributedString.Key.foregroundColor: ThemeColor.labelColor, NSAttributedString.Key.font: FontManager.codeFont(size: 13)]

    static func codeAttributedString(string: String) -> NSAttributedString {
        return NSAttributedString(string: string, attributes: codeAttributes)
    }

    static func addCodeAttributesToHTMLAttributedString(htmlAttributedString: NSMutableAttributedString) {
        htmlAttributedString.addAttributes(codeAttributes, range: NSRange(location: 0, length: htmlAttributedString.string.count))
    }
    
    
    static let descAttributes = [NSAttributedString.Key.foregroundColor: NSColor.lightGray, NSAttributedString.Key.font: FontManager.codeFont(size: 11)]
    
    static func descAttributedString(string: String) -> NSAttributedString {
        return NSAttributedString(string: string, attributes: descAttributes)
    }
    
    static let timeAttributes = [NSAttributedString.Key.foregroundColor: NSColor.darkGray, NSAttributedString.Key.font: FontManager.codeFont(size: 11)]
    
    static func timeAttributedString(string: String) -> NSAttributedString {
        return NSAttributedString(string: string, attributes: timeAttributes)
    }
}
