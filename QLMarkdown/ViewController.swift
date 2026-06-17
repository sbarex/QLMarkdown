//
//  ViewController.swift
//  QLMarkdown
//
//  Created by sbarex on 09/12/20.
//

import Cocoa
@preconcurrency import WebKit
import OSLog

class ViewController: NSViewController {
    @objc dynamic var elapsedTimeLabel: String = ""
    
    @objc dynamic var headsExtension: Bool = Settings.factorySettings.headsExtension {
        didSet {
            guard oldValue != headsExtension else { return }
            isDirty = true
        }
    }
    @objc dynamic var tableExtension: Bool = Settings.factorySettings.tableExtension {
        didSet {
            guard oldValue != tableExtension else { return }
            isDirty = true
        }
    }
    @objc dynamic var autoLinkExtension: Bool = Settings.factorySettings.autoLinkExtension {
        didSet {
            guard oldValue != autoLinkExtension else { return }
            isDirty = true
        }
    }
    @objc dynamic var tagFilterExtension: Bool = Settings.factorySettings.tagFilterExtension {
        didSet {
            guard oldValue != tagFilterExtension else { return }
            isDirty = true
        }
    }
    @objc dynamic var taskListExtension: Bool = Settings.factorySettings.taskListExtension {
        didSet {
            guard oldValue != taskListExtension else { return }
            isDirty = true
        }
    }
    @objc dynamic var yamlExtension: Bool = Settings.factorySettings.yamlExtension != .disabled {
        didSet {
            guard oldValue != yamlExtension else { return }
            updateYamlPopup()
            isDirty = true
        }
    }
    @objc dynamic var yamlExtensionAll: Bool = Settings.factorySettings.yamlExtension == .allFiles {
        didSet {
            guard oldValue != yamlExtensionAll else { return }
            updateYamlPopup()
            isDirty = true
        }
    }
    
    @objc dynamic var strikethroughExtension: Bool = Settings.factorySettings.strikethroughExtension != .disabled {
        didSet {
            guard oldValue != strikethroughExtension else { return }
            isDirty = true
            updateStrikethroughPopup()
        }
    }
    dynamic var strikethroughDoubleTildeOption: Bool = Settings.factorySettings.strikethroughExtension == .double {
        didSet {
            guard oldValue != strikethroughDoubleTildeOption else { return }
            isDirty = true
            updateStrikethroughPopup()
        }
    }
    
    @objc dynamic var mentionExtension: Bool = Settings.factorySettings.mentionExtension {
        didSet {
            guard oldValue != mentionExtension else { return }
            isDirty = true
        }
    }
    
    @objc dynamic var syntaxHighlightExtension: Bool = Settings.factorySettings.syntaxHighlightExtension {
        didSet {
            guard oldValue != syntaxHighlightExtension else { return }
            isDirty = true
        }
    }
    
    @objc dynamic var syntaxLineNumbers: Bool = Settings.factorySettings.syntaxLineNumbersOption {
        didSet {
            guard oldValue != syntaxLineNumbers else { return }
            isDirty = true
        }
    }
    
    @objc dynamic var syntaxWrapEnabled: Bool = Settings.factorySettings.syntaxWordWrapOption > 0 {
        didSet {
            guard oldValue != syntaxWrapEnabled else { return }
            isDirty = true
        }
    }
    
    @objc dynamic var syntaxWrapCharacters: Int = Settings.factorySettings.syntaxWordWrapOption > 0 ? Settings.factorySettings.syntaxWordWrapOption : 80 {
        didSet {
            guard oldValue != syntaxWrapCharacters else { return }
            isDirty = true
        }
    }
    
    @objc dynamic var syntaxTabsOption: Int = Settings.factorySettings.syntaxTabsOption {
        didSet {
            guard oldValue != syntaxTabsOption else { return }
            isDirty = true
        }
    }
    
    @objc dynamic var mathExtension: Bool = !Settings.factorySettings.mathExtension.isDisabled {
        didSet {
            guard oldValue != mathExtension else { return }
            updateMathPopup()
            isDirty = true
        }
    }
    
    @objc dynamic var mathExtensionEmbed: Bool = false {
        didSet {
            guard oldValue != mathExtensionEmbed else { return }
            updateMathPopup()
            isDirty = true
        }
    }

    @objc dynamic var mermaidExtension: Bool = !Settings.factorySettings.mermaidExtension.isDisabled {
        didSet {
            guard oldValue != mermaidExtension else { return }
            updateMermaidPopup()
            isDirty = true
        }
    }
    
    @objc dynamic var mermaidExtensionEmbed: Bool = false {
        didSet {
            guard oldValue != mermaidExtensionEmbed else { return }
            updateMermaidPopup()
            isDirty = true
        }
    }

    @objc dynamic var highlightExtension: Bool = Settings.factorySettings.highlightExtension {
        didSet {
            guard oldValue != highlightExtension else { return }
            isDirty = true
        }
    }
    
    @objc dynamic var subSuperScriptExtension: Bool = Settings.factorySettings.subExtension {
        didSet {
            guard oldValue != subSuperScriptExtension else { return }
            isDirty = true
        }
    }
    
    @objc dynamic var emojiExtension: Bool = Settings.factorySettings.emojiExtension != .disabled {
        didSet {
            guard oldValue != emojiExtension else { return }
            updateEmojiPopup()
            isDirty = true
        }
    }
    @objc dynamic var emojiImageOption: Bool = Settings.factorySettings.emojiExtension == .images {
        didSet {
            guard oldValue != emojiImageOption else { return }
            updateEmojiPopup()
            isDirty = true
        }
    }
    
    @objc dynamic var inlineImageExtension: Bool = Settings.factorySettings.inlineImageExtension {
        didSet {
            guard oldValue != inlineImageExtension else { return }
            isDirty = true
            if inlineImageExtension {
                self.unsafeHTMLOption = true
            }
        }
    }
    
    @objc dynamic var hardBreakOption: Bool = Settings.factorySettings.hardBreakOption {
        didSet {
            guard oldValue != hardBreakOption else { return }
            isDirty = true
        }
    }
    @objc dynamic var noSoftBreakOption: Bool = Settings.factorySettings.noSoftBreakOption {
        didSet {
            guard oldValue != noSoftBreakOption else { return }
            isDirty = true
        }
    }
    @objc dynamic var unsafeHTMLOption: Bool = Settings.factorySettings.unsafeHTMLOption {
        didSet {
            guard oldValue != unsafeHTMLOption else { return }
            isDirty = true
        }
    }
    @objc dynamic var validateUTFOption: Bool = Settings.factorySettings.validateUTFOption {
        didSet {
            guard oldValue != validateUTFOption else { return }
            isDirty = true
        }
    }
    @objc dynamic var smartQuotesOption: Bool = Settings.factorySettings.smartQuotesOption {
        didSet {
            guard oldValue != smartQuotesOption else { return }
            isDirty = true
        }
    }
    @objc dynamic var footnotesOption: Bool = Settings.factorySettings.footnotesOption {
        didSet {
            guard oldValue != footnotesOption else { return }
            isDirty = true
        }
    }
    
    @objc dynamic var debugMode: Bool = Settings.factorySettings.debug {
        didSet {
            guard oldValue != debugMode else { return }
            isDirty = true
        }
    }
    
    @objc dynamic var renderAsCode: Bool = Settings.factorySettings.renderAsCode {
        didSet {
            guard oldValue != renderAsCode else { return }
            isDirty = true
        }
    }
    
    @objc dynamic var qlWindowSizeCustomized: Bool = false {
        didSet {
            guard oldValue != qlWindowSizeCustomized else { return }
            isDirty = true
            qlWindowSizePopupButton.selectItem(at: qlWindowSizeCustomized ? 1 : 0)
        }
    }
    @objc dynamic var qlWindowWidth: Int = Settings.factorySettings.qlWindowWidth ?? 1000 {
        didSet {
            guard oldValue != qlWindowWidth else { return }
            isDirty = true
        }
    }
    @objc dynamic var qlWindowHeight: Int = Settings.factorySettings.qlWindowHeight ?? 800 {
        didSet {
            guard oldValue != qlWindowHeight else { return }
            isDirty = true
        }
    }

    
    @objc dynamic var useBaseFontSize: Bool = Settings.factorySettings.baseFontSize > 0 {
        didSet {
            guard oldValue != useBaseFontSize else { return }
            isDirty = true
        }
    }
    
