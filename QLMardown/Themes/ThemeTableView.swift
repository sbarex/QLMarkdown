//
//  File.swift
//  QLMardown
//
//  Created by Sbarex on 15/12/20.
//

import Cocoa

class ThemeTableView: NSView {
    @IBOutlet weak var contentView: NSView!
    @IBOutlet weak var tableView: NSTableView!
    
    var theme: Theme? {
        didSet {
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
        
        tableView.doubleAction = #selector(self.handleDoubleClick(_:))
    }
    
    func showPropertyEditor(_ property: Theme.PropertyStyle, name: Theme.PropertyName) {
        if let vc = NSStoryboard.main?.instantiateController(withIdentifier: "ThemePropertyViewController") as? ThemePropertyViewController {
            vc.themeProperty = property
            vc.themePropertyKey = name
            
            self.window?.contentViewController?.presentAsSheet(vc)
        }
    }
    
    @IBAction func test(_ sender: NSButton) {
        /*
        var topLevelArray: NSArray? = nil
        Bundle.main.loadNibNamed(NSNib.Name("ThemePropertyView"), owner: nil, topLevelObjects: &topLevelArray)
        guard let results = topLevelArray else { return }
        let views = Array<Any>(results).filter { $0 is NSView }
        guard let view = views.last as? NSView, let properyView = view as? ThemePropertyView else {
            return
        }
 */
        if let vc = NSStoryboard.main?.instantiateController(withIdentifier: "ThemePropertyViewController") as? ThemePropertyViewController {
            let popover = NSPopover()
            popover.contentViewController = vc
            vc.popover = popover
            popover.behavior = .applicationDefined
            popover.show(relativeTo: sender.bounds, of: sender, preferredEdge: .minX)
        }
    }
    
    @IBAction func handleDoubleClick(_ sender: Any) {
        guard tableView.clickedRow >= 0 else {
            return
        }
        guard let styles = theme?.styles else {
            return
        }
        let p = Array(styles)[tableView.clickedRow]
        self.showPropertyEditor(p.value, name: p.key)
    }
    
    @IBAction func handleEditProperty(_ sender: NSMenuItem) {
        let row = sender.tag
        guard let styles = theme?.styles else {
            return
        }
        let p = Array(styles)[row]
        self.showPropertyEditor(p.value, name: p.key)
    }
    
    @IBAction func handleRemoveProperty(_ sender: NSMenuItem) {
        let row = sender.tag
        guard let styles = theme?.styles else {
            return
        }
        let p = Array(styles)[row]
        let alert = NSAlert()
        alert.messageText = "Warning"
        alert.informativeText = "Are you sure to delete the \"\(p.key.name)\" property?"
        alert.addButton(withTitle: "Remove")
        alert.addButton(withTitle: "Cancel").keyEquivalent = "\u{1b}"
        
        alert.alertStyle = .warning
        let r = alert.runModal()
        if r == .alertFirstButtonReturn {
            print("delete")
        }
    }
    
    @IBAction func exportTheme(_ sender: Any) {
        guard let theme = self.theme else {
            return
        }
        let savePanel = NSSavePanel()
        savePanel.canCreateDirectories = true
        savePanel.showsTagField = false
        savePanel.allowedFileTypes = ["org.go.source", "json"]
        savePanel.isExtensionHidden = false
        savePanel.nameFieldStringValue = "\(theme.name).json"
        savePanel.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.modalPanelWindow)))
        
        let view = SaveAsFormatView(frame: NSRect(x: 0, y: 0, width: 200, height: 50))
        
        savePanel.accessoryView = view
        let result = savePanel.runModal()
        // savePanel.begin { (result) in
        guard result.rawValue == NSApplication.ModalResponse.OK.rawValue, let url = savePanel.url else {
            return
        }
        
        if view.popupButton.indexOfSelectedItem == 0 {
            var code: [String: String] = [:]
            for style in theme.styles {
                let export = style.value.export()
                if !export.isEmpty {
                    code[style.key.rawValue] = export
                }
            }
            
            let encoder = JSONEncoder()
            do {
                let json = try encoder.encode(code)
                try json.write(to: url)
            } catch {
                let alert = NSAlert()
                alert.alertStyle = .critical
                alert.messageText = "Unable to export the theme!"
                alert.addButton(withTitle: "Cancel")
                alert.runModal()
            }
        } else {
            let name = theme.name.camelized
            var code = """
    package styles
        
    import (
        "github.com/alecthomas/chroma"
    )
        
    var \(name) = Register(chroma.MustNewStyle("\(name)", chroma.StyleEntries{

    """
            for style in theme.styles {
                let export = style.value.export()
                if !export.isEmpty {
                    code += "\tchroma.\(style.key.rawValue): \"\(export)\"\n"
                }
            }
            code += "}))\n"
            do {
                try code.write(toFile: url.path, atomically: true, encoding: .utf8)
            } catch {
                let alert = NSAlert()
                alert.alertStyle = .critical
                alert.messageText = "Unable to export the theme!"
                alert.addButton(withTitle: "Cancel")
                alert.runModal()
            }
        }
        // }
    }
    
    @IBAction func exportThemeAsJSON(_ sender: Any) {
        guard let theme = self.theme else {
            return
        }
        let savePanel = NSSavePanel()
        savePanel.canCreateDirectories = true
        savePanel.showsTagField = false
        savePanel.nameFieldStringValue = "\(theme.name).json"
        savePanel.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.modalPanelWindow)))
        savePanel.begin { (result) in
            guard result.rawValue == NSApplication.ModalResponse.OK.rawValue, let url = savePanel.url else {
                return
            }
            var code: [String: String] = [:]
            for style in theme.styles {
                let export = style.value.export()
                if !export.isEmpty {
                    code[style.key.rawValue] = export
                }
            }
            
            let encoder = JSONEncoder()
            do {
                let json = try encoder.encode(code)
                try json.write(to: url)
            } catch {
                let alert = NSAlert()
                alert.alertStyle = .critical
                alert.messageText = "Unable to export the theme!"
                alert.addButton(withTitle: "Cancel")
                alert.runModal()
            }
        }
    }
}

