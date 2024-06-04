//
//  ViewController.swift
//  QLMarkdown
//
//  Created by sbarex on 09/12/20.
//

import Cocoa
import WebKit
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
    @objc dynamic var yamlExtension: Bool = Settings.factorySettings.yamlExtension {
        didSet {
            guard oldValue != yamlExtension else { return }
            updateYamlPopup()
            isDirty = true
        }
    }
    @objc dynamic var yamlExtensionAll: Bool = Settings.factorySettings.yamlExtensionAll {
        didSet {
            guard oldValue != yamlExtensionAll else { return }
            updateYamlPopup()
            isDirty = true
        }
    }
    
    @objc dynamic var strikethroughExtension: Bool = Settings.factorySettings.strikethroughExtension {
        didSet {
            guard oldValue != strikethroughExtension else { return }
            isDirty = true
            updateStrikethroughPopup()
        }
    }
    dynamic var strikethroughDoubleTildeOption: Bool = Settings.factorySettings.strikethroughDoubleTildeOption {
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
    
    @objc dynamic var syntaxCustomThemes: Bool = Settings.factorySettings.syntaxCustomThemes {
        didSet {
            guard oldValue != syntaxCustomThemes else { return }
            isDirty = true
        }
    }
    
    @objc dynamic var syntaxThemeLight: ThemePreview? = nil {
        didSet {
            guard oldValue != syntaxThemeLight else { return }
            isDirty = true
        }
    }
    @objc dynamic var syntaxThemeDark: ThemePreview? = nil {
        didSet {
            guard oldValue != syntaxThemeDark else { return }
            isDirty = true
        }
    }
    
    @objc dynamic var customBackgroundColor: Int = Settings.factorySettings.syntaxBackgroundColor.rawValue {
        didSet {
            guard oldValue != customBackgroundColor else { return }
            isDirty = true
        }
    }
    @objc dynamic var backgroundColorLight: NSColor = NSColor(css: Settings.factorySettings.syntaxBackgroundColorLight) ?? NSColor.textBackgroundColor {
        didSet {
            guard oldValue != backgroundColorLight else { return }
            isDirty = true
        }
    }
    
    @objc dynamic var backgroundColorDark: NSColor = NSColor(css: Settings.factorySettings.syntaxBackgroundColorDark) ?? NSColor.textBackgroundColor {
        didSet {
            guard oldValue != backgroundColorDark else { return }
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
    
    @objc dynamic var isFontCustomized: Bool = !Settings.factorySettings.syntaxFontFamily.isEmpty {
        didSet {
            guard oldValue != isFontCustomized else { return }
            isDirty = true
        }
    }
    @objc dynamic var syntaxFontSize: CGFloat = Settings.factorySettings.syntaxFontSize {
        didSet {
            guard oldValue != syntaxFontSize else { return }
            isDirty = true
            refreshFontPreview()
        }
    }
    @objc dynamic var syntaxFontFamily: String = Settings.factorySettings.syntaxFontFamily {
        /*willSet {
            self.willChangeValue(forKey: #keyPath(isFontCustomized))
        }*/
        didSet {
            guard oldValue != syntaxFontFamily else { return }
            isFontCustomized = !syntaxFontFamily.isEmpty
            //self.didChangeValue(forKey: #keyPath(isFontCustomized))
            refreshFontPreview()
            isDirty = true
        }
    }
    
    @objc dynamic var guessEngine: Int = Settings.factorySettings.guessEngine.rawValue {
        didSet {
            guard oldValue != guessEngine else { return }
            isDirty = true
        }
    }
    
    @objc dynamic var mathExtension: Bool = Settings.factorySettings.mathExtension {
        didSet {
            guard oldValue != mathExtension else { return }
            isDirty = true
        }
    }
    
    @objc dynamic var emojiExtension: Bool = Settings.factorySettings.emojiExtension {
        didSet {
            guard oldValue != emojiExtension else { return }
            updateEmojiPopup()
            isDirty = true
        }
    }
    @objc dynamic var emojiImageOption: Bool = Settings.factorySettings.emojiImageOption {
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
    
    func initStylesPopup(resetStyles: Bool = false) {
        stylesPopup.removeAllItems()
        // Standard CSS
        stylesPopup.addItem(withTitle: "GitHub ( Default )")
        stylesPopup.lastItem?.tag = -100
        
        // stylesPopup.addItem(withTitle: "None")
        // stylesPopup.lastItem?.tag = -101
        
        stylesPopup.menu?.addItem(NSMenuItem.separator())
        
        // Actions
        stylesPopup.addItem(withTitle: "Open Application support themes folder")
        stylesPopup.lastItem?.tag = -4
        
        stylesPopup.addItem(withTitle: "Reveal CSS in Finder")
        stylesPopup.lastItem?.tag = -6
        stylesPopup.lastItem?.isAlternate = true
        stylesPopup.lastItem?.keyEquivalentModifierMask = [.option]
        
        stylesPopup.addItem(withTitle: "Refresh")
        stylesPopup.lastItem?.tag = -5
        
        stylesPopup.menu?.addItem(NSMenuItem.separator())
        
        stylesPopup.addItem(withTitle: "Import…")
        stylesPopup.lastItem?.tag = -2
        stylesPopup.lastItem?.toolTip = "Import a CSS file into the standard themes folder."
        
        stylesPopup.addItem(withTitle: "Browse…")
        stylesPopup.lastItem?.tag = -1
        stylesPopup.lastItem?.isAlternate = true
        stylesPopup.lastItem?.keyEquivalentModifierMask = [.option]
        stylesPopup.lastItem?.toolTip = "Use a custom CSS file without importing into the standard themes folder."

        let settings = Settings.shared
        let custom_styles = settings.getAvailableStyles(resetCache: resetStyles)
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
            let defaults = UserDefaults.standard
            return defaults.value(forKey: "auto-refresh") as? Bool ?? true
        }
        set {
            let defaults = UserDefaults.standard
            defaults.setValue(newValue, forKey: "auto-refresh")
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
            if isDirty && isAutoSaving && isLoaded && pauseAutoRefresh == 0 {
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
    @IBOutlet weak var unsafeButton: NSButton!
    
    @IBOutlet weak var progressIndicator: NSProgressIndicator!
    @IBOutlet weak var inlineLinkPopup: NSPopUpButton!
    
    @IBOutlet weak var appearanceButton: NSButton!
    
    @IBOutlet weak var qlWindowSizePopupButton: NSPopUpButton!
    
    var edited: Bool = false
    var allow_reload: Bool = true
    fileprivate var markdown_source: DispatchSourceFileSystemObject?
    var markdown_file: URL? {
        didSet {
            if let file = markdown_file {
                do {
                    let s = try String(contentsOf: file)
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
        sender.toolTip = dark ? "Switch to light appearance." :  "Switch to dark appearance."
        self.doRefresh(sender)
    }
    
    @IBAction func doStyleOverrideChange(_ sender: NSPopUpButton) {
        self.customCSSOverride = sender.indexOfSelectedItem == 1
    }
    
    @IBAction func handleStrikethroughPopup(_ sender: NSPopUpButton) {
        if sender.indexOfSelectedItem == 3 {
            self.strikethroughExtension = false
        } else {
            self.strikethroughExtension = true
            self.strikethroughDoubleTildeOption = sender.indexOfSelectedItem == 2
        }
    }
    
    func updateStrikethroughPopup() {
        if !strikethroughExtension {
            strikethroughPopupButton.title = "Strikethrough"
        } else {
            strikethroughPopupButton.title = "Strikethrough (\(self.strikethroughDoubleTildeOption ? "~~" : "~"))"
        }
    }
    
    @IBAction func handleEmojiPopup(_ sender: NSPopUpButton) {
        if sender.indexOfSelectedItem == 3 {
            self.emojiExtension = false
        } else {
            pauseAutoRefresh += 1
            self.emojiExtension = true
            self.emojiImageOption = sender.indexOfSelectedItem == 2
            pauseAutoRefresh -= 1
        }
    }
    
    func updateEmojiPopup() {
        if !emojiExtension {
            emojiPopupButton.title = "Emoji"
        } else {
            emojiPopupButton.title = "Emoji as \(self.emojiImageOption ? "images" : "font")"
        }
    }
    
    @IBAction func handleYamlPopup(_ sender: NSPopUpButton) {
        if sender.indexOfSelectedItem == 3 {
            self.yamlExtension = false
        } else {
            self.yamlExtension = true
            self.yamlExtensionAll = sender.indexOfSelectedItem == 2
        }
    }
    
    func updateYamlPopup() {
        if !yamlExtension {
            yamlPopupButton.title = "YAML header"
        } else {
            yamlPopupButton.title = "YAML header (\(self.yamlExtensionAll ? "all files" : ".rmd, .qmd files"))"
        }
    }
    
    @discardableResult
    func openMarkdown(file: URL) -> Bool {
        if edited {
            let alert = NSAlert()
            alert.messageText = "The current markdown file has been modified.\nAre you sure to replace it?"
            alert.alertStyle = .warning
            alert.addButton(withTitle: "OK").keyEquivalent = "\r"
            alert.addButton(withTitle: "Cancel").keyEquivalent = "\u{1b}"
            let r = alert.runModal()
            guard r == .alertFirstButtonReturn else {
                return false
            }
        }
        self.markdown_file = file
        return true
    }
    
    @IBAction func openReadme(_ sender: Any) {
        if let file = Bundle.main.url(forResource: "README", withExtension: "md") {
            self.openMarkdown(file: file)
        }
    }
    
    @IBAction func openDocument(_ sender: Any) {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = false
        panel.canCreateDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedFileTypes = ["md"]
        panel.message = "Select a Markdown file to preview"
        
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
        
        do {
            try self.textView.string.write(to: dst, atomically: true, encoding: .utf8)
        } catch {
            let alert = NSAlert()
            alert.alertStyle = .critical
            alert.messageText = "Unable to export the Markdown source!"
            alert.addButton(withTitle: "Close").keyEquivalent = "\u{1b}"
            alert.runModal()
        }
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
                alert.messageText = "The source markdown has been changed outside the app, do you want to reload it?"
                alert.informativeText = "Changes made to the file will be lost. "
                alert.addButton(withTitle: "Reload")
                alert.addButton(withTitle: "Cancel").keyEquivalent = "\u{1b}"
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
        
        let html = settings.getCompleteHTML(title: markdown_file?.lastPathComponent ?? "markdown", body: body, basedir: Bundle.main.resourceURL ?? Bundle.main.bundleURL.deletingLastPathComponent(), forAppearance: appearance)
        do {
            try html.write(to: dst, atomically: true, encoding: .utf8)
        } catch {
            let alert = NSAlert()
            alert.alertStyle = .critical
            alert.messageText = "Unable to export the HTML preview!"
            alert.addButton(withTitle: "Close").keyEquivalent = "\u{1b}"
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
        alert.messageText = "Are you sure to reset all settings to factory default?"
        alert.addButton(withTitle: "Yes").keyEquivalent = "\r"
        alert.addButton(withTitle: "No").keyEquivalent = "\u{1b}"
        let r = alert.runModal()
        if r == .alertFirstButtonReturn {
            let settings = Settings.shared
            settings.resetToFactory()
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
        let settings = self.updateSettings()
        
        if settings.synchronize() {
            isDirty = false
        } else {
            let panel = NSAlert()
            panel.messageText = "Error saving the settings!"
            panel.alertStyle = .warning
            panel.addButton(withTitle: "Close").keyEquivalent = "\u{1b}"
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
        
        let html = settings.getCompleteHTML(title: ".md", body: body, header: header, footer: "", basedir: self.markdown_file?.deletingLastPathComponent() ?? Bundle.main.resourceURL ?? Bundle.main.bundleURL.deletingLastPathComponent(), forAppearance: appearance)
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        webView.loadHTMLString(html, baseURL: markdown_file?.deletingLastPathComponent())
        
        elapsedTimeLabel = String(format: "Rendered in %.3f seconds", timeElapsed)
    }
    
    func importStyle(copyOnSharedFolder: Bool) -> URL? {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = false
        panel.canCreateDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedFileTypes = ["css"]
        panel.message = "Select a custom CSS style"
        
        let result = panel.runModal()
        
        guard result.rawValue == NSApplication.ModalResponse.OK.rawValue, let src = panel.url else {
            return nil
        }
            
        if copyOnSharedFolder {
            guard let folder = Settings.stylesFolder else {
                return nil
            }
            let dst = folder.appendingPathComponent(src.lastPathComponent)
            do {
                if FileManager.default.fileExists(atPath: dst.path) {
                    let alert = NSAlert()
                    alert.messageText = "A file with the same name already exists. \nDo you want to overwrite?"
                    alert.alertStyle = .warning
                    alert.addButton(withTitle: "No").keyEquivalent = "\u{1b}"
                    alert.addButton(withTitle: "Yes").keyEquivalent = "\r"
                    
                    let r = alert.runModal()
                    guard r == .alertSecondButtonReturn else {
                        return nil
                    }
                    try FileManager.default.removeItem(at: dst)
                }
                try FileManager.default.copyItem(at: src, to: dst)
                return dst
            } catch {
                let alert = NSAlert()
                alert.messageText = "Unable to copy the file"
                alert.alertStyle = .critical
                alert.addButton(withTitle: "Close").keyEquivalent = "\r"
                
                alert.runModal()
                
                return nil
            }
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
                    alert.messageText = "Unable to export the css style!"
                    alert.addButton(withTitle: "Close").keyEquivalent = "\u{1b}"
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
                if item.tag == 1, let base = Settings.stylesFolder {
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
        guard let url = Settings.stylesFolder else {
            return
        }
        NSWorkspace.shared.selectFile(url.path, inFileViewerRootedAtPath: "")
    }
    
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        if segue.identifier == "HighlightSegue" {
            if let vc = segue.destinationController as? HighlightViewController {
                vc.settingsViewController = self
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let path = Bundle.main.resourceURL?.appendingPathComponent("highlight").path {
            cmark_syntax_highlight_init("\(path)/".cString(using: .utf8))
        }
        
        self.textView.isAutomaticQuoteSubstitutionEnabled = false // Settings this option on interfacebuilder is ignored.
        self.textView.isAutomaticTextReplacementEnabled = false
        self.textView.isAutomaticDashSubstitutionEnabled = false
        textView.font = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        
        let type = UserDefaults.standard.string(forKey: "AppleInterfaceStyle") ?? "Light"
        
        self.appearanceButton.state = type != "Light" ? .on : .off
        self.appearanceButton.toolTip = self.appearanceButton.state == .on ? "Switch to light appearance." : "Switch to dark appearance."
        self.webView.configuration.preferences.setValue(true, forKey: "developerExtrasEnabled")
        let contentController = self.webView.configuration.userContentController
        contentController.add(self, name: "scrollHandler")
        
        let settings = Settings.shared
        
        self.initFromSettings(settings)
        
        self.updateCustomCSSPopup()
        self.updateEmojiPopup()
        self.updateStrikethroughPopup()
        self.updateYamlPopup()
        
        markdown_file = Bundle.main.url(forResource: "test1", withExtension: "md")
        
        tabView.selectTabViewItem(at: 0)
        
        DispatchQueue.main.async {
            self.textView.setSelectedRange(NSRange(location: 0, length: 0))
        }
        
        isLoaded = true
        
        doRefresh(self)
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
    
    /// Refresh the preview font.
    internal func refreshFontPreview() {
        if let hvc = self.presentedViewControllers?.first(where: {$0 is HighlightViewController}) as? HighlightViewController {
            hvc.refreshFontPreview()
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
        self.renderAsCode = settings.renderAsCode
        
        self.qlWindowSizeCustomized = settings.qlWindowWidth ?? 0 > 0 && settings.qlWindowHeight ?? 0 > 0
        self.qlWindowWidth = settings.qlWindowWidth ?? 1000
        self.qlWindowHeight = settings.qlWindowHeight ?? 800
        
        self.tableExtension = settings.tableExtension
        self.autoLinkExtension = settings.autoLinkExtension
        self.tagFilterExtension = settings.tagFilterExtension
        self.taskListExtension = settings.taskListExtension
        
        self.yamlExtension = settings.yamlExtension
        self.yamlExtensionAll = settings.yamlExtensionAll
        
        self.strikethroughExtension = settings.strikethroughExtension
        self.strikethroughDoubleTildeOption = settings.strikethroughDoubleTildeOption
        
        self.mentionExtension = settings.mentionExtension
        self.syntaxHighlightExtension = settings.syntaxHighlightExtension
        
        self.emojiExtension = settings.emojiExtension
        self.emojiImageOption = settings.emojiImageOption
        
        self.inlineImageExtension = settings.inlineImageExtension
        self.headsExtension = settings.headsExtension
        
        self.mathExtension = settings.mathExtension
        
        self.hardBreakOption = settings.hardBreakOption
        self.noSoftBreakOption = settings.noSoftBreakOption
        self.unsafeHTMLOption = settings.unsafeHTMLOption
        self.validateUTFOption = settings.validateUTFOption
        self.smartQuotesOption = settings.smartQuotesOption
        self.footnotesOption = settings.footnotesOption
        
        self.customCSSFile = settings.customCSS
        self.customCSSOverride = settings.customCSSOverride
        
        let themes = Settings.shared.getAvailableThemes()
        
        self.syntaxCustomThemes = settings.syntaxCustomThemes
        self.syntaxThemeLight = HighlightViewController.searchTheme(settings.syntaxThemeLight, in: themes, appearance: .light)
        self.syntaxThemeDark = HighlightViewController.searchTheme(settings.syntaxThemeDark, in: themes, appearance: .dark)
        
        self.syntaxLineNumbers = settings.syntaxLineNumbersOption
        self.syntaxWrapEnabled = settings.syntaxWordWrapOption > 0
        self.syntaxWrapCharacters = settings.syntaxWordWrapOption > 0 ? settings.syntaxWordWrapOption : 80
        self.syntaxTabsOption = settings.syntaxTabsOption
        self.syntaxFontFamily = settings.syntaxFontFamily
        self.syntaxFontSize = settings.syntaxFontSize
        
        self.customBackgroundColor = settings.syntaxBackgroundColor.rawValue
        self.backgroundColorLight = NSColor(css: settings.syntaxBackgroundColorLight) ?? NSColor(css: settings.syntaxBackgroundColorDark) ?? NSColor(white: 0.9, alpha: 1)
        self.backgroundColorDark = NSColor(css: settings.syntaxBackgroundColorDark) ?? NSColor(white: 0.4, alpha: 1)
        
        self.guessEngine = settings.guessEngine.rawValue
        
        self.isAboutVisible = settings.about
        
        inlineLinkPopup.selectItem(at: settings.openInlineLink ? 0 : 1)
        
        isDirty = false
        pauseAutoRefresh -= 1
        pauseAutoSave -= 1
        
        doRefresh(self)
    }
    
    internal func updateSettings() -> Settings {
        let settings = Settings.shared
        
        settings.debug = self.debugMode
        settings.renderAsCode = self.renderAsCode
        settings.qlWindowWidth = self.qlWindowSizeCustomized ? self.qlWindowWidth : nil
        settings.qlWindowHeight = self.qlWindowSizeCustomized ? self.qlWindowHeight : nil
        
        settings.tableExtension = self.tableExtension
        settings.autoLinkExtension = self.autoLinkExtension
        settings.tagFilterExtension = self.tagFilterExtension
        settings.taskListExtension = self.taskListExtension
        settings.yamlExtension = self.yamlExtension
        settings.yamlExtensionAll = self.yamlExtensionAll
        settings.mentionExtension = self.mentionExtension
        settings.inlineImageExtension = self.inlineImageExtension
        settings.headsExtension = self.headsExtension
        
        settings.emojiExtension = self.emojiExtension
        settings.emojiImageOption = self.emojiImageOption
        
        settings.mathExtension = self.mathExtension
        
        settings.strikethroughExtension = self.strikethroughExtension
        settings.strikethroughDoubleTildeOption = self.strikethroughDoubleTildeOption
        
        settings.syntaxHighlightExtension = self.syntaxHighlightExtension
        settings.syntaxCustomThemes = self.syntaxCustomThemes
        settings.syntaxThemeLight = self.syntaxThemeLight?.fullName ?? ""
        settings.syntaxThemeDark = self.syntaxThemeDark?.fullName ?? ""
        settings.syntaxLineNumbersOption = self.syntaxLineNumbers
        settings.syntaxWordWrapOption = self.syntaxWrapEnabled ? self.syntaxWrapCharacters : 0
        
        settings.syntaxTabsOption = self.syntaxTabsOption
        if self.isFontCustomized {
            settings.syntaxFontFamily = self.syntaxFontFamily
            settings.syntaxFontSize = self.syntaxFontSize
        } else {
            settings.syntaxFontFamily = ""
            settings.syntaxFontSize = 0
        }
        
        settings.syntaxBackgroundColor = BackgroundColor(rawValue: self.customBackgroundColor) ?? .fromMarkdown
        settings.syntaxBackgroundColorLight = self.backgroundColorLight.css() ?? ""
        settings.syntaxBackgroundColorDark = self.backgroundColorDark.css() ?? ""
        /*
        if self.customBackgroundColor == 0 {
            settings.syntaxBackgroundColorLight = ""
            settings.syntaxBackgroundColorDark = ""
        } else if self.customBackgroundColor == 1 {
            settings.syntaxBackgroundColorLight = "ignore"
            settings.syntaxBackgroundColorDark = "ignore"
        } else {
            settings.syntaxBackgroundColorLight = self.backgroundColorLight.css() ?? ""
            settings.syntaxBackgroundColorDark = self.backgroundColorDark.css() ?? ""
        }
        */
        
        settings.guessEngine = GuessEngine(rawValue: self.guessEngine) ?? .none
        
        settings.hardBreakOption = self.hardBreakOption
        settings.noSoftBreakOption = self.noSoftBreakOption
        settings.unsafeHTMLOption = self.unsafeHTMLOption
        settings.validateUTFOption = self.validateUTFOption
        settings.smartQuotesOption = self.smartQuotesOption
        settings.footnotesOption = self.footnotesOption
        
        settings.customCSSOverride = self.customCSSOverride
        settings.customCSS = self.customCSSFile
        
        settings.openInlineLink = inlineLinkPopup.indexOfSelectedItem == 0
        
        settings.about = self.isAboutVisible
        return settings
    }
}

// MARK: - NSMenuItemValidation
extension ViewController: NSMenuItemValidation {
    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool
    {
        if menuItem.identifier?.rawValue == "auto refresh" {
            menuItem.state = autoRefresh ? .on : .off
        } else if menuItem.action == #selector(self.saveDocument(_:)) || menuItem.action == #selector(self.saveAction(_:)) {
            return self.isDirty
        } else if menuItem.action == #selector(self.revertDocumentToSaved(_:)) {
            return self.isDirty
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
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        guard let contentViewController = self.contentViewController as? ViewController else {
            return true
        }
        if self.askToSave && contentViewController.isDirty {
            let alert = NSAlert()
            alert.alertStyle = .warning
            alert.messageText = "There are some modified settings"
            alert.informativeText = "Do you want to save them before closing?"
            alert.addButton(withTitle: "Save").keyEquivalent = "\r"
            alert.addButton(withTitle: "Don't Save").keyEquivalent = "d"
            alert.addButton(withTitle: "Cancel").keyEquivalent = "\u{1b}"
            
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
        return true
    }
}


extension ViewController: NSMenuDelegate {
    func menuNeedsUpdate(_ menu: NSMenu) {
        if let item = menu.item(withTag: -6) {
            item.title = self.customCSSFile == nil ? "Download default CSS theme" : "Reveal CSS in Finder"
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
            let s = try String(contentsOf: url)
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

// MARK: - NSFontChanging
extension ViewController: NSFontChanging {
    /// Handle the selection of a font.
    func changeFont(_ sender: NSFontManager?) {
        guard let fontManager = sender else {
            return
        }
        
        let font = fontManager.convert(NSFont.systemFont(ofSize: 13.0))
        
        self.pauseAutoRefresh += 1
        self.syntaxFontFamily = font.familyName ?? font.fontName
        self.syntaxFontSize = font.pointSize
        self.pauseAutoRefresh -= 1
    }
    
    /// Customize font panel.
    func validModesForFontPanel(_ fontPanel: NSFontPanel) -> NSFontPanel.ModeMask
    {
        return [.collection, .face, .size]
    }
}
