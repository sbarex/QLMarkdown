//
//  QLMarkdownXPCHelper.swift
//  QLMarkdownXPCHelper
//
//  Created by Sbarex on 02/01/25.
//

import Foundation
import Security

/// This object implements the protocol which we have defined. It provides the actual behavior for the service. It is 'exported' by the service to make it available to the process hosting the service over an NSXPCConnection.
class QLMarkdownXPCHelper: NSObject, QLMarkdownXPCHelperProtocol {
    var styles: [String]? = nil
    var themes: [ThemePreview]? = nil
    var highlight_initialized = false
    
    static let serviceBundle: Bundle = {
        if Bundle.main.bundlePath.hasSuffix(".xpc") || Bundle.main.bundlePath.hasSuffix(".appex") {
            // This is an xpc/appex extension.
            var url = Bundle.main.bundleURL
            while url.pathExtension != "app" {
                let u = url.path
                url.deleteLastPathComponent()
                if u == url.path {
                    return Bundle.main
                }
            }
            url.appendPathComponent("Contents")
            
            if let appBundle = Bundle(url: url) {
                return appBundle
            }
        }
        return Bundle.main
    }()
    
    /// Get settings.
    func getSettings(with reply: @escaping (Data?) -> Void) {
        let settings = Settings(fromUserDefaults: .standard)
        
        let encoder = JSONEncoder()
        let data = try? encoder.encode(settings)
        reply(data)
    }
    
    /// Set and store the settings.
    func setSettings(data: Data, with reply: @escaping (Bool, String?) -> Void) {
        let decoder = JSONDecoder()
        if let s = try? decoder.decode(Settings.self, from: data) {
            if s.save(toUserDefaults: .standard) {
                reply(true, nil)
                
                DistributedNotificationCenter.default().post(name: .QLMarkdownSettingsUpdated, object: nil)
            } else {
                reply(false, "Fail to store data.")
            }
        } else {
            reply(false, "Fail to decode data.")
        }
    }
    
    func getStylesFolder(reply: @escaping (URL?) -> Void)
    {
        reply(Settings.stylesFolder)
    }
    
    func getAvailableStyles(resetCache: Bool, reply: @escaping ([String]) -> Void) {
        // Get customized styles.
        guard let url = Settings.stylesFolder else {
            reply([])
            return
        }
        
        if self.styles == nil || resetCache {
            self.styles = []
            if !FileManager.default.fileExists(atPath: url.path) {
                try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
            }
            
            let dirEnum = FileManager.default.enumerator(atPath: url.path)
            while let file = dirEnum?.nextObject() as? String {
                guard file.hasSuffix(".css") else {
                    continue
                }
                let style = url.appendingPathComponent(file)
                styles!.append(style.path)
            }
        }
        
        reply(self.styles ?? [])
    }
    
    func storeStyle(name: String, data: Data?, reply: @escaping (URL?, Bool)->Void) {
        guard let data = data, let folder = Settings.stylesFolder else {
            reply(nil, false)
            return
        }
        
        let dst = folder.appendingPathComponent(name)
        do {
            if FileManager.default.fileExists(atPath: dst.path) {
                try FileManager.default.removeItem(at: dst)
            }
            try data.write(to: dst)
            reply(dst, true)
        } catch {
            reply(nil, false)
        }
    }
    
    func initHighlight()
    {
        guard !highlight_initialized else {
            return;
        }
        if let path = Self.serviceBundle.resourceURL?.appendingPathComponent("highlight").path {
            highlight_init("\(path)/".cString(using: .utf8))
            highlight_initialized = true
        }
    }
    
    func getAvailableThemes(resetCache: Bool) -> [ThemePreview]
    {
        if self.themes == nil || resetCache {
            initHighlight()
            
            self.themes = []
            var me = self
            // Get standalone themes.
            _ = withUnsafeMutablePointer(to: &me) { (context) in
                highlight_list_themes(context) { (context1, themes, count, exit_code) in
                    /*
                    guard let context = context?.assumingMemoryBound(to: Settings.self).pointee else {
                        return
                    }
                    */
                    guard exit_code == EXIT_SUCCESS else {
                        return
                    }
                    let wrapper = context1!.bindMemory(to: QLMarkdownXPCHelper.self, capacity: 1)
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
                        
                        
                        wrapper.pointee.themes!.append(ThemePreview(theme: theme))
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
                    self.themes!.append(ThemePreview(theme: theme))
                }
            }
        }
        
        return self.themes ?? []
    }
    
    func getAvailableThemes(resetCache: Bool, reply: @escaping (Data?) -> Void)
    {
        let themes = getAvailableThemes(resetCache: resetCache)
        reply(try? JSONSerialization.data(withJSONObject: themes.map({ $0.toDictionary() }), options: []))
    }
    
    func removeTheme(path: String, reply: @escaping (Bool, Data?) -> Void) {
        var themes = getAvailableThemes(resetCache: false)
        
        guard let theme = themes.first(where: { $0.path == path }), !theme.isStandalone else {
            reply(false, try? JSONSerialization.data(withJSONObject: themes.map({ $0.toDictionary() }), options: []))
            return
        }
        
        var r = false
        
        if !theme.path.isEmpty {
            let url = URL(fileURLWithPath: theme.path)
            if FileManager.default.fileExists(atPath: url.path) {
                do {
                    try FileManager.default.removeItem(at: url)
                    
                    if let index = themes.firstIndex(of: theme) {
                        themes.remove(at: index)
                    }
                    
                    r = true
                } catch {
                    r = false
                }
            }
        }
        
        reply(r, try? JSONSerialization.data(withJSONObject: themes.map({ $0.toDictionary() }), options: []))
    }
    
    func getFileContents(_ url: URL, withReply reply: @escaping (String?) -> Void) {
        reply(try? String(contentsOf: url))
    }
    
    /*
    func getSettingsURL(reply: @escaping (_ url: URL?)->Void) {
        reply(type(of: self).preferencesUrl?.appendingPathComponent(type(of: self).XPCDomain + ".plist"))
    }
     */
    
    /// This implements the example protocol. Replace the body of this class with the implementation of this service's protocol.
    @objc func performCalculation(firstNumber: Int, secondNumber: Int, with reply: @escaping (Int) -> Void) {
        let response = firstNumber + secondNumber
        reply(response)
    }
    
    func shutdown() {
        exit(0)
    }
}
