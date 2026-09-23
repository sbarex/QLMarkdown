//
//  Settings.swift
//  QLMarkdown
//
//  Created by Sbarex on 13/12/20.
//

import Foundation
import OSLog
import Compression

enum CMARK_Error: Error {
    case parser_create
    case parser_parse
}

enum Appearance: Int, Codable {
    case undefined
    case light
    case dark
    
    var name: String {
        switch self {
        case .undefined:
            return "auto"
        case .light:
            return "light"
        case .dark:
            return "dark"
        }
    }
}

enum JSExtension: Int, Codable {
    case disabled = 0
    case link = 1
    case embed = 2
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

enum OverrideMode: Int {
    case never = 0
    case always = 1
    case onlyOlder = 2
}

extension NSNotification.Name {
    public static let QLMarkdownSettingsUpdated: NSNotification.Name = NSNotification.Name("org.sbarex.qlmarkdown-settings-changed")
}

// MARK: -
class Settings: Codable {
    enum CodingKeys: String, CodingKey {
        case appearance
        
        case baseFontSize
        case customCSS
        case customCSSCode
        case customCSSCodeFetched
        case customCSSOverride
        
        case admonitionExtension
        case autoLinkExtension
        case definitionListExtension
        case emojiExtension
        case alertExtension
        case mentionExtension
        case headsExtension
        case tableOfContentsOption
        case hightlightExtension
        case inlineImageExtension
        case mathExtension
        case mermaidExtension
        case subExtension
        case supExtension
        case strikethroughExtension
        case syntaxHighlightExtension
        case syntaxLineNumbersOption
        case syntaxTabsOption
        case syntaxWordWrapOption
        case tableExtension
        case tagFilterExtension
        case taskListExtension
        case wikilinkExtension
        case yamlExtension
        
        case checkboxExtension
        
        case smartQuotesOption
        case footnotesOption
        case hardBreakOption
        case noSoftBreakOption
        case unsafeHTMLOption
        case validateUTFOption
        case debug
        case renderAsCode
        
        case qlWindowWidth
        case qlWindowHeight
        
