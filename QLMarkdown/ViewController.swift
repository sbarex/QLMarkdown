//
//  ViewController.swift
//  QLMarkdown
//
//  Created by sbarex on 09/12/20.
//

import Cocoa
import WebKit

class ViewController: NSViewController {
    @objc dynamic var headsExtension: Bool = true {
        didSet {
            isDirty = true
        }
    }
    @objc dynamic var tableExtension: Bool = true {
        didSet {
            isDirty = true
        }
    }
    @objc dynamic var autoLinkExtension: Bool = true {
        didSet {
            isDirty = true
        }
    }
    @objc dynamic var tagFilterExtension: Bool = true {
        didSet {
            isDirty = true
        }
    }
    @objc dynamic var taskListExtension: Bool = true {
        didSet {
            isDirty = true
        }
    }
    @objc dynamic var strikethroughExtension: Bool = true {
        didSet {
            isDirty = true
            strikethroughPopupButton.mode = strikethroughExtension ? .popup : .button
        }
    }
    @objc dynamic var mentionExtension: Bool = false {
        didSet {
            isDirty = true
        }
    }
    
    @objc dynamic var syntaxHighlightExtension: Bool = true {
        didSet {
            isDirty = true
            self.sourceBackgroundLabel.textColor = syntaxHighlightExtension ? .labelColor : .disabledControlTextColor
            self.sourceCharactersLabel.textColor = syntaxHighlightExtension ? .labelColor : .disabledControlTextColor
            self.sourceTabsLabel.textColor = syntaxHighlightExtension ? .labelColor : .disabledControlTextColor
            self.sourceFontLabel.textColor = syntaxHighlightExtension && isFontCustomized ? .labelColor : .disabledControlTextColor
        }
    }
    