    @objc dynamic var baseFontSize: CGFloat = Settings.factorySettings.baseFontSize {
        didSet {
            guard oldValue != baseFontSize else { return }
            isDirty = true
        }
    }
    
    @objc dynamic var customCSSOverride: Bool = Settings.factorySettings.customCSSOverride {
        didSet {
            guard oldValue != customCSSOverride else { return }
            isDirty = true
            styleExtendPopup.selectItem(at: customCSSOverride ? 1 : 0)
        }
    }
    @objc dynamic var customCSSFile: URL? = Settings.factorySettings.customCSS {
        didSet {
            guard oldValue != customCSSFile else { return }
            isDirty = true
            updateCustomCSSPopup()
        }
    }
    
    internal var pauseAutoSave = 0 {
        didSet {
            if pauseAutoSave == 0 && isDirty && isLoaded && isAutoSaving {
                saveAction(self)
            }
        }
    }
    
    @objc dynamic var isAutoSaving: Bool {
        get {
            return UserDefaults.standard.value(forKey: "auto-save") as? Bool ?? true
        }
        set {
            guard newValue != isAutoSaving else { return }
            
            self.willChangeValue(forKey: "isAutoSaving")
            UserDefaults.standard.setValue(newValue, forKey: "auto-save")
            self.didChangeValue(forKey: "isAutoSaving")
            
            if newValue && isDirty && pauseAutoSave == 0 {
                saveAction(self)
            }
        }
    }
    
    @objc dynamic var isAboutVisible: Bool = Settings.factorySettings.about {
        didSet {
            guard oldValue != isAboutVisible else { return }
            isDirty = true
        }
    }
    
    var firstView = true
    
    func initStylesPopup(resetStyles: Bool = false) {
        stylesPopup.removeAllItems()
        // Standard CSS
        stylesPopup.addItem(withTitle: NSLocalizedString("GitHub ( Default )", comment: "Default GitHub style name"))
        stylesPopup.lastItem?.tag = -100
        
        // stylesPopup.addItem(withTitle: "None")
        // stylesPopup.lastItem?.tag = -101
        
        stylesPopup.menu?.addItem(NSMenuItem.separator())
        
        // Actions
        stylesPopup.addItem(withTitle: NSLocalizedString("Open Application support themes folder", comment: "Styles popup action"))
        stylesPopup.lastItem?.tag = -4
        
        stylesPopup.addItem(withTitle: NSLocalizedString("Reveal CSS in Finder", comment: "Styles popup action"))
        stylesPopup.lastItem?.tag = -6
        stylesPopup.lastItem?.isAlternate = true
        stylesPopup.lastItem?.keyEquivalentModifierMask = [.option]
        
        stylesPopup.addItem(withTitle: NSLocalizedString("Refresh", comment: "Styles popup action"))
        stylesPopup.lastItem?.tag = -5
        
        stylesPopup.menu?.addItem(NSMenuItem.separator())
        
        stylesPopup.addItem(withTitle: NSLocalizedString("Import…", comment: "Styles popup action"))
        stylesPopup.lastItem?.tag = -2
        stylesPopup.lastItem?.toolTip = NSLocalizedString("Import a CSS file into the standard themes folder.", comment: "Import style tooltip")
        
        stylesPopup.addItem(withTitle: NSLocalizedString("Browse…", comment: "Styles popup action"))
        stylesPopup.lastItem?.tag = -1
        stylesPopup.lastItem?.isAlternate = true
        stylesPopup.lastItem?.keyEquivalentModifierMask = [.option]
        stylesPopup.lastItem?.toolTip = NSLocalizedString("Use a custom CSS file without importing into the standard themes folder.", comment: "Browse style tooltip")

        let custom_styles = Settings.getAvailableStyles(resetCache: resetStyles)
        for url in custom_styles {
            addStyleSheet(url)
        }
        
        // stylesPopup.menu?.insertItem(NSMenuItem.separator(), at: stylesPopup.numberOfItems-6)
    }
    
    
    @discardableResult
    internal func addStyleSheet(_ file: URL) -> Int {
        let name: String
        let standalone: Bool
        if let folder = Settings.stylesFolder?.path, file.path.hasPrefix(folder) {
            name = String(file.path.dropFirst(folder.count + 1))
            standalone = true
        } else {
            name = file.path
            standalone = false
        }
        
        var index = 1
        while stylesPopup.item(at: index)?.tag ?? -1 >= 0 {
            index += 1
        }
        index -= 1
        stylesPopup.insertItem(withTitle: name, at: index)
        if standalone {
            stylesPopup.menu?.item(at: index)?.tag = 1
        }
        
        if index > 0 && !(stylesPopup.item(at: 1)?.isSeparatorItem ?? true) {
            stylesPopup.menu?.insertItem(NSMenuItem.separator(), at: 1)
            index += 1
        }
        if !(stylesPopup.item(at: index+1)?.isSeparatorItem ?? true) {
            stylesPopup.menu?.insertItem(NSMenuItem.separator(), at: index+1)
        }
        return index
    }
    
    func updateCustomCSSPopup() {
        if let style = customCSSFile {
            guard style.lastPathComponent != "-" else {
                self.stylesPopup.selectItem(withTag: -101)
                return
            }
            let base = Settings.stylesFolder
            if let index = stylesPopup.itemArray.firstIndex(where: {
                guard !$0.isSeparatorItem && $0.tag >= 0 else {
                    return false
                }
                let file: String
                if $0.tag == 1, let base = base {
                    file = base.appendingPathComponent($0.title).path
                } else {
                    file = $0.title
                }
                return file == style.path }) {
                self.stylesPopup.selectItem(at: index)
            } else {
                let i = addStyleSheet(style)
                self.stylesPopup.selectItem(at: i)
            }
        } else {
            self.stylesPopup.selectItem(at: 0)
        }
    }
    
