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
    
    /*
    
    @IBOutlet weak var addKeywordMenuItem: NSMenuItem!
    @IBOutlet weak var delThemeMenuItem: NSMenuItem!
    @IBOutlet weak var actionsPopupButton: NSPopUpButton!
    @IBOutlet weak var saveButton: NSButton!
    */
    
    /// Current theme.
    var theme: ThemePreview? {
        didSet {
            guard theme != oldValue else {
                return
            }
            /*
            oldValue?.delegate = nil
            theme?.delegate = self
 */
            themeView.theme = theme
            previewView.theme = theme
            themesView.theme = theme
            
            refreshThemeViews()
        }
    }
    
    
    /*
    /// Filter for theme style (light/dark).
    var style: ThemeStyleFilterEnum = .all {
        didSet {
            refreshThemes()
        }
    }
    */
    
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
    
    
    /*
    
    /// Add a new keyword to the current theme.
    @IBAction func handleAddKeyword(_ sender: NSButton) {
        guard  let theme = self.theme, !theme.isStandalone else {
            return
        }
        
        tableView.beginUpdates()
        let keyword = SCSHTheme.Property(color: NSColor.random().toHexString())
        
        let index = tableView.row(for: sender)
        let newIndex: Int
        if index >= 0 {
            let k = index - 3 - SCSHTheme.Property.Name.standardProperties.count
            theme.insertKeyword(keyword, at: k + 1)
            newIndex = index+1
        } else {
            theme.appendKeyword(keyword)
            newIndex = theme.numberOfProperties + 3 - 1
        }
        tableView.insertRows(at: IndexSet(integer: newIndex), withAnimation: .slideRight)
        tableView.reloadData(forRowIndexes: IndexSet(integersIn: newIndex..<theme.numberOfProperties+3-1), columnIndexes: IndexSet(integersIn: 0...1))
        
        tableView.endUpdates()
        
        tableView.scrollRowToVisible(newIndex)
        refreshPreview(sender)
    }
    
    @IBAction func handleAddKeywordFromMenu(_ sender: NSMenuItem) {
        guard  let theme = self.theme, !theme.isStandalone else {
            return
        }
        
        tableView.beginUpdates()
        let keyword = SCSHTheme.Property(color: NSColor.random().toHexString())
        theme.appendKeyword(keyword)
        let newIndex = theme.numberOfProperties + 3 - 1
        
        tableView.insertRows(at: IndexSet(integer: newIndex), withAnimation: .slideRight)
        tableView.endUpdates()
        
        tableView.scrollRowToVisible(newIndex)
        refreshPreview(sender)
    }
    
    /// Delete a keyword from the current theme.
    @IBAction func handleDelKeyword(_ sender: NSButton) {
        guard  let theme = self.theme, !theme.isStandalone else {
            return
        }
        
        let index = tableView.row(for: sender)
        guard index >= 0 else {
            return
        }
        
        tableView.beginUpdates()
        // Remove the keyword row.
        tableView.removeRows(at: IndexSet(integer: index), withAnimation: .slideRight)
        // Refresh the next keywords (necessary to rename them).
        tableView.reloadData(forRowIndexes: IndexSet(integersIn: index..<theme.numberOfProperties+3-1), columnIndexes: IndexSet(integersIn: 0...1))
        
        let k = index - 3 - SCSHTheme.Property.Name.standardProperties.count
        theme.removeKeyword(at: k)
        
        tableView.endUpdates()
        
        refreshPreview(sender)
    }
    
    // Invoked by save menu item.
    @IBAction func saveDocument(_ sender: Any) {
        let responder = self.view.window?.firstResponder
        self.view.window?.makeFirstResponder(nil)
        resignFirstResponder()
        
        if let theme = self.theme, theme.isDirty {
            saveTheme(theme)
        }
        // Restore previous responder.
        self.view.window?.makeFirstResponder(responder)
        responder?.resignFirstResponder()
    }
    
    @IBAction func showHelp(_ sender: Any) {
        if let locBookName = Bundle.main.object(forInfoDictionaryKey: "CFBundleHelpBookName") as? String {
            let anchor = "SyntaxHighlight_THEMES"
            
            NSHelpManager.shared.openHelpAnchor(anchor, inBook: locBookName)
        }
    }
    
    /// Save a theme.
    func saveTheme(_ theme: SCSHTheme, reply: ((Bool)->Void)? = nil) {
        guard theme.isDirty, !theme.isStandalone else {
            reply?(true)
            return
        }
        
        if theme.originalName == "" || theme.originalName != theme.name, let _ = customThemes.first(where: { $0.theme != theme && $0.theme.originalName == theme.name }) {
            let alert = NSAlert()
            
            alert.window.title = "Error"
            alert.messageText = "Unable to save the theme \(theme.name) because another already exists with the same name!"
            alert.addButton(withTitle: "Close")
            
            alert.alertStyle = .critical
            alert.runModal()
            reply?(false)
        }
        
        service?.saveTheme(theme.toDictionary() as NSDictionary) { (success, error) in
            if success {
                let oldName = theme.originalName
                theme.originalName = theme.name
                theme.isDirty = false
                NotificationCenter.default.post(name: .themeDidSaved, object: NotificationThemeSavedData(theme: theme, oldName: oldName))
                reply?(true)
            } else {
                print(error ?? "unknown error")
                DispatchQueue.main.sync {
                    let alert = NSAlert()
                    
                    alert.window.title = "Error"
                    alert.messageText = "Unable to save the theme \(theme.name)!"
                    alert.informativeText = error?.localizedDescription ?? ""
                    alert.addButton(withTitle: "Close")
                    
                    alert.alertStyle = .critical
                    alert.runModal()
                    reply?(false)
                }
            }
        }
    }
     
     */
    
    /// Refresh the theme elements.
    func refreshThemeViews() {
        // delThemeButton.isEnabled = !(theme?.isStandalone ?? true)
        
        /*
        addKeywordMenuItem.isEnabled = !(theme?.isStandalone ?? true)
        actionsPopupButton.isEnabled = theme != nil
        saveButton.isEnabled = theme?.isDirty ?? false
        delThemeMenuItem.isEnabled = !(theme?.isStandalone ?? true)
        */
        
        /*
        let dirty = theme?.isDirty ?? false
        if let fileMenu = NSApplication.shared.menu?.item(withTag: 100) {
            fileMenu.submenu?.item(withTag: 101)?.isEnabled = dirty
            fileMenu.submenu?.item(withTag: 102)?.isEnabled = customThemes.first(where: {$0.theme.isDirty}) != nil
        }
         */
    }
}

