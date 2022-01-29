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
    
    func application(_ sender: NSApplication, openFile filename: String) -> Bool {
        guard let controller = sender.windows.first(where: {$0.windowController?.contentViewController is ViewController })?.windowController?.contentViewController as? ViewController else {
            return false
        }
        let file = URL(fileURLWithPath: filename)
        guard file.pathExtension.lowercased() == "md" else {
            return false
        }
        return controller.openMarkdown(file: file)
    }
    
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        for window in sender.windows {
            if let wc = window.windowController as? PreferencesWindowController, !wc.windowShouldClose(window) {
                return .terminateCancel
            } else if let wc = window.windowController as? ThemesWindowController, !wc.windowShouldClose(window) {
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
            alert.addButton(withTitle: "Close").keyEquivalent = "\u{1b}"
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
            return self.updater?.canCheckForUpdates ?? false
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
    
    
    @IBAction func installCLITool(_ sender: Any) {
        guard let srcApp = Bundle.main.url(forResource: "qlmarkdown_cli", withExtension: nil) else {
            return
        }
        let dstApp = URL(fileURLWithPath: "/usr/local/bin/qlmarkdown_cli")
        
        let alert1 = NSAlert()
        alert1.messageText = "The tool will be installed in \(dstApp.path) \nDo you want to continue?"
        alert1.informativeText = "You can call the tool directly from this path: \n\(srcApp.path) \n\nManually install from a Terminal shell with this command: \nln -sfv \(srcApp.path) \(dstApp.path)"
        alert1.alertStyle = .informational
        alert1.addButton(withTitle: "OK").keyEquivalent = "\r"
        alert1.addButton(withTitle: "Cancel").keyEquivalent = "\u{1b}"
        guard alert1.runModal() == .alertFirstButtonReturn else {
            return
        }
        guard access(dstApp.deletingLastPathComponent().path, W_OK) == 0 else {
            let alert = NSAlert()
            alert.messageText = "Unable to install the tool: \(dstApp.deletingLastPathComponent().path) is not writable"
            alert.informativeText = "You can directly call the tool from this path: \n\(srcApp.path) \n\nManually intall from a Terminal shell with this command: \nln -sfv \(srcApp.path) \(dstApp.path)"
            alert.alertStyle = .warning
            alert.addButton(withTitle: "Close").keyEquivalent = "\u{1b}"
            alert.runModal()
            return
        }
        
        let alert = NSAlert()
        do {
            try FileManager.default.createSymbolicLink(at: dstApp, withDestinationURL: srcApp)
            alert.messageText = "Command line tool installed"
            alert.informativeText = "You can call it from this path: \(dstApp.path)"
            alert.alertStyle = .informational
        } catch {
            alert.messageText = "Unable to install the command line tool"
            alert.informativeText = "(\(error.localizedDescription))\n\nYou can manually install the tool from a Terminal shell with this command: \nln -sfv \(srcApp.path) \(dstApp.path)"
            alert.alertStyle = .critical
        }
        alert.runModal()
    }
    
    @IBAction func revealCLITool(_ sender: Any) {
        let u = URL(fileURLWithPath: "/usr/local/bin/qlmarkdown_cli")
        if FileManager.default.fileExists(atPath: u.path) {
            // Open the Finder to the settings file.
            NSWorkspace.shared.activateFileViewerSelecting([u])
        } else {
            let alert = NSAlert()
            alert.messageText = "The command line tool is not installed."
            alert.alertStyle = .warning
            
            alert.runModal()
        }
    }
}

