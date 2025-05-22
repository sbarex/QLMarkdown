//
//  XPCSWrapper.swift
//  QLMarkdown
//
//  Created by Sbarex on 02/01/25.
//

import Foundation

class XPCWrapper {
    private static var connection: NSXPCConnection?
    private static var serviceAsync: QLMarkdownXPCHelperProtocol?
    private static var serviceSync: QLMarkdownXPCHelperProtocol?
    
    static func createNewConnection() -> NSXPCConnection {
        let connection = NSXPCConnection(serviceName: "org.sbarex.QLMarkdownXPCHelper")
        connection.invalidationHandler = {
            print("Unable to connect to QLMarkdownXPCHelper service!")
        }
        connection.interruptionHandler = {
            print("QLMarkdownXPCHelper interrupted!")
            connection.invalidate()
            if XPCWrapper.connection == connection {
                XPCWrapper.connection = nil
            }
        }
        connection.remoteObjectInterface = NSXPCInterface(with: QLMarkdownXPCHelperProtocol.self)
        connection.resume()
        return connection
    }
    
    static func getSharedConnection() -> NSXPCConnection {
        if connection == nil {
            connection = createNewConnection()
        }
        return connection!
    }
    
    static func invalidateSharedConnection() {
        serviceAsync?.shutdown()
        serviceAsync = nil
        
        serviceSync?.shutdown()
        serviceSync = nil
        
        connection?.invalidate()
        connection = nil
    }
    
    static func getAsynchronousService() -> QLMarkdownXPCHelperProtocol? {
        if serviceAsync == nil {
            serviceAsync = getSharedConnection().remoteObjectProxyWithErrorHandler { error in
                print("Received error:", error)
            } as? QLMarkdownXPCHelperProtocol
        }
        return serviceAsync
    }
    
    static func getSynchronousService() -> QLMarkdownXPCHelperProtocol? {
        if serviceSync == nil {
            serviceSync = getSharedConnection().synchronousRemoteObjectProxyWithErrorHandler { error in
                print("Received error:", error)
            } as? QLMarkdownXPCHelperProtocol
        }
        return serviceSync
    }
}
