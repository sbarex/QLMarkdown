//
//  HighlightViewController.swift
//  QLMarkdown
//
//  Created by Sbarex on 14/04/23.
//

import AppKit

class HighlightViewController: NSViewController {
    weak var settingsViewController: ViewController? = nil
    
    @IBOutlet weak var highlightBackground: NSPopUpButton!
    
    @IBOutlet weak var sourceLightThemePopup: NSPopUpButton!
    @IBOutlet weak var sourceDarkThemePopup: NSPopUpButton!
    @IBOutlet weak var sourceThemeLightColor: NSColorWell!
    @IBOutlet weak var sourceThemeDarkColor: NSColorWell!
    @IBOutlet weak var sourceWrapField: NSTextField!
    @IBOutlet weak var sourceWrapStepper: NSStepper!
    @IBOutlet weak var sourceTabsPopup: NSPopUpButton!
    @IBOutlet weak var sourceFontLabel: NSTextField!
    @IBOutlet weak var guessEnginePopup: NSPopUpButton!
    
    @objc dynamic var customScheme: Bool {
        get {
            return self.settingsViewController?.syntaxCustomThemes ?? false
        }
        set {
            guard newValue != self.settingsViewController?.syntaxCustomThemes else { return }
            self.willChangeValue(forKey: "syntaxCustomThemes")
            self.settingsViewController?.syntaxCustomThemes = newValue
            self.didChangeValue(forKey: "syntaxCustomThemes")
        }
    }
    
    @objc dynamic var syntaxThemeLight: ThemePreview? {
        get {
            return self.settingsViewController?.syntaxThemeLight
        }
        set {
            guard newValue != self.settingsViewController?.syntaxThemeLight else { return }
            self.willChangeValue(forKey: "syntaxThemeLight")
            self.settingsViewController?.syntaxThemeLight = newValue
            self.didChangeValue(forKey: "syntaxThemeLight")
            self.updateThemesPopup()
        }
    }
    @objc dynamic var syntaxThemeDark: ThemePreview? {
        get {
            return self.settingsViewController?.syntaxThemeDark
        }
        set {
            guard newValue != self.settingsViewController?.syntaxThemeDark else { return }
            self.willChangeValue(forKey: "syntaxThemeDark")
            self.settingsViewController?.syntaxThemeDark = newValue
            self.didChangeValue(forKey: "syntaxThemeDark")
            self.updateThemesPopup()
        }
    }
    
    @objc dynamic var isCustomColorsVisible: Bool {
        get {
            return customBackgroundColor == BackgroundColor.custom.rawValue
        }
    }
    
    @objc dynamic var customBackgroundColor: Int {
        get {
            return self.settingsViewController?.customBackgroundColor ?? BackgroundColor.fromMarkdown.rawValue
        }
        set {
            guard newValue != self.settingsViewController?.customBackgroundColor else { return }
            self.willChangeValue(forKey: "customBackgroundColor")
            self.willChangeValue(forKey: "isCustomColorsVisible")
            self.settingsViewController?.customBackgroundColor = newValue
            self.didChangeValue(forKey: "customBackgroundColor")
            self.didChangeValue(forKey: "isCustomColorsVisible")
        }
    }
    
    @objc dynamic var backgroundColorLight: NSColor {
        get {
            return self.settingsViewController?.backgroundColorLight ?? NSColor.textBackgroundColor
        }
        set {
            guard newValue != self.settingsViewController?.backgroundColorLight else { return }
            self.willChangeValue(forKey: "backgroundColorLight")
            self.settingsViewController?.backgroundColorLight = newValue
            self.didChangeValue(forKey: "backgroundColorLight")
        }
    }
    
    @objc dynamic var backgroundColorDark: NSColor {
        get {
            return self.settingsViewController?.backgroundColorDark ?? NSColor.textBackgroundColor
        }
        set {
            guard newValue != self.settingsViewController?.backgroundColorDark else { return }
            self.willChangeValue(forKey: "backgroundColorDark")
            self.settingsViewController?.backgroundColorDark = newValue
            self.didChangeValue(forKey: "backgroundColorDark")
        }
    }
    
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
    
    @objc dynamic var isFontCustomized: Bool {
        get {
            return self.settingsViewController?.isFontCustomized ?? false
        }
        set {
            guard newValue != self.settingsViewController?.isFontCustomized else { return }
            self.willChangeValue(forKey: "isFontCustomized")
            self.settingsViewController?.isFontCustomized = newValue
            self.didChangeValue(forKey: "isFontCustomized")
            sourceFontLabel.textColor = newValue ? .labelColor : .disabledControlTextColor
        }
    }