    var autoRefresh: Bool {
        get {
            return UserDefaults.standard.value(forKey: "auto-refresh") as? Bool ?? true
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: "auto-refresh")
            if newValue {
                doRefresh(self)
            }
        }
    }
    
    internal var pauseAutoRefresh = 0 {
        didSet {
            guard pauseAutoRefresh == 0 else {
                return
            }
            if isDirty && isLoaded {
                if autoRefresh {
                    self.refresh(self)
                }
                if isAutoSaving {
                    self.saveAction(self)
                }
            }
        }
    }
    internal var isDirty = false {
        didSet {
            self.view.window?.isDocumentEdited = isDirty
            if isDirty && autoRefresh && isLoaded && pauseAutoRefresh == 0 {
                self.refresh(self)
            }
            if isDirty && isAutoSaving && isLoaded && pauseAutoSave == 0 {
                self.saveAction(self)
            }
        }
    }
    internal var isLoaded = false
    
    @IBOutlet weak var tabView: NSTabView!
    @IBOutlet weak var tabViewLeftConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var webView: WKWebView!
    @IBOutlet weak var textView: NSTextView!
    @IBOutlet weak var stylesPopup: NSPopUpButton!
    
    @IBOutlet weak var styleExtendPopup: NSPopUpButton!
    
    @IBOutlet weak var strikethroughPopupButton: NSPopUpButton!
    @IBOutlet weak var emojiPopupButton: NSPopUpButton!
    @IBOutlet weak var yamlPopupButton: NSPopUpButton!
    @IBOutlet weak var highlightPopupButton: NSPopUpButton!
    
    @IBOutlet weak var mathPopupButton: NSPopUpButton!
    @IBOutlet weak var mermaidPopupButton: NSPopUpButton!
    
    @IBOutlet weak var unsafeButton: NSButton!
    
    @IBOutlet weak var progressIndicator: NSProgressIndicator!
    @IBOutlet weak var inlineLinkPopup: NSPopUpButton!
    
    @IBOutlet weak var appearanceButton: NSButton!
    
    @IBOutlet weak var qlWindowSizePopupButton: NSPopUpButton!
    
    @IBOutlet weak var fontSizeField: NSTextField!
    @IBOutlet weak var fontSizeStepper: NSStepper!
    
    var byteFormatter = ByteCountFormatter()
    
    var edited: Bool = false
    var allow_reload: Bool = true
    fileprivate var markdown_source: DispatchSourceFileSystemObject?
    var markdown_file: URL? {
        didSet {
            if let file = markdown_file {
                do {
                    let s = try String(contentsOf: file, encoding: .utf8)
                    self.textView.string = s
                } catch {
                    self.textView.string = "** Error loading file *\(file.path)*! **"
                }
                
                self.startMonitorFile()
            } else {
                self.textView.string = ""
            }
            self.textView.setSelectedRange(NSRange(location: 0, length: 0))
            prev_scroll = -1
            
            if isLoaded {
                doRefresh(self)
            }
            edited = false
        }
    }
    internal var prev_scroll: Int = -1
    
    deinit {
        self.markdown_source?.cancel()
    }
    
    @IBAction func doDirty(_ sender: Any) {
        isDirty = true
    }
    
    @IBAction func handleAppearanceChange(_ sender: NSButton) {
        let dark = sender.state == .on
        self.view.window?.appearance = NSAppearance(named: dark ? NSAppearance.Name.darkAqua : NSAppearance.Name.aqua)
        sender.toolTip = dark
            ? NSLocalizedString("Switch to light appearance.", comment: "Appearance button tooltip")
            : NSLocalizedString("Switch to dark appearance.", comment: "Appearance button tooltip")
        self.doRefresh(sender)
    }
    
    @IBAction func doStyleOverrideChange(_ sender: NSPopUpButton) {
        self.customCSSOverride = sender.indexOfSelectedItem == 1
    }
    
    @IBAction func handleStrikethroughPopup(_ sender: NSPopUpButton) {
        let tag = sender.selectedTag()
        if tag == -1 {
            self.strikethroughExtension = false
        } else {
            pauseAutoRefresh += 1
            self.strikethroughExtension = true
            self.strikethroughDoubleTildeOption = tag == 2
            pauseAutoRefresh -= 1
        }
    }
    
    func updateStrikethroughPopup() {
        if !strikethroughExtension {
            strikethroughPopupButton.title = NSLocalizedString("Strikethrough", comment: "Strikethrough popup title")
        } else {
            strikethroughPopupButton.title = String(format: NSLocalizedString("Strikethrough (%@)", comment: "Strikethrough popup title with mode"), self.strikethroughDoubleTildeOption ? "~~" : "~")
        }
    }
    
    @IBAction func handleEmojiPopup(_ sender: NSPopUpButton) {
        let tag = sender.selectedTag()
        if tag == -1 {
            self.emojiExtension = false
        } else {
            pauseAutoRefresh += 1
            self.emojiExtension = true
            self.emojiImageOption = tag == 2
            pauseAutoRefresh -= 1
        }
    }
    
    func updateEmojiPopup() {
        if !emojiExtension {
            emojiPopupButton.title = NSLocalizedString("Emoji", comment: "Emoji popup title")
        } else {
            let mode = self.emojiImageOption
                ? NSLocalizedString("images", comment: "Emoji replacement mode")
                : NSLocalizedString("font", comment: "Emoji replacement mode")
            emojiPopupButton.title = String(format: NSLocalizedString("Emoji (%@)", comment: "Emoji popup title with mode"), mode)
        }
    }
    
    @IBAction func handleYamlPopup(_ sender: NSPopUpButton) {
        let tag = sender.selectedTag()
        if tag == -1 {
            self.yamlExtension = false
        } else {
            pauseAutoRefresh += 1
            self.yamlExtension = true
            self.yamlExtensionAll = tag == 2
            pauseAutoRefresh -= 1
        }
    }
    
    func updateYamlPopup() {
        if !yamlExtension {
            yamlPopupButton.title = NSLocalizedString("YAML header", comment: "YAML popup title")
        } else {
            let mode = self.yamlExtensionAll
                ? NSLocalizedString("all files", comment: "YAML extension mode")
                : NSLocalizedString(".rmd, .qmd files", comment: "YAML extension mode")
            yamlPopupButton.title = String(format: NSLocalizedString("YAML header (%@)", comment: "YAML popup title with mode"), mode)
        }
    }
    
    @IBAction func handleSyntaxHighlightMenu(_ menuItem: NSMenuItem) {
        switch menuItem.identifier?.rawValue {
        case "mnu_highlight_ln":
            self.syntaxLineNumbers = !self.syntaxLineNumbers
        case "mnu_highlight_tab_0", "mnu_highlight_tab_2", "mnu_highlight_tab_4", "mnu_highlight_tab_8":
            self.syntaxTabsOption = menuItem.tag
        case "mnu_highlight_ww_0":
            self.syntaxWrapEnabled = false
        case "mnu_highlight_ww_80", "mnu_highlight_ww_120", "mnu_highlight_ww_custom":
            self.syntaxWrapEnabled = true
            self.syntaxWrapCharacters = menuItem.tag
        case "mnu_highlight_ww_x":
            if let v = getNumber(message: NSLocalizedString("Set a word wrap after this number of chars:", comment: "Syntax highlighting word wrap prompt"), value: 80) {
                self.syntaxWrapCharacters = v
            }
        case "mnu_highlight_on":
            self.syntaxHighlightExtension = true
        case "mnu_highlight_off":
            self.syntaxHighlightExtension = false
        default:
            break
        }
    }
    
    func getNumber(message: String, informativeText: String = "", value: Int) -> Int? {
        let alert = NSAlert()
        alert.messageText = message
        alert.informativeText = informativeText
        alert.addButton(withTitle: NSLocalizedString("OK", comment: "Default confirmation button")).keyEquivalent = "\r"
        alert.addButton(withTitle: NSLocalizedString("Cancel", comment: "Default cancel button")).keyEquivalent = "\u{1b}"
        
        let input = NSTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
        input.integerValue = value
        
        let formatter = NumberFormatter()
        formatter.allowsFloats = false
        input.formatter = formatter
        
        alert.accessoryView = input
        
        DispatchQueue.main.async {
            alert.window.makeFirstResponder(input)
        }
        
        if alert.runModal() == .alertFirstButtonReturn {
            return input.integerValue
        } else {
            return nil
        }
    }
    
    func handleJSExtensionPopup(_ sender: NSPopUpButton, libraryName name: String, `extension`: inout Bool, extensionEmbedded: inout Bool, fileUrl: URL?, cacheUrl: URL?, webUrl: URL) {
        let tag = sender.selectedTag()
        
        if tag == -1 /* disabled */ {
            `extension` = false
        } else if tag == 10, let cacheUrl /* fetch */ {
            let alert = NSAlert()
            alert.messageText = NSLocalizedString("Are you sure to locally cache the library from the web?", comment: "JavaScript library cache confirmation")
            alert.alertStyle = .informational
            alert.addButton(withTitle: NSLocalizedString("OK", comment: "Default confirmation button")).keyEquivalent = "\r"
            alert.addButton(withTitle: NSLocalizedString("Cancel", comment: "Default cancel button")).keyEquivalent = "\u{1b}"
            
            let r = alert.runModal()
            if r == .alertFirstButtonReturn {
                Settings.fetchCacheFile(from: webUrl, to: cacheUrl) { (success) in
                    DispatchQueue.main.async {
                        let alert = NSAlert()
                        alert.alertStyle = success ? .warning : .informational
                        alert.messageText = success
                            ? String(format: NSLocalizedString("%@ library downloaded from web.", comment: "JavaScript library download success"), name)
                            : String(format: NSLocalizedString("Error downloading the %@ library.", comment: "JavaScript library download failure"), name)
                        alert.addButton(withTitle: NSLocalizedString("OK", comment: "Default confirmation button")).keyEquivalent = "\r"
                        alert.runModal()
                    }
                }
            }
        } else if tag == 20 /* save */ {
            guard let file = fileUrl, FileManager.default.fileExists(atPath: file.path) else {
                let alert = NSAlert()
                alert.messageText = NSLocalizedString("No cached file to save!", comment: "JavaScript library cache save error")
                alert.alertStyle = .warning
                alert.addButton(withTitle: NSLocalizedString("Close", comment: "Default close button")).keyEquivalent = "\u{1b}"
                alert.runModal()
                return
            }
            
            let panel = NSOpenPanel()
                
            panel.title = NSLocalizedString("Choose the destination folder", comment: "Save cached library panel title")
            panel.canChooseFiles = false
            panel.canChooseDirectories = true
            panel.allowsMultipleSelection = false
            
            panel.begin { response in
                if response == .OK, let url = panel.url {
                    let dest = url.appendingPathComponent(file.lastPathComponent)
                    if FileManager.default.fileExists(atPath: dest.path) {
                        let alert = NSAlert()
                        alert.messageText = NSLocalizedString("A file with the same name already exists. Do you want to overwrite it?", comment: "Overwrite confirmation")
                        alert.alertStyle = .informational
                        alert.addButton(withTitle: NSLocalizedString("No", comment: "Default no button")).keyEquivalent = "\u{1b}"
                        alert.addButton(withTitle: NSLocalizedString("Yes", comment: "Default yes button")).keyEquivalent = ""
                        if alert.runModal() == .alertSecondButtonReturn {
                            do {
                                try FileManager.default.removeItem(at: dest)
                            } catch {
                                let alert = NSAlert()
                                alert.messageText = NSLocalizedString("Error deleting existing file!", comment: "Delete existing file error")
                                alert.alertStyle = .critical
                                alert.addButton(withTitle: NSLocalizedString("Close", comment: "Default close button")).keyEquivalent = "\u{1b}"
                                alert.runModal()
                                return
                            }
                        } else {
                            return
                        }
                    }
                    do {
                        try FileManager.default.copyItem(at: file, to: dest)
                        NSWorkspace.shared.activateFileViewerSelecting([dest])
                    } catch {
                        let alert = NSAlert()
                        alert.messageText = NSLocalizedString("Unable to save the file!", comment: "Save file error")
                        alert.alertStyle = .critical
                        alert.addButton(withTitle: NSLocalizedString("Close", comment: "Default close button")).keyEquivalent = "\u{1b}"
                        alert.runModal()
                        return
                    }
                }
            }
        } else if tag == 21 /* reveal */ {
            guard let file = fileUrl, FileManager.default.fileExists(atPath: file.path) else {
                let alert = NSAlert()
                alert.messageText = NSLocalizedString("No cached file to reveal!", comment: "JavaScript library cache reveal error")
                alert.alertStyle = .warning
                alert.addButton(withTitle: NSLocalizedString("Close", comment: "Default close button")).keyEquivalent = "\u{1b}"
                alert.runModal()
                return
            }
            
            NSWorkspace.shared.activateFileViewerSelecting([file])
        } else {
            pauseAutoRefresh += 1
            `extension` = true
            extensionEmbedded = tag == 1
            pauseAutoRefresh -= 1
        }
    }
    
    @IBAction func handleMathPopup(_ sender: NSPopUpButton) {
        handleJSExtensionPopup(sender, libraryName: "MathJax", extension: &self.mathExtension, extensionEmbedded: &self.mathExtensionEmbed, fileUrl: Settings.shared.mathJaxFileUrl, cacheUrl: Settings.mathJaxCacheFileUrl, webUrl: Settings.mathJaxWebUrl)
    }
    
    func updateMathPopup() {
        if !mathExtension {
            mathPopupButton.title = NSLocalizedString("Math extension", comment: "Math extension popup title")
        } else {
            let mode = self.mathExtensionEmbed
                ? NSLocalizedString("embedded", comment: "Embedded JavaScript extension mode")
                : NSLocalizedString("linked", comment: "Linked JavaScript extension mode")
            mathPopupButton.title = String(format: NSLocalizedString("Math extension (%@)", comment: "Math extension popup title with mode"), mode)
        }
    }
    
    @IBAction func handleMermaidPopup(_ sender: NSPopUpButton) {
        handleJSExtensionPopup(sender, libraryName: "Mermaid", extension: &self.mermaidExtension, extensionEmbedded: &self.mermaidExtensionEmbed, fileUrl: Settings.shared.mermaidFileUrl, cacheUrl: Settings.mermaidCacheFileUrl, webUrl: Settings.mermaidWebUrl)
    }
    
    func updateMermaidPopup() {
        if !mermaidExtension {
            mermaidPopupButton.title = NSLocalizedString("Mermaid diagram", comment: "Mermaid diagram popup title")
        } else {
            let mode = self.mermaidExtensionEmbed
                ? NSLocalizedString("embedded", comment: "Embedded JavaScript extension mode")
                : NSLocalizedString("linked", comment: "Linked JavaScript extension mode")
            mermaidPopupButton.title = String(format: NSLocalizedString("Mermaid diagram (%@)", comment: "Mermaid diagram popup title with mode"), mode)
        }
    }
    
    @discardableResult
    func openMarkdown(file: URL) -> Bool {
        if edited {
            let alert = NSAlert()
            alert.messageText = NSLocalizedString("The current markdown file has been modified.\nAre you sure to replace it?", comment: "Open Markdown replacement confirmation")
            alert.alertStyle = .warning
            alert.addButton(withTitle: NSLocalizedString("OK", comment: "Default confirmation button")).keyEquivalent = "\r"
            alert.addButton(withTitle: NSLocalizedString("Cancel", comment: "Default cancel button")).keyEquivalent = "\u{1b}"
            let r = alert.runModal()
            guard r == .alertFirstButtonReturn else {
                return false
            }
        }
        self.markdown_file = file
        return true
    }
    
    @IBAction func openDocument(_ sender: Any) {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = false
        panel.canCreateDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedFileTypes = ["md"]
        panel.message = NSLocalizedString("Select a Markdown file to preview", comment: "Open Markdown panel message")
        
        let result = panel.runModal()
        
        guard result.rawValue == NSApplication.ModalResponse.OK.rawValue, let src = panel.url else {
            return
        }
        
        self.openMarkdown(file: src)
    }
    
    @IBAction func exportMarkdown(_ sender: Any) {
        let savePanel = NSSavePanel()
        savePanel.canCreateDirectories = true
        savePanel.showsTagField = false
        savePanel.allowedFileTypes = ["md", "rmd", "qmd"]
        savePanel.isExtensionHidden = false
        savePanel.nameFieldStringValue = self.markdown_file?.lastPathComponent ?? "markdown.md"
        savePanel.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.modalPanelWindow)))
        
        let result = savePanel.runModal()
        
        guard result.rawValue == NSApplication.ModalResponse.OK.rawValue, let dst = savePanel.url else {
            return
        }
        _ = self.exportCurrentMarkdown(to: dst)
    }
    
    func exportCurrentMarkdown(to dst: URL) -> Bool {
        do {
            try self.textView.string.write(to: dst, atomically: true, encoding: .utf8)
        } catch {
            let alert = NSAlert()
            alert.alertStyle = .critical
            alert.messageText = NSLocalizedString("Unable to export the Markdown source!", comment: "Markdown export error")
            alert.addButton(withTitle: NSLocalizedString("Close", comment: "Default close button")).keyEquivalent = "\u{1b}"
            alert.runModal()
            return false
        }
        return true
    }
    
    @IBAction func reloadMarkdown(_ sender: Any) {
        guard let file = self.markdown_file else {
            return
        }
        let prev_scroll = self.prev_scroll
        self.openMarkdown(file: file)
        self.prev_scroll = prev_scroll
        if prev_scroll > 0 {
            webView.evaluateJavaScript("document.documentElement.scrollTop = \(prev_scroll);")
        }
    }
    
    func startMonitorFile() {
        self.markdown_source?.cancel()
        self.markdown_source = nil
        self.allow_reload = true
        
        guard let file = markdown_file else {
            return
        }
        
        let fileDescriptor = open(FileManager.default.fileSystemRepresentation(withPath: file.path), O_EVTONLY)
        guard fileDescriptor >= 0 else {
            return
        }
        
        self.markdown_source = DispatchSource.makeFileSystemObjectSource(fileDescriptor: fileDescriptor, eventMask: .all, queue: DispatchQueue.main)
        self.markdown_source!.setEventHandler { [weak self] in
            guard let me = self else {
                return
            }
            if me.edited {
                let alert = NSAlert()
                alert.alertStyle = .warning
                alert.messageText = NSLocalizedString("The source markdown has been changed outside the app, do you want to reload it?", comment: "External Markdown change reload confirmation")
                alert.informativeText = NSLocalizedString("Changes made to the file will be lost.", comment: "External Markdown change warning")
                alert.addButton(withTitle: NSLocalizedString("Reload", comment: "Reload button"))
                alert.addButton(withTitle: NSLocalizedString("Cancel", comment: "Default cancel button")).keyEquivalent = "\u{1b}"
                if alert.runModal() == .alertFirstButtonReturn {
                    me.reloadMarkdown(me)
                } else {
                    me.allow_reload = false
                    me.markdown_source?.cancel()
                }
            } else {
                self?.reloadMarkdown(me)
            }
        }
        self.markdown_source!.setCancelHandler {
            close(fileDescriptor)
        }
        self.markdown_source!.resume()
    }
    
    @IBAction func exportPreview(_ sender: Any) {
        let savePanel = NSSavePanel()
        savePanel.canCreateDirectories = true
        savePanel.showsTagField = false
        savePanel.allowedFileTypes = ["html"]
        savePanel.isExtensionHidden = false
        savePanel.nameFieldStringValue = "markdown.html"
        savePanel.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.modalPanelWindow)))
        
        let result = savePanel.runModal()
        
        guard result.rawValue == NSApplication.ModalResponse.OK.rawValue, let dst = savePanel.url else {
            return
        }
        
        let body: String
        let settings = self.updateSettings()
        let appearance: Appearance = self.appearanceButton.state == .off ? .light : .dark
        do {
            body = try settings.render(text: self.textView.string, filename: markdown_file?.lastPathComponent ?? "", forAppearance: appearance, baseDir: markdown_file?.deletingLastPathComponent().path ?? "")
        } catch {
            body = "Error"
        }
        
        let html = settings.getCompleteHTML(title: markdown_file?.lastPathComponent ?? "markdown", body: body)
        do {
            try html.write(to: dst, atomically: true, encoding: .utf8)
        } catch {
            let alert = NSAlert()
            alert.alertStyle = .critical
            alert.messageText = NSLocalizedString("Unable to export the HTML preview!", comment: "HTML export error")
            alert.addButton(withTitle: NSLocalizedString("Close", comment: "Default close button")).keyEquivalent = "\u{1b}"
            alert.runModal()
        }
    }
    
    @IBAction func saveDocument(_ sender: Any) {
        saveAction(sender)
    }
    
    @IBAction func revertDocumentToSaved(_ sender: Any) {
        let settings = Settings.shared
        settings.initFromDefaults()
        self.initFromSettings(settings)
    }
    
    @IBAction func resetToFactory(_ sender: Any) {
        let alert = NSAlert()
        alert.messageText = NSLocalizedString("Are you sure to reset all settings to factory default?", comment: "Factory reset confirmation")
        alert.addButton(withTitle: NSLocalizedString("Yes", comment: "Default yes button")).keyEquivalent = "\r"
        alert.addButton(withTitle: NSLocalizedString("No", comment: "Default no button")).keyEquivalent = "\u{1b}"
        let r = alert.runModal()
        if r == .alertFirstButtonReturn {
            let settings = Settings.shared
            settings.resetToFactory()
            settings.save()
            self.initFromSettings(settings)
        }
    }
    
    @IBAction func checkForUpdates(_ sender: Any) {
        (NSApplication.shared.delegate as? AppDelegate)?.checkForUpdates(sender)
    }
    
    @IBAction func handleQLSizeChanged(_ sender: NSPopUpButton) {
        self.qlWindowSizeCustomized = sender.indexOfSelectedItem == 1
    }
    
    @IBAction func saveAction(_ sender: Any) {
        let settings = self.updateSettings(withAlert: true)
        
        let r = settings.save()
        if r {
            isDirty = false
        } else {
            print("Error saving settings")
            os_log(
                "Error saving settings",
                log: OSLog.quickLookExtension,
                type: .error
            )
            
            let panel = NSAlert()
            panel.messageText = NSLocalizedString("Error saving the settings!", comment: "Settings save error")
            panel.alertStyle = .warning
            panel.addButton(withTitle: NSLocalizedString("Close", comment: "Default close button")).keyEquivalent = "\u{1b}"
            panel.runModal()
        }
    }
    
    @IBAction func refresh(_ sender: Any) {
        self.doRefresh(sender)
    }

    @IBAction func doRefresh(_ sender: Any)  {
        progressIndicator.startAnimation(self)
        
        // self.webView.loadHTMLString("", baseURL: nil)
        // self.webView.isHidden = true
        
        let body: String
        let settings = self.updateSettings()
        let appearance: Appearance = self.appearanceButton.state == .off ? .light : .dark
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        do {
            body = try settings.render(text: self.textView.string, filename: self.markdown_file?.lastPathComponent ?? "", forAppearance: appearance, baseDir: markdown_file?.deletingLastPathComponent().path ?? "")
        } catch {
            body = "Error"
        }
        
        let header = """
<script type="text/javascript">
// Reference: http://www.html5rocks.com/en/tutorials/speed/animations/

let last_known_scroll_position = 0;
let ticking = false;
let handler = 0;

function doSomething(scroll_pos) {
    // Do something with the scroll position
    handler = 0;

    window.webkit.messageHandlers.scrollHandler.postMessage({scroll: document.documentElement.scrollTop});

}

document.addEventListener('scroll', function(e) {
  last_known_scroll_position = window.scrollY;

  if (!ticking) {
    if (handler) {
        window.cancelAnimationFrame(handler);
    }
    handler = window.requestAnimationFrame(function() {
      doSomething(last_known_scroll_position);
      ticking = false;
    });

    ticking = true;
  }
});
</script>
"""
        
        let html = settings.getCompleteHTML(title: ".md", body: body, header: header)
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        webView.loadHTMLString(html, baseURL: markdown_file?.deletingLastPathComponent())
        
        let data = html.data(using: .utf8)
        
        elapsedTimeLabel = String(format: NSLocalizedString("Rendered in %.3f seconds | %@", comment: "Preview render status"), timeElapsed, self.byteFormatter.string(fromByteCount: Int64(data?.count ?? 0)))
    }
    
    func importStyle(copyOnSharedFolder: Bool) -> URL? {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = false
        panel.canCreateDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedFileTypes = ["css"]
        panel.message = NSLocalizedString("Select a custom CSS style", comment: "Custom CSS open panel message")
        
        let result = panel.runModal()
        
        guard result.rawValue == NSApplication.ModalResponse.OK.rawValue, let src = panel.url else {
            return nil
        }
            
        if copyOnSharedFolder {
            return Settings.storeStyle(name: src.lastPathComponent, data: try? Data(contentsOf: src));
        } else {
            return src
        }
    }
    
    @IBAction func handleImportStyle(_ sender: NSPopUpButton) {
        if let url = importStyle(copyOnSharedFolder: true) {
            self.initStylesPopup(resetStyles: true)
            customCSSFile = url
        }
    }
    
    @IBAction func handleStypesPopup(_ sender: NSPopUpButton) {
        let tag = sender.selectedTag()
        switch tag {
        case -1, /* Browse */ -2 /* Import */:
            if let url = importStyle(copyOnSharedFolder: tag == -2) {
                self.initStylesPopup(resetStyles: true)
                customCSSFile = url
            } else {
                updateCustomCSSPopup()
            }
            
        case -4: // Open application support folder
            updateCustomCSSPopup()
            
            self.revealApplicationSupportInFinder(self)
        
        case -5: // Refresh list
            let css = self.customCSSFile
            self.pauseAutoRefresh += 1
            self.customCSSFile = nil
            self.initStylesPopup(resetStyles: true)
            self.customCSSFile = css
            self.pauseAutoRefresh -= 1
            
        case -6: // Reveal
            updateCustomCSSPopup()
            
            guard customCSSFile == nil || customCSSFile!.lastPathComponent != "-" else {
                return
            }
            
            if customCSSFile == nil {
                // Download default theme.
                let savePanel = NSSavePanel()
                savePanel.canCreateDirectories = true
                savePanel.showsTagField = false
                savePanel.allowedFileTypes = ["css"]
                savePanel.isExtensionHidden = false
                savePanel.nameFieldStringValue = "default.css"
                savePanel.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.modalPanelWindow)))
                
                let result = savePanel.runModal()
                
                guard result.rawValue == NSApplication.ModalResponse.OK.rawValue, let dst = savePanel.url, let src = Bundle.main.url(forResource: "default", withExtension: "css") else {
                    return
                }
                do {
                    let css = try String(contentsOf: src, encoding: .utf8)
                    try css.write(to: dst, atomically: true, encoding: .utf8)
                } catch {
                    let alert = NSAlert()
                    alert.alertStyle = .critical
                    alert.messageText = NSLocalizedString("Unable to export the css style!", comment: "CSS export error")
                    alert.addButton(withTitle: NSLocalizedString("Close", comment: "Default close button")).keyEquivalent = "\u{1b}"
                    alert.runModal()
                }
            } else {
                // Reveal current theme.
                self.revealCSSInFinder(self)
            }
        case -100:
            // Default theme.
            customCSSFile = nil
        case -101:
            // None
            customCSSFile = URL(fileURLWithPath: "-")
            
        default:
            if let item = sender.selectedItem, item.tag >= 0 {
                let url: URL
                if item.tag == 1, let base = Settings.stylesFolder{
                    url = base.appendingPathComponent(item.title)
                } else {
                    url = URL(fileURLWithPath: item.title)
                }
                customCSSFile = url
            }
            updateCustomCSSPopup()
        }
    }
    
    @IBAction func revealCSSInFinder(_ sender: Any) {
        guard let url = self.customCSSFile else {
            return
        }
        NSWorkspace.shared.selectFile(url.path, inFileViewerRootedAtPath: "")
    }
    
    @IBAction func revealApplicationSupportInFinder(_ sender: Any) {
        if let url = Settings.stylesFolder{
            NSWorkspace.shared.selectFile(url.path, inFileViewerRootedAtPath: "")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        pauseAutoSave += 1
        
        if let path = Settings.shared.getHighlightSupportPath() {
            cmark_syntax_highlight_init("\(path)/".cString(using: .utf8))
        }
        
        self.textView.isAutomaticQuoteSubstitutionEnabled = false // Settings this option on interfacebuilder is ignored.
        self.textView.isAutomaticTextReplacementEnabled = false
        self.textView.isAutomaticDashSubstitutionEnabled = false
        textView.font = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        
        let type = Settings.isLightAppearance ? "Light" : "Dark"
        
        self.appearanceButton.state = type != "Light" ? .on : .off
        self.appearanceButton.toolTip = self.appearanceButton.state == .on
            ? NSLocalizedString("Switch to light appearance.", comment: "Appearance button tooltip")
            : NSLocalizedString("Switch to dark appearance.", comment: "Appearance button tooltip")
        self.webView.configuration.preferences.setValue(true, forKey: "developerExtrasEnabled")
        let contentController = self.webView.configuration.userContentController
        contentController.add(self, name: "scrollHandler")
        
        let settings = Settings.shared
        
        // let settings = Settings.shared
        
        self.initFromSettings(settings)
        
        self.updateCustomCSSPopup()
        self.updateEmojiPopup()
        self.updateStrikethroughPopup()
        self.updateYamlPopup()
        self.updateMathPopup()
        self.updateMermaidPopup()
        markdown_file = Bundle.main.url(forResource: "test1", withExtension: "md", subdirectory: "examples")
        
        tabView.selectTabViewItem(at: 0)
        
        DispatchQueue.main.async {
            self.textView.setSelectedRange(NSRange(location: 0, length: 0))
        }
        
        isLoaded = true
        
        if baseFontSize <= 0 {
            baseFontSize = 12
        }
        
        doRefresh(self)
        
        isDirty = false
        pauseAutoSave -= 1
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        guard firstView else {
            return
        }
        firstView = true;
        
        guard !UserDefaults.standard.bool(forKey: "qlmarkdown-suppress-editor-warning") else {
            return
        }
        
        let alert = NSAlert()
        
        alert.alertStyle = .warning
        alert.showsSuppressionButton = true
        alert.messageText = NSLocalizedString("QLMarkdown Preferences", comment: "Editor warning title")
        alert.informativeText = NSLocalizedString("This application is not intended to be a Markdown editor, but the interface for customising the Quick Look preview.", comment: "Editor warning informative text")
        alert.suppressionButton?.title = NSLocalizedString("Do not show this warning again", comment: "Editor warning suppression checkbox")
        
        alert.addButton(withTitle: NSLocalizedString("OK", comment: "Default confirmation button")).keyEquivalent = "\r"
        alert.runModal()
        
        if let suppressionButton = alert.suppressionButton, suppressionButton.state == .on {
            UserDefaults.standard.set(true, forKey: "qlmarkdown-suppress-editor-warning")
        }
    }
    
    
    @IBAction func doAutoRefresh(_ sender: NSMenuItem) {
        autoRefresh = !autoRefresh
        sender.state = autoRefresh ? .on : .off
    }
    
    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    internal func getBundleContents(forResource: String, ofType: String) -> String?
    {
        if let p = Bundle.main.path(forResource: forResource, ofType: ofType), let data = FileManager.default.contents(atPath: p), let s = String(data: data, encoding: .utf8) {
            return s
        } else {
            return nil
        }
    }
    
    internal func initFromSettings(_ settings: Settings) {
        pauseAutoRefresh += 1
        pauseAutoSave += 1
        
        initStylesPopup()
        
        self.debugMode = settings.debug
        self.isAboutVisible = settings.about
        self.renderAsCode = settings.renderAsCode
        
        self.qlWindowSizeCustomized = settings.qlWindowWidth ?? 0 > 0 && settings.qlWindowHeight ?? 0 > 0
        self.qlWindowWidth = settings.qlWindowWidth ?? 1000
        self.qlWindowHeight = settings.qlWindowHeight ?? 800
        
        self.tableExtension = settings.tableExtension
        self.autoLinkExtension = settings.autoLinkExtension
        self.tagFilterExtension = settings.tagFilterExtension
        self.taskListExtension = settings.taskListExtension
        
        self.yamlExtension = settings.yamlExtension != .disabled
        self.yamlExtensionAll = settings.yamlExtension == .allFiles
        
        self.strikethroughExtension = settings.strikethroughExtension != .disabled
        self.strikethroughDoubleTildeOption = settings.strikethroughExtension == .double
        
        self.mathExtension = !settings.mathExtension.isDisabled
        self.mathExtensionEmbed = settings.mathExtension.getMode()?.embed ?? false
        
        self.mermaidExtension = !settings.mermaidExtension.isDisabled
        self.mermaidExtensionEmbed = settings.mermaidExtension.getMode()?.embed ?? false
        
        self.mentionExtension = settings.mentionExtension
        self.syntaxHighlightExtension = settings.syntaxHighlightExtension
        
        self.emojiExtension = settings.emojiExtension != .disabled
        self.emojiImageOption = settings.emojiExtension == .images
        
        self.headsExtension = settings.headsExtension
        self.highlightExtension = settings.highlightExtension
        self.inlineImageExtension = settings.inlineImageExtension
        self.subSuperScriptExtension = settings.supExtension
        
        self.hardBreakOption = settings.hardBreakOption
        self.noSoftBreakOption = settings.noSoftBreakOption
        self.unsafeHTMLOption = settings.unsafeHTMLOption
        self.validateUTFOption = settings.validateUTFOption
        self.smartQuotesOption = settings.smartQuotesOption
        self.footnotesOption = settings.footnotesOption
        
        self.customCSSFile = settings.customCSS
        self.customCSSOverride = settings.customCSSOverride
                
        self.syntaxLineNumbers = settings.syntaxLineNumbersOption
        self.syntaxWrapEnabled = settings.syntaxWordWrapOption > 0
        self.syntaxWrapCharacters = settings.syntaxWordWrapOption > 0 ? settings.syntaxWordWrapOption : 80
        self.syntaxTabsOption = settings.syntaxTabsOption
        
        self.isAboutVisible = settings.about
        
        inlineLinkPopup.selectItem(at: settings.openInlineLink ? 0 : 1)
        
        isDirty = false
        pauseAutoRefresh -= 1
        pauseAutoSave -= 1
        
        doRefresh(self)
    }
    
    /**
     * Update the settings based on the application UI.
     * - parameters:
     *  - withAlert: Show an alert if there are errors on the settings.
     */
    internal func updateSettings(withAlert: Bool = false) -> Settings {
        let settings = Settings.shared
        
        settings.debug = self.debugMode
        settings.renderAsCode = self.renderAsCode
        settings.qlWindowWidth = self.qlWindowSizeCustomized ? self.qlWindowWidth : nil
        settings.qlWindowHeight = self.qlWindowSizeCustomized ? self.qlWindowHeight : nil
        
        settings.tableExtension = self.tableExtension
        settings.autoLinkExtension = self.autoLinkExtension
        settings.tagFilterExtension = self.tagFilterExtension
        settings.taskListExtension = self.taskListExtension
        settings.yamlExtension = self.yamlExtension ? ( self.yamlExtensionAll ? .allFiles : .onlyRmd) : .disabled
        
        settings.mathExtension = self.mathExtension ? (self.mathExtensionEmbed ? .embed(url: nil) : .link(url: nil)) : .disabled
        settings.mermaidExtension = self.mermaidExtension ? (self.mermaidExtensionEmbed ? .embed(url: nil) : .link(url: nil)) : .disabled
        settings.mentionExtension = self.mentionExtension

        settings.emojiExtension = self.emojiExtension ? (self.emojiImageOption ? .images : .font) : .disabled
        
        settings.headsExtension = self.headsExtension
        settings.highlightExtension = self.highlightExtension
        settings.inlineImageExtension = self.inlineImageExtension
        settings.subExtension = self.subSuperScriptExtension
        settings.supExtension = self.subSuperScriptExtension
        
        settings.strikethroughExtension = self.strikethroughExtension ? (self.strikethroughDoubleTildeOption ? .double : .single) : .disabled
        
        settings.syntaxHighlightExtension = self.syntaxHighlightExtension
        settings.syntaxLineNumbersOption = self.syntaxLineNumbers
        settings.syntaxWordWrapOption = self.syntaxWrapEnabled ? self.syntaxWrapCharacters : 0
        settings.syntaxTabsOption = self.syntaxTabsOption
        
        settings.hardBreakOption = self.hardBreakOption
        settings.noSoftBreakOption = self.noSoftBreakOption
        settings.unsafeHTMLOption = self.unsafeHTMLOption
        settings.validateUTFOption = self.validateUTFOption
        settings.smartQuotesOption = self.smartQuotesOption
        settings.footnotesOption = self.footnotesOption
        
        settings.baseFontSize = self.useBaseFontSize ? self.baseFontSize : 0
        settings.customCSSOverride = self.customCSSOverride
        settings.customCSS = self.customCSSFile
        
        settings.openInlineLink = inlineLinkPopup.indexOfSelectedItem == 0
        
        settings.about = self.isAboutVisible
        
        var msg: [String] = []
        settings.sanitize(allowLinkFile: false, messages: &msg)
        if withAlert && !msg.isEmpty {
            let alert = NSAlert()
            alert.messageText = NSLocalizedString("Configuration settings errors!", comment: "Settings validation alert title")
            alert.informativeText = msg.joined(separator: "\n")
            alert.alertStyle = .warning
            alert.addButton(withTitle: NSLocalizedString("Close", comment: "Default close button")).keyEquivalent = "\u{1b}"
            alert.runModal()
        }
        return settings
    }
    
    @IBAction func resetDependencyLibraries(_ sender: Any) {
        Settings.shared.installDependencies(override: true)
        
        if let path = Settings.mermaidCacheFileUrl, !FileManager.default.fileExists(atPath: path.path) {
            Settings.shared.updateMemaidCache { (success) in
                print("Mermaid reflesh: \(success ? "success" : "failure")")
            }
        }
        if let path = Settings.mathJaxCacheFileUrl, !FileManager.default.fileExists(atPath: path.path) {
            Settings.shared.updateMathJaxUCache { (success) in
                print("MathJax reflesh: \(success ? "success" : "failure")")
            }
        }
    }
    
    @IBAction func openSystemSettings(_ sender: Any) {
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.ExtensionsPreferences?extensionPointIdentifier=com.apple.quicklook.preview")!)
        // NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.ExtensionsPreferences")!)
    }

}

