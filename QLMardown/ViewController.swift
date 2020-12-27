//
//  ViewController.swift
//  QLMardown
//
//  Created by sbarex on 09/12/20.
//

import Cocoa
import WebKit

class ViewController: NSViewController {
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
            self.sourceThemeLightButton.image = syntaxThemeLight?.image
            self.sourceThemeLightLabel.attributedStringValue = syntaxThemeLight?.getAttributedTitle() ?? NSAttributedString()
        }
    }
    @objc dynamic var syntaxThemeDark: ThemePreview? {
        didSet {
            isDirty = true
            self.sourceThemeDarkButton.image = syntaxThemeDark?.image
            self.sourceThemeDarkLabel.attributedStringValue = syntaxThemeDark?.getAttributedTitle() ?? NSAttributedString()
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

    
    var styleFlag: Int = 0 {
        didSet {
            isDirty = true
            
            styleModePopup.selectItem(at: styleFlag)
            stylesPopup.isHidden = styleFlag == 0
            styleLabel.isHidden = styleFlag == 0
            styleRevealMenu.isHidden = styleFlag == 0
            styleSeparatorMenu.isHidden = styleFlag == 0
        }
    }
    
    @objc dynamic var customizedCSSFile: URL? {
        didSet {
            isDirty = true
            updateCustomCSSPopup()
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
            self.stylesPopup.selectItem(at: self.stylesPopup.numberOfItems - 2)
        }
    }
    
    internal var isDirty = false {
        didSet {
            if oldValue != isDirty {
                self.view.window?.isDocumentEdited = isDirty
                saveButton.isEnabled = isDirty
            }
        }
    }
    
    @IBOutlet weak var tabView: NSTabView!
    
    @IBOutlet weak var webView: WKWebView!
    @IBOutlet weak var textView: NSTextView!
    @IBOutlet weak var stylesPopup: NSPopUpButton!
    @IBOutlet weak var styleModePopup: NSPopUpButton!
    @IBOutlet weak var styleLabel: NSTextField!
    @IBOutlet weak var styleRevealMenu: NSMenuItem!
    @IBOutlet weak var styleSeparatorMenu: NSMenuItem!
    
    @IBOutlet weak var highlightBackground: NSPopUpButton!
    @IBOutlet weak var sourceBackgroundLabel: NSTextField!
    @IBOutlet weak var sourceThemeLightButton: NSButton!
    @IBOutlet weak var sourceThemeLightLabel: NSTextField!
    @IBOutlet weak var sourceThemeLightColor: NSColorWell!
    @IBOutlet weak var sourceThemeDarkButton: NSButton!
    @IBOutlet weak var sourceThemeDarkLabel: NSTextField!
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
    
    @IBOutlet weak var progressIndicator: NSProgressIndicator!
    @IBOutlet weak var saveButton: NSButton!
    @IBOutlet weak var inlineLinkPopup: NSPopUpButton!
    
    @IBOutlet weak var styleSegementedControl: NSSegmentedControl!
    
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
    
    internal var prev_scroll: Int = -1
    @IBAction func doRefresh(_ sender: Any)  {
        progressIndicator.startAnimation(self)
        
        // self.webView.loadHTMLString("", baseURL: nil)
        // self.webView.isHidden = true
        
        let body: String
        let settings = self.updateSettings()
        do {
            body = try settings.render(text: self.textView.string, forAppearance: self.styleSegementedControl.indexOfSelectedItem == 0 ? .light : .dark, baseDir: Bundle.main.resourceURL?.path ?? "", log: nil)
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
    
    @IBAction func handleStyleModePopup(_ sender: NSPopUpButton) {
        self.styleFlag = sender.indexOfSelectedItem
    }
    
    @IBAction func handleStypePopup(_ sender: NSPopUpButton) {
        if sender.indexOfSelectedItem == sender.numberOfItems - 1 {
            let panel = NSOpenPanel()
            panel.canChooseDirectories = false
            panel.canCreateDirectories = false
            panel.allowsMultipleSelection = false
            panel.allowedFileTypes = ["css"]
            panel.message = "Select a custom CSS style"
            
            let result = panel.runModal()
            
            guard result.rawValue == NSApplication.ModalResponse.OK.rawValue, let src = panel.url else {
                updateCustomCSSPopup()
                return
            }
            
            customizedCSSFile = src
        } else {
            if let item = sender.selectedItem {
                let url: URL
                if item.tag == 1, let base = Settings.stylesFolder {
                    url = base.appendingPathComponent(item.title)
                } else {
                    url = URL(fileURLWithPath: item.title)
                }
                customizedCSSFile = url
            } else {
                updateCustomCSSPopup()
            }
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
    
    @IBAction func handleDownloadStandardCSS(_ sender: Any) {
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
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let path = Bundle.main.resourceURL?.appendingPathComponent("highlight").path {
            cmark_syntax_highlight_init("\(path)/".cString(using: .utf8))
        }
        
        for btn in [self.sourceThemeLightButton, self.sourceThemeDarkButton] {
            // Add round corners and border to the theme icons.
            btn?.wantsLayer = true
            btn?.layer?.cornerRadius = 8
            btn?.layer?.borderWidth = 1
            btn?.layer?.borderColor = NSColor.tertiaryLabelColor.cgColor
        }
        
        self.textView.isAutomaticQuoteSubstitutionEnabled = false // Settings this option on interfacebuilder is ignored.
        self.textView.isAutomaticTextReplacementEnabled = false
        self.textView.isAutomaticDashSubstitutionEnabled = false
        
        let type = UserDefaults.standard.string(forKey: "AppleInterfaceStyle") ?? "Light"
        
        self.styleSegementedControl.setSelected(true, forSegment: type != "Light" ? 1 : 0)
        self.webView.configuration.preferences.setValue(true, forKey: "developerExtrasEnabled")
        let contentController = self.webView.configuration.userContentController
        contentController.add(self, name: "scrollHandler")
        
        let filename = "test1"
        let markdown_string = getBundleContents(forResource: filename, ofType: "md") ?? "*error*"
        
        self.textView.string = markdown_string
        
        versionLabel.stringValue = "lib cmark-gfm version \(String(cString: cmark_version_string())) (\(cmark_version()))"
        
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
        
        tabView.selectTabViewItem(at: 0)
    }
    
    @IBAction func showThemeSelector(_ sender: NSButton) {
        guard let vc = self.storyboard?.instantiateController(withIdentifier:"ThemeSelector") as? ThemeSelectorViewController else {
            return
        }
        
        vc.style = sender.tag == 2 ? .dark : .light
        vc.handler = { theme in
            if sender == self.sourceThemeLightButton {
                self.syntaxThemeLight = theme
            } else {
                self.syntaxThemeDark = theme
            }
        }
        vc.allThemes = Settings.shared.getAvailableThemes()
        
        self.present(vc, asPopoverRelativeTo: sender.frame, of: sender.superview!, preferredEdge: NSRectEdge.maxY, behavior: NSPopover.Behavior.semitransient)
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
        stylesPopup.insertItem(withTitle: name, at: stylesPopup.numberOfItems - 2)
        if (standalone) {
            stylesPopup.menu?.item(at: stylesPopup.numberOfItems - 3)?.tag = 1
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
    
    internal func initFromSettings(_ settings: Settings) {
        while stylesPopup.numberOfItems > 2 {
            stylesPopup.removeItem(at: 0)
        }
        for url in settings.getAvailableStyles() {
            addStyleSheet(url)
        }
        
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
        
        self.styleFlag = settings.customCSS != nil ? (settings.customCSSOverride ? 2 : 1) : 0
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
        
        settings.customCSSOverride = styleFlag == 2
        settings.customCSS = styleFlag == 0 ? nil : self.customizedCSSFile
        
        settings.openInlineLink = inlineLinkPopup.indexOfSelectedItem == 0
        
        return settings
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
