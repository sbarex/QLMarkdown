//
//  Log.swift
//  QLMarkdown
//
//  Created by Sbarex on 21/03/22.
//

import Foundation
import OSLog

extension OSLog {
    private static let subsystem = "org.sbarex.QLMarkdown"

    static let quickLookExtension = OSLog(subsystem: subsystem, category: "Quick Look Extension")
    static let cli = OSLog(subsystem: subsystem, category: "Command Line Tool")
    static let shortcutExtension = OSLog(subsystem: subsystem, category: "Shotcut Extension")
    static let highlightWrapperExtension = OSLog(subsystem: subsystem, category: "Highlight Wrapper")
    static let rendering = OSLog(subsystem: subsystem, category: "Rendering")
}
