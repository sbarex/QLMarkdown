//
//  external_launcher.swift
//  external-launcher
//
//  Created by Sbarex on 30/12/20.
//

import Cocoa

class ExternalLauncherService: NSObject, ExternalLauncherProtocol {
    /// Mirrors Settings.allowedExternalSchemes. This service is unsandboxed, so it does not rely on
    /// its caller having filtered the URL.
    static let allowedSchemes: Set<String> = ["http", "https", "mailto"]
    
    func open(_ url: URL, withReply reply: @escaping (Bool) -> Void) {
        guard let scheme = url.scheme?.lowercased(), Self.allowedSchemes.contains(scheme) else {
            NSLog("external-launcher: refused URL with scheme %@", url.scheme ?? "?")
            reply(false)
            return
        }
        let r = NSWorkspace.shared.open(url)
        reply(r)
    }
}
