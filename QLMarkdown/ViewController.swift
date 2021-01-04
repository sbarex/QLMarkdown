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
    @objc dynamic var headsExtension: Bool = Settings.factorySettings.headsExtension {
        didSet {
            isDirty = true
        }
    }
    @objc dynamic var tableExtension: Bool = Settings.factorySettings.tableExtension {
        didSet {
            isDirty = true
        }
    }
    @objc dynamic var autoLinkExtension: Bool = Settings.factorySettings.autoLinkExtension {
        didSet {
            isDirty = true
        }
    }
    @objc dynamic var tagFilterExtension: Bool = Settings.factorySettings.tagFilterExtension {
        didSet {
            isDirty = true
        }
    }
    @objc dynamic var taskListExtension: Bool = Settings.factorySettings.taskListExtension {
        didSet {
            isDirty = true
        }
    }
    @objc dynamic var strikethroughExtension: Bool = Settings.factorySettings.strikethroughExtension {
        didSet {
            isDirty = true
            updateStrikethroughPopup()
        }
    }
    dynamic var strikethroughDoubleTildeOption: Bool = Settings.factorySettings.strikethroughDoubleTildeOption {
        didSet {
            isDirty = true
            updateStrikethroughPopup()
        }
    }
    
    @objc dynamic var mentionExtension: Bool = Settings.factorySettings.mentionExtension {
        didSet {
            isDirty = true
        }
    }
    
    @objc dynamic var syntaxHighlightExtension: Bool = Settings.factorySettings.syntaxHighlightExtension {
        didSet {
            isDirty = true
            self.sourceBackgroundLabel.textColor = syntaxHighlightExtension ? .labelColor : .disabledControlTextColor
            self.sourceCharactersLabel.textColor = syntaxHighlightExtension ? .labelColor : .disabledControlTextColor
            self.sourceTabsLabel.textColor = syntaxHighlightExtension ? .labelColor : .disabledControlTextColor
            self.sourceFontLabel.textColor = syntaxHighlightExtension && isFontCustomized ? .labelColor : .disabledControlTextColor
        }
    }
    
    @objc dynamic var syntaxThemeLight: ThemePreview? = nil {
        didSet {
            isDirty = true
            
            updateThemes()
        }
    }
    @objc dynamic var syntaxThemeDark: ThemePreview? = nil {
        didSet {
            isDirty = true
            
            updateThemes()
        }
    }
    
    @objc dynamic var customBackgroundColor: Bool = false {
        didSet {
            isDirty = true
        }
    }
    @objc dynamic var backgroundColorLight: NSColor = NSColor(css: Settings.factorySettings.syntaxBackgroundColorLight) ?? NSColor.textBackgroundColor {
        didSet {
            isDirty = true
        }
    }
    
    @objc dynamic var backgroundColorDark: NSColor = NSColor(css: Settings.factorySettings.syntaxBackgroundColorDark) ?? NSColor.textBackgroundColor {
        didSet {
            isDirty = true
        }
    }
    
    @objc dynamic var syntaxLineNumbers: Bool = Settings.factorySettings.syntaxLineNumbersOption {
        didSet {
            isDirty = true
        }
    }
    
    @objc dynamic var syntaxWrapEnabled: Bool = Settings.factorySettings.syntaxWordWrapOption > 0 {
        didSet {
            isDirty = true
        }
    }
    
    @objc dynamic var syntaxWrapCharacters: Int = Settings.factorySettings.syntaxWordWrapOption > 0 ? Settings.factorySettings.syntaxWordWrapOption : 80 {
        didSet {
            isDirty = true
        }
    }
    @objc dynamic fileprivate(set) var isFontCustomized: Bool = !Settings.factorySettings.syntaxFontFamily.isEmpty {
        didSet {
            isDirty = true
            sourceFontLabel.textColor = syntaxHighlightExtension && isFontCustomized ? .labelColor : .disabledControlTextColor
        }
    }
    @objc dynamic var syntaxFontSize: CGFloat = Settings.factorySettings.syntaxFontSize {
        didSet {
            isDirty = true
            refreshFontPreview()
        }
    }
    @objc dynamic var syntaxFontFamily: String = Settings.factorySettings.syntaxFontFamily {
        /*willSet {
            self.willChangeValue(forKey: #keyPath(isFontCustomized))
        }*/
        didSet {
            isDirty = true
            isFontCustomized = !syntaxFontFamily.isEmpty
            //self.didChangeValue(forKey: #keyPath(isFontCustomized))
            refreshFontPreview()
        }
    }
    
    
    @objc dynamic var emojiExtension: Bool = Settings.factorySettings.emojiExtension {
        didSet {
            updateEmojiPopup()
            isDirty = true
        }
    }
    @objc dynamic var emojiImageOption: Bool = Settings.factorySettings.emojiImageOption {
        didSet {
            updateEmojiPopup()
            isDirty = true
        }
    }
    
    @objc dynamic var inlineImageExtension: Bool = Settings.factorySettings.inlineImageExtension {
        didSet {
            isDirty = true
        }
    }
    
    @objc dynamic var hardBreakOption: Bool = Settings.factorySettings.hardBreakOption {
        didSet {
            isDirty = true
        }
    }
    @objc dynamic var noSoftBreakOption: Bool = Settings.factorySettings.noSoftBreakOption {
        didSet {
            isDirty = true
        }
    }
    @objc dynamic var unsafeHTMLOption: Bool = Settings.factorySettings.unsafeHTMLOption {
        didSet {
            isDirty = true
        }
    }
    @objc dynamic var validateUTFOption: Bool = Settings.factorySettings.validateUTFOption {
        didSet {
            isDirty = true
        }
    }
    @objc dynamic var smartQuotesOption: Bool = Settings.factorySettings.smartQuotesOption {
        didSet {
            isDirty = true
        }
    }
    @objc dynamic var footnotesOption: Bool = Settings.factorySettings.footnotesOption {
        didSet {
            isDirty = true
        }
    }
    
    @objc dynamic var guessEnabled: Bool = Settings.factorySettings.guessEngine != .none {
        didSet {
            isDirty = true
        }
    }
    @objc dynamic var guessEngine: Int = Settings.factorySettings.guessEngine == .fast ? 0 : (Settings.factorySettings.guessEngine == .accurate ? 1 : 0) {
        didSet {
            isDirty = true
        }
    }
    
    @objc dynamic var debugMode: Bool = Settings.factorySettings.debug {
        didSet {
            isDirty = true
        }
    }

    @objc dynamic var customCSSOverride: Bool = Settings.factorySettings.customCSSOverride {
        didSet {
            isDirty = true
            styleExtendPopup.selectItem(at: customCSSOverride ? 1 : 0)
        }
    }
    @objc dynamic var customCSSFile: URL? = Settings.factorySettings.customCSS {
        didSet {
            isDirty = true
            updateCustomCSSPopup()
        }
    }
    
    func initStylesPopup(resetStyles: Bool = false) {
        stylesPopup.removeAllItems()
        stylesPopup.addItem(withTitle: "GitHub ( Default )")
        stylesPopup.lastItem?.tag = -100
        stylesPopup.menu?.addItem(NSMenuItem.separator())
        
        stylesPopup.addItem(withTitle: "Open Application support themes folder")
        stylesPopup.lastItem?.tag = -4
        
        stylesPopup.addItem(withTitle: "Reveal CSS in Finder")
        stylesPopup.lastItem?.tag = -6
        stylesPopup.lastItem?.isAlternate = true
        stylesPopup.lastItem?.keyEquivalentModifierMask = [.option]
        
        stylesPopup.addItem(withTitle: "Refresh themes list")
        stylesPopup.lastItem?.tag = -5
        
        stylesPopup.menu?.addItem(NSMenuItem.separator())
        
        stylesPopup.addItem(withTitle: "Import…")
        stylesPopup.lastItem?.tag = -2
        stylesPopup.lastItem?.toolTip = "Import a CSS file in the standard themes folder."
        
        stylesPopup.addItem(withTitle: "Browse…")
        stylesPopup.lastItem?.tag = -1
        stylesPopup.lastItem?.isAlternate = true
        stylesPopup.lastItem?.keyEquivalentModifierMask = [.option]
        stylesPopup.lastItem?.toolTip = "Use a custom CSS file without importing in the standard themes folder."

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
            if pauseAutoRefresh == 0 && isDirty && autoRefresh && isLoaded {
                self.refresh(self)
            }
        }
    }
    internal var isDirty = false {
        didSet {
            if oldValue != isDirty {
                self.view.window?.isDocumentEdited = isDirty
                saveButton?.isEnabled = isDirty
            }
            if isDirty && autoRefresh && isLoaded && pauseAutoRefresh == 0 {
                self.refresh(self)
            }
        }
    }
    internal var isLoaded = false
    
    var isAdvancedSettingsHidden: Bool {
        get {
            let defaults = UserDefaults.standard
            return defaults.value(forKey: "advanced-settings") as? Bool ?? true
        }
        set {
            let defaults = UserDefaults.standard
            defaults.setValue(newValue, forKey: "advanced-settings")
            updateTabView()
        }
    }
    
    @IBOutlet weak var tabView: NSTabView!
    @IBOutlet weak var tabViewLeftConstraint: NSLayoutConstraint!
    @IBOutlet weak var tabViewBottomConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var webView: WKWebView!
    @IBOutlet weak var textView: NSTextView!
    @IBOutlet weak var stylesPopup: NSPopUpButton!
    
    @IBOutlet weak var styleExtendPopup: NSPopUpButton!
    @IBOutlet weak var styleRevealMenu: NSMenuItem!
    
    @IBOutlet weak var highlightBackground: NSPopUpButton!
    @IBOutlet weak var sourceBackgroundLabel: NSTextField!
    
    @IBOutlet weak var sourceThemesPopup: NSPopUpButton!
    @IBOutlet weak var sourceThemeLightColor: NSColorWell!
    @IBOutlet weak var sourceThemeDarkColor: NSColorWell!
    @IBOutlet weak var sourceWrapButton: NSButton!
    @IBOutlet weak var sourceWrapField: NSTextField!
    @IBOutlet weak var sourceWrapStepper: NSStepper!
    @IBOutlet weak var sourceCharactersLabel: NSTextField!
    @IBOutlet weak var sourceTabsPopup: NSPopUpButton!
    @IBOutlet weak var sourceTabsLabel: NSTextField!
    @IBOutlet weak var sourceFontLabel: NSTextField!
    @IBOutlet weak var sourceFontButton: NSButton!
    @IBOutlet weak var guessButton: NSButton!
    @IBOutlet weak var guessEnginePopup: NSPopUpButton!
    
    @IBOutlet weak var strikethroughPopupButton: NSPopUpButton!
    @IBOutlet weak var emojiPopupButton: NSPopUpButton!
    @IBOutlet weak var unsafeButton: NSButton!
    @IBOutlet weak var versionLabel: NSTextField!
    @IBOutlet weak var advancedButton: NSButton!
    
    @IBOutlet weak var progressIndicator: NSProgressIndicator!
    @IBOutlet weak var saveButton: NSButton!
    @IBOutlet weak var inlineLinkPopup: NSPopUpButton!
    
    @IBOutlet weak var appearanceButton: NSButton!
    
    private let log = {
        return OSLog(subsystem: Bundle.main.bundleIdentifier!, category: "quicklook.qlmarkdown-host")
    }()
    
    var markdown_file: URL? {
        didSet {
            if let file = markdown_file {
                do {
                    let s = try String(contentsOf: file)
                    self.textView.string = s
                } catch {
                    self.textView.string = "** Error loading file *\(file.path)*! **"
                }
            } else {
                self.textView.string = ""
            }
            self.textView.setSelectedRange(NSRange(location: 0, length: 0))
            prev_scroll = -1
            
            if isLoaded {
                doRefresh(self)
            }
        }
    }
    internal var prev_scroll: Int = -1
    
    @IBAction func doHighlightExtensionChanged(_ sender: NSButton) {
        self.highlightBackground.isEnabled = sender.state == .on
    }
    
    @IBAction func doDirty(_ sender: Any) {
        isDirty = true
    }
    
    @IBAction func doBackgroundCanged(_ sender: NSPopUpButton) {
        customBackgroundColor = highlightBackground.indexOfSelectedItem == 2
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
        
        self.markdown_file = src
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
        do {
            body = try settings.render(text: self.textView.string, forAppearance: self.appearanceButton.state == .off ? .light : .dark, baseDir: markdown_file?.deletingLastPathComponent().path ?? "", log: log)
        } catch {
            body = "Error"
        }
        
        
        let html = settings.getCompleteHTML(title: ".md", body: body)
        do {
            
            try html.write(to: dst, atomically: true, encoding: .utf8)
        } catch {
            let alert = NSAlert()
            alert.alertStyle = .critical
            alert.messageText = "Unable to export the HTML preview!"
            alert.addButton(withTitle: "Cancel")
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
    
    @IBAction func saveAction(_ sender: Any) {
        let settings = self.updateSettings()
        
        if settings.synchronize() {
            isDirty = false
        } else {
            let panel = NSAlert()
            panel.messageText = "Error saving the settings!"
            panel.alertStyle = .warning
            panel.addButton(withTitle: "OK")
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
        do {
            body = try settings.render(text: self.textView.string, forAppearance: self.appearanceButton.state == .off ? .light : .dark, baseDir: markdown_file?.deletingLastPathComponent().path ?? "", log: log)
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
        let extrajs: String
        if settings.unsafeHTMLOption && settings.inlineImageExtension {
            extrajs = "<script type=\"text/javascript\">" + (settings.getBundleContents(forResource: "inlineimages", ofType: "js") ?? "") + "</script>\n";
        } else {
            extrajs = ""
        }
        
        let html = settings.getCompleteHTML(title: ".md", body: body, header: header, footer: extrajs)
        webView.loadHTMLString(html, baseURL: markdown_file?.deletingLastPathComponent())
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
                    alert.addButton(withTitle: "Yes")
                    
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
                    alert.addButton(withTitle: "Cancel")
                    alert.runModal()
                }
            } else {
                // Reveal current theme.
                self.revealCSSInFinder(self)
            }
        case -100:
            // Default theme.
            customCSSFile = nil
            
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
    
    @IBAction func doAdvancedSettings(_ sender: Any) {
        self.isAdvancedSettingsHidden = !self.isAdvancedSettingsHidden
    }
    
    internal func updateTabView() {
        tabView.tabViewType = isAdvancedSettingsHidden ? .noTabsNoBorder : .topTabsBezelBorder
        tabView.selectTabViewItem(at: isAdvancedSettingsHidden ? 0 : 1)
        tabViewLeftConstraint.constant = isAdvancedSettingsHidden ? 0 : 20
        tabViewBottomConstraint?.constant = isAdvancedSettingsHidden ? 0 : 20
        
        advancedButton.title = isAdvancedSettingsHidden ? "Show advanced options" : "Show only basic options"
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
        contentController.add(self, name: "imageExtensionHandler")
        
        let settings = Settings.shared
        
        self.syntaxThemeLight = Self.searchTheme(Settings.factorySettings.syntaxThemeLight, in: Settings.shared.getAvailableThemes(), appearance: .light)
        self.syntaxThemeDark = Self.searchTheme(Settings.factorySettings.syntaxThemeDark, in: Settings.shared.getAvailableThemes(), appearance: .dark)
        
        self.initFromSettings(settings)
        
        markdown_file = Bundle.main.url(forResource: "test1", withExtension: "md")
        
        updateTabView()
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
    
    /// Show panel to chose a new font.
    @IBAction func chooseFont(_ sender: NSButton) {
        let fontPanel = NSFontPanel.shared
        fontPanel.worksWhenModal = true
        fontPanel.becomesKeyOnlyIfNeeded = true
        
        let fontFamily: String  = self.syntaxFontFamily
        let fontSize: CGFloat = self.syntaxFontSize
        
        if let font = NSFont(name: fontFamily, size: fontSize) {
            fontPanel.setPanelFont(font, isMultiple: false)
        }
        
        self.view.window?.makeFirstResponder(self)
        fontPanel.makeKeyAndOrderFront(self)
    }
    
    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
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
    
    internal func getBundleContents(forResource: String, ofType: String) -> String?
    {
        if let p = Bundle.main.path(forResource: forResource, ofType: ofType), let data = FileManager.default.contents(atPath: p), let s = String(data: data, encoding: .utf8) {
            return s
        } else {
            return nil
        }
    }
    
    @IBAction func doResetSourceThemes(_ sender: Any) {
        self.syntaxThemeLight = nil
        self.syntaxThemeDark = nil
    }
    
    internal func updateThemes() {
        if syntaxThemeLight == nil && syntaxThemeDark == nil {
            sourceThemesPopup.itemArray.first?.image = nil
            sourceThemesPopup.itemArray.first?.title = "Inherit from theme"
        } else {
            sourceThemesPopup.itemArray.first?.image = Theme.getCombinedImage2(light: syntaxThemeLight, dark: syntaxThemeDark, size: 100, space: 10)
            sourceThemesPopup.itemArray.first?.title = (syntaxThemeLight?.name ?? "") + " / " + (syntaxThemeDark?.name ?? "")
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
        pauseAutoRefresh += 1
        initStylesPopup()
        
        self.debugMode = settings.debug
        
        self.tableExtension = settings.tableExtension
        self.autoLinkExtension = settings.autoLinkExtension
        self.tagFilterExtension = settings.tagFilterExtension
        self.taskListExtension = settings.taskListExtension
        self.strikethroughExtension = settings.strikethroughExtension
        self.strikethroughDoubleTildeOption = settings.strikethroughDoubleTildeOption
        self.mentionExtension = settings.mentionExtension
        self.syntaxHighlightExtension = settings.syntaxHighlightExtension
        self.emojiExtension = settings.emojiExtension
        self.emojiImageOption = settings.emojiImageOption
        self.inlineImageExtension = settings.inlineImageExtension
        self.headsExtension = settings.headsExtension
        
        let themes = Settings.shared.getAvailableThemes()
        
        self.syntaxThemeLight = Self.searchTheme(settings.syntaxThemeLight, in: themes, appearance: .light)
        self.syntaxThemeDark = Self.searchTheme(settings.syntaxThemeDark, in: themes, appearance: .dark)
        
        self.syntaxLineNumbers = settings.syntaxLineNumbersOption
        self.syntaxWrapEnabled = settings.syntaxWordWrapOption > 0
        self.sourceWrapField.isEnabled = self.syntaxHighlightExtension
        self.sourceWrapField.isEnabled = syntaxWrapEnabled
        self.sourceWrapStepper.isEnabled = self.sourceWrapField.isEnabled
        
        self.syntaxWrapCharacters = settings.syntaxWordWrapOption > 0 ? settings.syntaxWordWrapOption : 80
        if let i = self.sourceTabsPopup.itemArray.firstIndex(where: { $0.tag == settings.syntaxTabsOption}) {
            self.sourceTabsPopup.selectItem(at: i)
        }
        self.syntaxFontFamily = settings.syntaxFontFamily
        self.syntaxFontSize = settings.syntaxFontSize
        
        if settings.syntaxBackgroundColorLight == "ignore" {
            highlightBackground.selectItem(at: 1)
        } else if settings.syntaxBackgroundColorLight == "" {
            highlightBackground.selectItem(at: 0)
        } else {
            highlightBackground.selectItem(at: 2)
            customBackgroundColor = true
        }
        self.backgroundColorLight = NSColor(css: settings.syntaxBackgroundColorLight) ?? NSColor(css: settings.syntaxBackgroundColorDark) ?? NSColor(white: 0.9, alpha: 1)
        self.backgroundColorDark = NSColor(css: settings.syntaxBackgroundColorDark) ?? NSColor(white: 0.4, alpha: 1)
        
        self.guessEnabled = settings.guessEngine != .none
        self.guessEngine = settings.guessEngine == .accurate ? 1 : 0
        
        self.hardBreakOption = settings.hardBreakOption
        self.noSoftBreakOption = settings.noSoftBreakOption
        self.unsafeHTMLOption = settings.unsafeHTMLOption
        self.validateUTFOption = settings.validateUTFOption
        self.smartQuotesOption = settings.smartQuotesOption
        self.footnotesOption = settings.footnotesOption
        
        self.customCSSFile = settings.customCSS
        self.customCSSOverride = settings.customCSSOverride
        
        self.doRefresh(self)
        
        self.guessEnginePopup.isEnabled = self.guessEnabled && self.syntaxHighlightExtension
        
        inlineLinkPopup.selectItem(at: settings.openInlineLink ? 0 : 1)
        isDirty = false
        pauseAutoRefresh -= 1
        doRefresh(self)
    }
    
    internal func updateSettings() -> Settings {
        let themeName = { (theme: Theme) -> String in
            var name: String
            if theme.isStandalone {
                name = theme.name
                if theme.isBase16 {
                    name = "base16/\(name)"
                }
            } else {
                name = theme.path
            }
            return name
        }
        
        let settings = Settings.shared
        
        settings.debug = self.debugMode
        
        settings.tableExtension = self.tableExtension
        settings.autoLinkExtension = self.autoLinkExtension
        settings.tagFilterExtension = self.tagFilterExtension
        settings.taskListExtension = self.taskListExtension
        settings.mentionExtension = self.mentionExtension
        settings.inlineImageExtension = self.inlineImageExtension
        settings.headsExtension = self.headsExtension
        
        settings.emojiExtension = self.emojiExtension
        settings.emojiImageOption = self.emojiImageOption
        
        settings.strikethroughExtension = self.strikethroughExtension
        settings.strikethroughDoubleTildeOption = self.strikethroughDoubleTildeOption
        
        settings.syntaxHighlightExtension = self.syntaxHighlightExtension
        
        settings.syntaxThemeLight = self.syntaxThemeLight != nil ? themeName(self.syntaxThemeLight!) : ""
        settings.syntaxThemeDark = self.syntaxThemeDark != nil ? themeName(self.syntaxThemeDark!) : ""
        settings.syntaxLineNumbersOption = self.syntaxLineNumbers
        settings.syntaxWordWrapOption = syntaxWrapEnabled ? self.syntaxWrapCharacters : 0
        settings.syntaxTabsOption = self.sourceTabsPopup.selectedItem?.tag ?? 0
        settings.syntaxFontFamily = sourceFontButton.state == .on ?  self.syntaxFontFamily : ""
        settings.syntaxFontSize = sourceFontButton.state == .on ?  self.syntaxFontSize : 0
        
        if self.highlightBackground.indexOfSelectedItem == 0 {
            settings.syntaxBackgroundColorLight = ""
            settings.syntaxBackgroundColorDark = ""
        } else if self.highlightBackground.indexOfSelectedItem == 1 {
            settings.syntaxBackgroundColorLight = "ignore"
            settings.syntaxBackgroundColorDark = "ignore"
        } else {
            settings.syntaxBackgroundColorLight = self.backgroundColorLight.css() ?? ""
            settings.syntaxBackgroundColorDark = self.backgroundColorDark.css() ?? ""
        }
        
        if guessEnabled {
            settings.guessEngine = self.guessEngine == 0 ? .fast : .accurate
        } else {
            settings.guessEngine = .none
        }
        
        settings.hardBreakOption = self.hardBreakOption
        settings.noSoftBreakOption = self.noSoftBreakOption
        settings.unsafeHTMLOption = self.unsafeHTMLOption
        settings.validateUTFOption = self.validateUTFOption
        settings.smartQuotesOption = self.smartQuotesOption
        settings.footnotesOption = self.footnotesOption
        
        settings.customCSSOverride = self.customCSSOverride
        settings.customCSS = self.customCSSFile
        
        settings.openInlineLink = inlineLinkPopup.indexOfSelectedItem == 0
        
        return settings
    }
}

extension ViewController: NSMenuItemValidation {
    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool
    {
        if menuItem.identifier?.rawValue == "advanced settings" {
            menuItem.state = isAdvancedSettingsHidden ? .off : .on
        } else if menuItem.identifier?.rawValue == "auto refresh" {
            menuItem.state = autoRefresh ? .on : .off
        } else if menuItem.action == #selector(self.saveDocument(_:)) || menuItem.action == #selector(self.saveAction(_:)) {
            return self.isDirty
        } else if menuItem.action == #selector(self.revertDocumentToSaved(_:)) {
            return self.isDirty
        }
        return true
    }
}
extension ViewController: NSFontChanging {
    /// Handle the selection of a font.
    func changeFont(_ sender: NSFontManager?) {
        guard let fontManager = sender else {
            return
        }
        let font = fontManager.convert(NSFont.systemFont(ofSize: 13.0))
        
        self.syntaxFontFamily = font.familyName ?? font.fontName
        self.syntaxFontSize = font.pointSize
        
        // self.refresh(self)
    }
    
    /// Customize font panel.
    func validModesForFontPanel(_ fontPanel: NSFontPanel) -> NSFontPanel.ModeMask
    {
        return [.collection, .face, .size]
    }
}


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

extension ViewController: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "scrollHandler", let dict = message.body as? [String : AnyObject], let p = dict["scroll"] as? Int {
            self.prev_scroll = p
        } else if message.name == "imageExtensionHandler", let dict = message.body as? [String : AnyObject], let src = dict["src"] as? String, let id = dict["id"] as? String, let data = get_base64_image(src.cString(using: .utf8)) {
            
            let response: [String: String] = [
                "src": src,
                "id": id,
                "data": String(cString: data)
            ]
            data.deallocate()
            let encoder = JSONEncoder()
            guard let j = try? encoder.encode(response), let js = String(data: j, encoding: .utf8) else {
                return
            }

            message.webView?.evaluateJavaScript("replaceImageSrc(\(js))") { (r, error) in
                if let result = r as? Bool, !result {
                    os_log(
                        "Unable to replace <img> src %{public}s with the inline data.",
                        log: self.log,
                        type: .error,
                        src
                    )
                }
                if let error = error {
                    os_log(
                        "Unable to replace <img> src %{public}s with the inline data: %{public}s.",
                        log: self.log,
                        type: .error,
                        src, error.localizedDescription
                    )
                }
            }
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
            alert.addButton(withTitle: "No")
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
        
        print("menuNeedsUpdate")
    }
}

class DropableTextView: NSTextView {
    @IBOutlet weak var container: ViewController?
    
    func endDrag(_ sender: NSDraggingInfo) {
        if let fileUrl = sender.draggingPasteboard.pasteboardItems?.first?.propertyList(forType: .fileURL) as? String, let url = URL(string: fileUrl) {
            
            print(url.path)
        } else {
            print("fial")
        }
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
        if suffix == "md" {
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
        container?.markdown_file = url
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