// MARK: - NSTableViewDataSource
extension ThemeTableView: NSTableViewDataSource {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return theme?.styles.count ?? 0
    }
    
    /*
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        if let keys = theme?.styles.keys, let key = keys.first, let style = theme?.styles[key] {
            return style.getFormattedString(key.name, font: NSFont.systemFont(ofSize: NSFont.systemFontSize))
        }
        return nil
    }
    */
}

// MARK: - NSTableViewDelegate
extension ThemeTableView: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let styles = theme?.styles else {
            return nil
        }
        let p = Array(styles)[row]
        
        if tableColumn?.identifier.rawValue == "name" {
            guard let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "PropertyCell"), owner: self) as? NSTableCellView else {
                return nil
            }
            cell.textField?.attributedStringValue = p.value.getFormattedString(p.key.name, font: NSFont.systemFont(ofSize: NSFont.systemFontSize), defaultBackground: NSColor(css: theme?.styles[.background]?.background) ?? .clear, foreground: NSColor(css: nil) ?? .black)
            if let c = p.value.background, let cc = NSColor(css: c) {
                cell.textField?.backgroundColor = cc
                cell.textField?.drawsBackground = true
            } else {
                cell.textField?.drawsBackground = false
            }
            cell.textField?.wantsLayer = true
            cell.textField?.layer?.cornerRadius = 4
            if let c = p.value.border, let cc = NSColor(css: c) {
                cell.textField?.layer?.borderColor = cc.cgColor
                cell.textField?.layer?.borderWidth = 1
            } else {
                cell.textField?.layer?.borderColor = .clear
                cell.textField?.layer?.borderWidth = 0
            }
            cell.toolTip = p.key.name
            
            return cell
        } else if tableColumn?.identifier.rawValue == "bold" || tableColumn?.identifier.rawValue == "italic" || tableColumn?.identifier.rawValue == "underline" {
            guard let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "ImageCell"), owner: self) as? NSTableCellView else {
                return nil
            }
            let state: Bool?
            let image: String
            let tip: String
            if tableColumn?.identifier.rawValue == "bold" {
                state = p.value.bold
                image = "bold"
                tip = state == nil ? "Bold state inherited from the container element." : (state! ? "Bold enabled" : "Bold disabled")
            } else if tableColumn?.identifier.rawValue == "italic" {
                state = p.value.italic
                image = "italic"
                tip = state == nil ? "Italic state inherited from the container element." : (state! ? "Italic enabled" : "Italic disabled")
            } else {
                state = p.value.underline
                image = "underline"
                tip = state == nil ? "Underline state inherited from the container element." : (state! ? "Underline enabled" : "Underline disabled")
            }
            cell.toolTip = tip
            cell.imageView?.image = state == nil ? nil : NSImage(named: state! ? "\(image)_on" : "\(image)_off")
            return cell
        } else if tableColumn?.identifier.rawValue == "bg" || tableColumn?.identifier.rawValue == "fg" || tableColumn?.identifier.rawValue == "border" {
            guard let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "ColorCell"), owner: self) as? NSTableCellView else {
                return nil
            }
            let color: String?
            let tip: String
            if tableColumn?.identifier.rawValue == "bg" {
                color = p.value.background
                tip = color == nil ? "Background color inherited from the container element." : "Background color."
            } else if tableColumn?.identifier.rawValue == "fg" {
                color = p.value.foreground
                tip = color == nil ? "Foreground color inherited from the container element." : "Foreground color."
            } else {
                color = p.value.border
                tip = color == nil ? "Border color inherited from the container element." : "Border color."
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
            cell.popupButton.menu?.items.forEach({ $0.tag = row })
            return cell
        } else if tableColumn?.identifier.rawValue == "CSS" {
            guard let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "TextCell"), owner: self) as? NSTableCellView else {
                return nil
            }
            cell.textField?.stringValue = p.key.cssClass
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
