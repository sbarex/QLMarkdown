//
//  HighlightViewController.swift
//  QLMarkdown
//
//  Created by Sbarex on 14/04/23.
//

import AppKit

class HighlightViewController: NSViewController {
    weak var settingsViewController: ViewController? = nil
    
    @IBOutlet weak var sourceWrapField: NSTextField!
    @IBOutlet weak var sourceWrapStepper: NSStepper!
    @IBOutlet weak var sourceTabsPopup: NSPopUpButton!
    @IBOutlet weak var guessEnginePopup: NSPopUpButton!
    
    
    @objc dynamic var syntaxLineNumbers: Bool {
        get {
            return self.settingsViewController?.syntaxLineNumbers ?? false
        }
        set {
            guard newValue != self.settingsViewController?.syntaxLineNumbers else { return }
            self.willChangeValue(forKey: "syntaxLineNumbers")
            self.settingsViewController?.syntaxLineNumbers = newValue
            self.didChangeValue(forKey: "syntaxLineNumbers")
        }
    }
    
    @objc dynamic var syntaxWrapEnabled: Bool {
        get {
            return self.settingsViewController?.syntaxWrapEnabled ?? false
        }
        set {
            guard newValue != self.settingsViewController?.syntaxWrapEnabled else { return }
            self.willChangeValue(forKey: "syntaxWrapEnabled")
            self.settingsViewController?.syntaxWrapEnabled = newValue
            self.didChangeValue(forKey: "syntaxWrapEnabled")
        }
    }
    
    @objc dynamic var syntaxWrapCharacters: Int {
        get {
            return self.settingsViewController?.syntaxWrapCharacters ?? 80
        }
        set {
            guard newValue != self.settingsViewController?.syntaxWrapCharacters else { return }
            self.willChangeValue(forKey: "syntaxWrapCharacters")
            self.settingsViewController?.syntaxWrapCharacters = newValue
            self.didChangeValue(forKey: "syntaxWrapCharacters")
        }
    }
    
    @objc dynamic var syntaxTabsOption: Int {
        get {
            return self.settingsViewController?.syntaxTabsOption ?? 80
        }
        set {
            guard newValue != self.settingsViewController?.syntaxTabsOption else { return }
            self.willChangeValue(forKey: "syntaxTabsOption")
            self.settingsViewController?.syntaxTabsOption = newValue
            self.didChangeValue(forKey: "syntaxTabsOption")
        }
    }
    
    @objc dynamic var guessEngine: Int {
        get {
            return self.settingsViewController?.guessEngine ?? 0
        }
        set {
            guard newValue != self.settingsViewController?.guessEngine else { return }
            self.willChangeValue(forKey: "guessEngine")
            self.settingsViewController?.guessEngine = newValue
            self.didChangeValue(forKey: "guessEngine")
        }
    }
    
    @IBAction func onGuessChange(_ sender: NSPopUpButton)
    {
        self.guessEngine = sender.selectedTag()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let settings = self.settingsViewController?.updateSettings() {
            self.initFromSettings(settings)
        }
    }
    
    class func searchTheme(_ name: String, in themes: [ThemePreview], appearance: Theme.ThemeAppearance) -> ThemePreview? {
        let base16 = name.hasPrefix("base16/")
        let t_name = base16 ? String(name.dropLast("base16/".count)) : name
        let fullpath = t_name.contains("/")
        if let t = themes.first(where: {
                if fullpath {
                    return $0.path == t_name
                } else {
                    return $0.name == t_name && $0.isBase16 == base16
                }
            }) {
            return t;
        } else {
            return nil
        }
    }
    
    internal func initFromSettings(_ settings: Settings) {
        self.settingsViewController?.pauseAutoRefresh += 1
        self.settingsViewController?.pauseAutoSave += 1
        
        self.syntaxLineNumbers = settings.syntaxLineNumbersOption
        self.syntaxWrapEnabled = settings.syntaxWordWrapOption > 0
        
        self.syntaxWrapCharacters = settings.syntaxWordWrapOption > 0 ? settings.syntaxWordWrapOption : 80
        if let i = self.sourceTabsPopup.itemArray.firstIndex(where: { $0.tag == settings.syntaxTabsOption}) {
            self.sourceTabsPopup.selectItem(at: i)
        }
        
        self.guessEngine = settings.guessEngine.rawValue
                
        self.settingsViewController?.pauseAutoRefresh -= 1
        self.settingsViewController?.pauseAutoSave -= 1
    }
}
