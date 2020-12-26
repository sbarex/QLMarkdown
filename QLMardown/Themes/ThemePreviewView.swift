//
//  ThemePreviewView.swift
//  QLMardown
//
//  Created by Sbarex on 15/12/20.
//

import Cocoa
import WebKit

typealias ExampleItem = (url: URL, title: String, uti: String)

class ThemePreviewView: NSView {
    @IBOutlet weak var contentView: NSView!
    @IBOutlet weak var webView: WKWebView!
    @IBOutlet weak var messageLabel: NSTextField!
    @IBOutlet weak var examplesPopup: NSPopUpButton!
    @IBOutlet weak var refreshButton: NSButton!
    
    var theme: ThemePreview? {
        didSet {
            examplesPopup.isEnabled = theme != nil
            refreshButton.isEnabled = theme != nil
            
            if theme == nil {
                webView.isHidden = true
                messageLabel.isHidden = false
            } else {
                webView.isHidden = false
                messageLabel.isHidden = true
                refreshPreview(self)
            }
        }
    }
    /// List of available source file examples.
    var examples: [ExampleItem] = []
    
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
        /*constrain(self, contentView) { view, subview in
            subview.edges == view.edges
        }*/
        
        // Populate the example files list.
        examples = self.getAvailableExamples()
        examplesPopup.removeAllItems()
        examplesPopup.addItem(withTitle: "Theme colors")
        examplesPopup.menu?.addItem(NSMenuItem.separator())
        for file in examples {
            let m = NSMenuItem(title: file.title, action: nil, keyEquivalent: "")
            m.toolTip = file.uti
            examplesPopup.menu?.addItem(m)
        }
        examplesPopup.isEnabled = true
        
        // Register a custom js handler.
        webView.configuration.userContentController.add(self, name: "jsHandler")
        self.webView.configuration.preferences.setValue(true, forKey: "developerExtrasEnabled")
    }
    
    /// Get the list of available source file example.
    func getAvailableExamples() -> [ExampleItem] {
        // Populate the example files list.
        var examples: [ExampleItem] = []
        if let examplesDirURL = Bundle.main.url(forResource: "examples", withExtension: nil) {
            let fileManager = FileManager.default
            if let files = try? fileManager.contentsOfDirectory(at: examplesDirURL, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles]) {
                for file in files {
                    let title: String
                    if let uti = UTTypeCreatePreferredIdentifierForTag(
                        kUTTagClassFilenameExtension,
                        file.pathExtension as CFString,
                        nil)?.takeRetainedValue(), let desc = UTTypeCopyDescription(uti)?.takeRetainedValue() as String? {
                        title = desc.prefix(1).uppercased() + desc.dropFirst() + " (.\(file.pathExtension))"
                    } else {
                        title = file.lastPathComponent
                    }
                    examples.append((url: file, title: title, uti: ""))
                }
                examples.sort { (a, b) -> Bool in
                    a.title < b.title
                }
            }
        }
        return examples
    }
    
    /// Refresh the preview.
    @IBAction func refreshPreview(_ sender: Any) {
        guard let theme = self.theme else {
            return
        }
        
        let example: URL?
        if examplesPopup.indexOfSelectedItem == 0 || examples.count == 0 {
            example = nil
        } else {
            example = self.examples[examplesPopup.indexOfSelectedItem-2].url
        }
            
        if let url = example, let data = FileManager.default.contents(atPath: url.path), let code = String(data: data, encoding: .utf8) {
            /*
            /// Show a file.
            var settings: [String: Any] = [
                SCSHSettings.Key.theme: theme.name,
                SCSHSettings.Key.inlineTheme: theme.toDictionary(),
                SCSHSettings.Key.renderForExtension: false,
                SCSHSettings.Key.lineNumbers: true,
                SCSHSettings.Key.customCSS: "* { box-sizing: border-box; } html, body { height: 100%; margin: 0; } body { padding: 0; }"
            ]
            */
            
            if let s = colorizeCode(code.cString(using: .utf8)!, url.pathExtension, theme.name, false, true) {
                defer {
                    free(s);
                }
                if let html = String(cString: s, encoding: .utf8) {
                    self.webView.loadHTMLString(html, baseURL: nil)
                } else {
                    self.webView.loadHTMLString("error", baseURL: nil)
                }
            } else {
                self.webView.loadHTMLString("error", baseURL: nil)
            }
        } else {
            // Show standard theme preview.
            let schema = theme.getHtmlExample()
            webView.loadHTMLString(schema, baseURL: nil)
        }
    }
}

// MARK: - WKNavigationDelegate
extension ThemePreviewView: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        /*
        let c = NSColor.selectedControlColor.toHexString()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25, execute: {
            // Encapsulate a script to handle click on the property elements.
            self.webView.evaluateJavaScript("""
            (function() {
                if (window.css_initialized) {
                    return;
                }
                window.css_initialized = true
                const style=document.createElement('style');
                style.type='text/css';
                const css = "<style type='text/css'>* {transition: background-color 0.5s; box-sizing: border-box; } .blink {background-color: \(c);}</style>";
                
                
                style.appendChild(document.createTextNode(css));
                document.getElementsByTagName('head')[0].appendChild(style);
                
                window.blinkProperty = function(selector) {
                    const color = "\(c)";
                    console.log(selector);
                    const e = jQuery(selector).addClass("blink");
                    window.setTimeout(function() {
                        e.removeClass("blink");
                    }, 500);
                }

                window.jQuery('html').css({ height: "100%" });
                window.jQuery('body').css({ height: "100%" });
                window.jQuery('.hl').click(function(event) {
                    let classes = [];
                    const css = this.classList;
                    classes.push(this.tagName)
                    for (var i = 0; i < css.length; i++) {
                        classes.push(css.item(i))
                    }
                    window.webkit.messageHandlers.jsHandler.postMessage({classes: classes, text: this.innerHTML});
                    event.stopPropagation();
                });
            })();
                
            true; // result returned to swift
            """){ (result, error) in
                if let e = error {
                    print(e)
                }
            }
        })
        */
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        
    }
}

// MARK: - WKScriptMessageHandler
extension ThemePreviewView: WKScriptMessageHandler {
    /// Handle messages from the webkit.
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        /*
        
        guard message.name == "jsHandler", let result = message.body as? [String: Any], let classes = result["classes"] as? [String] else {
            return
        }
        
        let name: SCSHTheme.Property.Name
        if classes.first == "BODY" {
            name = .canvas
        } else {
            guard let className = classes.last, let n = SCSHTheme.Property.Name.nameForCSSClass(className) else {
                
                return
            }
            name = n
        }
        
        var index: Int?
        if name.isKeyword {
            index = SCSHTheme.Property.Name.indexOfKeyword(name)
            if index != nil {
                index = index! + SCSHTheme.Property.Name.standardProperties.count
            }
        } else {
            index = SCSHTheme.Property.Name.standardProperties.firstIndex(of: name)
        }
        
        guard index != nil else {
            return
        }
        
        tableView.scrollRowToVisible(index! + 3)
        
        if let row = tableView.rowView(atRow: index! + 3, makeIfNecessary: false) {
            // Blink the row.
            row.wantsLayer = true
            let layer = row.layer
            let anime = CABasicAnimation(keyPath: "backgroundColor")
            anime.fromValue = layer?.backgroundColor
            anime.toValue = NSColor.selectedControlColor.cgColor
            anime.duration = 0.25
            anime.autoreverses = true
            anime.repeatCount = 1
            layer?.add(anime, forKey: "backgroundColor")
        }
         */
    }
}
