//
//  Settings.swift
//  QLMardown
//
//  Created by Sbarex on 13/12/20.
//

import Foundation

class Settings {
    static let Domain: String = "org.sbarex.qlmarkdown"
    
    static let shared = Settings()
    
    @objc var tableExtension: Bool = true
    @objc var autoLinkExtension: Bool = true
    @objc var tagFilterExtension: Bool = true
    @objc var taskListExtension: Bool = true
    @objc var mentionExtension: Bool = false
    @objc var checkboxExtension: Bool = false
    
    @objc var strikethroughExtension: Bool = true
    @objc var strikethroughDoubleTildeOption: Bool = false
    
    @objc var syntaxHighlightExtension: Bool = true
    @objc var syntaxThemeLight: String = ""
    @objc var syntaxBackgroundColorLight: String = ""
    @objc var syntaxThemeDark: String = ""
    @objc var syntaxBackgroundColorDark: String = ""
    
    @objc var emojiExtension: Bool = true
    @objc var emojiImageOption: Bool = false
    @objc var inlineImageExtension: Bool = false
    
    @objc var hardBreakOption: Bool = false
    @objc var noSoftBreakOption: Bool = false
    @objc var unsafeHTMLOption: Bool = false
    @objc var validateUTFOption: Bool = false
    @objc var smartQuotesOption: Bool = false
    @objc var footnotesOption: Bool = false
    
    private init() {
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
        
        sanitizeEmojiOption()
    }
    
    private func sanitizeEmojiOption() {
        if emojiExtension && emojiImageOption {
            unsafeHTMLOption = true
        }
    }
    
    /// Save the settings to the defaults preferences.
    @discardableResult
    func synchronize()->Bool {
        let defaults = UserDefaults.standard
        var defaultsDomain = defaults.persistentDomain(forName: Settings.Domain) ?? [:]
        
        defaultsDomain["table"] = tableExtension
        defaultsDomain["autolink"] = autoLinkExtension
        defaultsDomain["tagfilter"] = tagFilterExtension
        defaultsDomain["tasklist"] = taskListExtension
        defaultsDomain["strikethrough"] = strikethroughExtension
        defaultsDomain["strikethrough_doubletilde"] = strikethroughDoubleTildeOption
        defaultsDomain["mention"] = mentionExtension
        defaultsDomain["checkbox"] = checkboxExtension
        defaultsDomain["syntax"] = syntaxHighlightExtension
        defaultsDomain["syntax_light_theme"] = syntaxThemeLight
        defaultsDomain["syntax_light_background"] = syntaxBackgroundColorLight
        defaultsDomain["syntax_dark_theme"] = syntaxThemeDark
        defaultsDomain["syntax_dark_background"] = syntaxBackgroundColorDark
        defaultsDomain["emoji"] = emojiExtension
        defaultsDomain["inlineimage"] = inlineImageExtension
        defaultsDomain["emoji_image"] = emojiImageOption
        defaultsDomain["hardbreak"] = hardBreakOption
        defaultsDomain["nosoftbreak"] = noSoftBreakOption
        defaultsDomain["hardbreak"] = hardBreakOption
        defaultsDomain["unsafeHTML"] = unsafeHTMLOption
        defaultsDomain["validateUTF"] = validateUTFOption
        defaultsDomain["smartquote"] = smartQuotesOption
        defaultsDomain["footnote"] = footnotesOption
        
        let userDefaults = UserDefaults()
        userDefaults.setPersistentDomain(defaultsDomain, forName: Settings.Domain)
        let r = userDefaults.synchronize()
        return r
    }
}
