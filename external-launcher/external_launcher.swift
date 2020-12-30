//
//  external_launcher.swift
//  external-launcher
//
//  Created by Sbarex on 30/12/20.
//

import Cocoa

class ExternalLauncherService: NSObject, ExternalLauncherProtocol {
    func open(_ url: URL, withReply reply: @escaping (Bool) -> Void) {
        let r = NSWorkspace.shared.open(url)
        reply(r)
    }
}
