//
//  Settings.swift
//  QLMarkdown
//
//  Created by Sbarex on 25/12/20.
//

import Foundation
import AppKit

extension Settings {
    private static var themes: [ThemePreview]?
    private static var styles: [URL]?
    
    /// Save the settings to the defaults preferences.
    @discardableResult
    func synchronize()->Bool {
        let defaults = UserDefaults.standard
        var defaultsDomain = defaults.persistentDomain(forName: Settings.Domain) ?? [:]
        
        defaultsDomain["table"] = tableExtension
        defaultsDomain["autolink"] = autoLinkExtension
        defaultsDomain["tagfilter"] = tagFilterExtension
        defaultsDomain["tasklist"] = taskListExtension
        defaultsDomain.removeValue(forKey: "rmd")
        defaultsDomain.removeValue(forKey: "rmd_all")
        defaultsDomain["yaml"] = yamlExtension
        defaultsDomain["yaml_all"] = yamlExtensionAll
        defaultsDomain["mention"] = mentionExtension
        defaultsDomain["checkbox"] = checkboxExtension
        defaultsDomain["inlineimage"] = inlineImageExtension
        defaultsDomain["heads"] = headsExtension
        defaultsDomain["highlight"] = highlightExtension
        defaultsDomain["math"] = mathExtension
        
        defaultsDomain["strikethrough"] = strikethroughExtension
        defaultsDomain["strikethrough_doubletilde"] = strikethroughDoubleTildeOption
        
        defaultsDomain["sub"] = subExtension
        defaultsDomain["sup"] = supExtension
        
        defaultsDomain["syntax"] = syntaxHighlightExtension
        defaultsDomain["syntax_custom_themes"] = syntaxCustomThemes
        defaultsDomain["syntax_light_theme"] = syntaxThemeLight
        defaultsDomain["syntax_dark_theme"] = syntaxThemeDark
        defaultsDomain["syntax_background"] = syntaxBackgroundColor.rawValue
        defaultsDomain["syntax_light_background"] = syntaxBackgroundColorLight
        defaultsDomain["syntax_dark_background"] = syntaxBackgroundColorDark
        defaultsDomain["syntax_word_wrap"] = syntaxWordWrapOption
        defaultsDomain["syntax_line_numbers"] = syntaxLineNumbersOption
        defaultsDomain["syntax_tabs"] = syntaxTabsOption
        defaultsDomain["syntax_font_name"] = syntaxFontFamily
        defaultsDomain["syntax_font_size"] = syntaxFontSize
        
        defaultsDomain["emoji"] = emojiExtension
        defaultsDomain["emoji_image"] = emojiImageOption
        
        defaultsDomain["hardbreak"] = hardBreakOption
        defaultsDomain["nosoftbreak"] = noSoftBreakOption
        defaultsDomain["hardbreak"] = hardBreakOption
        defaultsDomain["unsafeHTML"] = unsafeHTMLOption
        defaultsDomain["validateUTF"] = validateUTFOption
        defaultsDomain["smartquote"] = smartQuotesOption
        defaultsDomain["footnote"] = footnotesOption
        defaultsDomain["guess-engine"] = guessEngine.rawValue
        
        defaultsDomain["debug"] = self.debug
        defaultsDomain["about"] = self.about
        defaultsDomain["inline-link"] = openInlineLink
        defaultsDomain["render-as-code"] = self.renderAsCode
        
        defaultsDomain["ql-window-width"] = self.qlWindowWidth ?? 0
        defaultsDomain["ql-window-height"] = self.qlWindowHeight ?? 0
        
        if self.useLegacyPreview {
            defaultsDomain["legacy-preview"] = self.useLegacyPreview
        } else {
            defaultsDomain.removeValue(forKey: "legacy-preview")
        }
        
        let file: String
        if let url = customCSS {
            if let folder = Settings.stylesFolder?.path, url.path.hasPrefix(folder) {
                file = String(url.path.dropFirst(folder.count + 1))
            } else {
                file = url.path
            }
        } else {
            file = ""
        }
        defaultsDomain["customCSS"] = file
        defaultsDomain["customCSS-override"] = customCSSOverride
        
        let userDefaults = UserDefaults()
        userDefaults.setPersistentDomain(defaultsDomain, forName: Settings.Domain)
        let r = userDefaults.synchronize()
        
        if r {
            DistributedNotificationCenter.default().post(name: .QLMarkdownSettingsUpdated, object: nil)
        }
        return r
    }
    