// MARK: - NSMenuItemValidation
extension ViewController: NSMenuItemValidation {
    /**
     * Update the state of a menu item inside the context menu of a javascript library extension.
     * - Returns: `true` if the menu item must be enabled.
     */
    private static func updateJSExtensionMenuItem(_ menu: NSMenuItem, namePrefix prefix: String, state: Bool, embed: Bool, fileUrl: URL?, webUrl: URL, byteFormatter: ByteCountFormatter) -> Bool {
        switch menu.identifier?.rawValue {
        case prefix:
            // Menu item "header"
            return false
        case "\(prefix)_embed":
            menu.state = state && embed ? .on : .off
            menu.toolTip = fileUrl?.path ?? ""
            if let url = fileUrl, url.isFileURL && FileManager.default.fileExists(atPath: url.path) {
                let size = (try? url.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0
                menu.title = String(format: NSLocalizedString("Embed (%@)", comment: "Embedded JavaScript library menu title"), byteFormatter.string(fromByteCount: Int64(size)))
                
            } else {
                menu.title = NSLocalizedString("Embed (file missing)", comment: "Missing embedded JavaScript library menu title")
                return false
            }
        case "\(prefix)_save", "\(prefix)_reveal":
            guard let url = fileUrl, url.isFileURL && FileManager.default.fileExists(atPath: url.path) else {
                return false
            }
        case "\(prefix)_download":
            menu.toolTip = String(format: NSLocalizedString("Cache a local copy of the library from the web (%@).", comment: "Download JavaScript library tooltip"), webUrl.path)
        case "\(prefix)_link":
            menu.state = state && !embed ? .on : .off
            menu.toolTip = webUrl.absoluteString
        case "\(prefix)_disabled":
            menu.state = state ? .off : .on
        default:
            break
        }
        
        return true
    }
    
    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool
    {
        if menuItem.identifier?.rawValue == "auto refresh" {
            menuItem.state = autoRefresh ? .on : .off
        } else if menuItem.action == #selector(self.saveDocument(_:)) || menuItem.action == #selector(self.saveAction(_:)) {
            return self.isDirty
        } else if menuItem.action == #selector(self.revertDocumentToSaved(_:)) {
            return self.isDirty
        } else {
            switch menuItem.identifier?.rawValue {
            case "mnu_emoji":
                menuItem.isEnabled = false
                return false
            case "mnu_emoji_font":
                menuItem.state = self.emojiExtension && !self.emojiImageOption ? .on : .off
            case "mnu_emoji_image":
                menuItem.state = self.emojiExtension && self.emojiImageOption ? .on : .off
            case "mnu_emoji_off":
                menuItem.state = self.emojiExtension ? .off : .on
                
            case "mnu_math", "mnu_math_embed", "mnu_math_link", "mnu_math_disabled", "mnu_math_download", "mnu_math_reveal":
                return Self.updateJSExtensionMenuItem(menuItem, namePrefix: "mnu_math", state: mathExtension, embed: mathExtensionEmbed, fileUrl: Settings.shared.mathJaxFileUrl, webUrl: Settings.mathJaxWebUrl, byteFormatter: self.byteFormatter)
                
            case "mnu_mermaid", "mnu_mermaid_embed", "mnu_mermaid_link", "mnu_mermaid_disabled", "mnu_mermaid_download", "mnu_mermaid_reveal":
                return Self.updateJSExtensionMenuItem(menuItem, namePrefix: "mnu_mermaid", state: mermaidExtension, embed: mermaidExtensionEmbed, fileUrl: Settings.shared.mermaidFileUrl, webUrl: Settings.mermaidWebUrl, byteFormatter: self.byteFormatter)
                
            case "mnu_yaml":
                return false
            case "mnu_yaml_rmd":
                menuItem.state = self.yamlExtension && !self.yamlExtensionAll ? .on : .off
            case "mnu_yaml_all":
                menuItem.state = self.yamlExtension && self.yamlExtensionAll ? .on : .off
            case "mnu_yaml_disabled":
                menuItem.state = self.yamlExtension ? .off : .on
            
            case "mnu_strikethrough":
                return false
            case "mnu_strikethrough_1":
                menuItem.state = self.strikethroughExtension && !self.strikethroughDoubleTildeOption ? .on : .off
            case "mnu_strikethrough_2":
                menuItem.state = self.strikethroughExtension && self.strikethroughDoubleTildeOption ? .on : .off
            case "mnu_strikethrough_0":
                menuItem.state = self.strikethroughExtension ? .off : .on
            
            case "mnu_highlight":
                return false
            case "mnu_highlight_on":
                menuItem.state = self.syntaxHighlightExtension ? .on : .off
            case "mnu_highlight_ln":
                menuItem.state = self.syntaxLineNumbers ? .on : .off
                return self.syntaxHighlightExtension
            case "mnu_highlight_tab_0", "mnu_highlight_tab_2", "mnu_highlight_tab_4", "mnu_highlight_tab_8":
                menuItem.state = self.syntaxTabsOption == menuItem.tag ? .on : .off
                return self.syntaxHighlightExtension
            case "mnu_highlight_ww_0":
                menuItem.state = !self.syntaxWrapEnabled ? .on : .off
                return self.syntaxHighlightExtension
            case "mnu_highlight_ww_80", "mnu_highlight_ww_120", "mnu_highlight_ww_custom":
                menuItem.state = self.syntaxWrapEnabled && self.syntaxWrapCharacters == menuItem.tag ? .on : .off
                return self.syntaxHighlightExtension
            case "mnu_highlight_tab", "mnu_highlight_ww", "mnu_highlight_ww_x":
                return self.syntaxHighlightExtension
            case "mnu_highlight_off":
                menuItem.state = !self.syntaxHighlightExtension ? .on : .off
            default:
                break
            }
        }
        
