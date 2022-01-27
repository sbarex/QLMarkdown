//
//  ThemesView.swift
//  QLMarkdown
//
//  Created by Sbarex on 15/12/20.
//

import Cocoa

class ThemesView: NSView {
    @IBOutlet weak var contentView: NSView!
    @IBOutlet weak var outlineView: NSOutlineView!
    @IBOutlet weak var filterThemePopup: NSPopUpButton!
    @IBOutlet weak var searchField: NSSearchField!
        
    weak var delegate: ThemesViewDelegate?
    
    var theme: ThemePreview? {
        didSet {
            delegate?.theme = theme
            guard oldValue != theme else { return }
            
            oldValue?.removeObserver(self, forKeyPath: #keyPath(ThemePreview.name))
            
            var index = -1
            if let theme = self.theme {
                theme.addObserver(self, forKeyPath: #keyPath(ThemePreview.name), options: [], context: nil)
                
                if theme.isStandalone, let i = standardThemes.firstIndex(of: theme) {
                    index = i + 1
                } else if !theme.isStandalone, let i = customThemes.firstIndex(of: theme) {
                    index = i + 2 + standardThemes.count
                }
            }
            if index > 0 {
                outlineView.expandItem(theme!.isStandalone ? "Standard" : "Custom")
                outlineView.selectRowIndexes(IndexSet(integer: index), byExtendingSelection: false)
                outlineView.scrollRowToVisible(index)
            } else {
                outlineView.selectRowIndexes(IndexSet(integer: -1), byExtendingSelection: false)
            }
        }
    }
    
    /*
    func setTheme(name: String?, scroll: Bool) {
        if let name = name, var index = themes.firstIndex(where: {$0.name == name}) {
            let theme = themes[index]
            index += !theme.isStandalone ? 2 : 1
            outlineView.selectRowIndexes(IndexSet(integer: index), byExtendingSelection: false)
            if scroll {
                outlineView.scrollRowToVisible(index)
            }
        } else {
            outlineView.selectRowIndexes(IndexSet(integer: -1), byExtendingSelection: false)
        }
    }
    */
    
    /// All (unfiltered) standard and custom themes.
    var allThemes: [ThemePreview] = [] {
        didSet {
            self.outlineView?.beginUpdates()
            refreshThemes(custom: nil)
            self.outlineView?.endUpdates()
        }
    }
    
    /// Filtered standard themes.
    var standardThemes: [ThemePreview] = [] {
        didSet {
            guard oldValue != standardThemes else { return }
            self.outlineView?.beginUpdates()
            self.outlineView?.reloadItem("Standard", reloadChildren: true)
            if let theme = self.theme {
                let i = outlineView.row(forItem: theme)
                if i >= 0 {
                    // Reselect current theme.
                    self.outlineView?.selectRowIndexes(IndexSet(integer: i), byExtendingSelection: false)
                }
            }
            self.outlineView?.endUpdates()
        }
    }
    
    /// Filtered custom themes.
    var customThemes: [ThemePreview] = [] {
        didSet {
            guard oldValue != customThemes else { return }
            self.outlineView?.beginUpdates()
            self.outlineView?.reloadItem("Custom", reloadChildren: true)
            if let theme = self.theme {
                let i = outlineView.row(forItem: theme)
                if i >= 0 {
                    // Reselect current theme.
                    self.outlineView?.selectRowIndexes(IndexSet(integer: i), byExtendingSelection: false)
                }
            }
            self.outlineView?.endUpdates()
        }
    }
    
    /// Filter for theme name.
    var filter: String = "" {
        didSet {
            guard oldValue != filter else { return }
            refreshThemes()
        }
    }
    
    /// Filter for theme style (light/dark).
    var style: Theme.ThemeAppearance = .undefined {
        didSet {
            guard oldValue != style else { return }
            refreshThemes()
        }
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }

    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
        setup()
    }
    
    private func setup() {
        let bundle = Bundle(for: type(of: self))
        let nib = NSNib(nibNamed: .init(String(describing: type(of: self))), bundle: bundle)!
        nib.instantiate(withOwner: self, topLevelObjects: nil)

        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.width, .height]
        
        self.outlineView.beginUpdates()
        
        // Fetch the themes.
        self.allThemes = Settings.shared.getAvailableThemes()
        
        if self.standardThemes.count > 0 {
            self.outlineView.expandItem("Standard")
        }
        if self.customThemes.count > 0 {
            self.outlineView.expandItem("Custom")
        }
        self.outlineView.endUpdates()
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleThemeDidAdd(_:)), name: .themeDidAdded, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleThemeDidDelete(_:)), name: .themeDidDeleted, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleThemeDidChange(_:)), name: .currentThemeDidChange, object: nil)
        
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: .themeDidAdded, object: nil)
        NotificationCenter.default.removeObserver(self, name: .themeDidDeleted, object: nil)
        NotificationCenter.default.removeObserver(self, name: .currentThemeDidChange, object: nil)
        theme?.removeObserver(self, forKeyPath: #keyPath(ThemePreview.name))
    }
    
    @objc func handleThemeDidAdd(_ notification: Notification) {
        self.allThemes = Settings.shared.getAvailableThemes()
    }
    
    @objc func handleThemeDidDelete(_ notification: Notification) {
        if let theme = notification.object as? ThemePreview, self.theme == theme {
            self.theme = nil
        }
        self.allThemes = Settings.shared.getAvailableThemes()
    }
    
    @objc func handleThemeDidChange(_ notification: Notification) {
        guard let theme = notification.object as? ThemePreview else {
            return
        }
        let index = self.outlineView.row(forItem: theme)
        if index >= 0 {
            self.outlineView.reloadData(forRowIndexes: IndexSet(integer: index), columnIndexes: IndexSet(integersIn: 0..<self.outlineView.numberOfColumns))
        }
    }
    
    @objc override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if let theme = object as? ThemePreview, theme == self.theme {
            if keyPath == #keyPath(ThemePreview.name) || keyPath == #keyPath(ThemePreview.image) {
                self.outlineView.reloadItem(theme)
                return
            }
        }
        super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
    }
    
    /// Update the list of theme visible in the outline view.
    func refreshThemes(custom: Bool? = nil) {
        var standalone = true
        let filter_func = { (theme: Theme) -> Bool in
            if self.filter != "" {
                guard let _ = theme.name.range(of: self.filter, options: String.CompareOptions.caseInsensitive) else {
                    // Name don't match the search criteria.
                    return false
                }
            }
            
            if theme.isStandalone != standalone {
                return false
            }
            
            switch self.style {
            case .light:
                if theme.appearance != .light {
                    // Theme is not light.
                    return false
                }
            case .dark:
                if theme.appearance != .dark {
                    // Theme is not dark.
                    return false
                }
            default:
                break
            }
            return true
        }
        
        if custom == nil || custom == false {
            standalone = true
            standardThemes = allThemes.filter(filter_func)
        }
        if custom == nil || custom == true {
            standalone = false
            customThemes = allThemes.filter(filter_func).sorted(by: { $0.name < $1.name })
        }
    }
    
    /// Append a custom theme to the list.
    func appendCustomTheme(_ newTheme: ThemePreview) {
        outlineView.beginUpdates()
        Settings.shared.appendTheme(newTheme)
        self.theme = newTheme
        outlineView.endUpdates()
    }
    
    func removeTheme(_ theme: ThemePreview?) {
        guard let theme = theme else {
            return
        }
        do {
            try Settings.shared.removeTheme(theme)
        } catch {
            let alert = NSAlert()
            alert.messageText = "Unable to delete the theme \(theme.name)!"
            alert.informativeText = error.localizedDescription
            alert.addButton(withTitle: "Close").keyEquivalent = "\u{1b}"
            
            alert.alertStyle = .critical
            alert.runModal()
        }
    }
    
    private func getThemeForMenu(_ menuItem: NSMenuItem?) -> ThemePreview? {
        let theme: ThemePreview?
        if let identifier = menuItem?.menu?.identifier?.rawValue, identifier == "contextual" {
            theme = outlineView.item(atRow: outlineView.clickedRow) as? ThemePreview
        } else {
            theme = self.theme
        }
        return theme
    }
    
    /// Duplicate the current color scheme.
    @IBAction func handleDuplicate(_ sender: Any) {
        guard let theme = self.getThemeForMenu(sender as? NSMenuItem) else {
            return
        }
        let newTheme = theme.duplicate()
        
        // List of current customized theme names.
        var names = customThemes.map({ $0.name })
        if theme.isStandalone {
            names.append(theme.name)
        }
        /// New name based to the source theme.
        let themeName = theme.name.duplicate(format: "%@_copy_%d", suffixPattern: #"_+copy_+(?<n>\d+)"#, list: names)
        
        newTheme.name = themeName
        
        Settings.shared.appendTheme(newTheme)
        self.theme = newTheme
        newTheme.isDirty = true
    }
    
    /// Add a new empty theme.
    @IBAction func handleAddTheme(_ sender: Any) {
        let themeName = "new_theme".duplicate(format: "%@_%d", suffixPattern: #"_(?<n>\d+)"#, list: customThemes.map({ $0.name }))
        let newTheme = ThemePreview(name: themeName)
        
        appendCustomTheme(newTheme)
        
        self.theme = newTheme
        newTheme.isDirty = true
    }
    
    /// Delete the current theme.
    @IBAction func handleDelTheme(_ sender: Any) {
        guard let theme = self.getThemeForMenu(sender as? NSMenuItem), !theme.isStandalone else {
            return
        }
        
        let alert = NSAlert()
        alert.messageText = "Are you sure to delete the \(theme.name) custom theme?"
        alert.addButton(withTitle: "Yes").keyEquivalent = "\r"
        alert.addButton(withTitle: "No").keyEquivalent = "\u{1b}"
        alert.alertStyle = .warning
        
        alert.beginSheetModal(for: self.contentView.window!) { (response) in
            guard response == .alertFirstButtonReturn else {
                return
            }
            self.removeTheme(theme)
        }
    }
    
    /// Update the list of themes based of the requested style.
    @IBAction func handleFilterStyle(_ sender: NSPopUpButton) {
        if sender.indexOfSelectedItem == 0 {
            style = .undefined
        } else if sender.indexOfSelectedItem == 1 {
            style = .light
        } else if sender.indexOfSelectedItem == 2 {
            style = .dark
        }
    }
    
    @IBAction func importTheme(_ sender: Any) {
        guard let themesFolder = Settings.themesFolder else {
            let alert = NSAlert()
            alert.messageText = "Missing themes folder!"
            alert.alertStyle = .critical
            alert.addButton(withTitle: "Close").keyEquivalent = "\u{1b}"
            alert.runModal()
            return
        }
        
        let openPanel = NSOpenPanel()
        openPanel.canCreateDirectories = false
        openPanel.showsTagField = false
        openPanel.allowedFileTypes = ["theme"]
        openPanel.isExtensionHidden = false
        openPanel.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.modalPanelWindow)))
        
        let result = openPanel.runModal()
        
        guard result == .OK, let src = openPanel.url else {
            return
        }
        guard src.pathExtension == "theme" else {
            let alert = NSAlert()
            alert.messageText = "Theme file must have the `.theme` extension!"
            alert.alertStyle = .critical
            alert.addButton(withTitle: "Close").keyEquivalent = "\u{1b}"
            alert.runModal()
            return
        }
        
        var exit_code: Int32 = 0
        var release: ReleaseTheme?
        let t = highlight_get_theme2(src.path.cString(using: .utf8), &exit_code, &release)
        defer {
            release?(t)
        }
        guard t != nil, exit_code == EXIT_SUCCESS else {
            let alert = NSAlert()
            alert.messageText = "Invalid file"
            alert.alertStyle = .critical
            alert.addButton(withTitle: "Close").keyEquivalent = "\u{1b}"
            alert.runModal()
            return
        }
        
        let dst = themesFolder.appendingPathComponent(src.lastPathComponent)
            
        if FileManager.default.fileExists(atPath: dst.path) {
            let alert = NSAlert()
            alert.messageText = "A theme already exists with the same name. \nDo you want to overwrite?"
            alert.alertStyle = .warning
            alert.addButton(withTitle: "No").keyEquivalent = "\u{1b}"
            alert.addButton(withTitle: "Yes").keyEquivalent = "\r"
            if alert.runModal() == .alertSecondButtonReturn {
                do {
                    try FileManager.default.removeItem(at: dst)
                } catch {
                    
                }
            } else {
                return
            }
        }
        do {
            try FileManager.default.copyItem(at: src, to: dst)
        } catch {
            let alert = NSAlert()
            alert.messageText = "Unable to import the theme!"
            alert.informativeText = error.localizedDescription
            alert.alertStyle = .critical
            alert.addButton(withTitle: "Close").keyEquivalent = "\u{1b}"
            alert.runModal()
            return
        }
    }
    
    @IBAction func exportTheme(_ sender: Any) {
        let theme: ThemePreview?
        if let identifier = (sender as? NSMenuItem)?.menu?.identifier?.rawValue, identifier == "contextual" {
            theme = outlineView.item(atRow: outlineView.clickedRow) as? ThemePreview
        } else {
            theme = self.theme
        }
        guard let theme = theme else {
            return
        }

        let savePanel = NSSavePanel()
        savePanel.canCreateDirectories = true
        savePanel.showsTagField = false
        savePanel.allowedFileTypes = ["theme"]
        savePanel.isExtensionHidden = false
        savePanel.nameFieldStringValue = "\(theme.name).theme"
        savePanel.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.modalPanelWindow)))
        
        let view = SaveAsFormatView(frame: NSRect(x: 0, y: 0, width: 200, height: 50))
        savePanel.accessoryView = view
        view.savePanel = savePanel
        
        let result = savePanel.runModal()
        // savePanel.begin { (result) in
        guard result.rawValue == NSApplication.ModalResponse.OK.rawValue, let url = savePanel.url else {
            return
        }
        do {
            if url.pathExtension == "css" {
                let css = theme.getCSSStyle()
                try css.write(toFile: url.path, atomically: true, encoding: .utf8)
            } else {
                try theme.write(toFile: url.path)
            }
        } catch {
            let alert = NSAlert()
            alert.alertStyle = .critical
            alert.messageText = "Unable to export the theme!"
            alert.addButton(withTitle: "Close").keyEquivalent = "\u{1b}"
            alert.runModal()
        }
        // }
    }

    @IBAction func revealTheme(_ sender: Any) {
        guard let theme = self.getThemeForMenu(sender as? NSMenuItem) else {
            return
        }
        if !theme.path.isEmpty && FileManager.default.fileExists(atPath: theme.path) {
            NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: theme.path)])
        } else {
            let alert = NSAlert()
            alert.messageText = "Unable to find the theme file."
            alert.informativeText = theme.path.isEmpty ? "Perhaps the theme has not yet been saved?" : ""
            alert.alertStyle = .informational
            alert.addButton(withTitle: "Close").keyEquivalent = "\u{1b}"
            alert.runModal()
        }
    }
    
    @IBAction func revealApplicationSupportInFinder(_ sender: Any) {
        guard let url = Settings.themesFolder else {
            return
        }
        NSWorkspace.shared.selectFile(url.path, inFileViewerRootedAtPath: "")
    }
}

