//
//  Settings.swift
//  QLMarkdown
//
//  Created by Sbarex on 13/12/20.
//

import Foundation
import OSLog

import Yams
import SwiftSoup

enum CMARK_Error: Error {
    case parser_create
    case parser_parse
}

enum Appearance: Int {
    case undefined
    case light
    case dark
}

@objc enum GuessEngine: Int {
    case none
    case fast
    case accurate
}

extension NSNotification.Name {
    public static let QLMarkdownSettingsUpdated: NSNotification.Name = NSNotification.Name("org.sbarex.qlmarkdown-settings-changed")
}

class Settings {
    static let Domain: String = "org.sbarex.qlmarkdown"
    
    static let shared = Settings()
    static let factorySettings = Settings(noInitFromDefault: true)
    static var appBundleUrl: URL?
    
    @objc var autoLinkExtension: Bool = true
    @objc var checkboxExtension: Bool = false
    @objc var emojiExtension: Bool = true
    @objc var emojiImageOption: Bool = false
    @objc var headsExtension: Bool = true
    @objc var inlineImageExtension: Bool = true
    @objc var mentionExtension: Bool = false
    @objc var strikethroughExtension: Bool = true
    @objc var strikethroughDoubleTildeOption: Bool = false
    
    @objc var syntaxHighlightExtension: Bool = true
    @objc var syntaxThemeLight: String = ""
    @objc var syntaxBackgroundColorLight: String = ""
    @objc var syntaxThemeDark: String = ""
    @objc var syntaxBackgroundColorDark: String = ""
    @objc var syntaxWordWrapOption: Int = 0
    @objc var syntaxLineNumbersOption: Bool = false
    @objc var syntaxTabsOption: Int = 4
    @objc var syntaxFontFamily: String = ""
    @objc var syntaxFontSize: CGFloat = 10
    @objc var guessEngine: GuessEngine = .none
    
    @objc var tableExtension: Bool = true
    @objc var tagFilterExtension: Bool = true
    @objc var taskListExtension: Bool = true
    @objc var yamlExtension: Bool = true
    @objc var yamlExtensionAll: Bool = false
    
    @objc var footnotesOption: Bool = true
    @objc var hardBreakOption: Bool = false
    @objc var noSoftBreakOption: Bool = false
    @objc var unsafeHTMLOption: Bool = false
    @objc var smartQuotesOption: Bool = true
    @objc var validateUTFOption: Bool = false
    
    @objc var customCSS: URL?
    @objc var customCSSOverride: Bool = false
    @objc var openInlineLink: Bool = false
    
    @objc var renderAsCode: Bool = false
    
    /// Quick Look window width.
    var qlWindowWidth: Int? = nil
    /// Quick Look window height.
    var qlWindowHeight: Int? = nil
    /// Quick Look window size.
    var qlWindowSize: CGSize {
        if let w = qlWindowWidth, w > 0, let h = qlWindowHeight, h > 0 {
            return CGSize(width: w, height: h)
        } else {
            return .zero
        }
    }
    
    @objc var debug: Bool = false
    
    
    class var applicationSupportUrl: URL? {
        let sharedContainerURL: URL? = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: Domain)?.appendingPathComponent("Library/Application Support")
        return sharedContainerURL
        