        return true
    }
}

// MARK: - WKNavigationDelegate
extension ViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if prev_scroll > 0 {
            webView.evaluateJavaScript("document.documentElement.scrollTop = \(prev_scroll);", completionHandler: {_,_ in
                // self.webView.isHidden = false
                self.progressIndicator.stopAnimation(self)
            })
        } else {
            // self.webView.isHidden = false
            progressIndicator.stopAnimation(self)
        }
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print(error)
        // self.webView.isHidden = false
        progressIndicator.stopAnimation(self)
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if !Settings.shared.openInlineLink, navigationAction.navigationType == .linkActivated, let url = navigationAction.request.url, url.scheme != "file" {
            let r = NSWorkspace.shared.open(url)
            // print(r, url.absoluteString)
            if r {
                decisionHandler(.cancel)
                return
            }
        }
        decisionHandler(.allow)
    }
}

// MARK: - WKScriptMessageHandler
extension ViewController: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "scrollHandler", let dict = message.body as? [String : AnyObject], let p = dict["scroll"] as? Int {
            self.prev_scroll = p
        }
    }
}

// MARK: - PreferencesWindowController
class PreferencesWindowController: NSWindowController, NSWindowDelegate {
    var askToSave = true

    override func windowDidLoad() {
        super.windowDidLoad()
        window?.subtitle = NSLocalizedString("Preferences", comment: "Preferences window subtitle")
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        guard let contentViewController = self.contentViewController as? ViewController else {
            return true
        }
        if self.askToSave && contentViewController.isDirty {
            let alert = NSAlert()
            alert.alertStyle = .warning
            alert.messageText = NSLocalizedString("There are some modified settings", comment: "Unsaved settings alert title")
            alert.informativeText = NSLocalizedString("Do you want to save them before closing?", comment: "Unsaved settings alert message")
            alert.addButton(withTitle: NSLocalizedString("Save", comment: "Default save button")).keyEquivalent = "\r"
            alert.addButton(withTitle: NSLocalizedString("Ignore", comment: "Ignore changes button")).keyEquivalent = "d"
            alert.addButton(withTitle: NSLocalizedString("Cancel", comment: "Default cancel button")).keyEquivalent = "\u{1b}"
            
            let r = alert.runModal()
            switch r {
            case .OK, .alertFirstButtonReturn:
                // Save the settings
                contentViewController.saveAction(contentViewController);
            case .cancel, .alertThirdButtonReturn: // Cancel
                // Do not close the window
                return false
            default:
                return true
            }
        }
        
        if contentViewController.edited, let file = contentViewController.markdown_file, !file.relativePath.contains(Bundle.main.bundleURL.relativePath) {
            let alert = NSAlert()
            alert.alertStyle = .warning
            alert.messageText = NSLocalizedString("The markdown file is changed!", comment: "Unsaved Markdown alert title")
            alert.informativeText = NSLocalizedString("Do you want to save them before closing?", comment: "Unsaved Markdown alert message")
            alert.addButton(withTitle: NSLocalizedString("Save", comment: "Default save button")).keyEquivalent = "\r"
            alert.addButton(withTitle: NSLocalizedString("Do not Save", comment: "Do not save button")).keyEquivalent = "d"
            alert.addButton(withTitle: NSLocalizedString("Cancel", comment: "Default cancel button")).keyEquivalent = "\u{1b}"
            
            let r = alert.runModal()
            switch r {
            case .OK, .alertFirstButtonReturn:
                // Save the markdown file
                if contentViewController.exportCurrentMarkdown(to: file) {
                    contentViewController.edited = false
                    return true
                } else {
                    return false
                }
            case .cancel, .alertThirdButtonReturn: // Cancel
                // Do not close the window
                return false
            default:
                contentViewController.edited = false
                return true
            }
        }
        return true
    }
}


