//
//  QLMarkdownXPCHelperProtocol.swift
//  QLMarkdownXPCHelper
//
//  Created by Sbarex on 02/01/25.
//

import Foundation

/// The protocol that this service will vend as its API. This protocol will also need to be visible to the process hosting the service.
@objc protocol QLMarkdownXPCHelperProtocol {
    var isHalted: Bool { get }
    
    /// Get the settings.
    func getSettings(with reply: @escaping (Data?) -> Void)
    
    /// Set and store the settings.
    func setSettings(data settings: Data, with reply: @escaping (Bool, String?) -> Void)
    
    func getStylesFolder(reply: @escaping (URL?) -> Void)
    func getAvailableStyles(resetCache: Bool, reply: @escaping ([String]) -> Void)
    func storeStyle(name: String, data: Data?, reply: @escaping (URL?, Bool)->Void)
    
    func getFileContents(_ url: URL, withReply: @escaping (String?) -> Void)
    
    func shutdown()
}

/*
 To use the service from an application or other process, use NSXPCConnection to establish a connection to the service by doing something like this:

     connectionToService = NSXPCConnection(serviceName: "org.sbarex.QLMarkdownXPCHelper")
     connectionToService.remoteObjectInterface = NSXPCInterface(with: QLMarkdownXPCHelperProtocol.self)
     connectionToService.resume()

 Once you have a connection to the service, you can use it like this:

     if let proxy = connectionToService.remoteObjectProxy as? QLMarkdownXPCHelperProtocol {
         proxy.performCalculation(firstNumber: 23, secondNumber: 19) { result in
             NSLog("Result of calculation is: \(result)")
         }
     }

 And, when you are finished with the service, clean up the connection like this:

     connectionToService.invalidate()
*/
