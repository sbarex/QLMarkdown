//
//  external_launcherProtocol.swift
//  external-launcher
//
//  Created by Sbarex on 30/12/20.
//

import Foundation

@objc public protocol ExternalLauncherProtocol {
    func open(_ url: URL, withReply reply: @escaping (Bool) -> Void)
}

