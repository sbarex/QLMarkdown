//
//  File.swift
//  QLMarkdown
//
//  Created by Sbarex on 15/12/20.
//

import Cocoa

class ThemeTableView: NSView {
    @IBOutlet weak var contentView: NSView!
    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet weak var nameField: NSTextField!
    @IBOutlet weak var descriptionField: NSTextField!
    @IBOutlet weak var styleControl: NSSegmentedControl!
    @IBOutlet weak var newKeywordButton: NSButton!
    @IBOutlet weak var saveButton: NSButton!
    
    var order: [Theme.PropertyName] = []
    
    var isDirty: Bool = false {
        didSet {
            guard oldValue != isDirty else { return }
        }
    }
    
    var theme: ThemePreview? {
        didSet {
            oldValue?.removeObserver(self, forKeyPath: #keyPath(ThemePreview.isDirty))
            
            contentView.isHidden = theme == nil
            
            nameField.isEditable = !(theme?.isStandalone ?? true)
            nameField.stringValue = theme?.name ?? ""
            descriptionField.isEditable = !(theme?.isStandalone ?? true)
            descriptionField.stringValue = theme?.desc ?? ""
            styleControl.isEnabled = !(theme?.isStandalone ?? true)
            if theme?.appearance == .light {
                styleControl.setSelected(true, forSegment: 1)
            } else if theme?.appearance == .dark {
                styleControl.setSelected(true, forSegment: 2)
            } else {
                styleControl.setSelected(true, forSegment: 0)
            }
             
            order = [
                .canvas,
                .plain,
                .number,
                .string,
                .escape,
                .preProcessor,
                .stringPreProc,
                .blockComment,
                .lineComment,
                .lineNum,
                .operator,
                .interpolation,
            ]
            for i in 0..<100 {
                order.append(.keyword(index: i))
            }
            
            tableView.reloadData()
            self.isDirty = theme?.isDirty ?? false
            self.newKeywordButton.isHidden = theme?.isStandalone ?? true
            self.saveButton.isHidden = self.theme?.isStandalone ?? true
            theme?.addObserver(self, forKeyPath: #keyPath(ThemePreview.isDirty), options: [], context: nil)
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
    
    deinit {
        theme?.removeObserver(self, forKeyPath: #keyPath(ThemePreview.isDirty))
    }
    
    private func setup() {
        let bundle = Bundle(for: type(of: self))
        let nib = NSNib(nibNamed: .init(String(describing: type(of: self))), bundle: bundle)!
        nib.instantiate(withOwner: self, topLevelObjects: nil)

        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.width, .height]
        contentView.isHidden = true
        
        tableView.doubleAction = #selector(self.handleDoubleClick(_:))
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        if let theme = object as? ThemePreview, theme == self.theme {
            if keyPath == #keyPath(ThemePreview.isDirty) {
                if theme.isDirty {
                    self.window?.isDocumentEdited = true
                }
                NotificationCenter.default.post(name: .currentThemeDidChange, object: theme)
            }
        }
    }
    
    func showPropertyEditor(name: Theme.PropertyName) {
        if let theme = self.theme, let vc = NSStoryboard.main?.instantiateController(withIdentifier: "ThemePropertyViewController") as? ThemePropertyViewController {
            vc.setTheme(theme, property: name)
            vc.action = { vc in
                guard let prop = theme[name] else {
                    return
                }

                prop.color = vc.color
                prop.bold = vc.bold <= 0 ? nil : vc.bold == 1
                prop.italic = vc.italic <= 0 ? nil : vc.italic == 1
                prop.underline = vc.underline <= 0 ? nil : vc.underline == 1
                
                theme.invalidateImage()
                
                if name == .canvas || name == .plain {
                    self.tableView.reloadData()
                } else {
                    self.tableView.reloadData(forRowIndexes: IndexSet(integer: name.index), columnIndexes: IndexSet(integersIn: 0..<self.tableView.numberOfColumns))
                }
                
                theme.isDirty = true
                self.isDirty = true
            }
            
            self.window?.contentViewController?.presentAsSheet(vc)
        }
    }
    
    @IBAction func handleDoubleClick(_ sender: Any) {
        guard let theme = self.theme, !theme.isStandalone, tableView.clickedRow >= 0 else {
            return
        }
        
        let name = order[tableView.clickedRow]
        self.showPropertyEditor(name: name)
    }
    
    @IBAction func handleEditProperty(_ sender: Any) {
        let row: Int
        if sender is NSMenuItem {
            row = self.tableView.clickedRow
        } else if let sender = sender as? NSButton {
            row = sender.tag
        } else {
            return
        }
        let name = order[row]
        self.showPropertyEditor(name: name)
    }
    
    @IBAction func handleStyleChanged(_ sender: NSSegmentedControl) {
        guard let theme = self.theme, !theme.isStandalone else {
            return
        }
        switch sender.indexOfSelectedItem {
        case 0: theme.appearance = .undefined
        case 1: theme.appearance = .light
        case 2: theme.appearance = .dark
        default: break
        }
    }
    
    @objc func controlTextDidChange(_ obj: Notification) {
        guard let textField = obj.object as? NSTextField, let theme = self.theme, !theme.isStandalone else {
            return
        }
        if textField == self.nameField {
            theme.name = textField.stringValue
        } else if textField == self.descriptionField {
            theme.desc = textField.stringValue
        }
    }
    
    @IBAction func handleAddKeyword(_ sender: Any) {
        guard let theme = self.theme, !theme.isStandalone else {
            return
        }
        let k = Theme.PropertyStyle(color: "#999999", italic: false, bold: false, underline: false)
        theme.keywords.append(k)
        theme.isDirty = true
        self.isDirty = true
        
        tableView.insertRows(at: IndexSet(integer: 12 + theme.keywords.count), withAnimation: .slideDown)
    }
    
    @IBAction func handleRemoveProperty(_ sender: Any) {
        guard let theme = self.theme, !theme.isStandalone else {
            return
        }
        let row: Int
        if sender is NSMenuItem {
            row = self.tableView.clickedRow
        } else if let sender = sender as? NSButton {
            row = sender.tag
        } else {
            return
        }
        let name = order[row]
        guard name.isKeyword else {
            return
        }
        
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "Are you sure to remove the keyword \(name.keywordIndex+1)?"
        alert.addButton(withTitle: "No").keyEquivalent = "\u{1b}"
        alert.addButton(withTitle: "Yes").keyEquivalent = "\r"
        let r = alert.runModal()
        if r == .alertSecondButtonReturn {
            let index = row - 12
            
            theme.keywords.remove(at: index)
            theme.isDirty = true
            self.isDirty = true
            
            tableView.beginUpdates()
            tableView.removeRows(at: IndexSet(integer: row), withAnimation: .slideUp)
            tableView.reloadData(forRowIndexes: IndexSet(row ..< (12 + theme.keywords.count)), columnIndexes: IndexSet(integer: 1))
            tableView.endUpdates()
        }
    }
    
    @IBAction func saveTheme(_ sender: Any) {
        guard let theme = self.theme, !theme.isStandalone else { return }
        
        do {
            try theme.save()
            self.isDirty = false
        } catch {
            let alert = NSAlert()
            alert.messageText = "Unable to save the theme in \(theme.path)"
            alert.informativeText = error.localizedDescription
            alert.alertStyle = .critical
            alert.runModal()
        }
    }
}

// MARK: - NSMenuDelegate

extension ThemeTableView: NSMenuDelegate {
    func menuWillOpen(_ menu: NSMenu) {
        menu.items.forEach({
            if $0.tag == 1 {
                $0.isEnabled = !(theme?.isStandalone ?? true) && self.tableView.clickedRow >= 0 && self.order[self.tableView.clickedRow].isKeyword
                $0.isHidden = !(theme?.isStandalone ?? true) && self.tableView.clickedRow >= 0 && self.order[self.tableView.clickedRow].isKeyword
            } else {
                $0.isEnabled = !(theme?.isStandalone ?? true)
                if $0.tag == 2 {
                    if self.tableView.clickedRow >= 0 {
                        let prop = self.order[self.tableView.clickedRow]
                        $0.title = "Edit the \(prop.name) style"
                    } else {
                        $0.title = "Edit"
                    }
                }
            }
        })
    }
}

// MARK: - NSTableViewDataSource
extension ThemeTableView: NSTableViewDataSource {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return theme == nil ? 0 : 12 + theme!.keywords.count // theme?.styles.count ?? 0
    }
}

// MARK: - NSTableViewDelegate
extension ThemeTableView: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let theme = self.theme else {
            return nil
        }
        
        let name = order[row]
        let property = theme[name]
        
        if tableColumn?.identifier.rawValue == "name" {
            let background = NSColor(css: theme.canvas.color) ?? .white
            guard let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "PropertyCell"), owner: self) as? NSTableCellView else {
                return nil
            }
            if name == .canvas {
                cell.textField?.stringValue = name.name
                cell.textField?.textColor = NSColor(css: theme.plain.color) ?? .textColor
            } else {
                cell.textField?.attributedStringValue = property?.getFormattedString(name.name, font: NSFont.systemFont(ofSize: NSFont.systemFontSize), plainColor: theme.plain.color) ?? NSAttributedString()
            }
            