        // return FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?.appendingPathComponent("QLMarkdown")
    }
    
    class var stylesFolder: URL? {
        return Settings.applicationSupportUrl?.appendingPathComponent("themes")
    }
    
    class var themesFolder: URL? {
        return Settings.applicationSupportUrl?.appendingPathComponent("syntax-highlight-color-schemes")
    }
    
    private init(noInitFromDefault: Bool = false) {
        if !noInitFromDefault {
            self.initFromDefaults()
        }
    }
    deinit {
        stopMonitorChange()
    }
    
    fileprivate var isMonitoring = false
    func startMonitorChange() {
        isMonitoring = true
        DistributedNotificationCenter.default().addObserver(self, selector: #selector(self.handleSettingsChanged(_:)), name: .QLMarkdownSettingsUpdated, object: nil)
    }
    
    func stopMonitorChange() {
        if isMonitoring {
            DistributedNotificationCenter.default().removeObserver(self)
        }
    }
    
    @objc func handleSettingsChanged(_ notification: NSNotification) {
        // print("settings changed")
        self.initFromDefaults()
    }
    
    func initFromDefaults() {
        // print("Shared preferences stored in \(Settings.applicationSupportUrl?.path ?? "??").")
        
        let defaults = UserDefaults.standard
        // let d = UserDefaults(suiteName: Settings.Domain)
        // Remember that macOS store the precerences inside a cache. If you manual edit the preferences file you need to reset this cache:
        // $ killall -u $USER cfprefsd
        let defaultsDomain = defaults.persistentDomain(forName: Settings.Domain) ?? [:]
        if let ext = defaultsDomain["table"] as? Bool {
            tableExtension = ext
        }
        if let ext = defaultsDomain["autolink"] as? Bool {
            autoLinkExtension = ext
        }
        if let ext = defaultsDomain["tagfilter"] as? Bool {
            tagFilterExtension = ext
        }
        if let ext = defaultsDomain["tasklist"] as? Bool {
            taskListExtension = ext
        }
        if let ext = defaultsDomain["rmd"] as? Bool {
            yamlExtension = ext
        }
        if let v = defaultsDomain["rmd_all"] as? Bool {
            yamlExtensionAll = v
        }
        
        if let ext = defaultsDomain["strikethrough"] as? Bool {
            strikethroughExtension = ext
        }
        if let ext = defaultsDomain["strikethrough_doubletilde"] as? Bool {
            strikethroughDoubleTildeOption = ext
        }
        
        if let ext = defaultsDomain["mention"] as? Bool {
            mentionExtension = ext
        }
        if let ext = defaultsDomain["checkbox"] as? Bool {
            checkboxExtension = ext
        }
        if let ext = defaultsDomain["heads"] as? Bool {
            headsExtension = ext
        }
        
        if let ext = defaultsDomain["syntax"] as? Bool {
            syntaxHighlightExtension = ext
        }
        if let theme = defaultsDomain["syntax_light_theme"] as? String {
            syntaxThemeLight = theme
        }
        if let color = defaultsDomain["syntax_light_background"] as? String {
            syntaxBackgroundColorLight = color
        }
        if let theme = defaultsDomain["syntax_dark_theme"] as? String {
            syntaxThemeDark = theme
        }
        if let color = defaultsDomain["syntax_dark_background"] as? String {
            syntaxBackgroundColorDark = color
        }
        if let characters = defaultsDomain["syntax_word_wrap"] as? Int {
            syntaxWordWrapOption = characters
        }
        if let state = defaultsDomain["syntax_line_numbers"] as? Bool {
            syntaxLineNumbersOption = state
        }
        if let n = defaultsDomain["syntax_tabs"] as? Int {
            syntaxTabsOption = n
        }
        if let font = defaultsDomain["syntax_font_name"] as? String {
            syntaxFontFamily = font
        }
        if let size = defaultsDomain["syntax_font_size"] as? CGFloat {
            syntaxFontSize = size
        }
        
        if let ext = defaultsDomain["emoji"] as? Bool {
            emojiExtension = ext
        }
        
        if let ext = defaultsDomain["inlineimage"] as? Bool {
            inlineImageExtension = ext
        }
        
        if let opt = defaultsDomain["emoji_image"] as? Bool {
            emojiImageOption = opt
        }
        
        if let opt = defaultsDomain["hardbreak"] as? Bool {
            hardBreakOption = opt
        }
        if let opt = defaultsDomain["nosoftbreak"] as? Bool {
            noSoftBreakOption = opt
        }
        if let opt = defaultsDomain["unsafeHTML"] as? Bool {
            unsafeHTMLOption = opt
        }
        if let opt = defaultsDomain["validateUTF"] as? Bool {
            validateUTFOption = opt
        }
        if let opt = defaultsDomain["smartquote"] as? Bool {
            smartQuotesOption = opt
        }
        if let opt = defaultsDomain["footnote"] as? Bool {
            footnotesOption = opt
        }
        
        if let opt = defaultsDomain["customCSS"] as? String, !opt.isEmpty {
            if !opt.hasPrefix("/"), let path = Settings.stylesFolder {
                customCSS = path.appendingPathComponent(opt)
            } else {
                customCSS = URL(fileURLWithPath: opt)
            }
        }
        if let opt = defaultsDomain["customCSS-override"] as? Bool {
            customCSSOverride = opt
        }
        
        if let opt = defaultsDomain["guess-engine"] as? Int, let guess = GuessEngine(rawValue: opt) {
            guessEngine = guess
        }
        
        if let opt = defaultsDomain["debug"] as? Bool {
            debug = opt
        }
        
        if let opt = defaultsDomain["inline-link"] as? Bool {
            openInlineLink = opt
        }
        if let opt = defaultsDomain["render-as-code"] as? Bool {
            renderAsCode = opt
        }
        if let opt = defaultsDomain["ql-window-width"] as? Int, opt > 0 {
            qlWindowWidth = opt
        } else {
            qlWindowWidth = nil
        }
        if let opt = defaultsDomain["ql-window-height"] as? Int, opt > 0 {
            qlWindowHeight = opt
        } else {
            qlWindowHeight = nil
        }
        
        sanitizeEmojiOption()
    }
    
    @discardableResult
    func resetToFactory() -> Bool {
        let userDefaults = UserDefaults()
        userDefaults.setPersistentDomain([:], forName: Settings.Domain)
        let r = userDefaults.synchronize()
        
        if r {
            let s = Settings()
            
            self.autoLinkExtension = s.autoLinkExtension
            self.checkboxExtension = s.checkboxExtension
            
            self.emojiExtension = s.emojiExtension
            self.emojiImageOption = s.emojiImageOption
            
            self.headsExtension = s.headsExtension
            self.inlineImageExtension = s.inlineImageExtension
            self.mentionExtension = s.mentionExtension
            
            self.strikethroughExtension = s.strikethroughExtension
            self.strikethroughDoubleTildeOption = s.strikethroughDoubleTildeOption
            
            self.syntaxHighlightExtension = s.syntaxHighlightExtension
            self.syntaxThemeLight = s.syntaxThemeLight
            self.syntaxBackgroundColorLight = s.syntaxBackgroundColorLight
            self.syntaxThemeDark = s.syntaxThemeDark
            self.syntaxBackgroundColorDark = s.syntaxBackgroundColorDark
            self.syntaxWordWrapOption = s.syntaxWordWrapOption
            self.syntaxLineNumbersOption = s.syntaxLineNumbersOption
            self.syntaxTabsOption = s.syntaxTabsOption
            self.syntaxFontFamily = s.syntaxFontFamily
            self.syntaxFontSize = s.syntaxFontSize
            self.guessEngine = s.guessEngine
            
            self.tableExtension = s.tableExtension
            self.tagFilterExtension = s.tagFilterExtension
            self.taskListExtension = s.taskListExtension
            self.yamlExtension = s.yamlExtension
            self.yamlExtensionAll = s.yamlExtensionAll
        
            self.footnotesOption = s.footnotesOption
            self.hardBreakOption = s.hardBreakOption
            self.noSoftBreakOption = s.noSoftBreakOption
            self.unsafeHTMLOption = s.unsafeHTMLOption
            self.smartQuotesOption = s.smartQuotesOption
            self.validateUTFOption = s.validateUTFOption
            
            self.customCSS = s.customCSS
            self.customCSSOverride = s.customCSSOverride
    
            self.openInlineLink = s.openInlineLink
    
            self.debug = s.debug
            
            self.renderAsCode = s.renderAsCode
            
            self.qlWindowWidth = s.qlWindowWidth
            self.qlWindowHeight = s.qlWindowHeight
            
            DistributedNotificationCenter.default().post(name: .QLMarkdownSettingsUpdated, object: nil)
        }
        return r
    }
    
    private func sanitizeEmojiOption() {
        if emojiExtension && emojiImageOption {
            unsafeHTMLOption = true
        }
    }
    
    func getCustomCSSCode() -> String? {
        guard let url = self.customCSS else {
            return nil
        }
        return try? String(contentsOf: url)
    }
    
    func render(file url: URL, forAppearance appearance: Appearance, baseDir: String?, log: OSLog? = nil) throws -> String {
        guard let data = FileManager.default.contents(atPath: url.path), let markdown_string = String(data: data, encoding: .utf8) else {
            return ""
        }
        
        return try self.render(text: markdown_string, filename: url.lastPathComponent, forAppearance: appearance, baseDir: baseDir ?? url.deletingLastPathComponent().path, log: log)
    }
    
    /// Get the Bundle with the resources.
    /// For the host app return the main Bundle. For the appex return the bundle of the hosting app.
    func getResourceBundle() -> Bundle {
        if let url = Settings.appBundleUrl, let appBundle = Bundle(url: url) {
            return appBundle
        } else if Bundle.main.bundlePath.hasSuffix(".appex") {
            // this is an app extension
            let url = Bundle.main.bundleURL.deletingLastPathComponent().deletingLastPathComponent()

            if let appBundle = Bundle(url: url) {
                return appBundle
            }
        }
        return Bundle.main
    }
    
    /// Get the path of folder with `highlight` support files.
    func getHighlightSupportPath() -> String? {
        let path = getResourceBundle().url(forResource: "highlight", withExtension: "")?.path
        return path
    }
    
    internal func parseYaml(node: Yams.Node) throws -> Any {
        switch node {
        case .scalar(let scalar):
            return scalar.string
        case .mapping(let mapping):
            var r: [(key: AnyHashable, value: Any)] = []
            for n in mapping {
                guard let k = try parseYaml(node: n.key) as? AnyHashable else {
                    continue
                }
                let v = try parseYaml(node: n.value)
                r.append((key: k, value: v))
            }
            return r
        case .sequence(let sequence):
            var r: [Any] = []
            for n in sequence {
                r.append(try parseYaml(node: n))
            }
            return r
        }
    }
    
    internal func renderYaml(_ yaml: [(key: AnyHashable, value: Any)]) -> String {
        guard yaml.count > 0 else {
            return ""
        }
        
        var s = "<table>"
        for element in yaml {
            let key: String = "<strong>\(element.key)</strong>"
            /*
            do {
                key = try self.render(text: "**\(element.key)**", filename: "", forAppearance: .light, baseDir: "")
            } catch {
                key = "<strong>\(element.key)</strong>"
            }*/
            s += "<tr><td align='right'>\(key)</td><td>"
            if let t = element.value as? [(key: AnyHashable, value: Any)] {
                s += renderYaml(t)
            } else if let t = element.value as? [Any] {
                s += "<ul>\n" + t.map({ v in
                    let s: String = "\(v)"
                    /*
                    if let t = v as? String {
                        do {
                            s = try self.render(text: t, filename: "", forAppearance: .light, baseDir: "")
                        } catch {
                            s = t
                        }
                    } else {
                        s = "\(v)"
                    }*/
                    return "<li>\(s)</li>"
                }).joined(separator: "\n")
            } else if let t = element.value as? String {
                s += t
                /*
                do {
                    s += try self.render(text: t, filename: "", forAppearance: .light, baseDir: "")
                } catch {
                    s += t.replacingOccurrences(of: "|", with: #"\|"#)
                }
                */
            } else {
                s += "\(element.value)"
            }
            s += "</td></tr>\n"
        }
        s += "</table>"
        return s
    }
    
    internal func renderYamlHeader(_ text: String, isHTML: inout Bool) -> String {
        if self.tableExtension {
            do {
                if let node = try Yams.compose(yaml: text), let yaml = try self.parseYaml(node: node) as? [(key: AnyHashable, value: Any)] {
                    isHTML = true
                    return renderYaml(yaml)
                }
            } catch {
                // print(error)
            }
        }
        // Embed the header inside a yaml block.
        isHTML = false
        return "```yaml\n"+text+"```\n"
    }
    
    func renderCode(text: String, forAppearance appearance: Appearance, baseDir: String, log: OSLog? = nil) -> String? {
        
        if let path = getHighlightSupportPath() {
            cmark_syntax_highlight_init("\(path)/".cString(using: .utf8))
        } else {
            if let l = log {
                os_log("Unable to found the `highlight` support dir!", log: l, type: .error)
            }
        }
        
        let theme: String
        switch appearance {
        case .light:
            theme = self.syntaxThemeLight.isEmpty ? "acid" : self.syntaxThemeLight
        case .dark:
            theme = self.syntaxThemeDark.isEmpty ? "zenburn" : self.syntaxThemeDark
        case .undefined:
            let mode = UserDefaults.standard.string(forKey: "AppleInterfaceStyle") ?? "Light"
            if mode == "Light" {
                theme = self.syntaxThemeLight.isEmpty ? "acid" : self.syntaxThemeLight
            } else {
                theme = self.syntaxThemeDark.isEmpty ? "zenburn" : self.syntaxThemeDark
            }
        }
        
        // Initialize a new generator and clear previous settings.
        highlight_init_generator()
        
        highlight_set_print_line_numbers(self.syntaxLineNumbersOption ? 1 : 0)
        highlight_set_formatting_mode(Int32(self.syntaxWordWrapOption), Int32(self.syntaxTabsOption))
        
        if !self.syntaxFontFamily.isEmpty {
            highlight_set_current_font(self.syntaxFontFamily, self.syntaxFontSize > 0 ? String(format: "%.02f", self.syntaxFontSize) : "1rem") // 1rem is rendered as 1rempt, so it is ignored.
        } else {
            highlight_set_current_font("ui-monospace, -apple-system, BlinkMacSystemFont, sans-serif", "10");
        }
        
        if let s = colorizeCode(text, "md", theme, true, self.syntaxLineNumbersOption) {
            defer {
                s.deallocate()
            }
            let code = String(cString: s)
            return code
        } else {
            return nil
        }
    }
    
    func render(text: String, filename: String, forAppearance appearance: Appearance, baseDir: String, log: OSLog? = nil) throws -> String {
        
        if self.renderAsCode, let code = self.renderCode(text: text, forAppearance: appearance, baseDir: baseDir, log: log) {
            return code
        }
        
        cmark_gfm_core_extensions_ensure_registered()
        
        var options = CMARK_OPT_DEFAULT
        if self.unsafeHTMLOption {
            options |= CMARK_OPT_UNSAFE
        }
        
        if self.hardBreakOption {
            options |= CMARK_OPT_HARDBREAKS
        }
        if self.noSoftBreakOption {
            options |= CMARK_OPT_NOBREAKS
        }
        if self.validateUTFOption {
            options |= CMARK_OPT_VALIDATE_UTF8
        }
        if self.smartQuotesOption {
            options |= CMARK_OPT_SMART
        }
        if self.footnotesOption {
            options |= CMARK_OPT_FOOTNOTES
        }
        
        if self.strikethroughExtension && self.strikethroughDoubleTildeOption {
            options |= CMARK_OPT_STRIKETHROUGH_DOUBLE_TILDE
        }
        
        if let l = log {
            os_log(
                "cmark_gfm options: %{public}d.",
                log: l,
                type: .debug,
                options
            )
        }
        
        guard let parser = cmark_parser_new(options) else {
            if let l = log {
                os_log(
                    "Unable to create new cmark_parser!",
                    log: l,
                    type: .error,
                    options
                )
            }
            throw CMARK_Error.parser_create
        }
        defer {
            cmark_parser_free(parser)
        }
        
        /*
        var extensions: UnsafeMutablePointer<cmark_llist>? = nil
        defer {
            cmark_llist_free(cmark_get_default_mem_allocator(), extensions)
        }
        */
        
        if self.tableExtension, let ext = cmark_find_syntax_extension("table") {
            cmark_parser_attach_syntax_extension(parser, ext)
            if let l = log {
                os_log(
                    "Enabled markdown `table` extension.",
                    log: l,
                    type: .debug
                )
            }
            // extensions = cmark_llist_append(cmark_get_default_mem_allocator(), nil, &ext)
        }
        
        if self.autoLinkExtension, let ext = cmark_find_syntax_extension("autolink") {
            cmark_parser_attach_syntax_extension(parser, ext)
            if let l = log {
                os_log(
                    "Enabled markdown `autolink` extension.",
                    log: l,
                    type: .debug
                )
            }
        }
        
        if self.tagFilterExtension, let ext = cmark_find_syntax_extension("tagfilter") {
            cmark_parser_attach_syntax_extension(parser, ext)
            if let l = log {
                os_log(
                    "Enabled markdown `tagfilter` extension.",
                    log: l,
                    type: .debug
                )
            }
        }
        
        if self.taskListExtension, let ext = cmark_find_syntax_extension("tasklist") {
            cmark_parser_attach_syntax_extension(parser, ext)
            if let l = log {
                os_log(
                    "Enabled markdown `tasklist` extension.",
                    log: l,
                    type: .debug
                )
            }
        }
        
        var md_text = text
        
        var header = ""
        
        if self.yamlExtension && (self.yamlExtensionAll || filename.lowercased().hasSuffix("rmd")) && md_text.hasPrefix("---") {
            /*
             (?s): Turn on "dot matches newline" for the remainder of the regular expression. For “single line mode” makes the dot match all characters, including line breaks.
             (?<=---\n): Positive lookbehind. Matches at a position if the pattern inside the lookbehind can be matched ending at that position. Find expression .* where expression `---\n` precedes.
             (?>\n(?:---|\.\.\.):
             (?:---|\.\.\.): not capturing group
             */
            let pattern = "(?s)((?<=---\n).*?(?>\n(?:---|\\.\\.\\.)\n))"
            if let range = md_text.range(of: pattern, options: .regularExpression) {
                let yaml = String(md_text[range.lowerBound ..< md_text.index(range.upperBound, offsetBy: -4)])
                var isHTML = false
                header = self.renderYamlHeader(yaml, isHTML: &isHTML)
                if isHTML {
                    md_text = String(md_text[range.upperBound ..< md_text.endIndex])
                } else {
                    md_text = header + md_text[range.upperBound ..< md_text.endIndex]
                    header = ""
                }
            }
        }
        
        if self.strikethroughExtension, let ext = cmark_find_syntax_extension("strikethrough") {
            cmark_parser_attach_syntax_extension(parser, ext)
            if let l = log {
                os_log(
                    "Enabled markdown `strikethrough` extension.",
                    log: l,
                    type: .debug
                )
            }
        }
        
        if self.mentionExtension, let ext = cmark_find_syntax_extension("mention") {
            cmark_parser_attach_syntax_extension(parser, ext)
            if let l = log {
                os_log(
                    "Enabled markdown `mention` extension.",
                    log: l,
                    type: .debug
                )
            }
        }
        
        if self.headsExtension, let ext = cmark_find_syntax_extension("heads") {
            cmark_parser_attach_syntax_extension(parser, ext)
            if let l = log {
                os_log(
                    "Enabled markdown `heads` extension.",
                    log: l,
                    type: .debug
                )
            }
        }
        
        if self.inlineImageExtension, let ext = cmark_find_syntax_extension("inlineimage") {
            cmark_parser_attach_syntax_extension(parser, ext)
            cmark_syntax_extension_inlineimage_set_wd(ext, baseDir.cString(using: .utf8))
            cmark_syntax_extension_inlineimage_set_mime_callback(ext, { (path, context) in
                let magic_file = Settings.shared.getResourceBundle().path(forResource: "magic", ofType: "mgc")?.cString(using: .utf8)
                let r = magic_get_mime_by_file(path, magic_file)
                return r
            }, nil)
            
            if let l = log {
                os_log(
                    "Enabled markdown `local inline image` extension with working path set to `%{public}s.",
                    log: l,
                    type: .debug,
                    baseDir
                )
            }
            
            if self.unsafeHTMLOption {
                cmark_syntax_extension_inlineimage_set_unsafe_html_processor_callback(ext, { (ext, fragment, workingDir, context, code) in
                    guard let fragment = fragment else {
                        return
                    }
                    
                    let baseDir: URL
                    if let s = workingDir {
                        let b = String(cString: s)
                        baseDir = URL(fileURLWithPath: b)
                    } else {
                        baseDir = URL(fileURLWithPath: "")
                    }
                    let html = String(cString: fragment)
                    var changed = false
                    do {
                        let doc = try SwiftSoup.parseBodyFragment(html, baseDir.path)
                        for img in try doc.select("img") {
                            let src = try img.attr("src")
                            
                            guard !src.isEmpty, !src.hasPrefix("http"), !src.hasPrefix("HTTP") else {
                                // Do not handle external image.
                                continue
                            }
                            guard !src.hasPrefix("data:") else {
                                // Do not reprocess data: image.
                                continue
                            }
                            
                            let file = baseDir.appendingPathComponent(src).path
                            guard FileManager.default.fileExists(atPath: file) else {
                                continue // File not found.
                            }
                            guard let data = get_base64_image(
                                file.cString(using: .utf8),
                                { (path: UnsafePointer<Int8>?, context: UnsafeMutableRawPointer?) -> UnsafeMutablePointer<Int8>? in
                                    let magic_file = Settings.shared.getResourceBundle().path(forResource: "magic", ofType: "mgc")?.cString(using: .utf8)
                                    
                                    let r = magic_get_mime_by_file(path, magic_file)
                                    return r
                                },
                                nil
                            ) else {
                                continue
                            }
                            defer {
                                data.deallocate()
                            }
                            let img_data = String(cString: data)
                            try img.attr("src", img_data)
                            changed = true
                        }
                        if changed, let html = try doc.body()?.html(), let s = strdup(html) {
                            code?.pointee = UnsafePointer(s)
                        }
                    } catch Exception.Error(_, let message) {
                        print("Error processing html: \(message)")
                    } catch {
                        print("Error parsing html: \(error.localizedDescription)")
                    }
                }, nil)
            }
        }
        
        if self.emojiExtension, let ext = cmark_find_syntax_extension("emoji") {
            cmark_syntax_extension_emoji_set_use_characters(ext, !self.emojiImageOption)
            cmark_parser_attach_syntax_extension(parser, ext)
            if let l = log {
                os_log(
                    "Enabled markdown `emoji` extension using %{public}%s.",
                    log: l,
                    type: .debug,
                    self.emojiImageOption ? "images" : "glyphs"
                )
            }
        }
        
        if self.syntaxHighlightExtension, let ext = cmark_find_syntax_extension("syntaxhighlight") {
            // TODO: set a property
            
            if let path = getHighlightSupportPath() {
                cmark_syntax_highlight_init("\(path)/".cString(using: .utf8))
            } else {
                if let l = log {
                    os_log("Unable to found the `highlight` support dir!", log: l, type: .error)
                }
            }
            
            let theme: String
            let background: String
            switch appearance {
            case .light:
                theme = self.syntaxThemeLight
                background = self.syntaxBackgroundColorLight
            case .dark:
                theme = self.syntaxThemeDark
                background = self.syntaxBackgroundColorDark
            case .undefined:
                let mode = UserDefaults.standard.string(forKey: "AppleInterfaceStyle") ?? "Light"
                if mode == "Light" {
                    theme = self.syntaxThemeLight
                    background = self.syntaxBackgroundColorLight
                } else {
                    theme = self.syntaxThemeDark
                    background = self.syntaxBackgroundColorDark
                }
            }
            
            cmark_syntax_extension_highlight_set_theme_name(ext, theme)
            cmark_syntax_extension_highlight_set_background_color(ext, background.isEmpty ? nil : background)
            cmark_syntax_extension_highlight_set_line_number(ext, self.syntaxLineNumbersOption ? 1 : 0)
            cmark_syntax_extension_highlight_set_tab_spaces(ext, Int32(self.syntaxTabsOption))
            cmark_syntax_extension_highlight_set_wrap_limit(ext, Int32(self.syntaxWordWrapOption))
            cmark_syntax_extension_highlight_set_guess_language(ext, guess_type(UInt32(self.guessEngine.rawValue)))
            if self.guessEngine == .fast, let f = getResourceBundle().path(forResource: "magic", ofType: "mgc") {
                cmark_syntax_extension_highlight_set_magic_file(ext, f)
            }
            
            if !self.syntaxFontFamily.isEmpty {
                cmark_syntax_extension_highlight_set_font_family(ext, self.syntaxFontFamily, Float(self.syntaxFontSize))
            } else {
                // cmark_syntax_extension_highlight_set_font_family(ext, "-apple-system, BlinkMacSystemFont, sans-serif", 0.0)
                // Pass a fake value, so will be used the font defined inside the main css file.
                cmark_syntax_extension_highlight_set_font_family(ext, "-", 0.0)
            }
            
            cmark_parser_attach_syntax_extension(parser, ext)
            
            if let l = log {
                os_log(
                    "Enabled markdown `syntax highlight` extension.\n Theme: %{public}s, background color: %{public}s",
                    log: l,
                    type: .debug,
                    theme, background
                )
            }
        }
        
        cmark_parser_feed(parser, md_text, strlen(md_text))
        guard let doc = cmark_parser_finish(parser) else {
            throw CMARK_Error.parser_parse
        }
        defer {
            cmark_node_free(doc)
        }
        
        let html_debug = self.renderDebugInfo(forAppearance: appearance, baseDir: baseDir)
        // Render
        if let html2 = cmark_render_html(doc, options, cmark_parser_get_syntax_extensions(parser)) {
            defer {
                free(html2)
            }
            
            return html_debug + header + String(cString: html2)
        } else {
            return html_debug + "<p>RENDER FAILED!</p>"
        }
    }
    
    internal func renderDebugInfo(forAppearance appearance: Appearance, baseDir: String) -> String
    {
        guard debug else {
            return ""
        }
        var html_debug = ""
        html_debug += """
<style type="text/css">
table.debug td {
    vertical-align: top;
    font-size: .8rem;
}
</style>
"""
        html_debug += "<table class='debug'>\n<caption>Debug info</caption>"
        var html_options = ""
        if self.unsafeHTMLOption || (self.emojiExtension && self.emojiImageOption) {
            html_options += "CMARK_OPT_UNSAFE "
        }
        
        if self.hardBreakOption {
            html_options += "CMARK_OPT_HARDBREAKS "
        }
        if self.noSoftBreakOption {
            html_options += "CMARK_OPT_NOBREAKS "
        }
        if self.validateUTFOption {
            html_options += "CMARK_OPT_VALIDATE_UTF8 "
        }
        if self.smartQuotesOption {
            html_options += "CMARK_OPT_SMART "
        }
        if self.footnotesOption {
            html_options += "CMARK_OPT_FOOTNOTES "
        }
        
        if self.strikethroughExtension && self.strikethroughDoubleTildeOption {
            html_options += "CMARK_OPT_STRIKETHROUGH_DOUBLE_TILDE "
        }

        html_debug += "<tr><td>options</td><td>\(html_options)</td></tr>\n"
        
        html_debug += "<tr><td>table extension</td><td>"
        if self.tableExtension {
            html_debug += "on " + (cmark_find_syntax_extension("table") == nil ? " (NOT AVAILABLE" : "")
        } else {
            html_debug += "off"
        }
        html_debug += "</td></tr>\n"

        html_debug += "<tr><td>autolink extension</td><td>"
        if self.autoLinkExtension {
            html_debug += "on " + (cmark_find_syntax_extension("autolink") == nil ? " (NOT AVAILABLE" : "")
        } else {
            html_debug += "off"
        }
        html_debug += "</td></tr>\n"
        
        html_debug += "<tr><td>tagfilter extension</td><td>"
        if self.tagFilterExtension {
            html_debug += "on " + (cmark_find_syntax_extension("tagfilter") == nil ? " (NOT AVAILABLE" : "")
        } else {
            html_debug += "off"
        }
        html_debug += "</td></tr>\n"

        html_debug += "<tr><td>tasklist extension</td><td>"
        if self.taskListExtension {
            html_debug += "on " + (cmark_find_syntax_extension("tasklist") == nil ? " (NOT AVAILABLE" : "")
        } else {
            html_debug += "off"
        }
        html_debug += "</td></tr>\n"
        
        html_debug += "<tr><td>YAML extension</td><td>"
        if self.yamlExtension {
            html_debug += "on "+(self.yamlExtensionAll ? "for all files" : "for .rmd files")
        } else {
            html_debug += "off"
        }
        html_debug += "</td></tr>\n"
        
        html_debug += "<tr><td>strikethrough extension</td><td>"
        if self.strikethroughExtension {
            html_debug += "on " + (cmark_find_syntax_extension("strikethrough") == nil ? " (NOT AVAILABLE" : "")
        } else {
            html_debug += "off"
        }
        html_debug += "</td></tr>\n"
        
        html_debug += "<tr><td>mention extension</td><td>"
        if self.mentionExtension {
            html_debug += "on " + (cmark_find_syntax_extension("mention") == nil ? " (NOT AVAILABLE" : "")
        } else {
            html_debug += "off"
        }
        html_debug += "</td></tr>\n"
        
        html_debug += "<tr><td>inlineimage extension</td><td>"
        if self.inlineImageExtension {
            html_debug += "on" + (cmark_find_syntax_extension("inlineimage") == nil ? " (NOT AVAILABLE" : "")
            html_debug += "<br />basedir: \(baseDir)"
        } else {
            html_debug += "off"
        }
        html_debug += "</td></tr>\n"
        
        html_debug += "<tr><td>heads extension</td><td>" + (self.headsExtension ?  "on" : "off") + "</td></tr>\n"
        
        html_debug += "<tr><td>emoji extension</td><td>"
        if self.emojiExtension {
            html_debug += "on" + (cmark_find_syntax_extension("emoji") == nil ? " (NOT AVAILABLE" : "")
            html_debug += " / \(self.emojiImageOption ? "using images" : "using emoji")"
        } else {
            html_debug += "off"
        }
        html_debug += "</td></tr>\n"
        
        html_debug += "<tr><td>syntax highlighting</td><td>"
        if self.syntaxHighlightExtension {
            html_debug += "on " + (cmark_find_syntax_extension("syntaxhighlight") == nil ? " (NOT AVAILABLE" : "")
            
            var theme: String
            var background: String
            
            switch appearance {
            case .light:
                theme = self.syntaxThemeLight
                background = self.syntaxBackgroundColorLight
            case .dark:
                theme = self.syntaxThemeDark
                background = self.syntaxBackgroundColorDark
            case .undefined:
                let mode = UserDefaults.standard.string(forKey: "AppleInterfaceStyle") ?? "Light"
                if mode == "Light" {
                    theme = self.syntaxThemeLight
                    background = self.syntaxBackgroundColorLight
                } else {
                    theme = self.syntaxThemeDark
                    background = self.syntaxBackgroundColorDark
                }
            }
            
            if theme.isEmpty {
                theme = "Inherit from document style"
                background = "Inherit from document style"
            } else {
                if background.isEmpty {
                    background = "use theme settings"
                } else if background == "ignore" {
                    background = "use markdown settings"
                }
            }
            
            html_debug += "<table>\n"
            html_debug += "<tr><td>datadir</td><td>\(getHighlightSupportPath() ?? "missing")</td></tr>\n"
            html_debug += "<tr><td>theme</td><td>\(theme)</td></tr>\n"
            html_debug += "<tr><td>background</td><td>\(background)</td></tr>\n"
            html_debug += "<tr><td>line numbers</td><td>\(self.syntaxLineNumbersOption ? "on" : "off")</td></tr>\n"
            html_debug += "<tr><td>spaces for a tab</td><td>\(self.syntaxTabsOption)</td></tr>\n"
            html_debug += "<tr><td>wrap</td><td> \(self.syntaxWordWrapOption > 0 ? "after \(self.syntaxWordWrapOption) characters" : "disabled")</td></tr>\n"
            html_debug += "<tr><td>spaces for a tab</td><td>\(self.syntaxTabsOption)</td></tr>\n"
            html_debug += "<tr><td>guess language</td><td>"
            switch self.guessEngine {
            case .none:
                html_debug += "off"
            case .fast:
                html_debug += "fast<br />"
                html_debug += "magic db: \(getResourceBundle().path(forResource: "magic", ofType: "mgc") ?? "missing")"
            case .accurate:
                html_debug += "accurate"
            }
            html_debug += "</td></tr>\n"
            html_debug += "<tr><td>font family</td><td>\(self.syntaxFontFamily.isEmpty ? "not set" : self.syntaxFontFamily)</td></tr>\n"
            html_debug += "<tr><td>font size</td><td>\(self.syntaxFontSize > 0 ? "\(self.syntaxFontSize)" : "not set")</td></tr>\n"
            html_debug += "</table>\n"
        } else {
            html_debug += "off"
        }
        html_debug += "</td></tr>\n"
        
        html_debug += "<tr><td>link</td><td>" + (self.openInlineLink ? "open inline" : "open in standard browser") + "</td></tr>\n"
        
        html_debug += "</table>\n"
        
        return html_debug
    }
    
    func getBundleContents(forResource: String, ofType: String) -> String?
    {
        if let p = getResourceBundle().path(forResource: forResource, ofType: ofType), let data = FileManager.default.contents(atPath: p), let s = String(data: data, encoding: .utf8) {
            return s
        } else {
            return nil
        }
    }
    
    func getCompleteHTML(title: String, body: String, header: String = "", footer: String = "", basedir: URL, forAppearance appearance: Appearance) -> String {
        
        let css_doc: String
        let css_doc_extended: String
        
        let formatCSS = { (code: String?) -> String in
            guard let css = code, !css.isEmpty else {
                return ""
            }
            return "<style type='text/css'>\(css)\n</style>\n"
        }
        
        if !self.renderAsCode {
            if let css = self.getCustomCSSCode() {
                css_doc_extended = formatCSS(css)
                if !self.customCSSOverride {
                    css_doc = formatCSS(getBundleContents(forResource: "default", ofType: "css"))
                } else {
                    css_doc = ""
                }
            } else {
                css_doc_extended = ""
                css_doc = formatCSS(getBundleContents(forResource: "default", ofType: "css"))
            }
            // css_doc = "<style type=\"text/css\">\n\(css_doc)\n</style>\n"
        } else {
            css_doc_extended = ""
            css_doc = ""
        }
            
        var css_highlight: String = ""
        if self.renderAsCode {
            let theme: String
            var background: String = ""
            switch appearance {
            case .light:
                theme = self.syntaxThemeLight.isEmpty ? "acid" : self.syntaxThemeLight
            case .dark:
                theme = self.syntaxThemeDark.isEmpty ? "zenburn" : self.syntaxThemeDark
            case .undefined:
                let mode = UserDefaults.standard.string(forKey: "AppleInterfaceStyle") ?? "Light"
                if mode == "Light" {
                    theme = self.syntaxThemeLight.isEmpty ? "acid" : self.syntaxThemeLight
                } else {
                    theme = self.syntaxThemeDark.isEmpty ? "zenburn" : self.syntaxThemeDark
                }
            }
            var release: ReleaseTheme?
            var exit_code: Int32 = 0
            let t = highlight_get_theme2(theme, &exit_code, &release)
            defer {
                release?(t)
            }
            if exit_code == EXIT_SUCCESS, let s = t?.pointee.canvas.pointee.color {
                background = String(cString: s)
            }
            exit_code = 0
            let p = highlight_format_style2(&exit_code, background)
            defer {
                p?.deallocate()
            }
            if exit_code == EXIT_SUCCESS, let p = p {
                css_highlight = String(cString: p) + "\npre.hl { white-space: pre; }\n"
            }
        } else if self.syntaxHighlightExtension, let ext = cmark_find_syntax_extension("syntaxhighlight"), cmark_syntax_extension_highlight_get_rendered_count(ext) > 0 {
            let theme = String(cString: cmark_syntax_extension_highlight_get_theme_name(ext))
            if !theme.isEmpty, let p = cmark_syntax_extension_get_style(ext) {
                // Embed the theme style.
                css_highlight = String(cString: p)
                p.deallocate()
            }
        }
        if !css_highlight.isEmpty {
            let font = self.syntaxFontFamily
            if font != "" {
                let code = """
:root {
--code-font: "\(font)", ui-monospace, -apple-system, Menlo, monospace;
}
"""
                css_highlight += code
            }
            css_highlight = formatCSS(css_highlight)
        }
        
        let style = css_doc + css_highlight + css_doc_extended
        let wrapper_open = self.renderAsCode ? "<pre class='hl'>" : "<article class='markdown-body'>"
        let wrapper_close = self.renderAsCode ? "</pre>" : "</article>"
        let body_style = self.renderAsCode ? " class='hl'" : ""
        let html =
"""
<!doctype html>
<html>
<head>
<meta charset='utf-8'>
<meta name='viewport' content='width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=0'>
<title>\(title)</title>
\(style)
\(header)
</head>
<body\(body_style)>
\(wrapper_open)
\(body)
\(wrapper_close)
\(footer)
</body>
</html>
"""
        return html
    }
}