/*
// MARK: SCSHThemeDelegate
extension ThemesViewController: SCSHThemeDelegate {
    func themeDidChangeDirtyStatus(_ theme: SCSHTheme) {
        if theme.isDirty {
            self.view.window?.isDocumentEdited = true
        } else {
            self.view.window?.isDocumentEdited = customThemes.first(where: { $0.theme.isDirty }) != nil
        }
        
        if theme == self.theme {
            refreshPreview(self)
            if let t = customThemes.first(where: { $0.theme == theme }) {
                // Reset current image forcing refresh.
                t.image = nil
                // Reload the row.
                outlineView.reloadItem(t)
            }
            saveButton.isEnabled = theme.isDirty
        }
    }
    
    func themeDidChangeName(_ theme: SCSHTheme) {
        if let t = customThemes.first(where: { $0.theme == theme }) {
            // Reload the row in the outline view.
            outlineView.reloadItem(t)
        }
    }
    
    func themeDidChangeDescription(_ theme: SCSHTheme) {
        if let t = customThemes.first(where: { $0.theme == theme }) {
            outlineView.beginUpdates()
            
            // Reload the row in the outline view.
            outlineView.reloadItem(t)
            // Research and resort the list.
            refreshThemes(custom: true)
            
            outlineView.endUpdates()
        }
    }
    func themeDidChangeProperty(_ theme: SCSHTheme, property: SCSHThemePropertyProtocol) {
        if let t = allCustomThemes.first(where: { $0.theme == theme }) {
            // Reset the image forcing refresh.
            t.image = nil
            // Reload the row in the outline view if is presents.
            outlineView.reloadItem(t)
        }
        if theme == self.theme {
            refreshPreview(self)
        }
    }
    
    func themeDidChangeCategories(_ theme: SCSHTheme) {
        // Research and resort the list.
        refreshThemes(custom: true)
    }
    
    func themeDidAddKeyword(_ theme: SCSHTheme, keyword: SCSHTheme.Property) {
        if let t = allCustomThemes.first(where: { $0.theme == theme }) {
            // Reset the image forcing refresh.
            t.image = nil
            // Reload the row in the outline view if is presents.
            outlineView.reloadItem(t)
        }
    }
    
    func themeDidRemoveKeyword(_ theme: SCSHTheme, keyword: SCSHTheme.Property) {
        if let t = allCustomThemes.first(where: { $0.theme == theme }) {
            // Reset the image forcing refresh.
            t.image = nil
            // Reload the row in the outline view if is presents.
            outlineView.reloadItem(t)
        }
    }
}
*/

// MARK: - Theme Property Cells View

