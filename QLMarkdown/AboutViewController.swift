//
//  AboutViewController.swift
//  QLMarkdown
//
//  Created by Sbarex on 31/12/20.
//

import Cocoa

class AboutViewController: NSViewController {
    @IBOutlet weak var imageView: NSImageView!
    @IBOutlet weak var titleField: NSTextField!
    @IBOutlet weak var versionField: NSTextField!
    @IBOutlet weak var copyrightField: NSTextField!
    @IBOutlet weak var infoTextView: NSTextView!
    
    override func viewDidLoad() {
        imageView.image = NSApplication.shared.applicationIconImage
        if let info = Bundle.main.infoDictionary {
            let version = info["CFBundleShortVersionString"] as? String ?? ""
            let build = info["CFBundleVersion"] as? String ?? ""
                
            titleField.stringValue = info["CFBundleExecutable"] as? String ?? "QLMarkdown"
            versionField.stringValue = "Version \(version) (\(build))"
            copyrightField.stringValue = info["NSHumanReadableCopyright"] as? String ?? ""
        } else {
            versionField.stringValue = ""
            copyrightField.stringValue = ""
        }
        
        let fg_color = NSColor.textColor.css() ?? "#000000"
        let bg_color = NSColor.textBackgroundColor.css() ?? "#ffffff"
        var s = "<div style='font-family: -apple-system; text-align: center; color: \(fg_color); background-color: \(bg_color)'>"
        
        s += "<b>Developer</b><br /><a href='https://github.com/sbarex/'>sbarex</a><br /><a href='https://github.com/sbarex/QLMarkdown'>https://github.com/sbarex/QLMarkdown</a><br /><br />"
        
        s += "<b>Libraries</b><br />"
        s += "cmark-gfm version \(String(cString: cmark_version_string())) (\(cmark_version())) (<a href=\"https://github.com/github/cmark-gfm\">https://github.com/github/cmark-gfm</a>)<br />\n"
        if let v = get_highlight_version() {
            defer {
                v.deallocate()
            }
            let web = get_highlight_website()
            defer {
                web?.deallocate()
            }
            
            var url = web != nil ? String(cString: web!) : ""
            if !url.isEmpty {
                url = "(<a href=\"\(url)\")>\(url)</a>)"
            }
            
            s += "highlight \(String(cString: v)) \(url)<br />\n"
        }
        
        s += "\(String(cString: get_lua_info()))<br />\n"
        s += "Enry (<a href=\"https://www.github.com/go-enry/go-enry/\">https://www.github.com/go-enry/go-enry/</a>)<br />\n"
        s += "<br />\n———<br />\n<br />\n"
        s += "Thanks to hazarek (<a href=\"https://github.com/hazarek\">https://github.com/hazarek</a>) for the css theme.<br />\n"
        
        s += "</div>"
       
        if let data = s.data(using: .utf8), let attributedString = try? NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.html, .characterEncoding: String.Encoding.utf8.rawValue], documentAttributes: nil) {
            infoTextView.textStorage?.setAttributedString(attributedString)
        }
    }
}

class AboutWindowController: NSWindowController {
    @IBAction func cancel(_ sender: Any?) {
        self.close()
    }
}