extension ViewController: NSMenuDelegate {
    func menuNeedsUpdate(_ menu: NSMenu) {
        if menu.identifier?.rawValue == "mnu_highlight_ww" {
            if menu.items.first(where: {$0.tag == self.syntaxWrapCharacters}) == nil {
                let title = String(format: NSLocalizedString("%d characters", comment: "Custom syntax word wrap menu title"), syntaxWrapCharacters)
                let item = NSMenuItem(title: title, action: #selector(self.handleSyntaxHighlightMenu(_:)), keyEquivalent: "")
                item.identifier = NSUserInterfaceItemIdentifier("mnu_highlight_ww_custom")
                item.tag = syntaxWrapCharacters
                
                if let index = menu.items.firstIndex(where: { $0.tag > self.syntaxWrapCharacters}) {
                    menu.insertItem(item, at: index)
                } else {
                    menu.insertItem(item, at: menu.items.count - 1)
                }
            }
            return
        }
        
        if let item = menu.item(withTag: -6) {
            item.title = self.customCSSFile == nil
                ? NSLocalizedString("Download default CSS theme", comment: "Styles popup action")
                : NSLocalizedString("Reveal CSS in Finder", comment: "Styles popup action")
        }
        
        // print("menuNeedsUpdate")
    }
}

// MARK: - DropableTextView
class DropableTextView: NSTextView {
    @IBOutlet weak var container: ViewController?
    