        case about
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
                title += ", version \(version) (\(build))."
            }
            title += "<br />\n"
            if let copy = info["NSHumanReadableCopyright"] as? String {
                title += copy.trimmingCharacters(in: CharacterSet(charactersIn: ". "))
            } else {
                title += "Developed by SBAREX"
            }
            
        } else {
            title += "QLMarkdown</a><br />\nDeveloped by SBAREX"
        }
        title += " with <span style='font-style: normal'>❤️</span>."
        title += "<br />\nIf you like this app, <a href='https://www.buymeacoffee.com/sbarex'><strong>buy me a coffee</strong></a>!"
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
            title += ".\n"
            if let copy = info["NSHumanReadableCopyright"] as? String {
                title += copy.trimmingCharacters(in: CharacterSet(charactersIn: ". ")) + " with ❤️"
            } else {
                title += "Developed by SBAREX with ❤️"
            }
        } else {
            title += "\nDeveloped by SBAREX with love"
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
    
    var appearance: Appearance = .undefined
    
    var baseFontSize: CGFloat = 0
    var customCSS: URL? {
        didSet {
            customCSSFetched = false
            customCSSCode = nil
        }
    }
    var customCSSFetched: Bool = false
    var customCSSCode: String?
    var customCSSOverride: Bool = false
    
    var admonitionExtension: Bool = false
    var autoLinkExtension: Bool = true
    var definitionListExtension: Bool = false
    var emojiExtension: EmojiMode = .font
    var alertExtension: Bool = false
    var mentionExtension: Bool = false
    var headsExtension: Bool = true
    var tableOfContentsOption: Bool = false
    var highlightExtension: Bool = false
    var inlineImageExtension: Bool = true
    var mathExtension: JSExtension = .link
    var mermaidExtension: JSExtension = .link
    var subExtension: Bool = false
    var supExtension: Bool = false
    var strikethroughExtension: StrikethroughMode = .single
    var syntaxHighlightExtension: Bool = true
    var syntaxLineNumbersOption: Bool = false
    var syntaxTabsOption: Int = 4
    var syntaxWordWrapOption: Int = 0
    var tableExtension: Bool = true
    var tagFilterExtension: Bool = true
    var taskListExtension: Bool = true
    var wikilinkExtension: Bool = false
    var yamlExtension: YamlMode = .allFiles
    
    var checkboxExtension: Bool = false
    
    var smartQuotesOption: Bool = true
    var footnotesOption: Bool = true
    var hardBreakOption: Bool = false
    var noSoftBreakOption: Bool = false
    var unsafeHTMLOption: Bool = true
    var validateUTFOption: Bool = false
    /// Show debug infomations.
    var debug: Bool = false
    var renderAsCode: Bool = false
    
    /// Quick Look window width.
    var qlWindowWidth: Int? = nil
    /// Quick Look window height.
    var qlWindowHeight: Int? = nil
    /// Width used when the style does not declare a content column.
    static let defaultQLWindowWidth: CGFloat = 960
    /// Height suggested to Quick Look. The preview scrolls if the content is longer.
    static let defaultQLWindowHeight: CGFloat = 1000
    /// Width used in `Render as code` mode, where the source is not laid out in a column.
    static let defaultQLWindowWidthAsCode: CGFloat = 1400
    /// Quick Look window size.
    /// Without a suggestion macOS opens a window as big as the screen.
    var qlWindowSize: CGSize {
        if let w = qlWindowWidth, w > 0, let h = qlWindowHeight, h > 0 {
            return CGSize(width: CGFloat(w), height: CGFloat(h))
        } else {
            return self.autoQLWindowSize
        }
    }
    
    /// Size used when no custom size is set. Fitted to the content column of the style in use.
    var autoQLWindowSize: CGSize {
        if let column = self.contentColumnWidth {
            return CGSize(width: column + 58, height: Self.defaultQLWindowHeight) // gutters and scroller
        } else if self.renderAsCode {
            return CGSize(width: Self.defaultQLWindowWidthAsCode, height: Self.defaultQLWindowHeight)
        } else {
            return CGSize(width: Self.defaultQLWindowWidth, height: Self.defaultQLWindowHeight)
        }
    }
    
    /// Show the informative message on the footer.
    var about: Bool = true
    
    lazy fileprivate(set) var resourceBundle: Bundle = {
        return Self.getResourceBundle()
    }()
    
    static func decode<T: Decodable>(from container: KeyedDecodingContainer<Settings.CodingKeys>, forKey key: Settings.CodingKeys, defaultValue: T) -> T {
        
        do {
            return try container.decodeIfPresent(T.self, forKey: key) ?? defaultValue
        } catch {
            return defaultValue
        }
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.appearance = Settings.decode(from: container, forKey: .appearance, defaultValue: Settings.factorySettings.appearance)
        
        self.baseFontSize = Settings.decode(from: container, forKey: .baseFontSize, defaultValue: Settings.factorySettings.baseFontSize)
        self.customCSS = Settings.decode(from: container, forKey: .customCSS, defaultValue: Settings.factorySettings.customCSS)
        self.customCSSFetched = Settings.decode(from: container, forKey: .customCSSCodeFetched, defaultValue: Settings.factorySettings.customCSSFetched)
        self.customCSSCode = Settings.decode(from: container, forKey: .customCSSCode, defaultValue: Settings.factorySettings.customCSSCode)
        self.customCSSOverride = Settings.decode(from: container, forKey: .customCSSOverride, defaultValue: Settings.factorySettings.customCSSOverride)
        
        self.admonitionExtension = Settings.decode(from: container, forKey: .admonitionExtension, defaultValue: Settings.factorySettings.admonitionExtension)
        self.autoLinkExtension = Settings.decode(from: container, forKey: .autoLinkExtension, defaultValue: Settings.factorySettings.autoLinkExtension)
        self.definitionListExtension = Settings.decode(from: container, forKey: .definitionListExtension, defaultValue: Settings.factorySettings.definitionListExtension)
        self.emojiExtension = Settings.decode(from: container, forKey:.emojiExtension, defaultValue: Settings.factorySettings.emojiExtension)
        self.alertExtension = Settings.decode(from: container, forKey:.alertExtension, defaultValue: Settings.factorySettings.alertExtension)
        self.mentionExtension = Settings.decode(from: container, forKey:.mentionExtension, defaultValue: Settings.factorySettings.mentionExtension)
        self.headsExtension = Settings.decode(from: container, forKey:.headsExtension, defaultValue: Settings.factorySettings.headsExtension)
        self.tableOfContentsOption = Settings.decode(from: container, forKey: .tableOfContentsOption, defaultValue: Settings.factorySettings.tableOfContentsOption)
        self.highlightExtension = Settings.decode(from: container, forKey: .hightlightExtension, defaultValue: Settings.factorySettings.highlightExtension)
        self.inlineImageExtension = Settings.decode(from: container, forKey:.inlineImageExtension, defaultValue: Settings.factorySettings.inlineImageExtension)
        self.mathExtension = Settings.decode(from: container, forKey:.mathExtension, defaultValue: Settings.factorySettings.mathExtension)
        self.mermaidExtension = Settings.decode(from: container, forKey:.mermaidExtension, defaultValue: Settings.factorySettings.mermaidExtension)
        self.subExtension = Settings.decode(from: container, forKey:.subExtension, defaultValue: Settings.factorySettings.subExtension)
        self.supExtension = Settings.decode(from: container, forKey:.supExtension, defaultValue: Settings.factorySettings.supExtension)
        self.strikethroughExtension = Settings.decode(from: container, forKey:.strikethroughExtension, defaultValue: Settings.factorySettings.strikethroughExtension)
        self.syntaxHighlightExtension = Settings.decode(from: container, forKey: .syntaxHighlightExtension, defaultValue: Settings.factorySettings.syntaxHighlightExtension)
        self.syntaxLineNumbersOption = Settings.decode(from: container, forKey: .syntaxLineNumbersOption, defaultValue: Settings.factorySettings.syntaxLineNumbersOption)
        self.syntaxTabsOption = Settings.decode(from: container, forKey: .syntaxTabsOption, defaultValue: Settings.factorySettings.syntaxTabsOption)
        self.syntaxWordWrapOption = Settings.decode(from: container, forKey: .syntaxWordWrapOption, defaultValue: Settings.factorySettings.syntaxWordWrapOption)
        self.tableExtension = Settings.decode(from: container, forKey: .tableExtension, defaultValue: Settings.factorySettings.tableExtension)
        self.tagFilterExtension = Settings.decode(from: container, forKey: .tagFilterExtension, defaultValue: Settings.factorySettings.tagFilterExtension)
        self.taskListExtension = Settings.decode(from: container, forKey: .taskListExtension, defaultValue: Settings.factorySettings.taskListExtension)
        self.wikilinkExtension = Settings.decode(from: container, forKey:.wikilinkExtension, defaultValue: Settings.factorySettings.wikilinkExtension)
        self.yamlExtension = Settings.decode(from: container, forKey: .yamlExtension, defaultValue: Settings.factorySettings.yamlExtension)
        
        self.checkboxExtension = Settings.decode(from: container, forKey:.checkboxExtension, defaultValue: Settings.factorySettings.checkboxExtension)
        
        self.smartQuotesOption = Settings.decode(from: container, forKey: .smartQuotesOption, defaultValue: Settings.factorySettings.smartQuotesOption)
        self.footnotesOption = Settings.decode(from: container, forKey: .footnotesOption, defaultValue: Settings.factorySettings.footnotesOption)
        self.hardBreakOption = Settings.decode(from: container, forKey: .hardBreakOption, defaultValue: Settings.factorySettings.hardBreakOption)
        self.noSoftBreakOption = Settings.decode(from: container, forKey: .noSoftBreakOption, defaultValue: Settings.factorySettings.noSoftBreakOption)
        self.unsafeHTMLOption = Settings.decode(from: container, forKey: .unsafeHTMLOption, defaultValue: Settings.factorySettings.unsafeHTMLOption)
        self.validateUTFOption = Settings.decode(from: container, forKey: .validateUTFOption, defaultValue: Settings.factorySettings.validateUTFOption)
        self.debug = Settings.decode(from: container, forKey: .debug, defaultValue: Settings.factorySettings.debug)
        self.renderAsCode = Settings.decode(from: container, forKey: .renderAsCode, defaultValue: Settings.factorySettings.renderAsCode)
                
        self.qlWindowWidth = Settings.decode(from: container, forKey: .qlWindowWidth, defaultValue: Settings.factorySettings.qlWindowWidth)
        self.qlWindowHeight = Settings.decode(from: container, forKey: .qlWindowHeight, defaultValue: Settings.factorySettings.qlWindowHeight)
        
        self.about = Settings.decode(from: container, forKey: .about, defaultValue: Settings.factorySettings.about)
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
        
        try container.encode(self.appearance, forKey: .appearance)
        
        try container.encode(self.baseFontSize, forKey: .baseFontSize)
        try container.encode(self.customCSS, forKey: .customCSS)
        try container.encode(self.customCSSCode, forKey: .customCSSCode)
        try container.encode(self.customCSSFetched, forKey: .customCSSCodeFetched)
        try container.encode(self.customCSSOverride, forKey: .customCSSOverride)
        
        try container.encode(self.admonitionExtension, forKey: .admonitionExtension)
        try container.encode(self.autoLinkExtension, forKey: .autoLinkExtension)
        try container.encode(self.definitionListExtension, forKey: .definitionListExtension)
        try container.encode(self.emojiExtension, forKey: .emojiExtension)
        try container.encode(self.alertExtension, forKey: .alertExtension)
        try container.encode(self.mentionExtension, forKey: .mentionExtension)
        try container.encode(self.headsExtension, forKey: .headsExtension)
        try container.encode(self.tableOfContentsOption, forKey: .tableOfContentsOption)
        try container.encode(self.highlightExtension, forKey: .hightlightExtension)
        try container.encode(self.inlineImageExtension, forKey: .inlineImageExtension)
        try container.encode(self.mathExtension, forKey: .mathExtension)
        try container.encode(self.mermaidExtension, forKey: .mermaidExtension)
        try container.encode(self.subExtension, forKey: .subExtension)
        try container.encode(self.supExtension, forKey: .supExtension)
        try container.encode(self.strikethroughExtension, forKey: .strikethroughExtension)
        try container.encode(self.syntaxHighlightExtension, forKey: .syntaxHighlightExtension)
        try container.encode(self.syntaxLineNumbersOption, forKey: .syntaxLineNumbersOption)
        try container.encode(self.syntaxTabsOption, forKey: .syntaxTabsOption)
        try container.encode(self.syntaxWordWrapOption, forKey: .syntaxWordWrapOption)
        try container.encode(self.tableExtension, forKey: .tableExtension)
        try container.encode(self.tagFilterExtension, forKey: .tagFilterExtension)
        try container.encode(self.taskListExtension, forKey: .taskListExtension)
        try container.encode(self.wikilinkExtension, forKey: .wikilinkExtension)
        try container.encode(self.yamlExtension, forKey: .yamlExtension)
    
        try container.encode(self.checkboxExtension, forKey: .checkboxExtension)
        
        try container.encode(self.smartQuotesOption, forKey: .smartQuotesOption)
        try container.encode(self.footnotesOption, forKey: .footnotesOption)
        try container.encode(self.hardBreakOption, forKey: .hardBreakOption)
        try container.encode(self.noSoftBreakOption, forKey: .noSoftBreakOption)
        try container.encode(self.unsafeHTMLOption, forKey: .unsafeHTMLOption)
        try container.encode(self.validateUTFOption, forKey: .validateUTFOption)
        try container.encode(self.debug, forKey: .debug)
        try container.encode(self.renderAsCode, forKey: .renderAsCode)
        
        try container.encode(self.qlWindowWidth, forKey: .qlWindowWidth)
        try container.encode(self.qlWindowHeight, forKey: .qlWindowHeight)
        
        try container.encode(self.about, forKey: .about)
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
        self.appearance = s.appearance
        
        self.baseFontSize = s.baseFontSize
        self.customCSS = s.customCSS
        self.customCSSCode = s.customCSSCode
        self.customCSSFetched = s.customCSSFetched
        self.customCSSOverride = s.customCSSOverride
        
        self.admonitionExtension = s.admonitionExtension
        self.autoLinkExtension = s.autoLinkExtension
        self.definitionListExtension = s.definitionListExtension
        self.emojiExtension = s.emojiExtension
        self.alertExtension = s.alertExtension
        self.mentionExtension = s.mentionExtension
        self.headsExtension = s.headsExtension
        self.tableOfContentsOption = s.tableOfContentsOption
        self.highlightExtension = s.highlightExtension
        self.inlineImageExtension = s.inlineImageExtension
        self.mathExtension = s.mathExtension
        self.mermaidExtension = s.mermaidExtension
        self.subExtension = s.subExtension
        self.supExtension = s.supExtension
        self.strikethroughExtension = s.strikethroughExtension
        self.syntaxHighlightExtension = s.syntaxHighlightExtension
        self.syntaxLineNumbersOption = s.syntaxLineNumbersOption
        self.syntaxTabsOption = s.syntaxTabsOption
        self.syntaxWordWrapOption = s.syntaxWordWrapOption
        self.tableExtension = s.tableExtension
        self.tagFilterExtension = s.tagFilterExtension
        self.taskListExtension = s.taskListExtension
        self.wikilinkExtension = s.wikilinkExtension
        self.yamlExtension = s.yamlExtension
        
        self.checkboxExtension = s.checkboxExtension
        
        self.smartQuotesOption = s.smartQuotesOption
        self.footnotesOption = s.footnotesOption
        self.hardBreakOption = s.hardBreakOption
        self.noSoftBreakOption = s.noSoftBreakOption
        self.unsafeHTMLOption = s.unsafeHTMLOption
        self.validateUTFOption = s.validateUTFOption
        self.debug = s.debug
        self.renderAsCode = s.renderAsCode
                
        self.qlWindowWidth = s.qlWindowWidth
        self.qlWindowHeight = s.qlWindowHeight
        
        self.about = s.about
    }
    
    /**
     * Update settings based on other settings provided from a UserDefaults dictionary.
     */
    func update(from defaultsDomain: [String: Any]) {
        if let n = defaultsDomain[Self.CodingKeys.appearance.rawValue] as? Int, let state = Appearance(rawValue: n) {
            appearance = state
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
        
        if let ext = defaultsDomain[Self.CodingKeys.admonitionExtension.rawValue] as? Bool {
            admonitionExtension = ext
        }
        if let ext = defaultsDomain[Self.CodingKeys.autoLinkExtension.rawValue] as? Bool {
            autoLinkExtension = ext
        }
        if let ext = defaultsDomain[Self.CodingKeys.definitionListExtension.rawValue] as? Bool {
            definitionListExtension = ext
        }
        if let n = defaultsDomain[Self.CodingKeys.emojiExtension.rawValue] as? Int, let ext = EmojiMode(rawValue: n) {
            emojiExtension = ext
        }
        if let ext = defaultsDomain[Self.CodingKeys.alertExtension.rawValue] as? Bool {
            alertExtension = ext
        }
        if let ext = defaultsDomain[Self.CodingKeys.mentionExtension.rawValue] as? Bool {
            mentionExtension = ext
        }
        if let ext = defaultsDomain[Self.CodingKeys.headsExtension.rawValue] as? Bool {
            headsExtension = ext
        }
        if let opt = defaultsDomain[Self.CodingKeys.tableOfContentsOption.rawValue] as? Bool {
            tableOfContentsOption = opt
        }
        if let ext = defaultsDomain[Self.CodingKeys.hightlightExtension.rawValue] as? Bool {
            highlightExtension = ext
        }
        if let ext = defaultsDomain[Self.CodingKeys.inlineImageExtension.rawValue] as? Bool {
            inlineImageExtension = ext
        }
        if let ext = defaultsDomain[Self.CodingKeys.mathExtension.rawValue] as? Int, let e = JSExtension(rawValue: ext) {
            mathExtension = e
        }
        if let ext = defaultsDomain[Self.CodingKeys.mermaidExtension.rawValue] as? Int, let e = JSExtension(rawValue: ext) {
            mermaidExtension = e
        }
        if let ext = defaultsDomain[Self.CodingKeys.subExtension.rawValue] as? Bool {
            subExtension = ext
        }
        if let ext = defaultsDomain[Self.CodingKeys.subExtension.rawValue] as? Bool {
            supExtension = ext
        }
        if let n = defaultsDomain[Self.CodingKeys.strikethroughExtension.rawValue] as? Int, let ext = StrikethroughMode(rawValue: n) {
            strikethroughExtension = ext
        }
        if let ext = defaultsDomain[Self.CodingKeys.syntaxHighlightExtension.rawValue] as? Bool {
            syntaxHighlightExtension = ext
        }
        if let state = defaultsDomain[Self.CodingKeys.syntaxLineNumbersOption.rawValue] as? Bool {
            syntaxLineNumbersOption = state
        }
        if let n = defaultsDomain[Self.CodingKeys.syntaxTabsOption.rawValue] as? Int {
            syntaxTabsOption = n
        }
        if let characters = defaultsDomain[Self.CodingKeys.syntaxWordWrapOption.rawValue] as? Int {
            syntaxWordWrapOption = characters
        }
        if let ext = defaultsDomain[Self.CodingKeys.tableExtension.rawValue] as? Bool {
            tableExtension = ext
        }
        if let ext = defaultsDomain[Self.CodingKeys.tagFilterExtension.rawValue] as? Bool {
            tagFilterExtension = ext
        }
        if let ext = defaultsDomain[Self.CodingKeys.taskListExtension.rawValue] as? Bool {
            taskListExtension = ext
        }
        if let ext = defaultsDomain[Self.CodingKeys.wikilinkExtension.rawValue] as? Bool {
            wikilinkExtension = ext
        }
        if let n = defaultsDomain[Self.CodingKeys.yamlExtension.rawValue] as? Int, let ext = YamlMode(rawValue: n) {
            yamlExtension = ext
        }
        
        if let ext = defaultsDomain[Self.CodingKeys.checkboxExtension.rawValue] as? Bool {
            checkboxExtension = ext
        }
        
        if let opt = defaultsDomain[Self.CodingKeys.smartQuotesOption.rawValue] as? Bool {
            smartQuotesOption = opt
        }
        if let opt = defaultsDomain[Self.CodingKeys.footnotesOption.rawValue] as? Bool {
            footnotesOption = opt
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
        if let opt = defaultsDomain[Self.CodingKeys.debug.rawValue] as? Bool {
            debug = opt
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
        
        if let opt = defaultsDomain[Self.CodingKeys.about.rawValue] as? Bool {
            about = opt
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
    
    @discardableResult
    func sanitize(allowLinkFile: Bool = false) -> Bool {
        var messages: [String] = []
        let r = sanitize(allowLinkFile: allowLinkFile, messages: &messages)
        messages.forEach({ print($0) })
        return r
    }
    
    /**
     * Sanitize the settings.
     * - parameters:
     *   - allowLinkFile: allow to link local file for the JSExtension properties
     *   - messages: Filled with a list of error messages.
     */
    @discardableResult
    func sanitize(allowLinkFile: Bool = false, messages: inout [String]) -> Bool {
        messages = []

        if baseFontSize < 0 {
            self.baseFontSize = 0
        }
        
        return checkValid(messages: &messages)
    }
    
    func checkValid() -> Bool {
        var messages: [String] = []
        return checkValid(messages: &messages)
    }
    
    func checkValid(messages: inout [String]) -> Bool {
        var valid = true
        
        if self.subExtension && self.strikethroughExtension == .single {
            messages.append(NSLocalizedString("The Sub extension is incompatibile with the Strikethrough extension when recognize a single tile (~).", comment: ""))
            valid = false
        }
        
        if self.supExtension && self.footnotesOption {
            messages.append(NSLocalizedString("The Sup extension can cause corrupted output when the Footnotes option is set.", comment: ""))
            valid = false
        }
        
        return valid
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
     * Get the style sheets applied to the rendered document, in cascade order.
     * The bundled `default.css` is used only in Markdown mode. The custom style is emitted last.
     */
    func getAppliedCSS() -> (bundled: String?, custom: String) {
        let custom = (self.customCSSFetched ? self.customCSSCode : self.getCustomCSSCode()) ?? ""
        let useBundled = !self.renderAsCode && (custom.isEmpty || !self.customCSSOverride)
        return (useBundled ? self.getBundleContents(forResource: "default", ofType: "css") : nil, custom)
    }
    
    /// Width of the column used by the style to lay out the content. `nil` if no style declares it.
    var contentColumnWidth: CGFloat? {
        let css = self.getAppliedCSS()
        // The custom style is emitted after the bundled one, so its declaration wins.
        return parseContentColumnWidth(css.custom) ?? parseContentColumnWidth(css.bundled)
    }
    
    /// Read the `--content-max-width` property. As in the cascade, the last declaration wins.
    private func parseContentColumnWidth(_ css: String?) -> CGFloat? {
        let pattern = #"--content-max-width\s*:\s*([0-9]+(?:\.[0-9]+)?)px"#
        guard let css, let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return nil
        }
        guard let match = regex.matches(in: css, options: [], range: NSRange(css.startIndex..., in: css)).last,
              let value = Range(match.range(at: 1), in: css).flatMap({ Double(css[$0]) }),
              value > 0
        else {
            return nil
        }
        return CGFloat(value)
    }
    
    /**
     * Install the dependencies files.
     *
     * This function create the support folders and copy from the bundle, if available, the mermaid and mathjax libraries.
     * Then copy the support files of highlight.
     */
    func installDependencies(override: OverrideMode = .never) {
        try? installDep(forResource: "highlight", withExtension: nil, to: Settings.syntaxHighlightSupportCacheUrl, overwrite: override)
    }
    
    private func installDep(forResource name: String, withExtension ext: String?, to destination: URL?, overwrite: OverrideMode) throws {
        guard let source = self.resourceBundle.url(forResource: name, withExtension: ext) else {
            os_log(
                "Unable to store cache the file/folder %{public}s: source is missing on the app bundle!",
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
    
    private func installDep(from source: URL?, to destination: URL?, overwrite: OverrideMode) throws {
        guard let source, let destination else {
            return
        }
        let fileManager = FileManager.default
        var isDirectory: ObjCBool = false
        
        let exists = fileManager.fileExists(atPath: destination.path, isDirectory: &isDirectory)
        guard overwrite != .never || !exists else {
            return
        }
        guard overwrite != .always else {
            if exists {
                // Remove original file/folder
                try fileManager.removeItem(at: destination)
            }
            let folder = destination.deletingLastPathComponent()
            
            if !fileManager.fileExists(atPath: folder.path) {
                // Create the destination folder
                try fileManager.createDirectory(at: folder, withIntermediateDirectories: true, attributes: nil)
            }
            
            try fileManager.copyItem(atPath: source.path, toPath: destination.path)
            return
        }
        
        if isDirectory.boolValue {
            if !fileManager.fileExists(atPath: destination.path) {
                // Create the destination folder
                try fileManager.createDirectory(
                    at: destination,
                    withIntermediateDirectories: true
                )
            }
            
            let contents = try fileManager.contentsOfDirectory(
                at: source,
                includingPropertiesForKeys: nil
            )
            
            for item in contents {
                let target = destination.appendingPathComponent(
                    item.lastPathComponent
                )
                
                try installDep(
                    from: item,
                    to: target,
                    overwrite: overwrite
                )
            }
        } else {
            if exists && overwrite == .onlyOlder {
                let srcValues = try source.resourceValues(
                    forKeys: [.contentModificationDateKey]
                )
                
                let dstValues = try destination.resourceValues(
                    forKeys: [.contentModificationDateKey]
                )
                
                let srcDate = srcValues.contentModificationDate ?? .distantPast
                let dstDate = dstValues.contentModificationDate ?? .distantPast
                
                guard srcDate > dstDate else {
                    // The destination file is newer than the original.
                    return
                }
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
    }
    
    static func decompressFile(_ file: URL, to destination: URL, hash: String?) throws -> Bool {
        let zData = try Data(contentsOf: file)
        let data = try gunzip(zData)
        if let hash {
            let dataHash: String = sha384OfData(data)
            guard dataHash == hash else {
                os_log(
                    "Decompressed data from %{public}@ has an invalid hash!",
                    log: OSLog.quickLookExtension,
                    type: .error,
                    file.path
                )
                
                return false
            }
        }
        try data.write(to: destination)
        
        os_log(
            "File %{public}@ decompressed to %{public}@",
            log: OSLog.quickLookExtension,
            type: .debug,
            file.path, destination.path
        )
        return true
    }
    
    static func checkHashOfFile(_ file: URL, hash: String) -> Bool {
        guard let data = try? Data(contentsOf: file) else {
            return false
        }
        let dataHash: String = sha384OfData(data)
        return hash == dataHash
    }
    
    func getDecopressedDep(name: String, hash: String) -> URL? {
        let tmpFile = FileManager.default.temporaryDirectory.appendingPathComponent(name)
        
        if FileManager.default.fileExists(atPath: tmpFile.path) {
            if Settings.checkHashOfFile(tmpFile, hash: hash) {
                // File exists and hash is correct.
                os_log(
                    "File %{public}@ already decompressed in %{public}@",
                    log: OSLog.quickLookExtension,
                    type: .debug,
                    name, tmpFile.path
                )
                return tmpFile
            } else {
                // Invalid hash!
                os_log(
                    "Invalid hash detected for decompressed file %{public}@",
                    log: OSLog.quickLookExtension,
                    type: .error,
                    tmpFile.path
                )
                try? FileManager.default.removeItem(at: tmpFile)
            }
        }
        
        // Try to decompress the bundled file
        if let url = self.resourceBundle.url(forResource: name, withExtension: "gz") {
            do {
                if try Settings.decompressFile(url, to: tmpFile, hash: hash) {
                    return tmpFile
                }
            } catch {
                os_log(
                    "Unable to decompress file %{public}@ to %{public}@: %{public}@",
                    log: OSLog.quickLookExtension,
                    type: .error,
                    url.path, tmpFile.path, error.localizedDescription
                )
            }
        }
        
        // Try to return the uncompressd bundled file.
        let s = name as NSString
        let ext = s.pathExtension
        let name = s.deletingPathExtension
        
        return self.resourceBundle.url(forResource: name, withExtension: ext)
    }
}

// MARK: - External link policy
extension Settings {
    /// Schemes a previewed document may hand to the system without asking. Everything else
    /// (smb://, ssh://, vnc://, third-party app schemes) can act on the user's behalf in another
    /// application, so it needs explicit confirmation.
    static let allowedExternalSchemes: Set<String> = ["http", "https", "mailto"]

    static func isExternalSchemeAllowed(_ url: URL) -> Bool {
        guard let scheme = url.scheme?.lowercased() else {
            return false
        }
        return allowedExternalSchemes.contains(scheme)
    }
}

// MARK: - Mermaid support
extension Settings {
    static let mermaidVersion = "12.0.0"
    /// Url from which to download the mermaid library.
    static let mermaidWebUrl = URL(string: "https://cdn.jsdelivr.net/npm/mermaid@\(Settings.mermaidVersion)/dist/mermaid.min.js")!
    static let mermaidHash = "sha384-xzghz1GQ5u9HCpVskeDPqMsdogD1yvuMQbEK53+wi+G70+6J1AG0L2cfi9PHjDWI" // https://srihash.org/
    
    /// Location of the Mermaid library file.
    var mermaidFileUrl: URL? {
        return self.getDecopressedDep(name: "mermaid.min.js", hash: Settings.mermaidHash)
    }
    
    /// - parameters:
    ///   - nonce: CSP nonce of the page (see `getCompleteHTML`); scripts without it are blocked.
    func getMermaidScriptCode(nonce: String) -> String {
        guard self.mermaidExtension != .disabled else {
            return ""
        }
        let code1 = """
<script type="text/javascript" nonce="\(nonce)">
mermaid.initialize({
    startOnLoad: true,
    theme: window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'default',
    securityLevel: 'strict'
});
</script>
"""
        if self.mermaidExtension == .embed, let url = self.mermaidFileUrl, let code = try? String(contentsOfFile: url.path, encoding: .utf8) {
            return "<script nonce=\"\(nonce)\">\n\(code)\n</script>\n\(code1)\n"
        }
        return "<script  nonce=\"\(nonce)\" src=\"\(Settings.mermaidWebUrl)\" integrity=\"\(Settings.mermaidHash)\" crossorigin=\"anonymous\"></script>\n\(code1)\n"
    }
}

// MARK: - MathJax
extension Settings {
    static let mathJaxVersion = "4.1.3"
    /// Url from which to download the mermaid library.
    static let mathJaxWebUrl = URL(string: "https://cdn.jsdelivr.net/npm/mathjax@\(Settings.mathJaxVersion)/tex-mml-chtml.js")!
    static let mathJaxHash = "sha384-OrHfGTnIbkl0do3N76qW/uWr38o91N05sbSPuYBPLH+hG8X/dNSrjZf3AGjzrCwC"
    
    /// Location of the Math library file.
    var mathJaxFileUrl: URL? {
        return self.getDecopressedDep(name: "tex-mml-chtml.js", hash: Settings.mathJaxHash)
    }
    
    /// - parameters:
    ///   - nonce: CSP nonce of the page (see `getCompleteHTML`); scripts without it are blocked.
    func getMathScriptCode(nonce: String) -> String {
        guard self.mathExtension != .disabled else {
            return ""
        }
        if self.mathExtension == .embed, let url = self.mathJaxFileUrl, let code = try? String(contentsOfFile: url.path, encoding: .utf8) {
            return "<script id='MathJax-script' nonce=\"\(nonce)\">\n\(code)\n</script>\n"
        }
        return "<script id='MathJax-script' nonce=\"\(nonce)\" src=\"\(Settings.mathJaxWebUrl)\" integrity=\"\(Settings.mathJaxHash)\" crossorigin=\"anonymous\" async></script>\n"
    }
}

// MARK: - Syntax highlight
extension Settings {
    /// Url from which to download the `highlight` support files.
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
