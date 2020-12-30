//
//  external_launcher_delegate.swift
//  external-launcher
//
//  Created by Sbarex on 30/12/20.
//

import Foundation

class ExternalLauncherDelegate: NSObject, NSXPCListenerDelegate {
    func listener(_ listener: NSXPCListener, shouldAcceptNewConnection newConnection: NSXPCConnection) -> Bool {
        let exportedObject = ExternalLauncherService()
        newConnection.exportedInterface = NSXPCInterface(with: ExternalLauncherProtocol.self)
        newConnection.exportedObject = exportedObject
        newConnection.resume()
        return true
    }
}
