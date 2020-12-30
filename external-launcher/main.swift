//
//  main.swift
//  external-launcher
//
//  Created by Sbarex on 30/12/20.
//

import Foundation

let delegate = ExternalLauncherDelegate()
let listener = NSXPCListener.service()
listener.delegate = delegate
listener.resume()
