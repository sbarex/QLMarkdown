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
    case none = 0
    case simple
    case accurate
}

@objc enum BackgroundColor: Int {
    case fromMarkdown = 0
    case fromScheme = 1
    case custom = 2
}

extension NSNotification.Name {
    public static let QLMarkdownSettingsUpdated: NSNotification.Name = NSNotification.Name("org.sbarex.qlmarkdown-settings-changed")
}

class Settings: Codable {
    enum CodingKeys: String, CodingKey {
        case autoLinkExtension
        case checkboxExtension
        case emojiExtension
        case emojiImageOption
        case headsExtension
        case inlineImageExtension
        case mentionExtension
        case strikethroughExtension
        case strikethroughDoubleTildeOption
        
        case mathExtension
        
        case syntaxHighlightExtension
        case syntaxCustomThemes
        case syntaxThemeLight
        case syntaxThemeDark
        case syntaxBackgroundColor
        case syntaxBackgroundColorLight
        case syntaxBackgroundColorDark
        case syntaxWordWrapOption
        case syntaxLineNumbersOption
        case syntaxTabsOption
        case syntaxFontFamily
        case syntaxFontSize
        case guessEngine
        
        case tableExtension
        case tagFilterExtension
        case taskListExtension
        case yamlExtension
        case yamlExtensionAll
        
        case footnotesOption
        case hardBreakOption
        case noSoftBreakOption
        case unsafeHTMLOption
        case smartQuotesOption
        case validateUTFOption
        
        case customCSS
        case customCSSOverride
        case openInlineLink
        
        case renderAsCode
        
        case useLegacyPreview
        
        case qlWindowWidth
        case qlWindowHeight
        
        case debug
    }

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
    
    @objc var mathExtension: Bool = true
    
    @objc var syntaxHighlightExtension: Bool = true
    @objc var syntaxCustomThemes: Bool = false
    @objc var syntaxThemeLight: String = ""
    @objc var syntaxThemeDark: String = ""
    @objc var syntaxBackgroundColor: BackgroundColor = .fromMarkdown 
    @objc var syntaxBackgroundColorLight: String = ""
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
    
    var useLegacyPreview: Bool = false
    
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
    
    lazy fileprivate (set) var resourceBundle: Bundle = {
        return getResourceBundle()
    }()
    
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
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.autoLinkExtension = try container.decode(Bool.self, forKey:.autoLinkExtension)
        self.checkboxExtension = try container.decode(Bool.self, forKey:.checkboxExtension)
        self.emojiExtension = try container.decode(Bool.self, forKey:.emojiExtension)
        self.emojiImageOption = try container.decode(Bool.self, forKey:.emojiImageOption)
        self.headsExtension = try container.decode(Bool.self, forKey:.headsExtension)
        self.inlineImageExtension = try container.decode(Bool.self, forKey:.inlineImageExtension)
        self.mentionExtension = try container.decode(Bool.self, forKey:.mentionExtension)
        self.strikethroughExtension = try container.decode(Bool.self, forKey:.strikethroughExtension)
        self.strikethroughDoubleTildeOption = try container.decode(Bool.self, forKey:.strikethroughDoubleTildeOption)
    
        self.mathExtension = try container.decode(Bool.self, forKey: .mathExtension)
        
