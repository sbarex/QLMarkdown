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
    
    func localizeMainMenu() {
        let appKitBundle = Bundle(for: NSMenuItem.self)
        /*guard let appKitBundle = Bundle(path: "/System/Library/Frameworks/AppKit.framework") else {
            return
        }*/
        guard let mainMenu = NSApp.mainMenu else {
            return
        }
        
        let tables = ["MenuCommands", "InputManager"]
        
        func localize(key: String) -> String? {
            for table in tables {
                let localized = appKitBundle.localizedString(
                    forKey: key,
                    value: nil,
                    table: table)
                if localized != key {
                    return localized
                }
            }
            
            return nil
        }
        
        func localize(menu: NSMenu, indent: String = "") {
            let title = menu.title
            
            // print("\(indent) [\(title)]")
            if !title.isEmpty {
                if let localized = localize(key: title) {
                    // print("\(indent) - \(title) → \(localized)")
                    menu.title = localized
                }
            }
            
            for item in menu.items {
                guard !item.isSeparatorItem else {
                    continue
                }
                
                let title = item.title
                
                if let localized = localize(key: title) {
                    // print("\(indent) - \(title) → \(localized)")
                    item.title = localized
                }
                
                if let submenu = item.submenu, !submenu.items.isEmpty {
                    localize(menu: submenu, indent: indent + " ")
                }
            }
        }
        
        localize(menu: mainMenu)
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        if let lang = Bundle.main.preferredLocalizations.first, lang != "en" {
            localizeMainMenu()
        }
        
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
            alert.messageText = NSLocalizedString("Updater Error", comment: "autoupdate message error")
            alert.informativeText = NSLocalizedString("The Updater failed to start. For detailed error information, check the Console.app log.", comment: "")
            alert.addButton(withTitle: NSLocalizedString("Close", comment: "Close button")).keyEquivalent = "\u{1b}"
            alert.runModal()
        }
        
        Settings.shared.installDependencies(override: .onlyOlder)
        
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
        alert1.messageText = String.localizedStringWithFormat(NSLocalizedString("The tool will be installed in %@ \nDo you want to continue?", comment: ""), dstApp.path)
        alert1.informativeText = String.localizedStringWithFormat(NSLocalizedString("You can call the tool directly from this path: \n%@) \n\nManually install from a Terminal shell with this command: \nln -sfv \"%@\" \"%@\"", comment: ""), srcApp.path, srcApp.path, dstApp.path)
        alert1.alertStyle = .informational
        alert1.addButton(withTitle: NSLocalizedString("OK", comment: "OK button")).keyEquivalent = "\r"
        alert1.addButton(withTitle: NSLocalizedString("Cancel", comment: "Cancel button")).keyEquivalent = "\u{1b}"
        guard alert1.runModal() == .alertFirstButtonReturn else {
            return
        }
        guard access(dstApp.deletingLastPathComponent().path, W_OK) == 0 else {
            let alert = NSAlert()
            alert.messageText = String.localizedStringWithFormat(NSLocalizedString("Unable to install the tool: %@ is not writable", comment: ""), dstApp.deletingLastPathComponent().path)
            alert.informativeText = String.localizedStringWithFormat(NSLocalizedString("You can call the tool directly from this path: \n%@) \n\nManually install from a Terminal shell with this command: \nln -sfv \"%@\" \"%@\"", comment: ""), srcApp.path, srcApp.path, dstApp.path)
            alert.alertStyle = .warning
            alert.addButton(withTitle: NSLocalizedString("Close", comment: "Close button")).keyEquivalent = "\u{1b}"
            alert.runModal()
            return
        }
        
        let alert = NSAlert()
        do {
            try FileManager.default.createSymbolicLink(at: dstApp, withDestinationURL: srcApp)
            alert.messageText = NSLocalizedString("Command line tool installed", comment: "")
            alert.informativeText = String.localizedStringWithFormat(NSLocalizedString("You can call it from this path: %@", comment: ""), dstApp.path)
            alert.alertStyle = .informational
        } catch {
            alert.messageText = NSLocalizedString("Unable to install the command line tool", comment: "")
            alert.informativeText = String.localizedStringWithFormat(NSLocalizedString("(%@)\n\nYou can manually install the tool from a Terminal shell with this command: \nln -sfv \"%@\" \"%@\"", comment: ""), error.localizedDescription, srcApp.path, dstApp.path)
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
            alert.messageText = NSLocalizedString("The command line tool is not installed.", comment: "")
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
    
    @IBAction func printPreview(_ sender: Any?) {
        guard let controller = NSApplication.shared.windows.first(where: {$0.windowController?.contentViewController is ViewController })?.windowController?.contentViewController as? ViewController else {
            return
        }
        
        guard let webView = controller.webView, let _ = webView.window else {
            return
        }
        
        let printInfo = NSPrintInfo.shared.copy() as! NSPrintInfo
        printInfo.jobDisposition = .spool
        printInfo.orientation = .portrait
        
    
        let operation = webView.printOperation(with: printInfo)
        
        operation.showsPrintPanel = true
        operation.showsProgressPanel = true
        
        operation.view?.frame = webView.bounds
        operation.jobTitle = webView.title ?? "Markdown"
        operation.canSpawnSeparateThread = true
        
        operation.runModal(for: webView.window!, delegate: nil, didRun: nil, contextInfo: nil)
    }
}

