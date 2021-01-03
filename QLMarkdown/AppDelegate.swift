//
//  AppDelegate.swift
//  QLMarkdown
//
//  Created by Sbarex on 09/12/20.
//

import Cocoa
import Sparkle

@main
class AppDelegate: NSObject, NSApplicationDelegate, NSMenuItemValidation {
    var userDriver: SPUStandardUserDriver?
    var updater: SPUUpdater?
    
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        if let wc = NSApplication.shared.mainWindow?.windowController as? PreferencesWindowController {
            if wc.windowShouldClose(wc.window!) {
                return .terminateNow
            } else {
                return .terminateCancel
            }
        }
        return .terminateNow
    }
    
    func applicationWillFinishLaunching(_ notification: Notification) {
        if let folder = Settings.applicationSupportUrl {
            if FileManager.default.fileExists(atPath: folder.appendingPathComponent("styles").path) {
                // Migrate previous custom themes and color schemes.
                if FileManager.default.fileExists(atPath: folder.appendingPathComponent("themes").path), let color_schemes_folder = Settings.themesFolder {
                    try? FileManager.default.createDirectory(at: color_schemes_folder, withIntermediateDirectories: true, attributes: nil)
                    
                    let enumerator = FileManager.default.enumerator(atPath: folder.appendingPathComponent("themes").path)!
                    while let file = enumerator.nextObject() as? String {
                        let fullname = folder.appendingPathComponent("themes").appendingPathComponent(file)
                        if fullname.pathExtension == "theme" {
                            try? FileManager.default.moveItem(at: fullname, to: color_schemes_folder.appendingPathComponent(file))
                        }
                    }
                }
                
                if let themes_folder = Settings.stylesFolder {
                    try? FileManager.default.createDirectory(at: themes_folder, withIntermediateDirectories: true, attributes: nil)
                    
                    let enumerator = FileManager.default.enumerator(atPath: folder.appendingPathComponent("styles").path)!
                    
                    while let file = enumerator.nextObject() as? String {
                        let fullname = folder.appendingPathComponent("styles").appendingPathComponent(file)
                        if fullname.pathExtension == "css" {
                            try? FileManager.default.moveItem(at: fullname, to: themes_folder.appendingPathComponent(file))
                        }
                    }
                }
                
                try? FileManager.default.removeItem(at: folder.appendingPathComponent("styles"))
            }
        }
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        let hostBundle = Bundle.main
        let applicationBundle = hostBundle;
        
        self.userDriver = SPUStandardUserDriver(hostBundle: hostBundle, delegate: nil)
        self.updater = SPUUpdater(hostBundle: hostBundle, applicationBundle: applicationBundle, userDriver: self.userDriver!, delegate: nil)
        
        do {
            try self.updater!.start()
        } catch {
            print("Failed to start updater with error: \(error)")
            
            let alert = NSAlert()
            alert.messageText = "Updater Error"
            alert.informativeText = "The Updater failed to start. For detailed error information, check the Console.app log."
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }

    @IBAction func checkForUpdates(_ sender: Any)
    {
        self.updater?.checkForUpdates()
    }
    
    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool
    {
        if menuItem.action == #selector(self.checkForUpdates(_:)) {
            return self.userDriver?.canCheckForUpdates ?? false
        }
        if menuItem.identifier?.rawValue == "advanced settings" {
            let defaults = UserDefaults.standard
            if let a = defaults.value(forKey: "advanced-settings") as? Bool {
                menuItem.state = !a ? .on : .off
            }
        } else if menuItem.identifier?.rawValue == "auto refresh" {
            let defaults = UserDefaults.standard
            if let a = defaults.value(forKey: "auto refresh") as? Bool {
                menuItem.state = a ? .on : .off
            }
        }
        return true
    }
}