        self.syntaxHighlightExtension = try container.decode(Bool.self, forKey: .syntaxHighlightExtension)
        self.syntaxCustomThemes = try container.decode(Bool.self, forKey: .syntaxCustomThemes)
        self.syntaxThemeLight = try container.decode(String.self, forKey: .syntaxThemeLight)
        self.syntaxThemeDark = try container.decode(String.self, forKey: .syntaxThemeDark)
        self.syntaxBackgroundColor = BackgroundColor(rawValue: try container.decode(Int.self, forKey: .syntaxBackgroundColor)) ?? .fromMarkdown
        self.syntaxBackgroundColorLight = try container.decode(String.self, forKey: .syntaxBackgroundColorLight)
        self.syntaxBackgroundColorDark = try container.decode(String.self, forKey: .syntaxBackgroundColorDark)
        self.syntaxWordWrapOption = try container.decode(Int.self, forKey: .syntaxWordWrapOption)
        self.syntaxLineNumbersOption = try container.decode(Bool.self, forKey: .syntaxLineNumbersOption)
        self.syntaxTabsOption = try container.decode(Int.self, forKey: .syntaxTabsOption)
        self.syntaxFontFamily = try container.decode(String.self, forKey: .syntaxFontFamily)
        self.syntaxFontSize = try container.decode(CGFloat.self, forKey: .syntaxFontSize)
        self.guessEngine = GuessEngine(rawValue: try container.decode(Int.self, forKey: .guessEngine)) ?? .none
    
        self.tableExtension = try container.decode(Bool.self, forKey: .tableExtension)
        self.tagFilterExtension = try container.decode(Bool.self, forKey: .tagFilterExtension)
        self.taskListExtension = try container.decode(Bool.self, forKey: .taskListExtension)
        self.yamlExtension = try container.decode(Bool.self, forKey: .yamlExtension)
        self.yamlExtensionAll = try container.decode(Bool.self, forKey: .yamlExtensionAll)
    
        self.footnotesOption = try container.decode(Bool.self, forKey: .footnotesOption)
        self.hardBreakOption = try container.decode(Bool.self, forKey: .hardBreakOption)
        self.noSoftBreakOption = try container.decode(Bool.self, forKey: .noSoftBreakOption)
        self.unsafeHTMLOption = try container.decode(Bool.self, forKey: .unsafeHTMLOption)
        self.smartQuotesOption = try container.decode(Bool.self, forKey: .smartQuotesOption)
        self.validateUTFOption = try container.decode(Bool.self, forKey: .validateUTFOption)
    
        self.customCSS = try container.decode(URL?.self, forKey: .customCSS)
        self.customCSSOverride = try container.decode(Bool.self, forKey: .customCSSOverride)
        self.openInlineLink = try container.decode(Bool.self, forKey: .openInlineLink)
    
        self.renderAsCode = try container.decode(Bool.self, forKey: .renderAsCode)
    
        self.useLegacyPreview = try container.decode(Bool.self, forKey: .useLegacyPreview)
    
        self.qlWindowWidth = try container.decode(Int?.self, forKey: .qlWindowWidth)
        self.qlWindowHeight = try container.decode(Int?.self, forKey: .qlWindowHeight)
    
