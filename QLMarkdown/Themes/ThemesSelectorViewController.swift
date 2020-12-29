//
//  ThemesSelectorViewController.swift
//  QLMarkdown
//
//  Created by Sbarex on 28/12/20.
//

import Cocoa

class ThemesSelectorViewController: NSViewController {
    var lightTheme: ThemePreview? {
        didSet {
            if let theme = lightTheme {
                lighThemeButton?.image = theme.image
                lighThemeLabel?.attributedStringValue = theme.getAttributedTitle()
            } else {
                lighThemeButton?.image = nil
                lighThemeLabel?.stringValue = "inherit from document style"
            }
        }
    }
    var darkTheme: ThemePreview? {
        didSet {
            if let theme = darkTheme {
                darkThemeButton?.image = theme.image
                darkThemeLabel?.attributedStringValue = theme.getAttributedTitle()
            } else {
                darkThemeButton?.image = nil
                darkThemeLabel?.stringValue = "inherit from document style"
            }
        }
    }
    
    var handler: ((ThemePreview?, ThemePreview?) -> Void)?
    
    @IBOutlet weak var lighThemeButton: NSButton!
    @IBOutlet weak var darkThemeButton: NSButton!
    @IBOutlet weak var lighThemeLabel: NSTextField!
    @IBOutlet weak var darkThemeLabel: NSTextField!
    
    @IBAction func showThemeSelector(_ sender: NSButton) {
        guard let vc = self.storyboard?.instantiateController(withIdentifier:"ThemeSelector") as? ThemeSelectorViewController else {
            return
        }
        
        vc.style = sender.tag == 2 ? .dark : .light
        vc.handler = { theme in
            if vc.style == .light {
                self.lightTheme = theme
            } else {
                self.darkTheme = theme
            }
        }
        vc.allThemes = Settings.shared.getAvailableThemes()
        
        self.present(vc, asPopoverRelativeTo: sender.frame, of: sender.superview!, preferredEdge: NSRectEdge.maxY, behavior: NSPopover.Behavior.semitransient)
    }
    
    @IBAction func doDone(_ sender: Any) {
        handler?(lightTheme, darkTheme)
        self.view.window?.close()
        // self.dismiss(sender)
    }
    
    
    @IBAction func doCancel(_ sender: Any) {
        // self.dismiss(sender)
        self.view.window?.close()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        for btn in [self.lighThemeButton, self.darkThemeButton] {
            // Add round corners and border to the theme icons.
            btn?.wantsLayer = true
            btn?.layer?.cornerRadius = 8
            btn?.layer?.borderWidth = 1
            btn?.layer?.borderColor = NSColor.tertiaryLabelColor.cgColor
        }
        
        lighThemeButton?.image = lightTheme?.image
        lighThemeLabel?.attributedStringValue = lightTheme?.getAttributedTitle() ?? NSAttributedString()
        
        darkThemeButton?.image = darkTheme?.image
        darkThemeLabel?.attributedStringValue = darkTheme?.getAttributedTitle() ?? NSAttributedString()
    }
    
    
}
