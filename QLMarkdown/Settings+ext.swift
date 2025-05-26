//
//  Settings.swift
//  QLMarkdown
//
//  Created by Sbarex on 25/12/20.
//

import Foundation
import AppKit

extension Settings {
    func getAvailableStyles(resetCache reset: Bool = false) -> [URL] {
        var styles: [URL] = []
        XPCWrapper.getSynchronousService()?.getAvailableStyles(resetCache: reset) { urls in
            styles = urls.map({URL(fileURLWithPath: $0)})
        }
        return styles
    }
}
