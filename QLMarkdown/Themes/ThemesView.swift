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
    
    @IBOutlet weak var addThemeButton: NSButton!
    @IBOutlet weak var delThemeButton: NSButton!
    
    weak var delegate: ThemesViewDelegate?
    
    var theme: ThemePreview? {
        didSet {
            if oldValue != theme {
                delThemeButton.isEnabled = !(theme?.isStandalone ?? true)
                if let _ = theme, var index = themes.firstIndex(of: theme!) {
                    index += !theme!.isStandalone ? 2 : 1
                    outlineView.selectRowIndexes(IndexSet(integer: index), byExtendingSelection: false)
                } else {
                    outlineView.selectRowIndexes(IndexSet(integer: -1), byExtendingSelection: false)
                }
            }
            delegate?.theme = theme
        }
    }
    
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
    
    /// All (unfiltered) standard themes.
    var allThemes: [ThemePreview] = [] {
        didSet {
            refreshThemes(custom: false)
        }
    }
    /// All (unfiltered) custom themes.
    var allCustomThemes: [ThemePreview] = [] {
        didSet {
            refreshThemes(custom: true)
        }
    }
    
    /// Filtered standard themes.
    var themes: [ThemePreview] = [] {
        didSet {
            if oldValue != themes {
                self.outlineView?.reloadItem("Standard", reloadChildren: true)
                if let t = themes.first(where: { $0 == self.theme }) {
                    let i = outlineView.row(forItem: t)
                    if i >= 0 {
                        // Reselect current theme.
                        self.outlineView?.selectRowIndexes(IndexSet(integer: i), byExtendingSelection: false)
                    }
                }
            }
        }
    }
    
    /// Filtered custom themes.
    var customThemes: [ThemePreview] = [] {
        didSet {
            if oldValue != customThemes {
                self.outlineView?.reloadItem("Custom", reloadChildren: true)
                if let t = customThemes.first(where: { $0 == self.theme }) {
                    let i = self.outlineView.row(forItem: t)
                    if i >= 0 {
                        // Reselect current theme.
                        self.outlineView?.selectRowIndexes(IndexSet(integer: i), byExtendingSelection: false)
                    }
                }
            }
        }
    }
    
    /// Filter for theme name.
    var filter: String = "" {
        didSet {
            refreshThemes()
        }
    }
    
    /// Filter for theme style (light/dark).
    var style: Theme.ThemeAppearance = .undefined {
        didSet {
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
        self.themes = Settings.shared.getAvailableThemes() 
        
        self.allThemes = self.themes.filter({ $0.isStandalone })
        self.allCustomThemes = self.themes.filter({ !$0.isStandalone })
        
        if self.allThemes.count > 0 {
            self.outlineView.expandItem("Standard")
        }
        if self.allCustomThemes.count > 0 {
            self.outlineView.expandItem("Custom")
        }
        self.outlineView.endUpdates()
    }
    
    /// Update the list of theme visible in the outline view.
    func refreshThemes(custom: Bool? = nil) {
        let filter_func = { (theme: Theme) -> Bool in
            if self.filter != "" {
                guard let _ = theme.name.range(of: self.filter, options: String.CompareOptions.caseInsensitive) else {
                    // Name don't match the search criteria.
                    return false
                }
            }
            
            if !theme.isStandalone && !theme.isDirty {
                // Theme is not changed or is not standalone.
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
            themes = allThemes.filter(filter_func)
        }
        if custom == nil || custom == true {
            customThemes = allCustomThemes.filter(filter_func).sorted(by: { $0.name < $1.name })
        }
    }
    
    /// Append a custom theme to the list.
    func appendCustomTheme(_ newTheme: ThemePreview) {
        // newTheme.isStandalone = false
        // newTheme.addObserver(self, forKeyPath: "isDirty", options: [], context: nil)
        
        var themes = allCustomThemes
        themes.append(newTheme)
        themes.sort { (t1, t2) -> Bool in
            return t1.name < t2.name
        }
        
        contentView.window?.isDocumentEdited = true
        
        outlineView.beginUpdates()
        allCustomThemes = themes
            
        /// Index of inserted theme
        if let i = customThemes.firstIndex(where: { $0 == newTheme }) {
            // Expand the list of custom themes.
            outlineView.expandItem("Custom")
            let item = customThemes[i]
            let row = outlineView.row(forItem: item)
            if row >= 0 {
                // Select the new theme.
                outlineView.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
                // Scroll to the theme row.
                outlineView.scrollRowToVisible(row)
            }
        }
        outlineView.endUpdates()
    }
    
    func removeTheme() {
        /*
        guard let theme = self.theme, !theme.isStandalone else {
            return
        }
        
        let update = { () in
            /// Index of the theme in the list
            guard let index = self.allCustomThemes.firstIndex(where: { $0 == theme }) else {
                return
            }
            
            self.outlineView.beginUpdates()
            if let i = self.customThemes.firstIndex(where: { $0 == theme }) {
                // Remove the row of deleted theme.
                self.outlineView.removeItems(at: IndexSet(integer: i), inParent: "Custom", withAnimation: NSTableView.AnimationOptions.slideLeft)
            }
            
            // Remove the theme from the list
            let t = self.allCustomThemes.remove(at: index)
            t.theme.delegate = nil
            
            self.outlineView.endUpdates()
            
            // Update the dirty status of the windows.
            self.view.window?.isDocumentEdited = self.customThemes.first(where: { $0.isDirty }) != nil
                
            if self.theme == theme {
                self.theme = nil
            }
            
            NotificationCenter.default.post(name: .themeDidDeleted, object: NotificationThemeDeletedData(theme.name))
        }
        
        if theme.originalName.isEmpty {
            // Theme never saved.
            update()
        } else {
            service?.deleteTheme(name: theme.originalName) { (success, error) in
                if success {
                    DispatchQueue.main.async {
                        update()
                    }
                } else {
                    DispatchQueue.main.async {
                        let alert = NSAlert()
                        alert.window.title = "Error"
                        alert.messageText = "Unable to delete the theme \(theme.name)!"
                        alert.informativeText = error?.localizedDescription ?? ""
                        alert.addButton(withTitle: "Close")
                        
                        alert.alertStyle = .critical
                        alert.runModal()
                    }
                }
            }
        }
 */
    }
    
    /// Duplicate the current theme.
    @IBAction func handleDuplicate(_ sender: Any) {
        guard let theme = self.theme else {
            return
        }
        /*
        guard let newTheme = Theme(dict: theme.toDictionary()) else {
            return
        }
        
        // List of current customized theme names.
        var names = customThemes.map({ $0.name })
        if theme.isStandalone {
            names.append(theme.name)
        }
        /// New name based to the source theme.
        let themeName = theme.name.duplicate(format: "%@_copy_%d", suffixPattern: #"_+copy_+(?<n>\d+)"#, list: names)
        
        newTheme.name = themeName
        
        appendCustomTheme(newTheme)
        
        self.theme = newTheme
         */
    }
    
    /// Add a new empty theme.
    @IBAction func handleAddTheme(_ sender: Any) {
        let themeName = "new_theme".duplicate(format: "%@_%d", suffixPattern: #"_(?<n>\d+)"#, list: customThemes.map({ $0.name }))
        let newTheme = ThemePreview(name: themeName)
        newTheme.isDirty = true
        
        appendCustomTheme(newTheme)
        
        self.theme = newTheme
    }
    
    /// Delete the current theme.
    @IBAction func handleDelTheme(_ sender: Any) {
        guard let theme = self.theme, !theme.isStandalone else {
            return
        }
        
        let alert = NSAlert()
        alert.messageText = "Warning"
        alert.informativeText = "Are you sure to delete this custom theme?"
        alert.addButton(withTitle: "Yes")
        alert.addButton(withTitle: "No")
        alert.alertStyle = .warning
        
        alert.beginSheetModal(for: self.contentView.window!) { (response) in
            guard response == .alertFirstButtonReturn else {
                return
            }
            self.removeTheme()
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
            return themes.count
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
            return themes[index]
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
