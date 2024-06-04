//
//  CLIHelperProtocol.swift
//  qlmarkdon-cli_helper
//
//  Created by Sbarex on 28/01/22.
//

import Foundation

@objc public protocol CLIHelperProtocol {
    func installCLI(reply: @escaping (Bool)->Void)
    
    /// Called by the app at startup time to set up our authorization rights in the authorization database.
    func setupAuthorizationRights()

    /// Called by the app to get an endpoint that's connected to the helper tool.
    /// This a also returns the XPC service's authorization reference so that
    /// the app can pass that to the requests it sends to the helper tool.
    /// Without this authorization will fail because the app is sandboxed.
    func connectWithEndpointAndAuthorization(reply:(_ endpoint: NSXPCListenerEndpoint, _ authorization: Data)->Void)
    
        
}

