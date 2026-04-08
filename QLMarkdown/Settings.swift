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

enum JSExtension: Codable {
    enum CodingKeys: String, CodingKey {
        case state
        case url
    }
    
    case disabled
    case embed(url: URL?)
    case link(url: URL?)
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let state = try container.decode(Int.self, forKey: .state)
        if state == 0 {
            self = .disabled
        } else {
            let url = try container.decode(URL?.self, forKey: .url)
            if state == 1 {
                self = .embed(url: url)
            } else {
                self = .link(url: url)
            }
        }
    }
    
    init?(from dict: [String: Any]) {
        guard let state = dict[Self.CodingKeys.state.rawValue] as? Int else {
            return nil
        }
        if state == 0 {
            self = .disabled
        } else {
            let url: URL?
            if dict.keys.contains(Self.CodingKeys.url.rawValue) {
                url = dict[Self.CodingKeys.url.rawValue] as? URL
            } else {
                url = nil
            }
            if state == 1 {
                self = .embed(url: url)
            } else {
                self = .link(url: url)
            }
        }
    }
    
    func toDict() -> [String: Any] {
        switch self {
        case .disabled:
            return [Self.CodingKeys.state.rawValue: 0]
        case .embed(let url):
            var r: [String: Any] = [Self.CodingKeys.state.rawValue: 1]
            if let url {
                r[Self.CodingKeys.url.rawValue] = url
            }
            return r
        case .link(let url):
            var r: [String: Any] = [Self.CodingKeys.state.rawValue: 2]
            if let url {
                r[Self.CodingKeys.url.rawValue] = url
            }
            return r
        }
    }
    
    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
        case .disabled:
            try container.encode(0, forKey: .state)
        case .embed(let url):
            try container.encode(1, forKey: .state)
            try container.encode(url, forKey: .url)
        case .link(let url):
            try container.encode(2, forKey: .state)
            try container.encode(url, forKey: .url)
        }
    }
    
    var isDisabled: Bool {
        switch self {
        case .disabled:
            return true
        default:
            return false
        }
    }
    
    func getMode() -> (embed: Bool, url: URL?)?
    {
        switch self {
        case .disabled:
            return nil
        case .embed(let url):
            return (embed: true, url: url)
        case .link(let url):
            return (embed: false, url: url)
        }
    }
    
    /**
     * Sanitize the settings
     * - parameters:
     *   - cacheUrl: Path (local file or web uRL) of the library, from the cache folder or the main bundle.
     *   - cdnUrl: Web url from download the library. Tipically from a CDN service.
     *   - allowLinkFile: `true` allows you to link the library even if it is a local file and not a web URL.
     *
     * You can embed only exists local file. 
     */
    public mutating func sanitize(cacheUrl: URL?, cdnUrl: URL, allowLinkFile: Bool = false) {
        switch self {
        case .disabled:
            break
        case .link(let url):
            if let url = url ?? cacheUrl, allowLinkFile || !url.isFileURL {
                // Without `allowLinkFile`, only web url can be linked.
                // For link do not test if the file exists.
                self = .link(url: url)
            } else {
                // Link the CDN url.
                self = .link(url: cdnUrl)
            }
        case .embed(let url):
            if let url = url ?? cacheUrl {
                if url.isFileURL && FileManager.default.fileExists(atPath: url.path) {
                    // Only exists file can be embed.
                    self = .embed(url: url)
                } else if !url.isFileURL {
                    // Link a web url.
                    self = .link(url: cacheUrl)
                } else {
                    // Link the CDN url.
                    self = .link(url: cdnUrl)
                }
            } else {
                // Link the CDN url.
                self = .link(url: cdnUrl)
            }
        }
    }
    
    /**
     * Get the code to link/embed the JS library.
     * - parameters:
     *  - extraTagLink: Extra code to put in the `<script>` tag when the library is linked.
     *  - extraTagEmbed: Extra code to put in the `<script>` tag when the library is embedded.
     *
     * **Call `sanitize` before invokint this function.**
     */
    func getScriptCode(extraTagLink: String = "", extraTagEmbed: String = "") -> String {
        switch self {
        case .disabled:
            return ""
        case .link(let url):
            guard let url else {
                return ""
            }
            return "<script type='text/javascript' \(extraTagLink) src='\(url.absoluteString)'></script>\n"
        case .embed(let url):
            guard let url else {
                return ""
            }
            if let code = try? String(contentsOfFile: url.path, encoding: .utf8) {
                // Embed the libraty inline
                return "<script type='text/javascript' \(extraTagEmbed)>\n\(code)\n</script>\n"
            }
            return Self.link(url: url).getScriptCode(extraTagLink: extraTagLink, extraTagEmbed: extraTagEmbed)
        }
    }
}

