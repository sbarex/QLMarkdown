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
    
    @IBOutlet weak var exampleMenu: NSMenuItem!
    
    /// List o a markdown test files.
    var markdownFiles: [URL] = []
    
    var userDriver: SPUStandardUserDriver?
    var updater: SPUUpdater?
    
    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
    
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
            } 
        }
        
        return .terminateNow
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
        
        Settings.shared.installDependencies()
        
        if let path = Settings.mermaidCacheFileUrl, !FileManager.default.fileExists(atPath: path.path) {
            // Try to download Mermaid library from web.
            Settings.shared.updateMemaidCache { (success) in
                print("Mermaid reflesh: \(success ? "success" : "failure")")
            }
        }
        if let path = Settings.mathJaxCacheFileUrl, !FileManager.default.fileExists(atPath: path.path) {
            // Try to download MathJax library from web.
            Settings.shared.updateMathJaxUCache { (success) in
                print("MathJax reflesh: \(success ? "success" : "failure")")
            }
        }
        
        // Build the Examples menu
        if let exampleURL = Bundle.main.url(forResource: "examples", withExtension: nil), let files = try? FileManager.default.contentsOfDirectory(
                at: exampleURL,
                    includingPropertiesForKeys: nil,
                    options: [.skipsHiddenFiles]
        ) {
            self.markdownFiles.append(contentsOf: files.filter({ $0.pathExtension.lowercased() == "md" || $0.pathExtension.lowercased() == "rmd" }))
            self.markdownFiles.sort { a, b in
                a.lastPathComponent < b.lastPathComponent
            }
        }
        
        let mnu = NSMenuItem(title: "README.md", action: #selector(self.handleExample(_:)), keyEquivalent: "")
        mnu.tag = -1
        self.exampleMenu.submenu?.addItem(mnu)
        self.exampleMenu.submenu?.addItem(NSMenuItem.separator())
        
        for (i, markdownFile) in self.markdownFiles.enumerated() {
            let mnu = NSMenuItem(title: markdownFile.deletingPathExtension().lastPathComponent, action: #selector(self.handleExample(_:)), keyEquivalent: "")
            mnu.tag = i
            self.exampleMenu.submenu?.addItem(mnu)
        }
    }
    
    /**
     * Open an example file.
     */
    @IBAction func handleExample(_ sender: NSMenuItem) {
        if sender.tag == -1 /* readme */ {
            if let file = Bundle.main.url(forResource: "README", withExtension: "md") {
                _ = self.application(NSApplication.shared, openFile: file.path)
            }
            return
        }
        
        guard sender.tag >= 0 && sender.tag < markdownFiles.count else {
            return
        }
        _ = self.application(NSApplication.shared, openFile: markdownFiles[sender.tag].path)
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        
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
        if menuItem.identifier?.rawValue.starts(with: "update_refresh") ?? false {
            menuItem.state = ((NSApplication.shared.delegate as? AppDelegate)?.updater?.updateCheckInterval == TimeInterval(menuItem.tag)) ? .on : .off
        } else if menuItem.identifier?.rawValue == "auto refresh" {
            if let a = UserDefaults.standard.value(forKey: "auto-refresh") as? Bool {
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
        alert1.informativeText = "You can call the tool directly from this path: \n\(srcApp.path) \n\nManually install from a Terminal shell with this command: \nln -sfv \"\(srcApp.path)\" \"\(dstApp.path)\""
        alert1.alertStyle = .informational
        alert1.addButton(withTitle: "OK").keyEquivalent = "\r"
        alert1.addButton(withTitle: "Cancel").keyEquivalent = "\u{1b}"
        guard alert1.runModal() == .alertFirstButtonReturn else {
            return
        }
        guard access(dstApp.deletingLastPathComponent().path, W_OK) == 0 else {
            let alert = NSAlert()
            alert.messageText = "Unable to install the tool: \(dstApp.deletingLastPathComponent().path) is not writable"
            alert.informativeText = "You can directly call the tool from this path: \n\(srcApp.path) \n\nManually install from a Terminal shell with this command: \nln -sfv \"\(srcApp.path)\" \"\(dstApp.path)\""
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
            alert.informativeText = "(\(error.localizedDescription))\n\nYou can manually install the tool from a Terminal shell with this command: \nln -sfv \"\(srcApp.path)\" \"\(dstApp.path)\""
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
    
    @IBAction func onUpdateRate(_ sender: NSMenuItem) {
        updater?.updateCheckInterval = TimeInterval(sender.tag)
    }
    
    @IBAction func buyMeACoffee(_ sender: Any?) {
        let url = URL(string: "https://www.buymeacoffee.com/sbarex")!
        NSWorkspace.shared.open(url)
    }
}

