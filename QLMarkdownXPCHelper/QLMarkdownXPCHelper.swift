//
//  QLMarkdownXPCHelper.swift
//  QLMarkdownXPCHelper
//
//  Created by Sbarex on 02/01/25.
//

import Foundation
import Security
import OSLog

/// This object implements the protocol which we have defined. It provides the actual behavior for the service. It is 'exported' by the service to make it available to the process hosting the service over an NSXPCConnection.
class QLMarkdownXPCHelper: NSObject, QLMarkdownXPCHelperProtocol {
    public fileprivate(set) var isHalted = false
    var styles: [String]? = nil
    
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
        
        settings.customCSSFetched = true
        settings.customCSSCode = nil
        
        if let url = settings.customCSS, url.lastPathComponent != "-" {
            do {
                let css = try String(contentsOf: url)
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
            
            if let css = try? String(contentsOf: url) {
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
        
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(settings) {
            reply(data)
        } else {
            os_log(
                "Unable to encode the settings!",
                log: OSLog.quickLookExtension,
                type: .error
            )
            reply(nil)
        }
    }
    
    /// Set and store the settings.
    func setSettings(data: Data, with reply: @escaping (Bool, String?) -> Void) {
        let decoder = JSONDecoder()
        do {
            let s = try decoder.decode(Settings.self, from: data)
            if s.save(toUserDefaults: .standard) {
                reply(true, nil)
                DistributedNotificationCenter.default().postNotificationName(.QLMarkdownSettingsUpdated, object: nil, deliverImmediately: true)
                // DistributedNotificationCenter.default().post(name: .QLMarkdownSettingsUpdated, object: nil)
            } else {
                os_log(
                    "Fail to store data!",
                    log: OSLog.quickLookExtension,
                    type: .error
                )
                reply(false, "Fail to store data.")
            }
        } catch {
            os_log(
                "Fail to decode settings data %{public}@!",
                log: OSLog.quickLookExtension,
                type: .error,
                error.localizedDescription
            )
            
            reply(false, "Fail to decode settings data: \(error.localizedDescription)")
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
    
    /// Halt the XPC process.
    func shutdown() {
        isHalted = true
        exit(0)
    }
}