    @objc dynamic var syntaxFontSize: CGFloat {
        get {
            return self.settingsViewController?.syntaxFontSize ?? 12
        }
        set {
            guard newValue != self.settingsViewController?.syntaxFontSize else { return }
            self.willChangeValue(forKey: "syntaxFontSize")
            self.settingsViewController?.syntaxFontSize = newValue
            self.didChangeValue(forKey: "syntaxFontSize")
        
            refreshFontPreview()
        }
    }
    
    @objc dynamic var syntaxFontFamily: String {
        get {
            return self.settingsViewController?.syntaxFontFamily ?? ""
        }
        set {
            guard newValue != self.settingsViewController?.syntaxFontFamily else { return }
            self.willChangeValue(forKey: "syntaxFontFamily")
            self.settingsViewController?.syntaxFontFamily = newValue
            self.didChangeValue(forKey: "syntaxFontFamily")
        
            refreshFontPreview()
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
    
    let themeMenuImageSize = CGSize(width: 32, height: 32)
    let themeMenuImageFont = NSFont.monospacedSystemFont(ofSize: 4, weight: NSFont.Weight.regular)
    
    var light_themes: [ThemePreview] = []
    var dark_themes: [ThemePreview] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleThemeChanged(_:)), name: .currentThemeDidChange, object: nil)
        
        self.sourceLightThemePopup.removeAllItems()
        self.sourceLightThemePopup.menu?.delegate = self
        
        self.sourceDarkThemePopup.removeAllItems()
        self.sourceDarkThemePopup.menu?.delegate = self
        
