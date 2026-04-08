//
//  Settings.swift
//  QLMarkdown
//
//  Created by Sbarex on 25/12/20.
//

import Foundation
import AppKit

// MARK: -
extension JSExtension {
    /**
     * Strip the url info if is the predefined value.
     */
    func stripDefaultUrl(cacheUrl: URL?, cdnUrl: URL?) -> Self {
        switch self {
        case .disabled:
            return .disabled
        case .link(let url):
            if url == cdnUrl {
                return .link(url: nil)
            } else {
                return .link(url: url)
            }
        case .embed(let url):
            if url == cacheUrl {
                return .link(url: nil)
            } else {
                return .link(url: url)
            }
        }
    }
}

// MARK: -
extension Settings {
    static var styles: [URL]? = nil
    
    /**
     * Store a new CSS style sheet into the support folder with the specified name.
     * - parameters:
     *  - name: Destinaton file name. If exists will be overwritted.
     *  - data: Contents of the CSS file.
     *
     * - Returns: Return the Url of the saved CSS file or `nil` in case of an error.
     */
    static func storeStyle(name: String, data: Data?) -> URL? {
        guard let data = data, let folder = Settings.stylesFolder else {
            return nil
        }
        
        let dst = folder.appendingPathComponent(name)
        do {
            if FileManager.default.fileExists(atPath: dst.path) {
                try FileManager.default.removeItem(at: dst)
            }
            try data.write(to: dst)
            return dst
        } catch {
            return nil
        }
    }
    
    /**
     * Get a list of available CSS style sheets.
     */
    static func getAvailableStyles(resetCache reset: Bool = false) -> [URL] {
        // Get customized styles.
        guard Self.styles == nil || reset else {
            return Self.styles!
        }
        
        guard let url = Settings.stylesFolder else {
            return []
        }
        Self.styles = []
        if !FileManager.default.fileExists(atPath: url.path) {
            try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
        }
        
        let dirEnum = FileManager.default.enumerator(atPath: url.path)
        while let file = dirEnum?.nextObject() as? String {
            guard file.hasSuffix(".css") else {
                continue
            }
            let style = url.appendingPathComponent(file)
            styles!.append(style)
        }
        
        return Self.styles ?? []
    }
    
    /**
     * Check if the url is of type file and if it exists.
     * - parameters:
     *   - url: Url from fetch the librarty. If not set uses the `mathJaxFileUrl`.
     */
    public func allowToEmbedMathJax(customUrl url: URL? = nil) -> Bool {
        guard let library = url ?? mathJaxFileUrl else {
            return false
        }
        return library.isFileURL && FileManager.default.fileExists(atPath: library.path)
    }
    
    /**
     * Check if the url is of not a file.
     * - parameters:
     *   - url: Url from fetch the librarty. If not set uses the `mathJaxFileUrl`.
     */
    public func allowToLinkMathJax(customUrl url: URL? = nil) -> Bool {
        guard let library = url ?? mathJaxFileUrl else {
            return false
        }
        return !library.isFileURL
    }
    