            cell.textField?.backgroundColor = background
            cell.textField?.drawsBackground = true
            
            cell.textField?.wantsLayer = true
            cell.textField?.layer?.cornerRadius = 4
            
            cell.toolTip = name.name
            
            return cell
        } else if tableColumn?.identifier.rawValue == "bold" || tableColumn?.identifier.rawValue == "italic" || tableColumn?.identifier.rawValue == "underline" {
            guard let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "ImageCell"), owner: self) as? NSTableCellView else {
                return nil
            }
            let state: Bool?
            let image: String
            let tip: String
            if tableColumn?.identifier.rawValue == "bold" {
                state = property?.bold
                image = "bold"
                tip = state == nil ? "Bold state inherited from the container element." : (state! ? "Bold enabled" : "Bold disabled")
            } else if tableColumn?.identifier.rawValue == "italic" {
                state = property?.italic
                image = "italic"
                tip = state == nil ? "Italic state inherited from the container element." : (state! ? "Italic enabled" : "Italic disabled")
            } else {
                state = property?.underline
                image = "underline"
                tip = state == nil ? "Underline state inherited from the container element." : (state! ? "Underline enabled" : "Underline disabled")
            }
            cell.toolTip = tip
            cell.imageView?.image = state == nil ? nil : NSImage(named: state! ? "\(image)_on" : "\(image)_off")
            return cell
        } else if tableColumn?.identifier.rawValue == "color" {
            guard let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "ColorCell"), owner: self) as? NSTableCellView else {
                return nil
            }
            let color: String? = property?.color
            let tip: String
            if name == .canvas {
                tip = "Background color."
            } else {
                tip = "Foreground color."
            }
            cell.toolTip = tip
            cell.textField?.stringValue = color == nil ? "-" : ""
            cell.textField?.wantsLayer = true
            cell.textField?.layer?.cornerRadius = 8
            cell.textField?.drawsBackground = color != nil
            cell.textField?.backgroundColor =  (color != nil ? NSColor(css: color!) : nil) ?? .clear
            return cell
        } else if tableColumn?.identifier.rawValue == "detail" {
            guard let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "DetailCell"), owner: self) as? DetailPropertyCellView else {
                return nil
            }
            cell.deleteButton.isEnabled = !theme.isStandalone
            cell.deleteButton.isHidden = theme.isStandalone || !name.isKeyword
            cell.deleteButton.tag = row
            cell.editButton.isEnabled = !theme.isStandalone
            cell.editButton.isHidden = theme.isStandalone
            cell.editButton.tag = row
            return cell
        } else if tableColumn?.identifier.rawValue == "CSS" {
            guard let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "TextCell"), owner: self) as? NSTableCellView else {
                return nil
            }
            cell.textField?.stringValue = "." + name.cssClass.joined(separator: ".")
            return cell
        } else {
            return nil
        }
    }
    
    /*
    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        return row > 4
    }
    */
    
    /*
    func tableViewSelectionDidChange(_ notification: Notification) {
        let row = tableView.selectedRow
        guard let styles = theme?.styles, row >= 0 else {
            return
        }
        let p = Array(styles)[row]
        
        if let vc = NSStoryboard.main?.instantiateController(withIdentifier: "ThemePropertyViewController") as? ThemePropertyViewController {
            vc.themeProperty = p.value
            vc.themePropertyKey = p.key
            
            self.window?.contentViewController?.presentAsSheet(vc)
            return
            let popover = NSPopover()
            popover.contentViewController = vc
            vc.popover = popover
            popover.behavior = .applicationDefined
            popover.show(relativeTo: tableView.rect(ofRow: row), of: tableView, preferredEdge: .maxY)
        }
        self.tableView.deselectRow(row)
    }
    */
}

class DetailPropertyCellView: NSTableCellView {
    @IBOutlet weak var editButton: NSButton!
    @IBOutlet weak var deleteButton: NSButton!
}