    @objc dynamic var syntaxThemeLight: ThemePreview? {
        didSet {
            isDirty = true
            
            updateThemes()
        }
    }
    @objc dynamic var syntaxThemeDark: ThemePreview? {
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
    @objc dynamic var backgroundColorLight: NSColor = NSColor.textBackgroundColor {
        didSet {
            isDirty = true
        }
    }
    
    @objc dynamic var backgroundColorDark: NSColor = NSColor.textBackgroundColor {
        didSet {
            isDirty = true
        }
    }
    
    @objc dynamic var syntaxWrapEnabled: Bool = false {
        didSet {
            isDirty = true
        }
    }
    
    @objc dynamic var syntaxWrapCharacters: Int = 80 {
        didSet {
            isDirty = true
        }
    }
    @objc dynamic fileprivate(set) var isFontCustomized: Bool = false {
        didSet {
            isDirty = true
            sourceFontLabel.textColor = syntaxHighlightExtension && isFontCustomized ? .labelColor : .disabledControlTextColor
        }
    }
    @objc dynamic var syntaxFontSize: CGFloat = 12 {
        didSet {
            isDirty = true
            refreshFontPreview()
        }
    }
    @objc dynamic var syntaxFontFamily: String = "" {
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
    
    
    @objc dynamic var emojiExtension: Bool = true {
        didSet {
            updateEmojiStatus()
            emojiPopupButton.mode = emojiExtension ? .popup : .button
            isDirty = true
        }
    }
    
    @objc dynamic var inlineImageExtension: Bool = true {
        didSet {
            isDirty = true
        }
    }
    
    @objc dynamic var hardBreakOption: Bool = false {
        didSet {
            isDirty = true
        }
    }
    @objc dynamic var noSoftBreakOption: Bool = false {
        didSet {
            isDirty = true
        }
    }
    @objc dynamic var unsafeHTMLOption: Bool = false {
        didSet {
            isDirty = true
        }
    }
    @objc dynamic var validateUTFOption: Bool = false {
        didSet {
            isDirty = true
        }
    }
    @objc dynamic var smartQuotesOption: Bool = false {
        didSet {
            isDirty = true
        }
    }
    @objc dynamic var footnotesOption: Bool = false {
        didSet {
            isDirty = true
        }
    }
    
    @objc dynamic var guessEnabled: Bool = false {
        didSet {
            isDirty = true
        }
    }
    @objc dynamic var guessEngine: Int = 0 {
        didSet {
            isDirty = true
        }
    }
    
    @objc dynamic var debugMode: Bool = false {
        didSet {
            isDirty = true
        }
    }

    @objc dynamic var customizedCSSExtend: Bool = false {
        didSet {
            isDirty = true
            styleExtendPopup.selectItem(at: customizedCSSExtend ? 0 : 1)
        }
    }
    @objc dynamic var customizedCSSFile: URL? {
        didSet {
            isDirty = true
            updateCustomCSSPopup()
        }
    }
    
    func initStylesPopup(resetStyles: Bool = false) {
        stylesPopup.removeAllItems()
        stylesPopup.addItem(withTitle: "Default style")
        stylesPopup.menu?.addItem(NSMenuItem.separator())
        stylesPopup.addItem(withTitle: "Reveal in Finder")
        stylesPopup.lastItem?.tag = -6
        stylesPopup.addItem(withTitle: "Refresh")
        stylesPopup.lastItem?.tag = -5
        stylesPopup.addItem(withTitle: "Open application support styles folder")
        stylesPopup.lastItem?.tag = -4
        stylesPopup.addItem(withTitle: "Download Default style")
        stylesPopup.lastItem?.tag = -3
        stylesPopup.menu?.addItem(NSMenuItem.separator())
        stylesPopup.addItem(withTitle: "Import…")
        stylesPopup.lastItem?.tag = -2
        stylesPopup.addItem(withTitle: "Browse…")
        stylesPopup.lastItem?.tag = -1
        
        let settings = Settings.shared
        for url in settings.getAvailableStyles(resetCache: resetStyles) {
            addStyleSheet(url)
        }
        stylesPopup.menu?.insertItem(NSMenuItem.separator(), at: stylesPopup.numberOfItems-7)
    }
    
    internal func addStyleSheet(_ file: URL) {
        let name: String
        let standalone: Bool
        if let folder = Settings.stylesFolder?.path, file.path.hasPrefix(folder) {
            name = String(file.path.dropFirst(folder.count + 1))
            standalone = true
        } else {
            name = file.path
            standalone = false
        }
        stylesPopup.insertItem(withTitle: name, at: stylesPopup.numberOfItems - 7)
        if standalone {
            stylesPopup.menu?.item(at: stylesPopup.numberOfItems - 8)?.tag = 1
        }
    }
    
    func updateCustomCSSPopup() {
        if let style = customizedCSSFile {
            let base = Settings.stylesFolder
            if let index = stylesPopup.itemArray.firstIndex(where: {
                let file: String
                if $0.tag == 1, let base = base {
                    file = base.appendingPathComponent($0.title).path
                } else {
                    file = $0.title
                }
                return file == style.path }) {
                self.stylesPopup.selectItem(at: index)
            } else {
                addStyleSheet(style)
                self.stylesPopup.selectItem(at: self.stylesPopup.numberOfItems - 3)
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
    
    internal var isDirty = false {
        didSet {
            if oldValue != isDirty {
                self.view.window?.isDocumentEdited = isDirty
                saveButton?.isEnabled = isDirty
            }
            if isDirty && autoRefresh && isLoaded {
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
    @IBOutlet weak var sourceLineNumbersButton: NSButton!
    @IBOutlet weak var sourceTabsPopup: NSPopUpButton!
    @IBOutlet weak var sourceTabsLabel: NSTextField!
    @IBOutlet weak var sourceFontLabel: NSTextField!
    @IBOutlet weak var sourceFontButton: NSButton!
    @IBOutlet weak var guessButton: NSButton!
    @IBOutlet weak var guessEnginePopup: NSPopUpButton!
    
    @IBOutlet weak var strikethroughPopupButton: CustomPopUpButton!
    @IBOutlet weak var emojiPopupButton: CustomPopUpButton!
    @IBOutlet weak var unsafeButton: NSButton!
    @IBOutlet weak var versionLabel: NSTextField!
    @IBOutlet weak var advancedButton: NSButton!
    
    @IBOutlet weak var progressIndicator: NSProgressIndicator!
    @IBOutlet weak var saveButton: NSButton!
    @IBOutlet weak var inlineLinkPopup: NSPopUpButton!
    
    @IBOutlet weak var styleSegementedControl: NSSegmentedControl!
    
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
            prev_scroll = -1
            doRefresh(self)
        }
    }
    internal var prev_scroll: Int = -1
    
    @IBAction func doHighlightExtensionChanged(_ sender: NSButton) {
        self.highlightBackground.isEnabled = sender.state == .on
    }
    
    @IBAction func doEmojiChanged(_ sender: NSPopUpButton) {
        isDirty = true
        updateEmojiStatus()
    }
    
    @IBAction func doDirty(_ sender: Any) {
        isDirty = true
    }
    
    @IBAction func doBackgroundCanged(_ sender: NSPopUpButton) {
        customBackgroundColor = highlightBackground.indexOfSelectedItem == 2
    }
    
    @IBAction func doStyleChange(_ sender: NSSegmentedControl) {
        self.view.window?.appearance = NSAppearance(named: sender.selectedSegment == 1 ? NSAppearance.Name.darkAqua : NSAppearance.Name.aqua)
        self.doRefresh(sender)
    }
    
    @IBAction func doStyleOverrideChange(_ sender: NSPopUpButton) {
        self.customizedCSSExtend = sender.indexOfSelectedItem == 0
    }
    
    @IBAction func openDocument(_ sender: Any) {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = false
        panel.canCreateDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedFileTypes = ["md"]
        panel.message = "Select a markdown file to preview"
        
        let result = panel.runModal()
        
        guard result.rawValue == NSApplication.ModalResponse.OK.rawValue, let src = panel.url else {
            return
        }
        
        self.markdown_file = src
    }
    
    @IBAction func saveDocument(_ sender: Any) {
        saveAction(sender)
    }
    
    @IBAction func revertDocumentToSaved(_ sender: Any) {
        let settings = Settings.shared
        settings.reset()
        self.initFromSettings(settings)
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
            body = try settings.render(text: self.textView.string, forAppearance: self.styleSegementedControl.indexOfSelectedItem == 0 ? .light : .dark, baseDir: markdown_file?.deletingLastPathComponent().path ?? "", log: nil)
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
        webView.loadHTMLString(html, baseURL: Bundle.main.resourceURL)
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
                self.initStylesPopup(resetStyles: true)
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
            customizedCSSFile = url
        }
    }
    
    @IBAction func handleStypesPopup(_ sender: NSPopUpButton) {
        let tag = sender.selectedTag()
        switch tag {
        case -1, /* Browse */ -2 /* Import */:
            if let url = importStyle(copyOnSharedFolder: tag == -2) {
                customizedCSSFile = url
            }
        case -3: // Download default style
            updateCustomCSSPopup()
            
            let savePanel = NSSavePanel()
            savePanel.canCreateDirectories = true
            savePanel.showsTagField = false
            savePanel.allowedFileTypes = ["css"]
            savePanel.isExtensionHidden = false
            savePanel.nameFieldStringValue = "markdown.css"
            savePanel.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.modalPanelWindow)))
            
            let result = savePanel.runModal()
            
            guard result.rawValue == NSApplication.ModalResponse.OK.rawValue, let dst = savePanel.url, let src = Bundle.main.url(forResource: "markdown", withExtension: "css") else {
                return
            }
            do {
                try FileManager.default.copyItem(at: src, to: dst)
            } catch {
                let alert = NSAlert()
                alert.alertStyle = .critical
                alert.messageText = "Unable to export the css style!"
                alert.addButton(withTitle: "Cancel")
                alert.runModal()
            }
        case -4: // Open application support folder
            updateCustomCSSPopup()
            
            self.revealApplicationSupportInFinder(self)
        
        case -5: // Refresh list
            let css = self.customizedCSSFile
            self.customizedCSSFile = nil
            self.initStylesPopup(resetStyles: true)
            self.customizedCSSFile = css
            
        case -6: // Reveal
            updateCustomCSSPopup()
            
            self.revealCSSInFinder(self)
            
        default:
            if sender.indexOfSelectedItem == 0 {
                customizedCSSFile = nil
            } else {
                if let item = sender.selectedItem {
                    let url: URL
                    if item.tag == 1, let base = Settings.stylesFolder {
                        url = base.appendingPathComponent(item.title)
                    } else {
                        url = URL(fileURLWithPath: item.title)
                    }
                    customizedCSSFile = url
                }
            }
            updateCustomCSSPopup()
        }
    }
    
    @IBAction func revealCSSInFinder(_ sender: Any) {
        guard let url = self.customizedCSSFile else {
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
        if isAdvancedSettingsHidden {
            tabView.selectTabViewItem(at: 0)
        }
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
        
        let type = UserDefaults.standard.string(forKey: "AppleInterfaceStyle") ?? "Light"
        
        self.styleSegementedControl.setSelected(true, forSegment: type != "Light" ? 1 : 0)
        self.webView.configuration.preferences.setValue(true, forKey: "developerExtrasEnabled")
        let contentController = self.webView.configuration.userContentController
        contentController.add(self, name: "scrollHandler")
        
        markdown_file = Bundle.main.url(forResource: "test1", withExtension: "md")
        
        versionLabel?.stringValue = "lib cmark-gfm version \(String(cString: cmark_version_string())) (\(cmark_version()))"
        
        let settings = Settings.shared
        
        self.initFromSettings(settings)
        
        self.strikethroughPopupButton.actionButton = { sender in
            self.strikethroughExtension = true
        }
        self.strikethroughPopupButton.mode = self.strikethroughExtension ? .popup : .button
        self.emojiPopupButton.actionButton = { sender in
            self.emojiExtension = true
        }
        self.emojiPopupButton.mode = self.emojiExtension ? .popup : .button
        
        textView.font = NSFont.systemFont(ofSize: 14)
        
        tabView.selectTabViewItem(at: 0)
        
        updateTabView()
        
        isLoaded = true
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
    
    internal func updateEmojiStatus() {
        if emojiExtension && emojiPopupButton.indexOfSelectedItem == 1 {
            unsafeHTMLOption = true
            unsafeButton.state = .on
            unsafeButton.isEnabled = false
        } else {
            unsafeButton.isEnabled = true
        }
    }
    
    internal func updateThemes() {
        sourceThemesPopup.itemArray.first?.image = Theme.getCombinedImage2(light: syntaxThemeLight, dark: syntaxThemeDark, size: 100, space: 10)
        sourceThemesPopup.itemArray.first?.title = (syntaxThemeLight?.name ?? "") + " / " + (syntaxThemeDark?.name ?? "")
    }
    
    internal func initFromSettings(_ settings: Settings) {
        initStylesPopup()
        
        self.debugMode = settings.debug
        
        self.tableExtension = settings.tableExtension
        self.autoLinkExtension = settings.autoLinkExtension
        self.tagFilterExtension = settings.tagFilterExtension
        self.taskListExtension = settings.taskListExtension
        self.strikethroughExtension = settings.strikethroughExtension
        self.mentionExtension = settings.mentionExtension
        self.syntaxHighlightExtension = settings.syntaxHighlightExtension
        self.emojiExtension = settings.emojiExtension
        self.inlineImageExtension = settings.inlineImageExtension
        self.headsExtension = settings.headsExtension
        
        let themes = Settings.shared.getAvailableThemes()
        
        let searchTheme = { (name: String, appearance: Theme.ThemeAppearance) -> ThemePreview? in
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
                return themes.first(where: {$0.appearance == appearance}) ?? themes.first
            }
        }
        
        self.syntaxThemeLight = searchTheme(settings.syntaxThemeLight, .light)
        self.syntaxThemeDark = searchTheme(settings.syntaxThemeDark, .dark)
        
        
        self.sourceLineNumbersButton.state = settings.syntaxLineNumbersOption ? .on : .off
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
        
        self.sourceLineNumbersButton.state = settings.syntaxLineNumbersOption ? .on : .off
        self.guessEnabled = settings.guessEngine != .none
        self.guessEngine = settings.guessEngine == .accurate ? 1 : 0
        
        self.hardBreakOption = settings.hardBreakOption
        self.noSoftBreakOption = settings.noSoftBreakOption
        self.unsafeHTMLOption = settings.unsafeHTMLOption
        self.validateUTFOption = settings.validateUTFOption
        self.smartQuotesOption = settings.smartQuotesOption
        self.footnotesOption = settings.footnotesOption
        
        self.customizedCSSFile = settings.customCSS
        
        self.doRefresh(self)
        
        self.guessEnginePopup.isEnabled = self.guessEnabled && self.syntaxHighlightExtension
        
        inlineLinkPopup.selectItem(at: settings.openInlineLink ? 0 : 1)
        isDirty = false
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
        settings.emojiImageOption = self.emojiPopupButton.indexOfSelectedItem != 0
        
        settings.strikethroughExtension = self.strikethroughExtension
        settings.strikethroughDoubleTildeOption = self.strikethroughPopupButton.indexOfSelectedItem != 0
        
        settings.syntaxHighlightExtension = self.syntaxHighlightExtension
        
        settings.syntaxThemeLight = self.syntaxThemeLight != nil ? themeName(self.syntaxThemeLight!) : "acid"
        settings.syntaxThemeDark = self.syntaxThemeDark != nil ? themeName(self.syntaxThemeDark!) : "zenburn"
        settings.syntaxLineNumbersOption = self.sourceLineNumbersButton.state == .on
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
        
        settings.customCSSOverride = !customizedCSSExtend
        settings.customCSS = self.customizedCSSFile
        
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
}

extension ViewController: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == "scrollHandler" else {
            return
        }
        guard let dict = message.body as? [String : AnyObject] else {
            return
        }

        if let p = dict["scroll"] as? Int {
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


enum CustomPopUpButtonMode {
    case popup
    case button
}

class CustomPopUpButton: NSPopUpButton {
    var mode: CustomPopUpButtonMode = .popup {
        didSet {
            guard let c = self.cell as? NSPopUpButtonCell else {
                return
            }
            c.arrowPosition = mode == .popup ? .arrowAtCenter : .noArrow
        }
    }
    
    var actionButton: ((CustomPopUpButton) -> Void)?
    
    override func willOpenMenu(_ menu: NSMenu, with event: NSEvent) {
        if mode == .popup {
            super.willOpenMenu(menu, with: event)
        } else {
            // this grant the popup menu to not showup (or disappear so quickly)
            menu.cancelTrackingWithoutAnimation()
            actionButton?(self)
        }
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