    public func getMathJaxFileSize() -> Int
    {
        return  (try? self.mathJaxFileUrl?.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0
    }
    
    /// Download and cache the mermaid library from web.
    func updateMathJaxUCache(_ reply: ((Bool) -> Void)?) {
        guard let mathJaxCacheFileUrl = Self.mathJaxCacheFileUrl else {
            reply?(false)
            return
        }
        Self.fetchCacheFile(from: Self.mathJaxWebUrl, to: mathJaxCacheFileUrl, withReply: reply)
    }
    
    /// Download and cache the mermaid library from web.
    func updateMemaidCache(_ reply: ((Bool) -> Void)?) {
        guard let mermaidCacheFileUrl = Self.mermaidCacheFileUrl else {
            reply?(false)
            return
        }
        Self.fetchCacheFile(from: Self.mermaidWebUrl, to: mermaidCacheFileUrl, withReply: reply)
    }
    
    /**
     * Check if the url is of type file and if it exists.
     * - parameters:
     *   - url: Url from fetch the librarty. If not set uses the `mermaidFileUrl`.
     */
    public func allowToEmbedMermaid(customUrl url: URL? = nil) -> Bool {
        guard let library = url ?? mermaidFileUrl else {
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
        guard let library = url ?? mermaidFileUrl else {
            return false
        }
        return !library.isFileURL
    }
    
    public func getMermaidFileSize() -> Int
    {
        return  (try? self.mermaidFileUrl?.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0
    }
    
    /**
     * Save the settings.
     */
    @discardableResult
    func save() -> Bool {
        guard let defaults = UserDefaults(suiteName: Self.appGroup) else {
            return false
        }
        return self.save(toUserDefaults: defaults)
    }
    
    /**
     * Save the settings to the defaults preferences.
     */
    @discardableResult
    func save(toUserDefaults defaults: UserDefaults)->Bool {
        self.sanitize(allowLinkFile: false)
        
        defaults.set(tableExtension, forKey: Self.CodingKeys.tableExtension.rawValue)
        defaults.set(autoLinkExtension, forKey: Self.CodingKeys.autoLinkExtension.rawValue)
        defaults.set(tagFilterExtension, forKey: Self.CodingKeys.tagFilterExtension.rawValue)
        defaults.set(taskListExtension, forKey: Self.CodingKeys.taskListExtension.rawValue)
        defaults.set(yamlExtension.rawValue, forKey: Self.CodingKeys.yamlExtension.rawValue)
        
        defaults.set(strikethroughExtension.rawValue, forKey: Self.CodingKeys.strikethroughExtension.rawValue)
        
        // Prevent to save the url info if is the predefined value on the math/mermaid extension.
        defaults.set(mathExtension.stripDefaultUrl(cacheUrl: self.mathJaxFileUrl, cdnUrl: Self.mathJaxWebUrl).toDict(), forKey: Self.CodingKeys.mathExtension.rawValue)
        defaults.set(mermaidExtension.stripDefaultUrl(cacheUrl: self.mermaidFileUrl, cdnUrl: Self.mermaidWebUrl).toDict(), forKey: Self.CodingKeys.mermaidExtension.rawValue)
        
        defaults.set(mentionExtension, forKey: Self.CodingKeys.mentionExtension.rawValue)
        defaults.set(checkboxExtension, forKey: Self.CodingKeys.checkboxExtension.rawValue)
        defaults.set(headsExtension, forKey: Self.CodingKeys.headsExtension.rawValue)
        
        defaults.set(highlightExtension, forKey: Self.CodingKeys.hightlightExtension.rawValue)
        
        defaults.set(syntaxHighlightExtension, forKey: Self.CodingKeys.syntaxHighlightExtension.rawValue)
        
        defaults.set(syntaxWordWrapOption, forKey: Self.CodingKeys.syntaxWordWrapOption.rawValue)
        defaults.set(syntaxLineNumbersOption, forKey: Self.CodingKeys.syntaxLineNumbersOption.rawValue)
        defaults.set(syntaxTabsOption, forKey: Self.CodingKeys.syntaxTabsOption.rawValue)
        
        defaults.set(subExtension, forKey: Self.CodingKeys.subExtension.rawValue)
        defaults.set(supExtension, forKey: Self.CodingKeys.supExtension.rawValue)
        
        defaults.set(emojiExtension.rawValue, forKey: Self.CodingKeys.emojiExtension.rawValue)
        
        defaults.set(inlineImageExtension, forKey: Self.CodingKeys.inlineImageExtension.rawValue)
        
        defaults.set(hardBreakOption, forKey: Self.CodingKeys.hardBreakOption.rawValue)
        defaults.set(noSoftBreakOption, forKey: Self.CodingKeys.noSoftBreakOption.rawValue)
        defaults.set(unsafeHTMLOption, forKey: Self.CodingKeys.unsafeHTMLOption.rawValue)
        defaults.set(validateUTFOption, forKey: Self.CodingKeys.validateUTFOption.rawValue)
        defaults.set(smartQuotesOption, forKey: Self.CodingKeys.smartQuotesOption.rawValue)
        defaults.set(footnotesOption, forKey: Self.CodingKeys.footnotesOption.rawValue)
        
        if baseFontSize > 0 {
            defaults.set(baseFontSize, forKey: Self.CodingKeys.baseFontSize.rawValue)
        } else {
            defaults.removeObject(forKey: Self.CodingKeys.baseFontSize.rawValue)
        }
        
        let file: String
        if let url = customCSS {
            if let folder = Settings.stylesFolder?.path, url.path.hasPrefix(folder) {
                file = String(url.path.dropFirst(folder.count + 1))
            } else {
                file = url.path
            }
            defaults.set(file, forKey: Self.CodingKeys.customCSS.rawValue)
        } else {
            defaults.removeObject(forKey: Self.CodingKeys.customCSS.rawValue)
        }
        defaults.set(customCSSOverride, forKey: Self.CodingKeys.customCSSOverride.rawValue)
                
        defaults.set(about, forKey: Self.CodingKeys.about.rawValue)
        defaults.set(debug, forKey: Self.CodingKeys.debug.rawValue)
        defaults.set(openInlineLink, forKey: Self.CodingKeys.openInlineLink.rawValue)
        defaults.set(renderAsCode, forKey: Self.CodingKeys.renderAsCode.rawValue)
        
        defaults.set(self.qlWindowWidth ?? 0, forKey: Self.CodingKeys.qlWindowWidth.rawValue)
        defaults.set(self.qlWindowHeight ?? 0, forKey: Self.CodingKeys.qlWindowHeight.rawValue)

        defaults.synchronize()
        
        DistributedNotificationCenter.default().post(name: .QLMarkdownSettingsUpdated, object: nil)
        
        return true
    }
}
