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
        }
    }
    @objc dynamic var mentionExtension: Bool = false {
        didSet {
            isDirty = true
        }
    }
    @objc dynamic var checkboxExtension: Bool = false {
        didSet {
            isDirty = true
        }
    }
    @objc dynamic var syntaxHighlightExtension: Bool = true {
        didSet {
            isDirty = true
        }
    }
    @objc dynamic var emojiExtension: Bool = true {
        didSet {
            updateEmojiStatus()
            isDirty = true
        }
    }
    
    @objc dynamic var inlineImageExtension: Bool = true {
        didSet {
            isDirty = true
        }
    }
    
    @objc dynamic var backgroundColor: NSColor = NSColor.textBackgroundColor {
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
    
    internal var isDirty = false {
        didSet {
            if oldValue != isDirty {
                self.view.window?.isDocumentEdited = isDirty
            }
        }
    }
    
    @IBOutlet weak var webView: WKWebView!
    @IBOutlet weak var textView: NSTextView!
    @IBOutlet weak var languageThemePopupButton: NSPopUpButton!
    @IBOutlet weak var highlightBackground: NSPopUpButton!
    @IBOutlet weak var colorPicker: NSColorWell!
    
    @IBOutlet weak var strikethroughPopupButton: NSPopUpButton!
    @IBOutlet weak var emojiPopupButton: NSPopUpButton!
    @IBOutlet weak var warningImageView: NSImageView!
    @IBOutlet weak var unsafeButton: NSButton!
    @IBOutlet weak var versionLabel: NSTextField!
    
    @IBOutlet weak var styleSegementedControl: NSSegmentedControl!
    
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        if segue.identifier == "EditThemeSegue", let wc = segue.destinationController as? NSWindowController, let vc = wc.contentViewController as? ThemesViewController {
            vc.themesView.setTheme(name: self.languageThemePopupButton.selectedItem?.title, scroll: true)
            /*
            if let t = vc.themesView?.themes.first(where: {$0.name == self.languageThemePopupButton.selectedItem?.title}) {
                vc.theme = t
            }
 */
        }
        super.prepare(for: segue, sender: sender)
    }
    
    @IBAction func doHighlightExtensionChanged(_ sender: NSButton) {
        self.highlightBackground.isEnabled = sender.state == .on
        self.colorPicker.isEnabled = sender.state == .on && highlightBackground.indexOfSelectedItem == 2
    }
    
    @IBAction func doEmojiChanged(_ sender: NSPopUpButton) {
        updateEmojiStatus()
    }
    
    @IBAction func doBackgroundCanged(_ sender: NSPopUpButton) {
        self.colorPicker.isEnabled = syntaxHighlightExtension && highlightBackground.indexOfSelectedItem == 2
    }
    
    @IBAction func doStyleChange(_ sender: NSSegmentedControl) {
        self.view.window?.appearance = NSAppearance(named: sender.selectedSegment == 1 ? NSAppearance.Name.darkAqua : NSAppearance.Name.aqua)
        self.doRefresh(sender)
    }
    
    internal func updateEmojiStatus() {
        warningImageView.isHidden = !emojiExtension || emojiPopupButton.indexOfSelectedItem == 0
        if emojiExtension && emojiPopupButton.indexOfSelectedItem == 1 {
            unsafeHTMLOption = true
            unsafeButton.state = .on
            unsafeButton.isEnabled = false
        } else {
            unsafeButton.isEnabled = true
        }
    }
    
    @IBAction func saveAction(_ sender: Any) {
        let settings = Settings.shared
        settings.tableExtension = self.tableExtension
        settings.autoLinkExtension = self.autoLinkExtension
        settings.tagFilterExtension = self.tagFilterExtension
        settings.taskListExtension = self.taskListExtension
        settings.mentionExtension = self.mentionExtension
        settings.checkboxExtension = self.checkboxExtension
        
        settings.strikethroughExtension = self.strikethroughExtension
        settings.strikethroughDoubleTildeOption = self.strikethroughPopupButton.indexOfSelectedItem != 0
        
        settings.syntaxHighlightExtension = self.syntaxHighlightExtension
        settings.syntaxThemeLight = self.languageThemePopupButton.stringValue
        if self.highlightBackground.indexOfSelectedItem == 0 {
            settings.syntaxBackgroundColorLight = ""
        } else if self.highlightBackground.indexOfSelectedItem == 1 {
            settings.syntaxBackgroundColorLight = "ignore"
        } else if let css = self.backgroundColor.css() {
            settings.syntaxBackgroundColorLight = css
        }
        
        // settings.syntaxThemeDark = self.syntaxThemeDark
        // settings.syntaxBackgroundColorDark = self.syntaxBackgroundColorDark
        
        settings.emojiExtension = self.emojiExtension
        settings.inlineImageExtension = self.inlineImageExtension
        settings.emojiImageOption = self.emojiPopupButton.indexOfSelectedItem != 0
        
        settings.hardBreakOption = self.hardBreakOption
        settings.noSoftBreakOption = self.noSoftBreakOption
        settings.unsafeHTMLOption = self.unsafeHTMLOption
        settings.validateUTFOption = self.validateUTFOption
        settings.smartQuotesOption = self.smartQuotesOption
        settings.footnotesOption = self.footnotesOption
        
        if settings.synchronize() {
            isDirty = false
        }
    }
    
    @IBAction func doRefresh(_ sender: Any)
    {
        self.webView.loadHTMLString("", baseURL: nil)
        
        cmark_gfm_core_extensions_ensure_registered()
        
        var options = CMARK_OPT_DEFAULT
        if emojiExtension && emojiPopupButton.indexOfSelectedItem == 1 {
            options |= CMARK_OPT_UNSAFE
        }
        
        if hardBreakOption {
            options |= CMARK_OPT_HARDBREAKS
        }
        if noSoftBreakOption {
            options |= CMARK_OPT_NOBREAKS
        }
        if unsafeHTMLOption {
            options |= CMARK_OPT_UNSAFE
        }
        if validateUTFOption {
            options |= CMARK_OPT_VALIDATE_UTF8
        }
        if smartQuotesOption {
            options |= CMARK_OPT_SMART
        }
        if footnotesOption {
            options |= CMARK_OPT_FOOTNOTES
        }
        
        if strikethroughExtension && strikethroughPopupButton.indexOfSelectedItem == 1 {
            options |= CMARK_OPT_STRIKETHROUGH_DOUBLE_TILDE
        }
        
        // Modified version of cmark_parse_document in blocks.c
        guard let parser = cmark_parser_new(options) else {
            return
        }
        defer {
            cmark_parser_free(parser)
        }
        if self.tableExtension, let ext = cmark_find_syntax_extension("table") {
            cmark_parser_attach_syntax_extension(parser, ext)
        }
        if self.autoLinkExtension, let ext = cmark_find_syntax_extension("autolink") {
            cmark_parser_attach_syntax_extension(parser, ext)
        }
        if self.tagFilterExtension, let ext = cmark_find_syntax_extension("tagfilter") {
            cmark_parser_attach_syntax_extension(parser, ext)
        }
        if self.taskListExtension, let ext = cmark_find_syntax_extension("tasklist") {
            cmark_parser_attach_syntax_extension(parser, ext)
        }
        if self.strikethroughExtension, let ext = cmark_find_syntax_extension("strikethrough") {
            cmark_parser_attach_syntax_extension(parser, ext)
        }
        
        if self.mentionExtension, let ext = cmark_find_syntax_extension("mention") {
            cmark_parser_attach_syntax_extension(parser, ext)
        }
        if self.checkboxExtension, let ext = cmark_find_syntax_extension("checkbox") {
            cmark_parser_attach_syntax_extension(parser, ext)
        }
        if self.emojiExtension, let ext = cmark_find_syntax_extension("emoji") {
            cmark_syntax_extension_emoji_set_use_characters(ext, emojiPopupButton.indexOfSelectedItem == 0)
            cmark_parser_attach_syntax_extension(parser, ext)
        }
        if self.inlineImageExtension, let ext = cmark_find_syntax_extension("inlineimage") {
            cmark_parser_attach_syntax_extension(parser, ext)
            cmark_syntax_extension_inlineimage_set_wd(ext, (Bundle.main.resourceURL?.path ?? "").cString(using: .utf8))
        }
        
        if self.syntaxHighlightExtension, let ext = cmark_find_syntax_extension("syntaxhighlight") {
            let theme = languageThemePopupButton.titleOfSelectedItem?.cString(using: .utf8) ?? "".cString(using: .utf8)
            cmark_syntax_extension_highlight_set_theme_name(ext, theme)
            if self.highlightBackground.indexOfSelectedItem == 0 {
                cmark_syntax_extension_highlight_set_background_color(ext, nil)
            } else if self.highlightBackground.indexOfSelectedItem == 1 {
                cmark_syntax_extension_highlight_set_background_color(ext, "ignore")
            } else if self.highlightBackground.indexOfSelectedItem == 2, let css = self.colorPicker.color.css() {
                cmark_syntax_extension_highlight_set_background_color(ext, css)
            }
            
            
            if let s = themeInfo(theme) {
                if let t = String(cString: s, encoding: .utf8), let data = t.data(using: .utf8), let j = try? JSONDecoder().decode([String: String].self, from: data) {
                    print(j)
                }
                free(s)
            }
            
            cmark_parser_attach_syntax_extension(parser, ext)
        }
        
        let markdown_string = self.textView.string
        cmark_parser_feed(parser, markdown_string, strlen(markdown_string))
        guard let doc = cmark_parser_finish(parser) else {
            return
        }
        defer {
            cmark_node_free(doc)
        }
        
        if self.syntaxHighlightExtension {
            // processMyDoc(doc)
        }
        /*
        let iterator = cmark_iter_new(doc)
        while cmark_iter_next(iterator) != CMARK_EVENT_DONE {
            let cur = cmark_iter_get_node(iterator)
            
        }
         */
        
        // Render
        let html2 = cmark_render_html(doc, options, nil)
        defer {
            free(html2)
        }
        
        let html = String(cString: html2!)
        let css1 = getBundleContents(forResource: "markdown", ofType: "css") ?? ""
        let css2 = getBundleContents(forResource: "syntax", ofType: "css") ?? ""
            
        webView.loadHTMLString(
"""
<!doctype html>
<html>
<head>
<meta charset='utf-8'>
<meta name='viewport' content='width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=0'>
<title>.md</title>
<style type='text/css'>
\(css1)
\(css2)
</style>
</head>
<body class="markdown-body">
\(html)
</body>
</html>
""", baseURL: Bundle.main.resourceURL)
    }
    
    internal func getBundleContents(forResource: String, ofType: String) -> String?
    {
        if let p = Bundle.main.path(forResource: forResource, ofType: ofType), let data = FileManager.default.contents(atPath: p), let s = String(data: data, encoding: .utf8) {
            return s
        } else {
            return nil
        }
    }
    
    override func viewDidLoad() {
        let settings = Settings.shared
        self.tableExtension = settings.tableExtension
        self.autoLinkExtension = settings.autoLinkExtension
        self.tagFilterExtension = settings.tagFilterExtension
        self.taskListExtension = settings.taskListExtension
        self.strikethroughExtension = settings.strikethroughExtension
        self.mentionExtension = settings.mentionExtension
        self.checkboxExtension = settings.checkboxExtension
        self.syntaxHighlightExtension = settings.syntaxHighlightExtension
        self.emojiExtension = settings.emojiExtension
        self.inlineImageExtension = settings.inlineImageExtension
        
        if settings.syntaxBackgroundColorLight == "ignore" {
            highlightBackground.selectItem(at: 1)
        } else if settings.syntaxBackgroundColorLight == "" {
            highlightBackground.selectItem(at: 0)
        } else {
            if let c = NSColor(css: settings.syntaxBackgroundColorLight) {
                self.colorPicker.color = c
                highlightBackground.selectItem(at: 2)
            } else {
                highlightBackground.selectItem(at: 0)
            }
        }
        
        self.hardBreakOption = Settings.shared.hardBreakOption
        self.noSoftBreakOption = Settings.shared.noSoftBreakOption
        self.unsafeHTMLOption = Settings.shared.unsafeHTMLOption
        self.validateUTFOption = Settings.shared.validateUTFOption
        self.smartQuotesOption = Settings.shared.smartQuotesOption
        self.footnotesOption = Settings.shared.footnotesOption
        
        super.viewDidLoad()
        self.textView.isAutomaticQuoteSubstitutionEnabled = false // Settings this option on interfacebuilder is ignored.
        self.textView.isAutomaticTextReplacementEnabled = false
        self.textView.isAutomaticDashSubstitutionEnabled = false
        
        let type = UserDefaults.standard.string(forKey: "AppleInterfaceStyle") ?? "Light"
        
        self.styleSegementedControl.setSelected(true, forSegment: type != "Light" ? 1 : 0)
        self.webView.configuration.preferences.setValue(true, forKey: "developerExtrasEnabled")
        
        self.isDirty = false
        
        versionLabel.stringValue = "lib cmark-gfm version \(String(cString: cmark_version_string())) (\(cmark_version()))"
        
        let filename = "test1"
        let markdown_string = getBundleContents(forResource: filename, ofType: "md") ?? "*error*"
        
        self.textView.string = markdown_string
        
        let theme_name = "prova"
        let data: [String: String] = [
            "Comment":        "italic #F00",
            "CommentSpecial": "#888",
            "Keyword":        "#00f",
            "OperatorWord":   "#00f",
            "Name":           "#000",
            "LiteralNumber":  "#3af",
            "LiteralString":  "#5a2",
            "Error":          "#F00",
            "Background":     " bg:#ff0000",
        ];
        let j = try!JSONEncoder().encode(data)
        let s = String(data: j, encoding: .utf8)!.cString(using: .utf8)!
        
        importNewStyle(theme_name.cString(using: .utf8), s)
        
        if let s = getStyles() {
            let t = String(cString: s)
            s.deallocate()
            
            let themes: [String] = try! JSONDecoder().decode([String].self, from: t.data(using: .utf8)!)
            languageThemePopupButton.menu?.removeAllItems()
            for theme in themes {
                languageThemePopupButton.menu?.addItem(withTitle: theme, action: nil, keyEquivalent: "")
            }
        }
        self.doRefresh(self)
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
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
