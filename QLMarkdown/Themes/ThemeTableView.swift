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
    @IBOutlet weak var newKeywordMenu: NSMenuItem!
    @IBOutlet weak var deleteThemeMenu: NSMenuItem!
    
    var order: [Theme.PropertyName] = []
    var theme: ThemePreview? {
        didSet {
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
            newKeywordMenu.isEnabled = theme != nil && !theme!.isStandalone
            deleteThemeMenu.isEnabled = theme != nil && !theme!.isStandalone
            
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
        contentView.isHidden = true
        
        tableView.doubleAction = #selector(self.handleDoubleClick(_:))
    }
    
    func showPropertyEditor(name: Theme.PropertyName) {
        if let theme = self.theme, let vc = NSStoryboard.main?.instantiateController(withIdentifier: "ThemePropertyViewController") as? ThemePropertyViewController {
            vc.setTheme(theme, property: name)
            
            self.window?.contentViewController?.presentAsSheet(vc)
        }
    }
    
    @IBAction func handleDoubleClick(_ sender: Any) {
        guard tableView.clickedRow >= 0 else {
            return
        }
        
        let name = order[tableView.clickedRow]
        self.showPropertyEditor(name: name)
    }
    
    @IBAction func handleEditProperty(_ sender: NSMenuItem) {
        let row = sender.tag
        let name = order[row]
        self.showPropertyEditor(name: name)
    }
    
    
    @IBAction func revealApplicationSupportInFinder(_ sender: Any) {
        guard let url = Settings.themesFolder else {
            return
        }
        NSWorkspace.shared.selectFile(url.path, inFileViewerRootedAtPath: "")
    }
    
    @IBAction func handleAddKeyword(_ sender: Any) {
        guard let theme = self.theme else {
            return
        }
        let k = Theme.PropertyStyle(color: "#ffffff", italic: false, bold: false, underline: false)
        theme.keywords.append(k)
        theme.isDirty = true
        
        tableView.insertRows(at: IndexSet(integer: 12 + theme.keywords.count), withAnimation: .slideDown)
    }
    
    @IBAction func handleRemoveProperty(_ sender: NSMenuItem) {
        guard let theme = self.theme else {
            return
        }
        let row = sender.tag
        let name = order[row]
        guard name.isKeyword else {
            return
        }
        
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "Are you sure to remove this keyword?"
        alert.addButton(withTitle: "No").keyEquivalent = "\u{1b}"
        alert.addButton(withTitle: "Yes").keyEquivalent = "\r"
        let r = alert.runModal()
        if r == .alertSecondButtonReturn {
            let index = row - 12
            
            theme.keywords.remove(at: index)
            theme.isDirty = true
            
            tableView.beginUpdates()
            tableView.removeRows(at: IndexSet(integer: row), withAnimation: .slideUp)
            tableView.reloadData(forRowIndexes: IndexSet(row ..< (12 + theme.keywords.count)), columnIndexes: IndexSet(integer: 1))
            tableView.endUpdates()
        }
    }
    
    @IBAction func exportTheme(_ sender: Any) {
        guard let theme = self.theme else {
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
            alert.addButton(withTitle: "Cancel")
            alert.runModal()
        }
        // }
    }
    
    @IBAction func duplicateTheme(_ sender: Any) {
        
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
                cell.textField?.attributedStringValue = property?.getFormattedString(name.name, font: NSFont.systemFont(ofSize: NSFont.systemFontSize)) ?? NSAttributedString()
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
            cell.popupButton.menu?.item(at: 2)?.isHidden = !name.isKeyword
            cell.popupButton.menu?.items.forEach({ $0.tag = row })
            cell.popupButton.isEnabled = !theme.isStandalone
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
    @IBOutlet weak var popupButton: NSPopUpButton!
}
