//
//  ThemeCollectionViewItem.swift
//  Syntax Highlight
//
//  Created by Sbarex on 01/05/2020.
//  Copyright © 2020 sbarex. All rights reserved.
//

import Cocoa

class ThemeCollectionViewItem: NSCollectionViewItem {
    override func awakeFromNib() {
        super.awakeFromNib()
        imageView?.wantsLayer = true
        imageView?.layer?.cornerRadius = 8
        imageView?.layer?.masksToBounds = true
        imageView?.layer?.borderWidth = 1
        imageView?.layer?.borderColor = NSColor.tertiaryLabelColor.cgColor
    }
    
    var theme: ThemePreview? {
        didSet {
            if let theme = self.theme {
                self.textField?.stringValue = theme.desc
                self.textField?.toolTip = theme.desc
                self.imageView?.image = theme.image
                self.imageView?.toolTip = theme.desc
            } else {
                self.textField?.stringValue = ""
                self.textField?.toolTip = nil
                self.imageView?.image = nil
                self.imageView?.toolTip = nil
            }
            
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        self.imageView?.image = nil
        self.imageView?.toolTip = nil
        
        self.textField?.stringValue = ""
        self.textField?.toolTip = nil
        
        imageView?.wantsLayer = true
        imageView?.layer?.cornerRadius = 8
        imageView?.layer?.masksToBounds = true
        imageView?.layer?.borderWidth = 1
        imageView?.layer?.borderColor = NSColor.tertiaryLabelColor.cgColor
    }
}
