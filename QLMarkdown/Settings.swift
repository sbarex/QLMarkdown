//
//  Settings.swift
//  QLMarkdown
//
//  Created by Sbarex on 13/12/20.
//

import Foundation
import OSLog

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
        case hightlightExtension
        case inlineImageExtension
        case mathExtension
        case mentionExtension
        case subExtension
        case supExtension
        case strikethroughExtension
        case strikethroughDoubleTildeOption
        case syntaxHighlightExtension
        case syntaxWordWrapOption
        case syntaxLineNumbersOption
        case syntaxTabsOption
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
        case customCSSCode
        case customCSSCodeFetched
        case customCSSOverride
        case openInlineLink
        
        case renderAsCode
        
        case useLegacyPreview
        
        case qlWindowWidth
        case qlWindowHeight
        
        case about
        case debug
    }

    static let shared = {
        return Settings.settingsFromSharedFile() ?? Settings()
    }()
    static let factorySettings = Settings(noInitFromDefault: true)
    static var appBundleUrl: URL?
    
    static var isLightAppearance: Bool {
        get {
            return UserDefaults.standard.string(forKey: "AppleInterfaceStyle") ?? "Light" == "Light"
        }
    }
    
    @objc var autoLinkExtension: Bool = true
    @objc var checkboxExtension: Bool = false
    @objc var emojiExtension: Bool = true
    @objc var emojiImageOption: Bool = false
    @objc var headsExtension: Bool = true
    @objc var highlightExtension: Bool = false
    @objc var inlineImageExtension: Bool = true
    @objc var mathExtension: Bool = true
    @objc var mentionExtension: Bool = false
    
    @objc var strikethroughExtension: Bool = true
    @objc var strikethroughDoubleTildeOption: Bool = false
    
    @objc var subExtension: Bool = false
    @objc var supExtension: Bool = false
    
    @objc var syntaxHighlightExtension: Bool = true
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
    @objc var customCSSFetched: Bool = false
    @objc var customCSSCode: String?
    @objc var customCSSOverride: Bool = false
    
    @objc var openInlineLink: Bool = false
    
    @objc var renderAsCode: Bool = false
    
    var renderStats: Int {
        get {
            return UserDefaults.standard.integer(forKey: "ql-markdown-render-count");
        }
        set {
            // print("Rendered \(newValue) files.")
            UserDefaults.standard.setValue(newValue, forKey: "ql-markdown-render-count")
            UserDefaults.standard.synchronize();
        }
    }
    
    var useLegacyPreview: Bool = false
    
    /// Quick Look window width.
    var qlWindowWidth: Int? = nil
    /// Quick Look window height.
    var qlWindowHeight: Int? = nil
    /// Quick Look window size.
    var qlWindowSize: CGSize {
        if let w = qlWindowWidth, w > 0, let h = qlWindowHeight, h > 0 {
            return CGSize(width: CGFloat(w), height: CGFloat(h))
        } else {
            return CGSize(width: 0, height: 0)
        }
    }
    
    @objc var debug: Bool = false
    @objc var about: Bool = true
    
    var app_version: String {
        var title: String = "<a href='https://github.com/sbarex/QLMarkdown'>";
        if let info = Bundle.main.infoDictionary {
            title += (info["CFBundleExecutable"] as? String ?? "QLMarkdown") + "</a>"
            if let version = info["CFBundleShortVersionString"] as? String,
                let build = info["CFBundleVersion"] as? String {
                title += ", version \(version) (\(build))"
            }
            if let copy = info["NSHumanReadableCopyright"] as? String {
                title += ".<br />\n\(copy.trimmingCharacters(in: CharacterSet(charactersIn: ". ")) + " with <span style='font-style: normal'>❤️</span>")"
            }
        } else {
            title += "QLMarkdown</a>"
        }
        title += ".<br/>\nIf you like this app, <a href='https://www.buymeacoffee.com/sbarex'><strong>buy me a coffee</strong></a>!"
        return title
    }
    
    var app_version2: String {
        var title: String = "<!--\n\nFile generated with QLMarkdown [https://github.com/sbarex/QLMarkdown] - ";
        if let info = Bundle.main.infoDictionary {
            title += (info["CFBundleExecutable"] as? String ?? "QLMarkdown")
            if let version = info["CFBundleShortVersionString"] as? String,
                let build = info["CFBundleVersion"] as? String {
                title += ", version \(version) (\(build))"
            }
            if let copy = info["NSHumanReadableCopyright"] as? String {
                title += ".\n\(copy.trimmingCharacters(in: CharacterSet(charactersIn: ". ")) + " with ❤️")"
            }
        }
        title += "\n\n-->\n"
        return title
    }
    
    lazy fileprivate(set) var resourceBundle: Bundle = {
        return Self.getResourceBundle()
    }()
    
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
        self.highlightExtension = try container.decode(Bool.self, forKey: .hightlightExtension)
        self.inlineImageExtension = try container.decode(Bool.self, forKey:.inlineImageExtension)
        
        self.mathExtension = try container.decode(Bool.self, forKey: .mathExtension)
        self.mentionExtension = try container.decode(Bool.self, forKey:.mentionExtension)
        self.strikethroughExtension = try container.decode(Bool.self, forKey:.strikethroughExtension)
        self.strikethroughDoubleTildeOption = try container.decode(Bool.self, forKey:.strikethroughDoubleTildeOption)
        self.subExtension = try container.decode(Bool.self, forKey:.subExtension)
        self.supExtension = try container.decode(Bool.self, forKey:.supExtension)
        self.syntaxHighlightExtension = try container.decode(Bool.self, forKey: .syntaxHighlightExtension)
        self.syntaxWordWrapOption = try container.decode(Int.self, forKey: .syntaxWordWrapOption)
        self.syntaxLineNumbersOption = try container.decode(Bool.self, forKey: .syntaxLineNumbersOption)
        self.syntaxTabsOption = try container.decode(Int.self, forKey: .syntaxTabsOption)
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
        self.customCSSFetched = try container.decode(Bool.self, forKey: .customCSSCodeFetched)
        self.customCSSCode = try container.decode(String?.self, forKey: .customCSSCode)
        self.customCSSOverride = try container.decode(Bool.self, forKey: .customCSSOverride)
        self.openInlineLink = try container.decode(Bool.self, forKey: .openInlineLink)
    
        self.renderAsCode = try container.decode(Bool.self, forKey: .renderAsCode)
    
        self.useLegacyPreview = try container.decode(Bool.self, forKey: .useLegacyPreview)
    
        self.qlWindowWidth = try container.decode(Int?.self, forKey: .qlWindowWidth)
        self.qlWindowHeight = try container.decode(Int?.self, forKey: .qlWindowHeight)
    
        self.debug = try container.decode(Bool.self, forKey: .debug)
        self.about = try container.decode(Bool.self, forKey: .about)
    }
    
    init() {
        
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
        try container.encode(self.highlightExtension, forKey: .hightlightExtension)
        try container.encode(self.inlineImageExtension, forKey: .inlineImageExtension)
        try container.encode(self.mathExtension, forKey: .mathExtension)
        try container.encode(self.mentionExtension, forKey: .mentionExtension)
        try container.encode(self.strikethroughExtension, forKey: .strikethroughExtension)
        try container.encode(self.strikethroughDoubleTildeOption, forKey: .strikethroughDoubleTildeOption)
        try container.encode(self.syntaxHighlightExtension, forKey: .syntaxHighlightExtension)
        try container.encode(self.syntaxWordWrapOption, forKey: .syntaxWordWrapOption)
        try container.encode(self.syntaxLineNumbersOption, forKey: .syntaxLineNumbersOption)
        try container.encode(self.syntaxTabsOption, forKey: .syntaxTabsOption)
        try container.encode(self.subExtension, forKey: .subExtension)
        try container.encode(self.supExtension, forKey: .supExtension)
        
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
        try container.encode(self.customCSSCode, forKey: .customCSSCode)
        try container.encode(self.customCSSFetched, forKey: .customCSSCodeFetched)
        try container.encode(self.customCSSOverride, forKey: .customCSSOverride)
        try container.encode(self.openInlineLink, forKey: .openInlineLink)
        try container.encode(self.renderAsCode, forKey: .renderAsCode)
        
        try container.encode(self.useLegacyPreview, forKey: .useLegacyPreview)
        try container.encode(self.qlWindowWidth, forKey: .qlWindowWidth)
        try container.encode(self.qlWindowHeight, forKey: .qlWindowHeight)
        try container.encode(self.about, forKey: .about)
        try container.encode(self.debug, forKey: .debug)
    }
    
    var isMonitoring = false
    func startMonitorChange() {
        guard !isMonitoring else {
            return
        }
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
        let s = Settings.settingsFromSharedFile() ?? Settings()
        update(from: s)
    }
    
    func update(from s: Settings) {
        self.autoLinkExtension = s.autoLinkExtension
        self.checkboxExtension = s.checkboxExtension
        
        self.emojiExtension = s.emojiExtension
        self.emojiImageOption = s.emojiImageOption
        
        self.headsExtension = s.headsExtension
        self.highlightExtension = s.highlightExtension
        self.inlineImageExtension = s.inlineImageExtension
        
        self.mathExtension = s.mathExtension
        self.mentionExtension = s.mentionExtension
        
        self.strikethroughExtension = s.strikethroughExtension
        self.strikethroughDoubleTildeOption = s.strikethroughDoubleTildeOption
        
        self.syntaxHighlightExtension = s.syntaxHighlightExtension
        self.syntaxWordWrapOption = s.syntaxWordWrapOption
        self.syntaxLineNumbersOption = s.syntaxLineNumbersOption
        self.syntaxTabsOption = s.syntaxTabsOption
        self.syntaxFontFamily = s.syntaxFontFamily
        self.syntaxFontSize = s.syntaxFontSize
        self.subExtension = s.subExtension
        self.supExtension = s.supExtension
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
        self.customCSSCode = s.customCSSCode
        self.customCSSOverride = s.customCSSOverride

        self.openInlineLink = s.openInlineLink

        self.about = s.about
        self.debug = s.debug
        
        self.renderAsCode = s.renderAsCode
        
        self.qlWindowWidth = s.qlWindowWidth
        self.qlWindowHeight = s.qlWindowHeight
        
        self.useLegacyPreview = false
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
        
        
        if let ext = defaultsDomain["math"] as? Bool {
            mathExtension = ext
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
        
        if let ext = defaultsDomain["highlight"] as? Bool {
            highlightExtension = ext
        }
        
        if let ext = defaultsDomain["syntax"] as? Bool {
            syntaxHighlightExtension = ext
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
        
        if let ext = defaultsDomain["sub"] as? Bool {
            subExtension = ext
        }
        if let ext = defaultsDomain["sup"] as? Bool {
            supExtension = ext
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
            if !opt.hasPrefix("/"), let path = Settings.getStylesFolder() {
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
        
        if let opt = defaultsDomain["about"] as? Bool {
            about = opt
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
    
    func resetToFactory() {
        let s = Settings()
        update(from: s)
    }
    
    static func settingsFromSharedFile() -> Settings? {
        var settings: Settings? = nil
        
        XPCWrapper.getSynchronousService()?.getSettings() { data in
            guard let data = data, let _settings = try? JSONDecoder().decode(Settings.self, from: data) else {
                return
            }
            settings = _settings
        }
        
        return settings
    }
    
    @discardableResult
    func saveToSharedFile() -> (Bool, String?) {
        guard let data = try? JSONEncoder().encode(self) else {
            return (false, "Could not encode settings")
        }
        
        var r = false
        var msg: String? = nil
        XPCWrapper.getSynchronousService()?.setSettings(data: data) { (success, _msg) in
            r = success
            msg = _msg
        }
        return (r, msg)
    }
    
    private func sanitizeEmojiOption() {
        if emojiExtension && emojiImageOption {
            unsafeHTMLOption = true
        }
    }
    
    /// Get the Bundle with the resources.
    /// For the host app return the main Bundle. For the appex return the bundle of the hosting app.
    static func getResourceBundle() -> Bundle {
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
            if let appBundle = Bundle(url: Bundle.main.bundleURL.appendingPathComponent("Contents/Resources")) {
                return appBundle
            }
        }
        return Bundle.main
    }
    
    /// Get the path of folder with `highlight` support files.
    func getHighlightSupportPath() -> String? {
        let path = self.resourceBundle.url(forResource: "highlight", withExtension: "")?.path
        return path
    }
    
    func getBundleContents(forResource: String, ofType: String) -> String? {
        if let p = self.resourceBundle.path(forResource: forResource, ofType: ofType), let data = FileManager.default.contents(atPath: p), let s = String(data: data, encoding: .utf8) {
            return s
        } else {
            return nil
        }
    }
}
