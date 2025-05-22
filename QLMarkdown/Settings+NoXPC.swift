//
//  Settings+NoXPC.swift
//  QLMarkdown
//
//  Created by Sbarex on 09/05/25.
//

import Foundation

extension Settings {
    static func isSandboxed() -> Bool {
        guard let task = SecTaskCreateFromSelf(nil) else { return false }
        let key = "com.apple.security.app-sandbox" as CFString
        if let value = SecTaskCopyValueForEntitlement(task, key, nil) {
            return (value as? Bool) == true
        }
        return false
    }
    
    class var applicationSupportUrl: URL? {
        // FIXME: questo codice non deve essere eseguito perchè crea un avviso di accesso
        
        if Self.isSandboxed() {
            return FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
        } else {
            return FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?.appendingPathComponent("QLMarkdown")
        }
    }
    
    class func getStylesFolder() -> URL? {
        return Settings.applicationSupportUrl?.appendingPathComponent("themes")
    }
    
    func getCustomCSSCode() -> String? {
        guard let url = self.customCSS, url.lastPathComponent != "-" else {
            return nil
        }
        return try? String(contentsOf: url)
    }
}