enum YamlMode: Int, Codable {
    case disabled = 0
    case allFiles = 1
    case onlyRmd = 2
}

enum EmojiMode: Int, Codable {
    case disabled = 0
    case font = 1
    case images = 2
}

enum StrikethroughMode: Int, Codable {
    case disabled = 0
    case single = 1
    case double = 2
}

extension NSNotification.Name {
    public static let QLMarkdownSettingsUpdated: NSNotification.Name = NSNotification.Name("org.sbarex.qlmarkdown-settings-changed")
}

// MARK: -
class Settings: Codable {
    enum CodingKeys: String, CodingKey {
        case autoLinkExtension
        case checkboxExtension
        case headsExtension
        case hightlightExtension
        case inlineImageExtension
        case mathExtension
        case mermaidExtension
        case mentionExtension
        case subExtension
        case supExtension
        case tableExtension
        case tagFilterExtension
        case taskListExtension
        case yamlExtension
        case emojiExtension
        case strikethroughExtension
        case syntaxHighlightExtension
        case syntaxWordWrapOption
        case syntaxLineNumbersOption
        case syntaxTabsOption
        case footnotesOption
        case hardBreakOption
        case noSoftBreakOption
        case unsafeHTMLOption
        case smartQuotesOption
        case validateUTFOption
        case baseFontSize
        case customCSS
        case customCSSCode
        case customCSSCodeFetched
        case customCSSOverride
        case openInlineLink
        case renderAsCode
        case qlWindowWidth
        case qlWindowHeight
        case about
        case debug
    }

    // MARK: - Static properties and methods
    
    /// Shared App Groups name.
    static let appGroup = "group.org.sbarex.qlmarkdown"
    
    /// Shared instance of the Settings.
    static let shared = {
        return Settings.settingsFromSharedFile() ?? Settings()
    }()
    
    static let factorySettings = Settings(noInitFromDefault: true)
    
    /// URL of the Application Bundle.
    static var appBundleUrl: URL?
    
    /**
     * Get the Bundle with the resources.
     * For the host app return the main Bundle. For the appex return the bundle of the hosting app.
     */
    static func getResourceBundle() -> Bundle {
        if let url = Settings.appBundleUrl, let appBundle = Bundle(url: url) {
            return appBundle
        } else if let url = Settings.appBundleUrl?.appendingPathComponent("Contents/Resources"), let appBundle = Bundle(url: url) {
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
            } else if let appBundle = Bundle(url: Bundle.main.bundleURL) {
                return appBundle
            }
        }
        