// MARK: - NSControlTextEditingDelegate
extension ThemesView: NSControlTextEditingDelegate {
    /// Handle change on search field.
    func controlTextDidChange(_ obj: Notification) {
        guard obj.object as? NSSearchField == self.searchField else {
            return
        }
       
        filter = self.searchField.stringValue
    }
}


// MARK: - NSOutlineViewDataSource
extension ThemesView: NSOutlineViewDataSource {
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        if item == nil {
            return 2 // Standard and Custom item.
        } else if item as? String == "Standard" {
            // Standalone filtered themes.
            return standardThemes.count
        } else if item as? String == "Custom" {
            // Customized filtered themes.
            return customThemes.count
        } else {
            return 0
        }
    }
    
    func outlineView(_ outlineView: NSOutlineView, objectValueFor tableColumn: NSTableColumn?, byItem item: Any?) -> Any? {
        if let theme = item as? Theme {
            return theme
        } else if item as? String == "Standard" || item as? String == "Custom" {
            return item
        }
        return nil
    }
    
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        if item == nil {
            if index == 0 {
                return "Standard"
            } else {
                return "Custom"
            }
        } else if item as? String == "Standard" {
            return standardThemes[index]
        } else if item as? String == "Custom" {
            return customThemes[index]
        } else {
            return 0
        }
    }
    
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        if item is Theme {
            return false
        } else {
            return true
        }
    }
}