    func getAvailableThemes(resetCache reset: Bool = false) -> [ThemePreview] {
        if Settings.themes == nil || reset {
            Settings.themes = []
            var me = self
            // Get standalone themes.
            _ = withUnsafeMutablePointer(to: &me) { (context) in
                highlight_list_themes(context) { (context, themes, count, exit_code) in
                    /*
                    guard let context = context?.assumingMemoryBound(to: Settings.self).pointee else {
                        return
                    }
                    */
                    guard exit_code == EXIT_SUCCESS else {
                        return
                    }
                    for i in 0 ..< Int(count) {
                        guard let theme_info = themes?.advanced(by: i).pointee else {
                            continue
                        }
                        
                        var exit_code: Int32 = 0
                        var release: ReleaseTheme? = nil
                        let theme_p = highlight_get_theme2(theme_info.pointee.path, &exit_code, &release)
                        defer {
                            release?(theme_p)
                        }
                        guard exit_code == EXIT_SUCCESS, let theme = theme_p?.pointee else {
                            continue;
                        }
                        Settings.themes!.append(ThemePreview(theme: theme))
                    }
                }
            }
            // Get customized themes.
            if let url = Settings.themesFolder {
                if !FileManager.default.fileExists(atPath: url.path) {
                    try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
                }
                let dirEnum = FileManager.default.enumerator(atPath: url.path)
                while let file = dirEnum?.nextObject() as? String {
                    guard file.hasSuffix(".theme") else {
                        continue
                    }
                    var exit_code: Int32 = 0
                    var release: ReleaseTheme? = nil
                    let theme_url = url.appendingPathComponent(file)
                    let theme_p = highlight_get_theme2(theme_url.path, &exit_code, &release)
                    defer {
                        release?(theme_p)
                    }
                    guard exit_code == EXIT_SUCCESS, let theme = theme_p?.pointee else {
                        continue;
                    }
                    Settings.themes!.append(ThemePreview(theme: theme))
                }
            }
        }
        return Settings.themes!
    }
    
    func appendTheme(_ theme: ThemePreview) {
        if Settings.themes == nil {
            let _ = getAvailableThemes(resetCache: true)
        }
        Settings.themes?.append(theme)
        NotificationCenter.default.post(name: .themeDidAdded, object: theme)
    }
    
    @discardableResult
    func removeTheme(path: String) throws -> Bool {
        guard let theme = self.getAvailableThemes().first(where: { $0.path == path }) else {
            return false
        }
        return try self.removeTheme(theme)
    }
    
    @discardableResult
    func removeTheme(_ theme: ThemePreview) throws -> Bool {
        guard !theme.isStandalone else { return false }
        
        if !theme.path.isEmpty {
            let url = URL(fileURLWithPath: theme.path)
            if FileManager.default.fileExists(atPath: url.path) {
                try FileManager.default.removeItem(at: url)
            }
            if self.syntaxThemeLight == theme.path {
                self.syntaxThemeLight = ""
            }
            if self.syntaxThemeDark == theme.path {
                self.syntaxThemeDark = ""
            }
        }
        
        if let index = Settings.themes?.firstIndex(of: theme) {
            Settings.themes!.remove(at: index)
            NotificationCenter.default.post(name: .themeDidDeleted, object: theme)
            return true
        } else {
            return false
        }
        
    }
    
    func getAvailableStyles(resetCache reset: Bool = false) -> [URL] {
        if Settings.styles == nil || reset {
            Settings.styles = []
            // Get customized styles.
            if let url = Settings.stylesFolder {
                if !FileManager.default.fileExists(atPath: url.path) {
                    try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
                }
                let dirEnum = FileManager.default.enumerator(atPath: url.path)
                while let file = dirEnum?.nextObject() as? String {
                    guard file.hasSuffix(".css") else {
                        continue
                    }
                    let style = url.appendingPathComponent(file)
                    Settings.styles!.append(style)
                }
            }
        }
        return Settings.styles!
    }
}