        return Bundle.main
    }
    
    static var isLightAppearance: Bool {
        get {
            return UserDefaults.standard.string(forKey: "AppleInterfaceStyle") ?? "Light" == "Light"
        }
    }
    
    /// URL of the Application Support folder.
    class var applicationSupportUrl: URL? {
        return FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: Self.appGroup)?
            .appendingPathComponent("Library")
            .appendingPathComponent("Application Support")
    }
    
    /**
     * URL of the folder for the style sheets.
     * * SeeAlso
     * Settings.applicationSupportUrl
     */
    static var stylesFolder: URL? {
        return Settings.applicationSupportUrl?.appendingPathComponent("styles")
    }
    
    /**
     * URL of the folder for the js cached files.
     * * SeeAlso
     * Settings.applicationSupportUrl
     */
    static var jsFolder: URL? {
        return Settings.applicationSupportUrl?.appendingPathComponent("js")
    }
    
    /**
     * Informative message.
     */
    static var aboutInfo: String {
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
    
    /**
     * Informative hidden message.
     */
    static var aboutComment: String {
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
    
    /**
     * Returns the number of rendered files.
     *
     * Each target has its own counter.
     **/
    static var renderStats: Int {
        get {
            return UserDefaults.standard.integer(forKey: "ql-markdown-render-count");
        }
        set {
            // print("Rendered \(newValue) files.")
            UserDefaults.standard.setValue(newValue, forKey: "ql-markdown-render-count")
            UserDefaults.standard.synchronize();
        }
    }
    
    /**
     * Init the settins from the shared App Groups.
     */
    static func settingsFromSharedFile() -> Settings? {
        var settings: Settings? = nil
        
        if let defaults = UserDefaults(suiteName: Self.appGroup) {
            settings = Settings(fromUserDefaults: defaults)
        }
        guard let settings else {
            return nil
        }
        
        settings.customCSSFetched = true
        settings.customCSSCode = nil
        
        if let url = settings.customCSS, url.lastPathComponent != "-" {
            do {
                let css = try String(contentsOf: url, encoding: .utf8)
                settings.customCSSCode = css
            } catch {
                os_log(
                    "Unable to fetch the CSS file %{public}@: %{public}@",
                    log: OSLog.quickLookExtension,
                    type: .error,
                    url.path,
                    error.localizedDescription
                )
                settings.customCSSFetched = false
            }
            
            if let css = try? String(contentsOf: url, encoding: .utf8) {
                settings.customCSSCode = css
            } else {
                os_log(
                    "Unable to fetch the CSS file %{public}@!",
                    log: OSLog.quickLookExtension,
                    type: .error,
                    url.path
                )
                settings.customCSSFetched = false
            }
        } else {
            settings.customCSSCode = ""
        }
        
        return settings
    }
    
    // MARK: - Instance properties and methods
    
    var autoLinkExtension: Bool = true
    var checkboxExtension: Bool = false
    var headsExtension: Bool = true
    var highlightExtension: Bool = false
    var inlineImageExtension: Bool = true
    var mathExtension: JSExtension = .link(url: nil)
    var mermaidExtension: JSExtension = .link(url: nil)
    var mentionExtension: Bool = false
    var subExtension: Bool = false
    var supExtension: Bool = false
    var tableExtension: Bool = true
    var tagFilterExtension: Bool = true
    var taskListExtension: Bool = true
    var yamlExtension: YamlMode = .onlyRmd
    var emojiExtension: EmojiMode = .font
    var strikethroughExtension: StrikethroughMode = .single
    var syntaxHighlightExtension: Bool = true
    var syntaxWordWrapOption: Int = 0
    var syntaxLineNumbersOption: Bool = false
    var syntaxTabsOption: Int = 4

    var footnotesOption: Bool = true
    var hardBreakOption: Bool = false
    var noSoftBreakOption: Bool = false
    var unsafeHTMLOption: Bool = true
    var smartQuotesOption: Bool = true
    var validateUTFOption: Bool = false
    
    var baseFontSize: CGFloat = 0
    var customCSS: URL?
    var customCSSFetched: Bool = false
    var customCSSCode: String?
    var customCSSOverride: Bool = false
    
    var openInlineLink: Bool = false
    var renderAsCode: Bool = false

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
    
    /// Show the informative message on the footer.
    var about: Bool = true
    
    /// Show debug infomations.
    var debug: Bool = false
    
    lazy fileprivate(set) var resourceBundle: Bundle = {
        return Self.getResourceBundle()
    }()
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.tableExtension = try container.decode(Bool.self, forKey: .tableExtension)
        self.autoLinkExtension = try container.decode(Bool.self, forKey:.autoLinkExtension)
        self.tagFilterExtension = try container.decode(Bool.self, forKey: .tagFilterExtension)
        self.taskListExtension = try container.decode(Bool.self, forKey: .taskListExtension)
        
        self.yamlExtension = try container.decode(YamlMode.self, forKey: .yamlExtension)
    
        self.strikethroughExtension = try container.decode(StrikethroughMode.self, forKey:.strikethroughExtension)
        
        self.mathExtension = try container.decode(JSExtension.self, forKey:.mathExtension)
        self.mermaidExtension = try container.decode(JSExtension.self, forKey:.mermaidExtension)
        
        self.mentionExtension = try container.decode(Bool.self, forKey:.mentionExtension)
        self.checkboxExtension = try container.decode(Bool.self, forKey:.checkboxExtension)
        self.headsExtension = try container.decode(Bool.self, forKey:.headsExtension)
        self.highlightExtension = try container.decode(Bool.self, forKey: .hightlightExtension)
       
        self.syntaxHighlightExtension = try container.decode(Bool.self, forKey: .syntaxHighlightExtension)
        self.syntaxWordWrapOption = try container.decode(Int.self, forKey: .syntaxWordWrapOption)
        self.syntaxLineNumbersOption = try container.decode(Bool.self, forKey: .syntaxLineNumbersOption)
        self.syntaxTabsOption = try container.decode(Int.self, forKey: .syntaxTabsOption)
        
        self.subExtension = try container.decode(Bool.self, forKey:.subExtension)
        self.supExtension = try container.decode(Bool.self, forKey:.supExtension)
        
        self.emojiExtension = try container.decode(EmojiMode.self, forKey:.emojiExtension)
        
        self.inlineImageExtension = try container.decode(Bool.self, forKey:.inlineImageExtension)
        
        self.hardBreakOption = try container.decode(Bool.self, forKey: .hardBreakOption)
        self.noSoftBreakOption = try container.decode(Bool.self, forKey: .noSoftBreakOption)
        self.unsafeHTMLOption = try container.decode(Bool.self, forKey: .unsafeHTMLOption)
        self.validateUTFOption = try container.decode(Bool.self, forKey: .validateUTFOption)
        self.smartQuotesOption = try container.decode(Bool.self, forKey: .smartQuotesOption)
        self.footnotesOption = try container.decode(Bool.self, forKey: .footnotesOption)
        
        self.baseFontSize = try container.decode(CGFloat.self, forKey: .baseFontSize)
        self.customCSS = try container.decode(URL?.self, forKey: .customCSS)
        self.customCSSFetched = try container.decode(Bool.self, forKey: .customCSSCodeFetched)
        self.customCSSCode = try container.decode(String?.self, forKey: .customCSSCode)
        self.customCSSOverride = try container.decode(Bool.self, forKey: .customCSSOverride)
        
        self.about = try container.decode(Bool.self, forKey: .about)
        self.debug = try container.decode(Bool.self, forKey: .debug)
        
        self.openInlineLink = try container.decode(Bool.self, forKey: .openInlineLink)
        self.renderAsCode = try container.decode(Bool.self, forKey: .renderAsCode)

        self.qlWindowWidth = try container.decode(Int?.self, forKey: .qlWindowWidth)
        self.qlWindowHeight = try container.decode(Int?.self, forKey: .qlWindowHeight)
    }
    
    init() { }
    
    init(defaults defaultsDomain: [String: Any]) {
        self.update(from: defaultsDomain)
    }
    
    convenience init(fromUserDefaults defaults: UserDefaults) {
        self.init()
        update(from: defaults.dictionaryRepresentation())
    }
    
    private init(noInitFromDefault: Bool = false) {
        if !noInitFromDefault {
            self.initFromDefaults()
        }
    }

    deinit {
        stopMonitorChange()
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(self.tableExtension, forKey: .tableExtension)
        try container.encode(self.autoLinkExtension, forKey: .autoLinkExtension)
        try container.encode(self.tagFilterExtension, forKey: .tagFilterExtension)
        try container.encode(self.taskListExtension, forKey: .taskListExtension)
    
        try container.encode(self.yamlExtension, forKey: .yamlExtension)
    
        try container.encode(self.strikethroughExtension, forKey: .strikethroughExtension)
        
        try container.encode(self.mathExtension, forKey: .mathExtension)
        try container.encode(self.mermaidExtension, forKey: .mermaidExtension)
        
        try container.encode(self.mentionExtension, forKey: .mentionExtension)
        try container.encode(self.checkboxExtension, forKey: .checkboxExtension)
        try container.encode(self.headsExtension, forKey: .headsExtension)
        try container.encode(self.highlightExtension, forKey: .hightlightExtension)
        
        try container.encode(self.syntaxHighlightExtension, forKey: .syntaxHighlightExtension)
        try container.encode(self.syntaxWordWrapOption, forKey: .syntaxWordWrapOption)
        try container.encode(self.syntaxLineNumbersOption, forKey: .syntaxLineNumbersOption)
        try container.encode(self.syntaxTabsOption, forKey: .syntaxTabsOption)
        
        try container.encode(self.subExtension, forKey: .subExtension)
        try container.encode(self.supExtension, forKey: .supExtension)
        
        try container.encode(self.emojiExtension, forKey: .emojiExtension)
        
        try container.encode(self.inlineImageExtension, forKey: .inlineImageExtension)
    
        try container.encode(self.hardBreakOption, forKey: .hardBreakOption)
        try container.encode(self.noSoftBreakOption, forKey: .noSoftBreakOption)
        try container.encode(self.unsafeHTMLOption, forKey: .unsafeHTMLOption)
        try container.encode(self.validateUTFOption, forKey: .validateUTFOption)
        try container.encode(self.smartQuotesOption, forKey: .smartQuotesOption)
        try container.encode(self.footnotesOption, forKey: .footnotesOption)
        
        try container.encode(self.baseFontSize, forKey: .baseFontSize)
        try container.encode(self.customCSS, forKey: .customCSS)
        try container.encode(self.customCSSCode, forKey: .customCSSCode)
        try container.encode(self.customCSSFetched, forKey: .customCSSCodeFetched)
        try container.encode(self.customCSSOverride, forKey: .customCSSOverride)
        
        try container.encode(self.about, forKey: .about)
        try container.encode(self.debug, forKey: .debug)
    
        try container.encode(self.openInlineLink, forKey: .openInlineLink)
        try container.encode(self.renderAsCode, forKey: .renderAsCode)

        try container.encode(self.qlWindowWidth, forKey: .qlWindowWidth)
        try container.encode(self.qlWindowHeight, forKey: .qlWindowHeight)
    }
    
    func initFromDefaults() {
        if let s = Settings.settingsFromSharedFile() {
            update(from: s)
        }
    }
    
    private(set) var isMonitoring = false
    /**
     * Monitors settings changes by other processes.
     */
    func startMonitorChange() {
        guard !isMonitoring else {
            return
        }
        isMonitoring = true
        DistributedNotificationCenter.default().addObserver(self, selector: #selector(self.handleSettingsChanged(_:)), name: .QLMarkdownSettingsUpdated, object: nil)
    }
    /**
     * Suspend the settings changes monitor.
     */
    func stopMonitorChange() {
        if isMonitoring {
            DistributedNotificationCenter.default().removeObserver(self)
            isMonitoring = false
        }
    }
    
    /**
     * Reloads settings after they have been changed by another process.
     */
    @objc func handleSettingsChanged(_ notification: NSNotification) {
        // print("settings changed")
        self.initFromDefaults()
    }
    
    /**
     * Update settings based on other settings provided.
     */
    func update(from s: Settings) {
        self.tableExtension = s.tableExtension
        self.autoLinkExtension = s.autoLinkExtension
        self.tagFilterExtension = s.tagFilterExtension
        self.taskListExtension = s.taskListExtension
        
        self.yamlExtension = s.yamlExtension
        
        self.strikethroughExtension = s.strikethroughExtension
        
        self.mathExtension = s.mathExtension
        self.mermaidExtension = s.mermaidExtension
        self.mentionExtension = s.mentionExtension
        self.checkboxExtension = s.checkboxExtension
        self.headsExtension = s.headsExtension
        
        self.highlightExtension = s.highlightExtension
        
        self.syntaxHighlightExtension = s.syntaxHighlightExtension
        self.syntaxWordWrapOption = s.syntaxWordWrapOption
        self.syntaxLineNumbersOption = s.syntaxLineNumbersOption
        self.syntaxTabsOption = s.syntaxTabsOption
        
        self.subExtension = s.subExtension
        self.supExtension = s.supExtension
        
        self.emojiExtension = s.emojiExtension
        
        self.inlineImageExtension = s.inlineImageExtension
        
        self.hardBreakOption = s.hardBreakOption
        self.noSoftBreakOption = s.noSoftBreakOption
        self.unsafeHTMLOption = s.unsafeHTMLOption
        self.validateUTFOption = s.validateUTFOption
        self.smartQuotesOption = s.smartQuotesOption
        self.footnotesOption = s.footnotesOption
        
        self.baseFontSize = s.baseFontSize
        self.customCSS = s.customCSS
        self.customCSSCode = s.customCSSCode
        self.customCSSOverride = s.customCSSOverride
        
        self.about = s.about
        self.debug = s.debug
        
        self.openInlineLink = s.openInlineLink
        
        self.renderAsCode = s.renderAsCode
        
        self.qlWindowWidth = s.qlWindowWidth
        self.qlWindowHeight = s.qlWindowHeight
    }
    
    /**
     * Update settings based on other settings provided from a UserDefaults dictionary.
     */
    func update(from defaultsDomain: [String: Any]) {
        if let ext = defaultsDomain[Self.CodingKeys.tableExtension.rawValue] as? Bool {
            tableExtension = ext
        }
        if let ext = defaultsDomain[Self.CodingKeys.autoLinkExtension.rawValue] as? Bool {
            autoLinkExtension = ext
        }
        if let ext = defaultsDomain[Self.CodingKeys.tagFilterExtension.rawValue] as? Bool {
            tagFilterExtension = ext
        }
        if let ext = defaultsDomain[Self.CodingKeys.taskListExtension.rawValue] as? Bool {
            taskListExtension = ext
        }
        if let n = defaultsDomain[Self.CodingKeys.yamlExtension.rawValue] as? Int, let ext = YamlMode(rawValue: n) {
            yamlExtension = ext
        }
        
        if let n = defaultsDomain[Self.CodingKeys.strikethroughExtension.rawValue] as? Int, let ext = StrikethroughMode(rawValue: n) {
            strikethroughExtension = ext
        }
        
        if let ext = defaultsDomain[Self.CodingKeys.mathExtension.rawValue] as? [String: Any] {
            mathExtension = JSExtension(from: ext) ?? .disabled
        }
        if let ext = defaultsDomain[Self.CodingKeys.mermaidExtension.rawValue] as? [String: Any] {
            mermaidExtension = JSExtension(from: ext) ?? .disabled
        }
        if let ext = defaultsDomain[Self.CodingKeys.mentionExtension.rawValue] as? Bool {
            mentionExtension = ext
        }
        if let ext = defaultsDomain[Self.CodingKeys.checkboxExtension.rawValue] as? Bool {
            checkboxExtension = ext
        }
        if let ext = defaultsDomain[Self.CodingKeys.headsExtension.rawValue] as? Bool {
            headsExtension = ext
        }
        
        if let ext = defaultsDomain[Self.CodingKeys.hightlightExtension.rawValue] as? Bool {
            highlightExtension = ext
        }
        
        if let ext = defaultsDomain[Self.CodingKeys.syntaxHighlightExtension.rawValue] as? Bool {
            syntaxHighlightExtension = ext
        }
        
        if let characters = defaultsDomain[Self.CodingKeys.syntaxWordWrapOption.rawValue] as? Int {
            syntaxWordWrapOption = characters
        }
        if let state = defaultsDomain[Self.CodingKeys.syntaxLineNumbersOption.rawValue] as? Bool {
            syntaxLineNumbersOption = state
        }
        if let n = defaultsDomain[Self.CodingKeys.syntaxTabsOption.rawValue] as? Int {
            syntaxTabsOption = n
        }
        
        if let ext = defaultsDomain[Self.CodingKeys.subExtension.rawValue] as? Bool {
            subExtension = ext
        }
        if let ext = defaultsDomain[Self.CodingKeys.subExtension.rawValue] as? Bool {
            supExtension = ext
        }
        
        if let n = defaultsDomain[Self.CodingKeys.emojiExtension.rawValue] as? Int, let ext = EmojiMode(rawValue: n) {
            emojiExtension = ext
        }
        
        if let ext = defaultsDomain[Self.CodingKeys.inlineImageExtension.rawValue] as? Bool {
            inlineImageExtension = ext
        }
        
        if let opt = defaultsDomain[Self.CodingKeys.hardBreakOption.rawValue] as? Bool {
            hardBreakOption = opt
        }
        if let opt = defaultsDomain[Self.CodingKeys.noSoftBreakOption.rawValue] as? Bool {
            noSoftBreakOption = opt
        }
        if let opt = defaultsDomain[Self.CodingKeys.unsafeHTMLOption.rawValue] as? Bool {
            unsafeHTMLOption = opt
        }
        if let opt = defaultsDomain[Self.CodingKeys.validateUTFOption.rawValue] as? Bool {
            validateUTFOption = opt
        }
        if let opt = defaultsDomain[Self.CodingKeys.smartQuotesOption.rawValue] as? Bool {
            smartQuotesOption = opt
        }
        if let opt = defaultsDomain[Self.CodingKeys.footnotesOption.rawValue] as? Bool {
            footnotesOption = opt
        }
        
        
        if let opt = defaultsDomain[Self.CodingKeys.baseFontSize.rawValue] as? CGFloat {
            baseFontSize = opt
        }
        
        if let opt = defaultsDomain[Self.CodingKeys.customCSS.rawValue] as? String, !opt.isEmpty {
            if !opt.hasPrefix("/"), let path = Settings.stylesFolder{
                customCSS = path.appendingPathComponent(opt)
            } else {
                customCSS = URL(fileURLWithPath: opt)
            }
        }
        if let opt = defaultsDomain[Self.CodingKeys.customCSSOverride.rawValue] as? Bool {
            customCSSOverride = opt
        }
        
        if let opt = defaultsDomain[Self.CodingKeys.about.rawValue] as? Bool {
            about = opt
        }
        
        if let opt = defaultsDomain[Self.CodingKeys.debug.rawValue] as? Bool {
            debug = opt
        }
        
        if let opt = defaultsDomain[Self.CodingKeys.openInlineLink.rawValue] as? Bool {
            openInlineLink = opt
        }
        if let opt = defaultsDomain[Self.CodingKeys.renderAsCode.rawValue] as? Bool {
            renderAsCode = opt
        }
        if let opt = defaultsDomain[Self.CodingKeys.qlWindowWidth.rawValue] as? Int, opt > 0 {
            qlWindowWidth = opt
        } else {
            qlWindowWidth = nil
        }
        if let opt = defaultsDomain[Self.CodingKeys.qlWindowHeight.rawValue] as? Int, opt > 0 {
            qlWindowHeight = opt
        } else {
            qlWindowHeight = nil
        }

        sanitize()
    }
    
    /**
     * Reset the settings to the factory values.
     */
    func resetToFactory() {
        let s = Settings()
        update(from: s)
    }
    
    /**
     * Sanitize the settings.
     */
    func sanitize(allowLinkFile: Bool = false) {
        if baseFontSize < 0 {
            self.baseFontSize = 0
        }
        
        self.mathExtension.sanitize(cacheUrl: mathJaxUrl, cdnUrl: Self.mathJaxWebUrl, allowLinkFile: allowLinkFile)
        self.mermaidExtension.sanitize(cacheUrl: mermaidUrl, cdnUrl: Self.mermaidWebUrl, allowLinkFile: allowLinkFile)
    }
    
    /**
     * Get the contents of a file insie dhe Reource Bundle.
     *  - parameters:
     *    - name: Name of the resource.
     *    - ext: Extension of the resource
     */
    func getBundleContents(forResource name: String, ofType ext: String) -> String? {
        if let p = self.resourceBundle.path(forResource: name, ofType: ext), let data = FileManager.default.contents(atPath: p), let s = String(data: data, encoding: .utf8) {
            return s
        } else {
            return nil
        }
    }
    
    /**
     * Get the custom CSS code
     */
    func getCustomCSSCode() -> String? {
        guard let url = self.customCSS, url.lastPathComponent != "-" else {
            return nil
        }
        return try? String(contentsOf: url, encoding: .utf8)
    }
    
    /**
     * Install the dependencies files.
     *
     * This function create the support folders and copy from the bundle, if available, the mermaid and mathjax libraries.
     * Then copy the support files of highlight.
     */
    func installDependencies(override: Bool = false) {
        try? installDep(forResource: "mermaid.min", withExtension: "js", to: Self.mermaidCacheUrl, overwrite: override)
        try? installDep(forResource: "tex-mml-chtml", withExtension: "js", to: Self.mathJaxCacheUrl, overwrite: override)
        
        try? installDep(forResource: "highlight", withExtension: nil, to: Settings.syntaxHighlightSupportCacheUrl, overwrite: override)
    }
    
    private func installDep(forResource name: String, withExtension ext: String?, to destination: URL?, overwrite: Bool) throws {
        guard let source = self.resourceBundle.url(forResource: name, withExtension: ext) else {
            os_log(
                "Unable to store cache the file/folder %{public}s: source is missing!",
                log: OSLog.quickLookExtension,
                type: .error,
                "\(name)\(ext != nil ? "." + ext! : "")"
            )
            return
        }
        
        do {
            try installDep(from: source, to: destination, overwrite: overwrite)
        } catch {
            os_log(
                "Unable to store cache the file/folder %{public}s to %{public}s: %{public}s!",
                log: OSLog.quickLookExtension,
                type: .error,
                "\(name)\(ext != nil ? "." + ext! : "")",
                destination?.path ?? "N/D",
                error.localizedDescription
            )
            throw error
        }
    }
    
    private func installDep(from source: URL?, to destination: URL?, overwrite: Bool) throws {
        guard let source, let destination else {
            return
        }
        let fileManager = FileManager.default
        let exists = fileManager.fileExists(atPath: destination.path)
        guard overwrite || !exists else {
            return
        }
        if exists {
            try fileManager.removeItem(at: destination)
        }
        let folder = destination.deletingLastPathComponent()
            
        if !fileManager.fileExists(atPath: folder.path) {
            try fileManager.createDirectory(at: folder, withIntermediateDirectories: true, attributes: nil)
        }
        
        try fileManager.copyItem(atPath: source.path, toPath: destination.path)
    }
    
    /**
     * Download and cache a fiile from web.
     * - parameters:
     *   - source: Source url.
     *   - destination: Destination path
     *   - reply: Action to perform after the download.
     */
    static func fetchCacheFile(from source: URL, to destination: URL, withReply reply: ((Bool) -> Void)?) {
        let cacheFolderUrl = destination.deletingLastPathComponent()
        
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: cacheFolderUrl.path) {
            do {
                try FileManager.default.createDirectory(at: cacheFolderUrl, withIntermediateDirectories: true, attributes: nil)
            } catch {
                reply?(false)
                return
            }
        }
        
        let task = URLSession.shared.downloadTask(with: source) { tempURL, response, error in
            if let error = error {
                print("Unable to fetch \(source.absoluteString):", error)
                os_log("Unable to fetch %{public}s", log: OSLog.rendering, type: .error, source.absoluteString)
                reply?(false)
                return
            }
            
            guard let tempURL = tempURL else {
                print("No file downloaded")
                os_log("No file downloaded from %{public}s", log: OSLog.rendering, type: .error, source.absoluteString)
                reply?(false)
                return
            }
            
            do {
                // Rimuove se esiste già
                if fileManager.fileExists(atPath: destination.path) {
                    try fileManager.removeItem(at: destination)
                }
                
                // Sposta il file temporaneo
                try fileManager.moveItem(at: tempURL, to: destination)
                
                // print("File seved in:", mermaidCacheUrl)
                reply?(true)
            } catch {
                print("Error storing file on \(destination.path):", error)
                os_log("Error storing mermaid file on %{public}s: %{public}s", log: OSLog.rendering, type: .error, destination.path, error.localizedDescription)
                reply?(false)
            }
        }
        
        task.resume()
    }
    
}

