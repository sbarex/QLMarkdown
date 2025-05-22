//
//  Settings.swift
//  QLMarkdown
//
//  Created by Sbarex on 25/12/20.
//

import Foundation
import AppKit

extension Settings {
    func getAvailableThemes(resetCache reset: Bool = false) -> [ThemePreview] {
        var themes: [ThemePreview] = []
        XPCWrapper.getSynchronousService()?.getAvailableThemes(resetCache: reset) { data_themes in
            guard let data_themes = data_themes else {
                return
            }
            guard let data = try? JSONSerialization.jsonObject(with: data_themes, options: []) as? [[String: Any]] else {
                return
            }
            for t in data {
                if let tt = ThemePreview(dictionary: t) {
                    themes.append(tt)
                }
            }
        }
        
        return themes
    }
    
    func getAvailableStyles(resetCache reset: Bool = false) -> [URL] {
        var styles: [URL] = []
        XPCWrapper.getSynchronousService()?.getAvailableStyles(resetCache: reset) { urls in
            styles = urls.map({URL(fileURLWithPath: $0)})
        }
        return styles
    }
}