        self.debug = try container.decode(Bool.self, forKey: .debug)
    }
    
    init(defaults defaultsDomain: [String: Any]) {
        self.update(from: defaultsDomain)
    }

    deinit {
        stopMonitorChange()
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.autoLinkExtension, forKey: .autoLinkExtension)
        try container.encode(self.checkboxExtension, forKey: .checkboxExtension)
        try container.encode(self.emojiExtension, forKey: .emojiExtension)
        try container.encode(self.emojiImageOption, forKey: .emojiImageOption)
        try container.encode(self.headsExtension, forKey: .headsExtension)
        try container.encode(self.inlineImageExtension, forKey: .inlineImageExtension)
        try container.encode(self.mentionExtension, forKey: .mentionExtension)
        try container.encode(self.strikethroughExtension, forKey: .strikethroughExtension)
        try container.encode(self.strikethroughDoubleTildeOption, forKey: .strikethroughDoubleTildeOption)
        try container.encode(self.mathExtension, forKey: .mathExtension)
        
        try container.encode(self.syntaxHighlightExtension, forKey: .syntaxHighlightExtension)
        try container.encode(self.syntaxCustomThemes, forKey: .syntaxCustomThemes)
        try container.encode(self.syntaxThemeLight, forKey: .syntaxThemeLight)
        try container.encode(self.syntaxThemeDark, forKey: .syntaxThemeDark)
        try container.encode(self.syntaxBackgroundColor.rawValue, forKey: .syntaxBackgroundColor)
        try container.encode(self.syntaxBackgroundColorLight, forKey: .syntaxBackgroundColorLight)
        try container.encode(self.syntaxBackgroundColorDark, forKey: .syntaxBackgroundColorDark)
        try container.encode(self.syntaxWordWrapOption, forKey: .syntaxWordWrapOption)
        try container.encode(self.syntaxLineNumbersOption, forKey: .syntaxLineNumbersOption)
        try container.encode(self.syntaxTabsOption, forKey: .syntaxTabsOption)
        try container.encode(self.syntaxFontFamily, forKey: .syntaxFontFamily)
        try container.encode(self.syntaxFontSize, forKey: .syntaxFontSize)
        try container.encode(self.guessEngine.rawValue, forKey: .guessEngine)
    
        try container.encode(self.tableExtension, forKey: .tableExtension)
        try container.encode(self.tagFilterExtension, forKey: .tagFilterExtension)
        try container.encode(self.taskListExtension, forKey: .taskListExtension)
        try container.encode(self.yamlExtension, forKey: .yamlExtension)
        try container.encode(self.yamlExtensionAll, forKey: .yamlExtensionAll)
    
        try container.encode(self.footnotesOption, forKey: .footnotesOption)
        try container.encode(self.hardBreakOption, forKey: .hardBreakOption)
        try container.encode(self.noSoftBreakOption, forKey: .noSoftBreakOption)
        try container.encode(self.unsafeHTMLOption, forKey: .unsafeHTMLOption)
        try container.encode(self.smartQuotesOption, forKey: .smartQuotesOption)
        try container.encode(self.validateUTFOption, forKey: .validateUTFOption)
    
        try container.encode(self.customCSS, forKey: .customCSS)
        try container.encode(self.customCSSOverride, forKey: .customCSSOverride)
        try container.encode(self.openInlineLink, forKey: .openInlineLink)
        try container.encode(self.renderAsCode, forKey: .renderAsCode)
        
        try container.encode(self.useLegacyPreview, forKey: .useLegacyPreview)
        try container.encode(self.qlWindowWidth, forKey: .qlWindowWidth)
        try container.encode(self.qlWindowHeight, forKey: .qlWindowHeight)
        try container.encode(self.debug, forKey: .debug)
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
        
        self.update(from: defaultsDomain)
    }
    
    func update(from defaultsDomain: [String: Any]) {
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
        if let ext = defaultsDomain["yaml"] as? Bool {
            yamlExtension = ext
        } else if let ext = defaultsDomain["rmd"] as? Bool {
            yamlExtension = ext
        }
        if let ext = defaultsDomain["yaml_all"] as? Bool {
            yamlExtensionAll = ext
        } else if let ext = defaultsDomain["rmd_all"] as? Bool {
            yamlExtensionAll = ext
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
        
        if let ext = defaultsDomain["math"] as? Bool {
            mathExtension = ext
        }
        
        if let ext = defaultsDomain["syntax"] as? Bool {
            syntaxHighlightExtension = ext
        }
        
        if let state = defaultsDomain["syntax_custom_themes"] as? Bool {
            syntaxCustomThemes = state
        }
        if let theme = defaultsDomain["syntax_light_theme"] as? String {
            syntaxThemeLight = theme
        }
        if let theme = defaultsDomain["syntax_dark_theme"] as? String {
            syntaxThemeDark = theme
        }
        if let bg = defaultsDomain["syntax_background"] as? Int, let b = BackgroundColor(rawValue: bg) {
            syntaxBackgroundColor = b
        }
        if let color = defaultsDomain["syntax_light_background"] as? String {
            syntaxBackgroundColorLight = color
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
        
        if let opt = defaultsDomain["legacy-preview"] as? Bool {
            useLegacyPreview = opt
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
            
            self.mathExtension = s.mathExtension
            
            self.syntaxHighlightExtension = s.syntaxHighlightExtension
            self.syntaxCustomThemes = s.syntaxCustomThemes
            self.syntaxThemeLight = s.syntaxThemeLight
            self.syntaxThemeDark = s.syntaxThemeDark
            self.syntaxBackgroundColor = s.syntaxBackgroundColor
            self.syntaxBackgroundColorLight = s.syntaxBackgroundColorLight
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
            
            self.useLegacyPreview = false
            
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
        guard let url = self.customCSS, url.lastPathComponent != "-" else {
            return nil
        }
        return try? String(contentsOf: url)
    }
    
    func render(file url: URL, forAppearance appearance: Appearance, baseDir: String?) throws -> String {
        guard let data = FileManager.default.contents(atPath: url.path), let markdown_string = String(data: data, encoding: .utf8) else {
            os_log("Unable to read the file %{private}@", log: OSLog.rendering, type: .error, url.path)
            return ""
        }
        
        return try self.render(text: markdown_string, filename: url.lastPathComponent, forAppearance: appearance, baseDir: baseDir ?? url.deletingLastPathComponent().path)
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
            } else if let appBundle = Bundle(identifier: "org.sbarex.QLMarkdown") {
                return appBundle
            }
            // To access the main bundle, the extension must not be sandboxed (or must have a security exception entitlement to access the entire disk).
            os_log(
                "Unable to open the main application bundle from %{public}@",
                log: OSLog.quickLookExtension,
                type: .error,
                url.path
            )
        }
        return Bundle.main
    }
    
    /// Get the path of folder with `highlight` support files.
    func getHighlightSupportPath() -> String? {
        let path = self.resourceBundle.url(forResource: "highlight", withExtension: "")?.path
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
    
    func renderCode(text: String, forAppearance appearance: Appearance, baseDir: String) -> String? {
        if let path = getHighlightSupportPath() {
            cmark_syntax_highlight_init("\(path)/".cString(using: .utf8))
        } else {
            os_log("Unable to found the `highlight` support dir!", log: OSLog.rendering, type: .error)
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
    
    func render(text: String, filename: String, forAppearance appearance: Appearance, baseDir: String) throws -> String {
        if self.renderAsCode, let code = self.renderCode(text: text, forAppearance: appearance, baseDir: baseDir) {
            return code
        }
        
        cmark_gfm_core_extensions_ensure_registered()
        cmark_gfm_extra_extensions_ensure_registered()
        
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
        
        os_log("cmark_gfm options: %{public}d.", log: OSLog.rendering, type: .debug, options)
        
        guard let parser = cmark_parser_new(options) else {
            os_log("Unable to create new cmark_parser!", log: OSLog.rendering, type: .error, options)
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
        
        if self.tableExtension {
            if let ext = cmark_find_syntax_extension("table") {
                cmark_parser_attach_syntax_extension(parser, ext)
                os_log("Enabled markdown markdown `table` extension.", log: OSLog.rendering, type: .debug)
                // extensions = cmark_llist_append(cmark_get_default_mem_allocator(), nil, &ext)
            } else {
                os_log("Could not enable markdown `table` extension!", log: OSLog.rendering, type: .error)
            }
        }
        
        if self.autoLinkExtension {
            if let ext = cmark_find_syntax_extension("autolink") {
                cmark_parser_attach_syntax_extension(parser, ext)
                os_log("Enabled markdown `autolink` extension.", log: OSLog.rendering, type: .debug)
            } else {
                os_log("Could not enable markdown `autolink` extension!", log: OSLog.rendering, type: .error)
            }
        }
        
        if self.tagFilterExtension {
            if let ext = cmark_find_syntax_extension("tagfilter") {
                cmark_parser_attach_syntax_extension(parser, ext)
                os_log("Enabled markdown `tagfilter` extension.", log: OSLog.rendering, type: .debug)
            } else {
                os_log("Could not enable markdown `tagfilter` extension!", log: OSLog.rendering, type: .error)
            }
        }
        
        if self.taskListExtension {
            if let ext = cmark_find_syntax_extension("tasklist") {
                cmark_parser_attach_syntax_extension(parser, ext)
                os_log("Enabled markdown `tasklist` extension.",  log: OSLog.rendering, type: .debug)
            } else {
                os_log("Could not enable markdown `tasklist` extension!", log: OSLog.rendering, type: .error)
            }
        }
        
        var md_text = text
        
        var header = ""
        
        if self.yamlExtension && (self.yamlExtensionAll || filename.lowercased().hasSuffix("rmd") || filename.lowercased().hasSuffix("qmd")) && md_text.hasPrefix("---") {
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
        
        if self.strikethroughExtension {
            if let ext = cmark_find_syntax_extension("strikethrough") {
                cmark_parser_attach_syntax_extension(parser, ext)
                os_log("Enabled markdown `strikethrough` extension.", log: OSLog.rendering, type: .debug)
            } else {
                os_log("Could not enable markdown `strikethrough` extension!", log: OSLog.rendering, type: .error)
            }
        }
        
        if self.mentionExtension {
            if let ext = cmark_find_syntax_extension("mention") {
                cmark_parser_attach_syntax_extension(parser, ext)
                os_log("Enabled markdown `mention` extension.", log: OSLog.rendering, type: .debug)
            } else {
                os_log("Could not enable markdown `mention` extension!", log: OSLog.rendering, type: .error)
            }
        }
        
        if self.headsExtension {
            if let ext = cmark_find_syntax_extension("heads") {
                cmark_parser_attach_syntax_extension(parser, ext)
                os_log("Enabled markdown `heads` extension.", log: OSLog.rendering, type: .debug)
            } else {
                os_log("Could not enable markdown `heads` extension!", log: OSLog.rendering, type: .error)
            }
        }
        
        if self.inlineImageExtension {
            if let ext = cmark_find_syntax_extension("inlineimage") {
                cmark_parser_attach_syntax_extension(parser, ext)
                cmark_syntax_extension_inlineimage_set_wd(ext, baseDir.cString(using: .utf8))
                cmark_syntax_extension_inlineimage_set_mime_callback(ext, { (path, context) in
                    let magic_file = Settings.shared.resourceBundle.path(forResource: "magic", ofType: "mgc")?.cString(using: .utf8)
                    let r = magic_get_mime_by_file(path, magic_file)
                    return r
                }, nil)
                /*
                cmark_syntax_extension_inlineimage_set_remote_data_callback(ext, { (url, context) -> UnsafeMutablePointer<Int8>? in
                    guard let uu = url, let u = URL(string: String(cString: uu)) else {
                        return nil
                    }
                    do {
                        let data = try Data(contentsOf: u)
                    } catch {
                        os_log("Error fetch data from %{public}@: %{public}@", log: OSLog.rendering, type: .error, String(cString: uu), error.localizedDescription)
                        return nil
                    }
                    return nil
                }, nil)
                */
                
                os_log("Enabled markdown `local inline image` extension with working path set to `%{public}s`.", log: OSLog.rendering, type: .debug, baseDir)
                
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
                                    os_log("Image %{private}@ not found!", log: OSLog.rendering, type: .error)
                                    continue // File not found.
                                }
                                guard let data = get_base64_image(
                                    file.cString(using: .utf8),
                                    { (path: UnsafePointer<Int8>?, context: UnsafeMutableRawPointer?) -> UnsafeMutablePointer<Int8>? in
                                        let magic_file = Settings.shared.resourceBundle.path(forResource: "magic", ofType: "mgc")?.cString(using: .utf8)
                                        
                                        let r = magic_get_mime_by_file(path, magic_file)
                                        return r
                                    },
                                    nil,
                                    /*{ (url, _ )->UnsafeMutablePointer<Int8>? in
                                        guard let s = url else {
                                            return nil
                                        }
                                        let u = URL(fileURLWithPath: String(cString: s))
                                        guard let data = try? Data(contentsOf: u) else {
                                            return nil
                                        }
                                        return nil
                                    }*/ nil,
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
                            os_log("Error processing html: %{public}@!", log: OSLog.rendering, type: .error, message)
                        } catch {
                            os_log("Error parsing html: %{public}@!", log: OSLog.rendering, type: .error, error.localizedDescription)
                        }
                    }, nil)
                }
            } else {
                os_log("Could not enable markdown `local inline image` extension!", log: OSLog.rendering, type: .error)
            }
        }
        
        if self.emojiExtension {
            if let ext = cmark_find_syntax_extension("emoji") {
                cmark_syntax_extension_emoji_set_use_characters(ext, !self.emojiImageOption)
                cmark_parser_attach_syntax_extension(parser, ext)
                os_log("Enabled markdown `emoji` extension using %{public}s.", log: OSLog.rendering, type: .debug, self.emojiImageOption ? "images" : "glyphs")
            } else {
                os_log("Could not enable markdown `emoji` extension!", log: OSLog.rendering, type: .error)
            }
        }
        
        if self.mathExtension {
            if let ext = cmark_find_syntax_extension("math") {
                cmark_parser_attach_syntax_extension(parser, ext)
                
                os_log(
                    "Enabled markdown `math` extension.",
                    log: OSLog.rendering,
                    type: .debug)
            } else {
                os_log("Could not enable markdown `math` extension!", log: OSLog.rendering, type: .error)
            }
        }
        
        if self.syntaxHighlightExtension {
            if let ext = cmark_find_syntax_extension("syntaxhighlight") {
                if let path = getHighlightSupportPath() {
                    cmark_syntax_highlight_init("\(path)/".cString(using: .utf8))
                } else {
                    os_log("Unable to found the `highlight` support dir!", log: OSLog.rendering, type: .error)
                }
                
                let theme: String
                var background: String = ""
                switch self.syntaxBackgroundColor {
                case .fromMarkdown:
                    background = "var(--hl_Background)" 
                case .fromScheme:
                    background = "" // Do not override the background color.
                case .custom:
                    switch appearance {
                    case .light:
                        background = self.syntaxBackgroundColorLight
                    case .dark:
                        background = self.syntaxBackgroundColorDark
                    case .undefined:
                        let mode = UserDefaults.standard.string(forKey: "AppleInterfaceStyle") ?? "Light"
                        if mode == "Light" {
                            background = self.syntaxBackgroundColorLight
                        } else {
                            background = self.syntaxBackgroundColorDark
                        }
                    }
                }
                if self.syntaxCustomThemes {
                    switch appearance {
                    case .light:
                        theme = self.syntaxThemeLight
                    case .dark:
                        theme = self.syntaxThemeDark
                    case .undefined:
                        let mode = UserDefaults.standard.string(forKey: "AppleInterfaceStyle") ?? "Light"
                        if mode == "Light" {
                            theme = self.syntaxThemeLight
                        } else {
                            theme = self.syntaxThemeDark
                        }
                    }
                } else {
                    theme = ""
                }
                
                cmark_syntax_extension_highlight_set_theme_name(ext, theme)
                cmark_syntax_extension_highlight_set_background_color(ext, background.isEmpty ? nil : background)
                cmark_syntax_extension_highlight_set_line_number(ext, self.syntaxLineNumbersOption ? 1 : 0)
                cmark_syntax_extension_highlight_set_tab_spaces(ext, Int32(self.syntaxTabsOption))
                cmark_syntax_extension_highlight_set_wrap_limit(ext, Int32(self.syntaxWordWrapOption))
                cmark_syntax_extension_highlight_set_guess_language(ext, guess_type(UInt32(self.guessEngine.rawValue)))
                if self.guessEngine == .simple, let f = self.resourceBundle.path(forResource: "magic", ofType: "mgc") {
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
                
                os_log(
                    "Enabled markdown `syntax highlight` extension.\n Theme: %{public}s, background color: %{public}s",
                    log: OSLog.rendering,
                    type: .debug,
                    theme, background)
            } else {
                os_log("Could not enable markdown `syntax highlight` extension!", log: OSLog.rendering, type: .error)
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
        
        html_debug += "<tr><td>autolink extension</td><td>"
        if self.autoLinkExtension {
            html_debug += "on " + (cmark_find_syntax_extension("autolink") == nil ? " (NOT AVAILABLE" : "")
        } else {
            html_debug += "off"
        }
        html_debug += "</td></tr>\n"
        
        html_debug += "<tr><td>emoji extension</td><td>"
        if self.emojiExtension {
            html_debug += "on" + (cmark_find_syntax_extension("emoji") == nil ? " (NOT AVAILABLE" : "")
            html_debug += " / \(self.emojiImageOption ? "using images" : "using emoji")"
        } else {
            html_debug += "off"
        }
        html_debug += "</td></tr>\n"
        
        html_debug += "<tr><td>heads extension</td><td>" + (self.headsExtension ?  "on" : "off") + "</td></tr>\n"
        
        html_debug += "<tr><td>inlineimage extension</td><td>"
        if self.inlineImageExtension {
            html_debug += "on" + (cmark_find_syntax_extension("inlineimage") == nil ? " (NOT AVAILABLE" : "")
            html_debug += "<br />basedir: \(baseDir)"
        } else {
            html_debug += "off"
        }
        html_debug += "</td></tr>\n"
        
        html_debug += "<tr><td>math extension</td><td>"
        if self.mathExtension {
            html_debug += "on " + (cmark_find_syntax_extension("math") == nil ? " (NOT AVAILABLE" : "")
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
        
        html_debug += "<tr><td>strikethrough extension</td><td>"
        if self.strikethroughExtension {
            html_debug += "on " + (cmark_find_syntax_extension("strikethrough") == nil ? " (NOT AVAILABLE" : "")
        } else {
            html_debug += "off"
        }
        html_debug += "</td></tr>\n"
        
        html_debug += "<tr><td>syntax highlighting extension</td><td>"
        if self.syntaxHighlightExtension {
            html_debug += "on " + (cmark_find_syntax_extension("syntaxhighlight") == nil ? " (NOT AVAILABLE" : "")
            
            var theme: String
            var background: String
            
            if self.syntaxCustomThemes {
                switch appearance {
                case .light:
                    theme = self.syntaxThemeLight
                case .dark:
                    theme = self.syntaxThemeDark
                case .undefined:
                    let mode = UserDefaults.standard.string(forKey: "AppleInterfaceStyle") ?? "Light"
                    if mode == "Light" {
                        theme = self.syntaxThemeLight
                    } else {
                        theme = self.syntaxThemeDark
                    }
                }
                if theme.isEmpty {
                    theme = "N/D"
                }
            } else {
                theme = "Inherit from markdown style"
            }
            
            switch self.syntaxBackgroundColor {
            case .fromMarkdown:
                background = "use markdown settings"
            case .fromScheme:
                background = "use scheme settings"
            case .custom:
                switch appearance {
                case .light:
                    background = self.syntaxBackgroundColorLight
                case .dark:
                    background = self.syntaxBackgroundColorDark
                case .undefined:
                    let mode = UserDefaults.standard.string(forKey: "AppleInterfaceStyle") ?? "Light"
                    if mode == "Light" {
                        background = self.syntaxBackgroundColorLight
                    } else {
                        background = self.syntaxBackgroundColorDark
                    }
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
            case .simple:
                html_debug += "simple<br />"
                html_debug += "magic db: \(self.resourceBundle.path(forResource: "magic", ofType: "mgc") ?? "missing")"
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
        
        html_debug += "<tr><td>table extension</td><td>"
        if self.tableExtension {
            html_debug += "on " + (cmark_find_syntax_extension("table") == nil ? " (NOT AVAILABLE" : "")
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
            html_debug += "on "+(self.yamlExtensionAll ? "for all files" : "only for .rmd and .qmd files")
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
        if let p = self.resourceBundle.path(forResource: forResource, ofType: ofType), let data = FileManager.default.contents(atPath: p), let s = String(data: data, encoding: .utf8) {
            return s
        } else {
            return nil
        }
    }
    
    func getCompleteHTML(title: String, body: String, header: String = "", footer: String = "", basedir: URL, forAppearance appearance: Appearance) -> String {
        
        let css_doc: String
        let css_doc_extended: String
        
        var s_header = header
        var s_footer = footer
        
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
            var exit_code: Int32 = 0
            
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
            var background: String = ""
            
            switch self.syntaxBackgroundColor {
            case .fromMarkdown:
                background = ""
            case .fromScheme:
                var release: ReleaseTheme?
                let t = highlight_get_theme2(theme, &exit_code, &release)
                defer {
                    release?(t)
                }
                
                if exit_code == EXIT_SUCCESS, let s = t?.pointee.canvas.pointee.color {
                    background = String(cString: s)
                }
            case .custom:
                let mode = UserDefaults.standard.string(forKey: "AppleInterfaceStyle") ?? "Light"
                if mode == "Light" {
                    background = self.syntaxBackgroundColorLight
                } else {
                    background = self.syntaxBackgroundColorDark
                }
            }
            
            exit_code = 0
            let p = highlight_format_style2(&exit_code, background.isEmpty ? nil : background)
            defer {
                p?.deallocate()
            }
            css_highlight += "pre.hl { white-space: pre; }\n"
            if exit_code == EXIT_SUCCESS, let p = p {
                css_highlight = String(cString: p) + "\n"
            }
        } else if self.syntaxHighlightExtension, let ext = cmark_find_syntax_extension("syntaxhighlight"), cmark_syntax_extension_highlight_get_rendered_count(ext) > 0 {
            let theme = self.syntaxCustomThemes ? String(cString: cmark_syntax_extension_highlight_get_theme_name(ext)) : ""
            if !theme.isEmpty, let p = cmark_syntax_extension_get_style(ext) {
                // Embed the theme style.
                css_highlight = String(cString: p)
                p.deallocate()
            } else {
                if let s = cmark_syntax_extension_highlight_get_background_color(ext) {
                    let background_color = String(cString: s)
                    if background_color != "ignore" && !background_color.isEmpty {
                        css_highlight += "body.hl, pre.hl { background-color: \(background_color); }\n"
                    }
                }
            }
            if let s = cmark_syntax_extension_highlight_get_font_family(ext) {
                let font_name = String(cString: s)
                if !font_name.isEmpty && font_name != "-" {
                    let font = "\"\(font_name)\", ui-monospace, -apple-system, Menlo, monospace"
                    css_highlight += "body.hl, pre.hl, pre.hl code { font-family: \(font); }\n"
                }
            }
            let size = cmark_syntax_extension_highlight_get_font_size(ext)
            if size > 0 {
                css_highlight += "body.hl, pre.hl, pre.hl code { font-size: \(size)pt; }\n"
            }
        }
        css_highlight = formatCSS(css_highlight)
        
        if !self.renderAsCode, self.mathExtension, let ext = cmark_find_syntax_extension("math"), cmark_syntax_extension_math_get_rendered_count(ext) > 0 || body.contains("$") {
            s_header += """
<script type="text/javascript">
MathJax = {
  options: {
    enableMenu: \(self.debug ? "true" : "false"),
  },
  tex: {
    // packages: ['base'],        // extensions to use
    inlineMath: [              // start/end delimiter pairs for in-line math
      ['$', '$']
      // , ['\\(', '\\)']
    ],
    displayMath: [             // start/end delimiter pairs for display math
      ['$$', '$$']
      //, ['\\[', '\\]']
    ],
    processEscapes: true,       // use \\$ to produce a literal dollar sign
    processEnvironments: false
  }
};
</script>
"""
            s_footer += """
<script type="text/javascript" id="MathJax-script" async
  src="https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-mml-chtml.js">
</script>
"""
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
\(s_header)
</head>
<body\(body_style)>
\(wrapper_open)
\(body)
\(wrapper_close)
\(s_footer)
</body>
</html>
"""
        return html
    }
}