// MARK: - Mermaid support
extension Settings {
    /// Url from which to download the mermaid library.
    static let mermaidWebUrl = URL(string: "https://cdn.jsdelivr.net/npm/mermaid/dist/mermaid.min.js")!
    
    /// Cache of the mermaid library.
    static var mermaidCacheUrl: URL? {
        return Self.jsFolder?.appendingPathComponent("mermaid.min.js")
    }
    
    /// Location of the mermaid library. Can be from the cache or from the bundle.
    var mermaidUrl: URL? {
        return Self.mermaidCacheUrl ?? self.resourceBundle.url(forResource: "mermaid.min", withExtension: "js")
    }
    
    /// Download and cache the mermaid library from web.
    func updateMemaidCache(_ reply: ((Bool) -> Void)?) {
        guard let mermaidCacheUrl = Self.mermaidCacheUrl else {
            reply?(false)
            return
        }
        Self.fetchCacheFile(from: Self.mermaidWebUrl, to: mermaidCacheUrl, withReply: reply)
    }
    
    /**
     * Check if the url is of type file and if it exists.
     * - parameters:
     *   - url: Url from fetch the librarty. If not set uses the `mermaidUrl`.
     */
    public func allowToEmbedMermaid(customUrl url: URL? = nil) -> Bool {
        guard let library = url ?? mermaidUrl else {
            return false
        }
        return library.isFileURL && FileManager.default.fileExists(atPath: library.path)
    }
    