// typealias ThemePropertyData = (theme: Theme?, propertyName: SCSHTheme.Property.Name)



/*
/// Show the color and style of a single property of a theme.
class ThemePropertyTableCellView: NSTableCellView {
    @IBOutlet weak var style: NSSegmentedControl!
    @IBOutlet weak var colorWell: NSColorWell!
    
    override var objectValue: Any? {
        didSet {
            refreshCell()
        }
    }
    
    func refreshCell() {
        if let data = objectValue as? ThemePropertyData, let prop = data.theme?[data.propertyName]  {
            if let prop = prop as? SCSHTheme.Property {
                style?.setSelected(prop.isBold, forSegment: 0)
                style?.setSelected(prop.isItalic, forSegment: 1)
                style?.setSelected(prop.isUnderline, forSegment: 2)
                style?.isEnabled = true // !(data.theme?.isStandalone ?? true)
                style?.isHidden = false
            } else {
                style?.isHidden = true
            }
            
            colorWell?.color = NSColor(fromHexString: prop.color) ?? .clear
            colorWell?.isEnabled = true
            colorWell?.isBordered = !(data.theme?.isStandalone ?? true)
        } else {
            style?.isEnabled = false
            style?.setSelected(false, forSegment: 0)
            style?.setSelected(false, forSegment: 1)
            style?.setSelected(false, forSegment: 2)
            
            colorWell?.isEnabled = false
            colorWell?.color = .clear
        }
    }
    
    @IBAction func handleStyleChange(_ sender: NSSegmentedControl) {
        guard let data = objectValue as? ThemePropertyData else {
            return
        }
        if data.theme?.isStandalone ?? true {
            // Ignore the input.
            refreshCell()
        } else {
            if let prop = data.theme?[data.propertyName] as? SCSHTheme.Property {
                prop.isBold = sender.isSelected(forSegment: 0)
                prop.isItalic = sender.isSelected(forSegment: 1)
                prop.isUnderline = sender.isSelected(forSegment: 2)
            }
        }
    }
    
    @IBAction func handleColorChange(_ sender: NSColorWell) {
        guard let data = objectValue as? ThemePropertyData else {
            return
        }
        if data.theme?.isStandalone ?? true {
            // Ignore the input.
            refreshCell()
        } else {
            data.theme?[data.propertyName]?.color = sender.color.toHexString()
        }
    }
}
*/

/*
/// Show the label of a property of a theme.
class ThemePropertyLabelTableCellView: NSTableCellView {
     override var objectValue: Any? {
        didSet {
            if let data = objectValue as? ThemePropertyData {
                textField?.stringValue = data.propertyName.description
            }
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        textField?.stringValue = ""
    }
}
*/

/*
/// Show the label of a keyword of a theme.
class ThemeKeywordLabelTableCellView: NSTableCellView {
    @IBOutlet weak var addButton: NSButton!
    @IBOutlet weak var delButton: NSButton!
    
    override var objectValue: Any? {
        didSet {
            if let data = objectValue as? ThemePropertyData {
                textField?.stringValue = data.propertyName.description
            }
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        textField?.stringValue = ""
        addButton.isHidden = true
        delButton.isHidden = true
    }
    
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        addTrackingArea(NSTrackingArea(rect: bounds, options: [.mouseEnteredAndExited, .activeAlways], owner: self, userInfo: nil))
    }
    
    override func mouseEntered(with event: NSEvent) {
        guard let data = objectValue as? ThemePropertyData, let theme = data.theme, !theme.isStandalone else {
            return
        }
        addButton.isHidden = false
        delButton.isHidden = false
    }
    override func mouseExited(with event: NSEvent) {
        addButton.isHidden = true
        delButton.isHidden = true
    }
}
*/

/*
/// Global style (dark or light) for a theme.
class ThemeStyleTableCellView: NSTableCellView {
    @IBOutlet weak var style: NSSegmentedControl?

    override var objectValue: Any? {
        didSet {
            refreshCell()
        }
    }
    
    func refreshCell() {
        if let theme = objectValue as? SCSHTheme {
            style?.setSelected(theme.isLight, forSegment: 0)
            style?.setSelected(theme.isDark, forSegment: 1)
            style?.isEnabled = true // !theme.isStandalone
        } else {
            style?.setSelected(false, forSegment: 0)
            style?.setSelected(false, forSegment: 0)
            style?.isEnabled = false
        }
    }
    
    @IBAction func handleStyleChange(_ sender: NSSegmentedControl) {
        guard let theme = objectValue as? SCSHTheme else {
            return
        }
        if theme.isStandalone {
            // Ignore the input.
            refreshCell()
        } else {
            theme.isLight = sender.isSelected(forSegment: 0)
        }
    }
}
*/

