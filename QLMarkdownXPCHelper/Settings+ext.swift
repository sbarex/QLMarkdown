//
//  Settings+ext.swift
//  QLMarkdown
//
//  Created by Sbarex on 09/05/25.
//

import Foundation

extension Settings {
    convenience init(fromUserDefaults defaults: UserDefaults) {
        self.init()
        update(from: defaults.dictionaryRepresentation())
    }
    
    class var stylesFolder: URL? {
        return Settings.applicationSupportUrl?.appendingPathComponent("themes")
    }
    
    class var themesFolder: URL? {
        return Settings.applicationSupportUrl?.appendingPathComponent("syntax-highlight-color-schemes")
    }
    
    /// Save the settings to the defaults preferences.
    @discardableResult
    func save(toUserDefaults defaults: UserDefaults = .standard)->Bool {
        defaults.set(tableExtension, forKey: "table")
        defaults.set(autoLinkExtension, forKey: "autolink")
        defaults.set(tagFilterExtension, forKey: "tagfilter")
        defaults.set(taskListExtension, forKey: "tasklist")
        defaults.removeObject(forKey: "rmd")
        defaults.removeObject(forKey: "rmd_all")
        defaults.set(yamlExtension, forKey: "yaml")
        defaults.set(yamlExtensionAll, forKey: "yaml_all")
        defaults.set(mentionExtension, forKey: "mention")
        defaults.set(checkboxExtension, forKey: "checkbox")
        defaults.set(inlineImageExtension, forKey: "inlineimage")
        defaults.set(headsExtension, forKey: "heads")
        defaults.set(highlightExtension, forKey: "highlight")
        defaults.set(mathExtension, forKey: "math")
        
        defaults.set(strikethroughExtension, forKey: "strikethrough")
        defaults.set(strikethroughDoubleTildeOption, forKey: "strikethrough_doubletilde")
        
        defaults.set(subExtension, forKey: "sub")
        defaults.set(supExtension, forKey: "sup")
        
        defaults.set(syntaxHighlightExtension, forKey: "syntax")
        defaults.set(syntaxWordWrapOption, forKey: "syntax_word_wrap")
        defaults.set(syntaxLineNumbersOption, forKey: "syntax_line_numbers")
        defaults.set(syntaxTabsOption, forKey: "syntax_tabs")
        defaults.set(syntaxFontFamily, forKey: "syntax_font_name")
        defaults.set(syntaxFontSize, forKey: "syntax_font_size")
        
        defaults.set(emojiExtension, forKey: "emoji")
        defaults.set(emojiImageOption, forKey: "emoji_image")
        
        defaults.set(hardBreakOption, forKey: "hardbreak")
        defaults.set(noSoftBreakOption, forKey: "nosoftbreak")
        defaults.set(hardBreakOption, forKey: "hardbreak")
        defaults.set(unsafeHTMLOption, forKey: "unsafeHTML")
        defaults.set(validateUTFOption, forKey: "validateUTF")
        defaults.set(smartQuotesOption, forKey: "smartquote")
        defaults.set(footnotesOption, forKey: "footnote")
        defaults.set(guessEngine.rawValue, forKey: "guess-engine")
        
        defaults.set(debug, forKey: "debug")
        defaults.set(about, forKey: "about")
        defaults.set(openInlineLink, forKey: "inline-link")
        defaults.set(renderAsCode, forKey: "render-as-code")
        
        defaults.set(self.qlWindowWidth ?? 0, forKey: "ql-window-width")
        defaults.set(self.qlWindowHeight ?? 0, forKey: "ql-window-height")
        
        if self.useLegacyPreview {
            defaults.set(useLegacyPreview, forKey: "legacy-preview")
        } else {
            defaults.removeObject(forKey: "legacy-preview")
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
        defaults.set(file, forKey: "customCSS")
        defaults.set(customCSSOverride, forKey: "customCSS-override")
        
        let r = defaults.synchronize()
        return r
    }
}