    /**
     * Check if the url is of not a file.
     * - parameters:
     *   - url: Url from fetch the librarty. If not set uses the `mermaidUrl`.
     */
    public func allowToLinkMermaid(customUrl url: URL? = nil) -> Bool {
        guard let library = url ?? mathJaxUrl else {
            return false
        }
        return !library.isFileURL
    }
}

// MARK: - MathJax
extension Settings {
    /// Url from which to download the mermaid library.
    static let mathJaxWebUrl = URL(string: "https://cdn.jsdelivr.net/npm/mathjax/es5/tex-mml-chtml.js")!
    
    /// Cache of the mermaid library.
    static var mathJaxCacheUrl: URL? {
        return Self.jsFolder?.appendingPathComponent("tex-mml-chtml.js")
    }
    
    /// Location of the mermaid library. Can be from the cache or from the bundle.
    var mathJaxUrl: URL? {
        return Self.mathJaxCacheUrl ?? self.resourceBundle.url(forResource: "tex-mml-chtml", withExtension: "js")
    }
    
    /// Download and cache the mermaid library from web.
    func updateMathJaxUCache(_ reply: ((Bool) -> Void)?) {
        guard let mathJaxCacheUrl = Self.mathJaxCacheUrl else {
            reply?(false)
            return
        }
        Self.fetchCacheFile(from: Self.mathJaxWebUrl, to: mathJaxCacheUrl, withReply: reply)
    }
    