        if let settings = self.settingsViewController?.updateSettings() {
            let themes = settings.getAvailableThemes()
            light_themes = themes.filter({ $0.appearance == .light }).sorted(by: { $0.desc < $1.desc })
            dark_themes = themes.filter({ $0.appearance == .dark }).sorted(by: { $0.desc < $1.desc })
            
            var mnu = NSMenuItem(title: "", action: nil, keyEquivalent: "")
            self.sourceLightThemePopup.menu?.addItem(mnu)
            
            mnu = NSMenuItem(title: "", action: nil, keyEquivalent: "")
            var view = self.getSearchView()
            (view.subviews.first! as! NSSearchField).tag = 1
            mnu.view = view
            mnu.target = self
            self.sourceLightThemePopup.menu?.addItem(mnu)
            
            mnu = NSMenuItem(title: "", action: nil, keyEquivalent: "")
            mnu.indentationLevel = 0
            self.sourceDarkThemePopup.menu?.addItem(mnu)
            
            mnu = NSMenuItem(title: "", action: nil, keyEquivalent: "")
            view = self.getSearchView()
            (view.subviews.first! as! NSSearchField).tag = 2
            mnu.view = view
            mnu.target = self
            self.sourceDarkThemePopup.menu?.addItem(mnu)
            
            self.initFromSettings(settings)
            self.refreshFontPreview()
            self.updateThemesPopup()
        }
    }
    
    func getSearchView() -> NSView {
        let container = NSView(frame: NSRect(x: 8, y: 0, width: 100, height: 24))
        container.autoresizingMask = [.width, .height]
        
        let view = NSSearchField(frame: NSRect(x: 8, y: 0, width: 100, height: 24))
        container.addSubview(view)
        container.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-10-[input]-10-|", metrics: nil, views: ["input": view]))
        
        view.autoresizingMask = [.width, .height]
        view.translatesAutoresizingMaskIntoConstraints = false
        
        view.focusRingType = .none
        view.sendsSearchStringImmediately = true
        view.sendsWholeSearchString = false
        view.isContinuous = true
        view.delegate = self
        return container
    }
    
    func updateThemeMenu(menu: NSMenu, search: String) {
        let s = search.lowercased()
        
        while menu.items.count > 2 {
            menu.removeItem(at: 2)
        }
        
        var mnu = NSMenuItem(title: "Light themes", action: nil, keyEquivalent: "")
        mnu.isEnabled = false
        menu.addItem(mnu)
        var pos = menu.items.count - 1
        
        var found = false
        for (i, theme) in self.light_themes.enumerated() {
            if s.isEmpty || theme.desc.lowercased().contains(s) || theme.name.lowercased().contains(s) {
                found = true
                mnu = self.createThemeMenuItem(theme, current: nil)
                mnu.tag = i + 10 + 1
                menu.addItem(mnu)
            }
        }
        if !found {
            menu.removeItem(at: pos)
        }
        
        mnu = NSMenuItem(title: "Dark themes", action: nil, keyEquivalent: "")
        mnu.isEnabled = false
        menu.addItem(mnu)
        pos = menu.items.count - 1
        
        found = false
        for (i, theme) in self.dark_themes.enumerated() {
            if s.isEmpty || theme.desc.lowercased().contains(s) || theme.name.lowercased().contains(s) {
                found = true
                mnu = self.createThemeMenuItem(theme, current: nil)
                mnu.tag = -(i + 10 + 1)
                menu.addItem(mnu)
            }
        }
        if !found {
            menu.removeItem(at: pos)
        }
    }
    
    func createThemeMenuItem(_ theme: ThemePreview?, current: ThemePreview?) -> NSMenuItem {
        let mnu = NSMenuItem(title: theme?.desc ?? "N/D", action: nil, keyEquivalent: "")
        mnu.toolTip = theme?.name
        mnu.identifier = theme != nil ? NSUserInterfaceItemIdentifier(rawValue: theme!.fullName) : nil
        mnu.image = theme?.getImage(forSize: themeMenuImageSize, font: themeMenuImageFont)
        mnu.indentationLevel = 1
        mnu.state = (theme != nil && theme == current) ? .on : .off
        return mnu
    }
    
    @objc func handleThemeChanged(_ notification: Notification) {
        guard let theme = notification.object as? ThemePreview else { return }
        if theme.path == self.syntaxThemeLight?.path || theme.path == self.syntaxThemeDark?.path {
            self.updateThemesPopup()
        }
    }
    
    /// Refresh the preview font.
    internal func refreshFontPreview() {
        if self.syntaxFontFamily.isEmpty {
            self.sourceFontLabel.stringValue = "System font"
            self.sourceFontLabel.font = NSFont.systemFont(ofSize: NSFont.systemFontSize)
        } else {
            guard let font = NSFont(name: self.syntaxFontFamily, size: NSFont.systemFontSize) else {
                self.sourceFontLabel.stringValue = "???"
                self.sourceFontLabel.font = NSFont.systemFont(ofSize: NSFont.systemFontSize)
                return
            }
            
            let ff = font.familyName ?? font.fontName
            
            self.sourceFontLabel.stringValue = String(format:"%@ %.1f pt", ff, self.syntaxFontSize)
            self.sourceFontLabel.font = font
        }
    }
    
    /// Show panel to chose a new font.
    @IBAction func chooseFont(_ sender: NSButton) {
        let fontPanel = NSFontPanel.shared
        fontPanel.worksWhenModal = true
        fontPanel.becomesKeyOnlyIfNeeded = true
        
        let fontFamily: String  = self.syntaxFontFamily
        let fontSize: CGFloat = self.syntaxFontSize
        
        if let font = NSFont(name: fontFamily, size: fontSize) {
            NSFontManager.shared.setSelectedFont(font, isMultiple: false)
            // fontPanel.setPanelFont(font, isMultiple: false)
        }
        
        self.view.window?.makeFirstResponder(self)
        fontPanel.makeKeyAndOrderFront(self.settingsViewController)
    }
    
    @IBAction func doResetSourceThemes(_ sender: Any) {
        self.syntaxThemeLight = nil
        self.syntaxThemeDark = nil
    }
    
    @IBAction func doThemeChange(_ sender: NSPopUpButton)
    {
        guard let theme = Settings.shared.getAvailableThemes().first(where: { $0.fullName == sender.selectedItem?.identifier?.rawValue}) else {
            return
        }
        if sender == sourceLightThemePopup {
            self.syntaxThemeLight = theme
        } else {
            self.syntaxThemeDark = theme
        }
    }
    
    internal func updateThemesPopup() {
        if let settings = self.settingsViewController?.updateSettings() {
            let themes = settings.getAvailableThemes()
            light_themes = themes.filter({ $0.appearance == .light }).sorted(by: { $0.desc < $1.desc })
            dark_themes = themes.filter({ $0.appearance == .dark }).sorted(by: { $0.desc < $1.desc })
            
            let themeLight = themes.first(where: { $0.fullName == settings.syntaxThemeLight })
            let themeDark  = themes.first(where: { $0.fullName == settings.syntaxThemeDark })
            
            var mnu1 = self.createThemeMenuItem(themeLight, current: nil)
            if let mnu = self.sourceLightThemePopup.menu?.items.first {
                mnu.image = mnu1.image
                mnu.title = mnu1.title
                mnu.identifier = mnu1.identifier
                mnu.toolTip = mnu1.toolTip
            }
            self.sourceLightThemePopup.toolTip = themeLight != nil ? themeLight!.desc + " / " + themeLight!.name : nil
            
            mnu1 = self.createThemeMenuItem(themeDark, current: nil)
            if let mnu = self.sourceDarkThemePopup.menu?.items.first {
                mnu.image = mnu1.image
                mnu.title = mnu1.title
                mnu.identifier = mnu1.identifier
                mnu.toolTip = mnu1.toolTip
            }
            self.sourceDarkThemePopup.toolTip = themeDark != nil ? themeDark!.desc + " / " + themeDark!.name : nil
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
    
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        if segue.identifier == "ThemesSegue" {
            let vc0: ThemesSelectorViewController?
            if let vc1 = segue.destinationController as? ThemesSelectorViewController {
                vc0 = vc1
            } else if let wc1 = segue.destinationController as? NSWindowController, let vc1 = wc1.contentViewController as? ThemesSelectorViewController {
                vc0 = vc1
            } else {
                vc0 = nil
            }
            guard let vc = vc0 else {
                return
            }
            vc.lightTheme = self.syntaxThemeLight
            vc.darkTheme = self.syntaxThemeDark
            vc.handler = { light, dark in
                self.syntaxThemeLight = light
                self.syntaxThemeDark = dark
            }
        }
    }
    
    internal func initFromSettings(_ settings: Settings) {
        self.settingsViewController?.pauseAutoRefresh += 1
        self.settingsViewController?.pauseAutoSave += 1
        
        let themes = Settings.shared.getAvailableThemes()
        
        self.syntaxThemeLight = Self.searchTheme(settings.syntaxThemeLight, in: themes, appearance: .light)
        self.syntaxThemeDark = Self.searchTheme(settings.syntaxThemeDark, in: themes, appearance: .dark)
        
        self.syntaxLineNumbers = settings.syntaxLineNumbersOption
        self.syntaxWrapEnabled = settings.syntaxWordWrapOption > 0
        
        self.syntaxWrapCharacters = settings.syntaxWordWrapOption > 0 ? settings.syntaxWordWrapOption : 80
        if let i = self.sourceTabsPopup.itemArray.firstIndex(where: { $0.tag == settings.syntaxTabsOption}) {
            self.sourceTabsPopup.selectItem(at: i)
        }
        self.syntaxFontFamily = settings.syntaxFontFamily
        self.syntaxFontSize = settings.syntaxFontSize
        
        self.backgroundColorLight = NSColor(css: settings.syntaxBackgroundColorLight) ?? NSColor(css: settings.syntaxBackgroundColorDark) ?? NSColor(white: 0.9, alpha: 1)
        self.backgroundColorDark = NSColor(css: settings.syntaxBackgroundColorDark) ?? NSColor(white: 0.4, alpha: 1)
        
        self.guessEngine = settings.guessEngine.rawValue
                
        self.settingsViewController?.pauseAutoRefresh -= 1
        self.settingsViewController?.pauseAutoSave -= 1
    }
}

