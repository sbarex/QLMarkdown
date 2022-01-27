//
//  ThemePropertyViewController.swift
//  QLMarkdown
//
//  Created by Sbarex on 17/12/20.
//

import Cocoa

class ThemePropertyViewController: NSViewController {
    weak var popover: NSPopover?
    @IBOutlet weak var boxView: NSBox!
    
    @objc dynamic var italic: Int = 0
    @objc dynamic var bold: Int = 0
    @objc dynamic var underline: Int = 0
    
    @objc dynamic var isEditable: Bool = false
    
    var action: ((_ vc: ThemePropertyViewController)->Void)?
    
    var color = "#999999" {
        willSet {
            self.willChangeValue(forKey: #keyPath(color_color))
        }
        didSet {
            self.didChangeValue(forKey: #keyPath(color_color))
        }
    }
    @objc dynamic var color_color: NSColor? {
        get {
            return NSColor(css: color)
        }
        set {
            if let css = newValue?.css() {
                color = css
            }
        }
    }
    
    var theme: Theme?
    var name: Theme.PropertyName?
    func setTheme(_ theme: Theme, property name: Theme.PropertyName) {
        self.theme = theme
        self.name = name
        let property = theme[name]
        
        if let i = property?.italic {
            italic = i ? 1 : 2
        } else {
            italic = 0
        }
        if let i = property?.bold {
            bold = i ? 1 : 2
        } else {
            bold = 0
        }
        if let i = property?.underline {
            underline = i ? 1 : 2
        } else {
            underline = 0
        }
        
        color = property?.color ?? "#999999"
        
        self.boxView?.title = "\(name.name) property"
        
        isEditable = !theme.isStandalone
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let name = self.name?.name {
            self.boxView.title = "\(name) property"
        } else {
            self.boxView.title = "Property"
        }
    }
    
    @IBAction func doSave(_ sender: Any) {
        action?(self)
        if let popover = self.popover {
            popover.performClose(sender)
        } else {
            self.dismiss(self)
        }
    }
    
    @IBAction func doCancel(_ sender: Any) {
        if let popover = self.popover {
            popover.performClose(sender)
        } else {
            self.dismiss(self)
        }
    }
}