    /**
     * Check if the url is of type file and if it exists.
     * - parameters:
     *   - url: Url from fetch the librarty. If not set uses the `mathJaxUrl`.
     */
    public func allowToEmbedMathJax(customUrl url: URL? = nil) -> Bool {
        guard let library = url ?? mathJaxUrl else {
            return false
        }
        return library.isFileURL && FileManager.default.fileExists(atPath: library.path)
    }
    
    /**
     * Check if the url is of not a file.
     * - parameters:
     *   - url: Url from fetch the librarty. If not set uses the `mathJaxUrl`.
     */
    public func allowToLinkMathJax(customUrl url: URL? = nil) -> Bool {
        guard let library = url ?? mathJaxUrl else {
            return false
        }
        return !library.isFileURL
    }
}

// MARK: - Syntax highlight
extension Settings {
    /// Url from which to download the mermaid library.
    static var syntaxHighlightSupportCacheUrl: URL? {
        return Self.applicationSupportUrl?.appendingPathComponent("highlight")
    }
    
    /// Get the path of folder with `highlight` support files.
    func getHighlightSupportPath() -> String? {
        if let cache = Self.syntaxHighlightSupportCacheUrl, FileManager.default.fileExists(atPath: cache.path) {
            return cache.path
        }
        
        return self.resourceBundle.url(forResource: "highlight", withExtension: "")?.path
    }
}
