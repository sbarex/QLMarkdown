//
//  ThemesViewController.swift
//  QLMarkdown
//
//  Created by Sbarex on 14/12/20.
//

import Foundation

import Cocoa
import WebKit

protocol ThemesViewDelegate: AnyObject {
    var theme: ThemePreview? { get set }
}

class ThemesViewController: NSViewController, ThemesViewDelegate {
    @IBOutlet weak var themesView: ThemesView!
    @IBOutlet weak var previewView: ThemePreviewView!
    @IBOutlet weak var themeView: ThemeTableView!
    
    /// Current theme.
    var theme: ThemePreview? {
        didSet {
            guard theme != oldValue else {
                return
            }
            
            refreshThemeViews()
        }
    }
    
    override func viewDidLoad() {
        self.themesView.delegate = self
        refreshThemeViews()
    }
    
    // Called from refresh menu item.
    @IBAction func refresh(_ sender: Any) {
        previewView.refreshPreview(sender)
    }
    
    // Called from the File/Duplicate menu.
    @IBAction func duplicateDocument(_ sender: Any) {
        themesView.handleDuplicate(sender)
    }
    
    /// Refresh the theme elements.
    func refreshThemeViews() {
        themeView.theme = theme
        previewView.theme = theme
        themesView.theme = theme
    }
}

// MARK: - ThemesWindowController
class ThemesWindowController: NSWindowController, NSWindowDelegate {
    override func windowDidLoad() {
        super.windowDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleThemeSavedDeleted(_:)), name: .themeDidSaved, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleThemeSavedDeleted(_:)), name: .themeDidDeleted, object: nil)
    }
    deinit {
        NotificationCenter.default.removeObserver(self, name: .themeDidSaved, object: nil)
        NotificationCenter.default.removeObserver(self, name: .themeDidDeleted, object: nil)
    }
    
    @objc func handleThemeSavedDeleted(_ notification: Notification) {
        self.window?.isDocumentEdited = Settings.shared.getAvailableThemes(resetCache: false).first(where: { $0.isDirty }) != nil
    }
    
    func windowDidBecomeKey(_ notification: Notification) {
        if let fileMenu = NSApplication.shared.menu?.item(withTag: 100) {
            fileMenu.submenu?.item(withTag: 101)?.isHidden = false
        }
    }
    func windowDidResignKey(_ notification: Notification) {
        if let fileMenu = NSApplication.shared.menu?.item(withTag: 100) {
            fileMenu.submenu?.item(withTag: 101)?.isHidden = true
        }
    }
    
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        let dirtyThemes = Settings.shared.getAvailableThemes(resetCache: false).filter({ $0.isDirty })
        guard !dirtyThemes.isEmpty else {
            return true
        }
        
        let alert = NSAlert()
        alert.messageText = "There are some modified themes"
        alert.informativeText = "Do you want to save them before closing?"
        alert.addButton(withTitle: "Save all")
        alert.addButton(withTitle: "Ignore")
        alert.addButton(withTitle: "Cancel").keyEquivalent = "\u{1b}"
        
        alert.alertStyle = .warning
        
        switch alert.runModal() {
        case .alertThirdButtonReturn, .cancel: // Cancel
            return false
        case .alertSecondButtonReturn, .abort: // No
            return true
        case .alertFirstButtonReturn, .OK: // Yes, save!
            for theme in dirtyThemes {
                do {
                    try theme.save()
                } catch {
                    let alert = NSAlert()
                    alert.messageText = "Unable to save the theme!"
                    alert.informativeText = error.localizedDescription
                    alert.addButton(withTitle: "Close").keyEquivalent = "\u{1b}"
                    
                    alert.alertStyle = .critical
                    
                    alert.runModal()
                    return false
                }
            }
            break
        default:
            break
        }
        return true
    }
}