    func endDrag(_ sender: NSDraggingInfo) {
        /*
        if let fileUrl = sender.draggingPasteboard.pasteboardItems?.first?.propertyList(forType: .fileURL) as? String, let url = URL(string: fileUrl) {
            
            // print(url.path)
        } else {
            print("fail")
        }*/
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        registerForDraggedTypes([.fileURL])
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        registerForDraggedTypes([.fileURL])
    }
    
    func checkFileDrop(_ sender: NSDraggingInfo) -> Bool {
        guard let board = sender.draggingPasteboard.propertyList(forType: NSPasteboard.PasteboardType(rawValue: "NSFilenamesPboardType")) as? NSArray,
              let path = board[0] as? String else {
            return false
        }
        let suffix = URL(fileURLWithPath: path).pathExtension.lowercased()
        if suffix == "md" || suffix == "markdown" || suffix == "rmd" || suffix == "qmd" {
            return true
        } else {
            return false
        }
    }
    
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        return checkFileDrop(sender) ? .copy : NSDragOperation()
    }
    
    override func prepareForDragOperation(_ sender: NSDraggingInfo) -> Bool {
        return checkFileDrop(sender)
    }
    
    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        guard let board = sender.draggingPasteboard.propertyList(forType: NSPasteboard.PasteboardType(rawValue: "NSFilenamesPboardType")) as? NSArray,
              let path = board[0] as? String else {
            return false
        }
        
        let url = URL(fileURLWithPath: path)
        container?.openMarkdown(file: url)
        return true
        /*
        do {
            let s = try String(contentsOf: url, encoding: .utf8)
            self.string = s
            return true
        } catch {
            return false
        }
         */
    }
}

// MARK: - NSTextDelegate
extension ViewController: NSTextDelegate {
    func textDidChange(_ notification: Notification) {
        guard let sender = notification.object as? NSTextView, sender == textView else {
            return
        }
        edited = true
    }
}