// MARK: - NSFontChanging
extension HighlightViewController: NSFontChanging {
    /// Handle the selection of a font.
    func changeFont(_ sender: NSFontManager?) {
        self.settingsViewController?.changeFont(sender)
    }
    
    /// Customize font panel.
    func validModesForFontPanel(_ fontPanel: NSFontPanel) -> NSFontPanel.ModeMask
    {
        self.settingsViewController?.validModesForFontPanel(fontPanel) ?? [.collection, .face, .size]
    }
}

extension AppDelegate: NSFontChanging {
    func getSettingsViewController()->ViewController? {
        return (NSApplication.shared.windows.first(where: { $0.contentViewController is ViewController }))?.contentViewController as? ViewController
    }
    
    /// Handle the selection of a font.
    func changeFont(_ sender: NSFontManager?) {
        if let vc = self.getSettingsViewController() {
            vc.changeFont(sender)
        }
    }
    
    /// Customize font panel.
    func validModesForFontPanel(_ fontPanel: NSFontPanel) -> NSFontPanel.ModeMask
    {
        return [.collection, .face, .size]
    }
}

// MARK: - NSSearchFieldDelegate
extension HighlightViewController: NSSearchFieldDelegate {
    func controlTextDidChange(_ obj: Notification) {
        if let sf = obj.object as? NSSearchField {
            updateThemeMenu(menu: sf.tag == 1 ? sourceLightThemePopup.menu! : sourceDarkThemePopup.menu!, search: sf.stringValue)
        }
    }
}

// MARK: - NSMenuDelegate
extension HighlightViewController: NSMenuDelegate {
    func menuWillOpen(_ menu: NSMenu) {
        if let sf = menu.items.first(where: { $0.view != nil })?.view?.subviews.first as? NSSearchField {
            sf.stringValue = ""
        }
        
        self.updateThemeMenu(menu: menu, search: "")
    }
}