// MARK: - NSOutlineViewDelegate
extension ThemesView: NSOutlineViewDelegate {
    func outlineView(_ outlineView: NSOutlineView, shouldExpandItem item: Any) -> Bool {
        return item as? String != nil  // Allow expansion of only Standard and custom items.
    }
    
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        if let s = item as? String {
            if let cell = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "TitleCell"), owner: self) as? NSTableCellView {
                cell.textField?.stringValue = s
                return cell
            }
        } else if let _ = item as? ThemePreview {
            if let cell = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "ThemeCell"), owner: self) as? ThemeTableCellView {
                // The value for cell is passed with objectValue.
                return cell
            }
        }
        return nil
    }
    
    func outlineView(_ outlineView: NSOutlineView, heightOfRowByItem item: Any) -> CGFloat {
        if let _ = item as? ThemePreview {
            return 70
        } else {
            return 20
        }
    }
    
    func outlineView(_ outlineView: NSOutlineView, shouldSelectItem item: Any) -> Bool {
        return item is ThemePreview // Are selectable only theme rows.
    }
    
    func outlineViewSelectionDidChange(_ notification: Notification) {
        if outlineView.selectedRow >= 0, let item = outlineView.item(atRow: outlineView.selectedRow) as? ThemePreview {
            self.theme = item
        }
    }
}

