//
//  ThemePropertyViewController.swift
//  QLMardown
//
//  Created by Sbarex on 17/12/20.
//

import Cocoa

class ThemePropertyViewController: NSViewController {
    weak var popover: NSPopover?
    @IBOutlet weak var boxView: NSBox!
    
    var italic = false {
        willSet {
            self.willChangeValue(forKey: #keyPath(italic_index))
        }
        didSet {
            self.didChangeValue(forKey: #keyPath(italic_index))
        }
    }
    @objc dynamic var italic_overriden = false
    @objc dynamic var italic_index: Int {
        get {
            return italic ? 0 : 1
        }
        set {
            italic = newValue == 0
        }
    }
    
    var bold = false {
        willSet {
            self.willChangeValue(forKey: #keyPath(bold_index))
        }
        didSet {
            self.didChangeValue(forKey: #keyPath(bold_index))
        }
    }
    @objc dynamic var bold_overriden = false
    @objc dynamic var bold_index: Int {
        get {
            return bold ? 0 : 1
        }
        set {
            bold = newValue == 0
        }
    }
    
    var underline = false {
        willSet {
            self.willChangeValue(forKey: #keyPath(underline_index))
        }
        didSet {
            self.didChangeValue(forKey: #keyPath(underline_index))
        }
    }
    @objc dynamic var underline_overriden = false
    @objc dynamic var underline_index: Int {
        get {
            return underline ? 0 : 1
        }
        set {
            underline = newValue == 0
        }
    }
    
    var background = "#ffffff" {
        willSet {
            self.willChangeValue(forKey: #keyPath(background_color))
        }
        didSet {
            self.didChangeValue(forKey: #keyPath(background_color))
        }
    }
    @objc dynamic var background_overriden = false
    @objc dynamic var background_color: NSColor? {
        get {
            return NSColor(css: background)
        }
        set {
            if let css = newValue?.css() {
                background = css
            }
        }
    }
    @objc dynamic var foreground = "#000000"
    @objc dynamic var foreground_overriden = false
    @objc dynamic var foreground_color: NSColor? {
        get {
            return NSColor(css: foreground)
        }
        set {
            if let css = newValue?.css() {
                foreground = css
            }
        }
    }
    @objc dynamic var border = "#cccccc"
    @objc dynamic var border_overriden = false
    @objc dynamic var border_color: NSColor? {
        get {
            return NSColor(css: border)
        }
        set {
            if let css = newValue?.css() {
                border = css
            }
        }
    }
    
    var themeProperty: Theme.PropertyStyle? {
        didSet {
            italic = themeProperty?.italic ?? false
            italic_overriden = themeProperty?.italic != nil
            bold = themeProperty?.bold ?? false
            bold_overriden = themeProperty?.bold != nil
            underline = themeProperty?.underline ?? false
            underline_overriden = themeProperty?.underline != nil
            
            background = themeProperty?.background ?? "#ffffff"
            background_overriden = themeProperty?.background != nil
            foreground = themeProperty?.foreground ?? "#000000"
            foreground_overriden = themeProperty?.foreground != nil
            border = themeProperty?.border ?? "#cccccc"
            border_overriden = themeProperty?.border != nil
        }
    }
    var themePropertyKey: Theme.PropertyName? {
        didSet {
            self.boxView?.title = themePropertyKey?.name ?? ""
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let name = self.themePropertyKey?.name {
            self.boxView.title = "\(name) property"
        } else {
            self.boxView.title = "Property"
        }
    }
    
    @IBAction func doSave(_ sender: Any) {
        
    }
    @IBAction func doCancel(_ sender: Any) {
        if let popover = self.popover {
            popover.performClose(sender)
        } else {
            self.dismiss(self)
        }
    }
}

