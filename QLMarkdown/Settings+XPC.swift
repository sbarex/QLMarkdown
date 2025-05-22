//
//  Settings+XPC.swift
//  QLMarkdown
//
//  Created by Sbarex on 09/05/25.
//

import Foundation

extension Settings {
    private static var stylesFolder: URL?
    private static var stylesFolderFetched = false
    
    class func getStylesFolder() -> URL? {
        if !stylesFolderFetched {
            XPCWrapper.getSynchronousService()?.getStylesFolder() { url in
                Self.stylesFolder = url
            }
        }
        return Self.stylesFolder
    }
    
    func getCustomCSSCode() -> String? {
        guard let url = self.customCSS, url.lastPathComponent != "-" else {
            return nil
        }
        var s: String? = nil
        XPCWrapper.getSynchronousService()?.getFileContents(url) { s = $0 }
        return s
    }
}