// MARK: - NSMenuDelegate
extension ThemesView: NSMenuDelegate {
    func menuWillOpen(_ menu: NSMenu) {
        let theme = menu.identifier?.rawValue == "contextual" ? outlineView.item(atRow: outlineView.clickedRow) as? ThemePreview : self.theme
        for item in menu.items {
            if item.tag == 2 {
                item.isEnabled = !(theme?.isStandalone ?? true)
            } else if item.tag > 0 {
                item.isEnabled = theme != nil
            }
        }
    }
}

// MARK: - Theme Property Cells View

// Theme cell with icon and description for the outline view.
class ThemeTableCellView: NSTableCellView {
    @IBOutlet weak var changedLabel: NSView!
    
    override var objectValue: Any? {
        didSet {
            if let theme = objectValue as? ThemePreview {
                imageView?.image = theme.image
                let label = NSMutableAttributedString(string: theme.name, attributes: [.font: NSFont.labelFont(ofSize: NSFont.smallSystemFontSize)])
                    
                textField?.attributedStringValue = label
                changedLabel.isHidden = !theme.isDirty
            } else {
                imageView?.image = nil
                textField?.stringValue = ""
                changedLabel.isHidden = true
            }
        }
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        initialize()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        initialize()
    }
    
    internal func initialize() {
        imageView?.wantsLayer = true
        // Round the image corners.
        imageView?.layer?.cornerRadius = 8
        imageView?.layer?.masksToBounds = true
        imageView?.layer?.borderColor = NSColor.tertiaryLabelColor.cgColor
        imageView?.layer?.borderWidth = 1
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        initialize()
    }
}