/// String label.
class ThemeLabelTableCellView: NSTableCellView {
    override var objectValue: Any? {
        didSet {
            if let string = objectValue as? String {
                textField?.stringValue = string
            }
        }
    }
}

class ThemeTextFieldTableCellView: NSTableCellView, NSTextFieldDelegate {
    override var objectValue: Any? {
        didSet {
            if let theme = objectValue as? Theme {
                //textField?.isBordered = !theme.isStandalone
                textField?.drawsBackground = !theme.isStandalone
                textField?.isEditable = !theme.isStandalone
            }
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        textField?.stringValue = ""
        textField?.isEditable = false
    }
    
    @IBAction func handleChange(_ sender: NSTextField) {
    }
    
    func controlTextDidEndEditing(_ notification: Notification) {
        if let t = notification.object as? NSTextField {
            handleChange(t)
        }
    }
    
    func textDidChange(_ notification: Notification) {
        if let t = notification.object as? NSTextField {
            handleChange(t)
        }
    }
}

/// Name of the theme.
class ThemeNameTableCellView: ThemeTextFieldTableCellView {
    override var objectValue: Any? {
        didSet {
            if let theme = objectValue as? Theme {
                textField?.stringValue = theme.name
            }
        }
    }
    @IBAction override func handleChange(_ sender: NSTextField) {
        if let theme = objectValue as? Theme {
            theme.name = sender.stringValue
        }
    }
}

/// Description of a theme.
class ThemeDescriptionTableCellView: ThemeTextFieldTableCellView {
    override var objectValue: Any? {
        didSet {
            if let theme = objectValue as? Theme {
                textField?.stringValue = theme.name
            }
        }
    }
    
    @IBAction override func handleChange(_ sender: NSTextField) {
        if let theme = objectValue as? Theme {
            theme.name = sender.stringValue
        }
    }
}

class ThemeNameFormatter: Formatter {
    override func isPartialStringValid(_ partialStringPtr: AutoreleasingUnsafeMutablePointer<NSString>, proposedSelectedRange proposedSelRangePtr: NSRangePointer?, originalString origString: String, originalSelectedRange origSelRange: NSRange, errorDescription error: AutoreleasingUnsafeMutablePointer<NSString?>?) -> Bool {
        let s = partialStringPtr.pointee as String
        
        let regex = try! NSRegularExpression(pattern: #"([^-a-zA-Z0-9_])"#, options: [.caseInsensitive])
        let range = NSMakeRange(0, s.count)
        let modString = regex.stringByReplacingMatches(in: s, options: [], range: range, withTemplate: "_")
        
        if s != modString {
            partialStringPtr.pointee = modString as NSString
            return false
        }
        return true
    }
    
    override func string(for obj: Any?) -> String? {
        if let s = obj as? String {
            return s
        } else {
            return nil
        }
    }
    
    override func getObjectValue(_ obj: AutoreleasingUnsafeMutablePointer<AnyObject?>?, for string: String, errorDescription error: AutoreleasingUnsafeMutablePointer<NSString?>?) -> Bool {
        obj?.pointee = string as AnyObject
        if let s = obj?.pointee as? String {
            let regex = try! NSRegularExpression(pattern: #"([^-a-zA-Z0-9_])"#, options: [.caseInsensitive])
            let range = NSMakeRange(0, s.count)
            let modString = regex.stringByReplacingMatches(in: s, options: [], range: range, withTemplate: "_")
            
            if s != modString {
                obj?.pointee = modString as NSString
                error?.pointee = "Invalid characters: allow only letters, numbers, hyphen and underscore."
                return false
            }
            
            return true
        } else {
            return false
        }
    }
}

// MARK: - ThemesWindowController
class ThemesWindowController: NSWindowController, NSWindowDelegate {
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
        // TODO
        guard let contentViewController = self.contentViewController as? ThemesViewController else {
            return true
        }
        /*
        if let _ = contentViewController.customThemes.first(where: { $0.isDirty } ) {
            let alert = NSAlert()
            alert.window.title = "Warning"
            alert.messageText = "There are some modified themes. Do you want to save them before closing?"
            alert.addButton(withTitle: "Yes")
            alert.addButton(withTitle: "No")
            alert.addButton(withTitle: "Cancel")
            
            alert.alertStyle = .warning
            
            switch alert.runModal() {
            case .alertThirdButtonReturn, .cancel: // Cancel
                return false
            case .alertSecondButtonReturn, .abort: // No
                return true
            case .alertFirstButtonReturn, .OK: // Yes, save!
                break
            default:
                return true
            }
        }
 */
        return true
    }
}

