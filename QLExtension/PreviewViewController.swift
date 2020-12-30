//
//  PreviewViewController.swift
//  QLExtension
//
//  Created by Sbarex on 16/12/20.
//

import Cocoa
import Quartz
import WebKit
import OSLog

class MyWKWebView: WKWebView {
    override var canBecomeKeyView: Bool {
        return false
    }
    
    override func becomeFirstResponder() -> Bool {
        // Quicklook window do not allow first responder child.
        return false
    }
}

@available(macOS, deprecated: 10.14)
class MyWebView: WebView {
    override var canBecomeKeyView: Bool {
        return false
    }
    
    override func becomeFirstResponder() -> Bool {
        // Quicklook window do not allow first responder child.
        return false
    }
}

class PreviewViewController: NSViewController, QLPreviewingController {
    private let log = {
        return OSLog(subsystem: Bundle.main.bundleIdentifier!, category: "quicklook.qlmarkdown-extension")
    }()
    
    var handler: ((Error?) -> Void)? = nil
    
    override var nibName: NSNib.Name? {
        return NSNib.Name("PreviewViewController")
    }

    override func loadView() {
        super.loadView()
        // Do any additional setup after loading the view.
        
        Settings.shared.startMonitorChange()
    }
    
    internal func getBundleContents(forResource: String, ofType: String) -> String?
    {
        if let p = Bundle.main.path(forResource: forResource, ofType: ofType), let data = FileManager.default.contents(atPath: p), let s = String(data: data, encoding: .utf8) {
            return s
        } else {
            return nil
        }
    }

    /*
     * Implement this method and set QLSupportsSearchableItems to YES in the Info.plist of the extension if you support CoreSpotlight.
     *
    func preparePreviewOfSearchableItem(identifier: String, queryString: String?, completionHandler handler: @escaping (Error?) -> Void) {
        // Perform any setup necessary in order to prepare the view.
        
        // Call the completion handler so Quick Look knows that the preview is fully loaded.
        // Quick Look will display a loading spinner while the completion handler is not called.
        handler(nil)
    }
     */
    
    func preparePreviewOfFile(at url: URL, completionHandler handler: @escaping (Error?) -> Void) {
        
        // Add the supported content types to the QLSupportedContentTypes array in the Info.plist of the extension.
        
        // Perform any setup necessary in order to prepare the view.
        
        // Call the completion handler so Quick Look knows that the preview is fully loaded.
        // Quick Look will display a loading spinner while the completion handler is not called.
        
        os_log(
            "Generating preview for file %{public}s",
            log: self.log,
            type: .info,
            url.path
        )
        
        let type = UserDefaults.standard.string(forKey: "AppleInterfaceStyle") ?? "Light"
        
        self.handler = handler
        
        let settings = Settings.shared
        
        do {
            let text = try settings.render(file: url, forAppearance: type == "Light" ? .light : .dark, baseDir: url.deletingLastPathComponent().path, log: self.log)
            
            let html = settings.getCompleteHTML(title: url.lastPathComponent, body: text)
            
            let previewRect: CGRect
            if #available(macOS 11, *) {
                previewRect = self.view.bounds
            } else {
                previewRect = self.view.bounds.insetBy(dx: 2, dy: 2)
            }
            
            /*
            if #available(macOS 11, *) {
                // On Big Sur there are some bugs with the current WKWebView:
                // - WKWebView crash on launch becaouse ignore the com.apple.security.network.client entitlement (workaround setting the com.apple.security.temporary-exception.mach-lookup.global-name exception for com.apple.nsurlsessiond
                // - WKWebView cannot scroll when QL preview window is in fullscreen.
                // Old WebView API works.
                let webView = MyWebView(frame: previewRect)
                webView.autoresizingMask = [.height, .width]
                webView.preferences.isJavaScriptEnabled = false
                webView.preferences.allowsAirPlayForMediaPlayback = false
                webView.preferences.arePlugInsEnabled = false
                
                self.view.addSubview(webView)
                
                webView.mainFrame.loadHTMLString(html, baseURL: nil)
                webView.frameLoadDelegate = self
                webView.drawsBackground = false // Best solution is use the same color of the body
            } else {
            */
                let preferences = WKPreferences()
                preferences.javaScriptEnabled = false

                // Create a configuration for the preferences
                let configuration = WKWebViewConfiguration()
                //configuration.preferences = preferences
                configuration.allowsAirPlayForMediaPlayback = false
                // configuration.userContentController.add(self, name: "jsHandler")
                
                let webView = MyWKWebView(frame: previewRect, configuration: configuration)
                webView.autoresizingMask = [.height, .width]
                
                webView.wantsLayer = true
                if #available(macOS 11, *) {
                    webView.layer?.borderWidth = 0
                } else {
                    // Draw a border around the web view
                    webView.layer?.borderColor = NSColor.gridColor.cgColor
                    webView.layer?.borderWidth = 1
                }
            
                webView.navigationDelegate = self
                // webView.uiDelegate = self

                webView.loadHTMLString(html, baseURL: nil)
                self.view.addSubview(webView)
                
                webView.loadHTMLString(html, baseURL: url.deletingLastPathComponent())
           /* } */
        } catch {
            handler(error)
        }
    }
}

@available(macOS, deprecated: 10.14)
extension PreviewViewController: WebFrameLoadDelegate {
    func webView(_ sender: WebView!, didFinishLoadFor frame: WebFrame!) {
        if let handler = self.handler {
            handler(nil)
        }
        self.handler = nil
    }
    func webView(_ sender: WebView!, didFailLoadWithError error: Error!, for frame: WebFrame!) {
        if let handler = self.handler {
            handler(error)
        }
        self.handler = nil
    }
}

extension PreviewViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if let handler = self.handler {
            // Show the quicklook preview only after the complete rendering (preventing a flickering glitch).
            
            handler(nil)
            self.handler = nil
        }
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        if let handler = self.handler {
            handler(error)
            self.handler = nil
        }
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if !Settings.shared.openInlineLink, navigationAction.navigationType == .linkActivated, let url = navigationAction.request.url, url.scheme != "file" {
            // FIXME: on big sur fail with this error on Console:
            // Launch Services generated an error at +[_LSRemoteOpenCall(PrivateCSUIAInterface) invokeWithXPCConnection:object:]:455, converting to OSStatus -54: Error Domain=NSOSStatusErrorDomain Code=-54 "The sandbox profile of this process is missing "(allow lsopen)", so it cannot invoke Launch Services' open API." UserInfo={NSDebugDescription=The sandbox profile of this process is missing "(allow lsopen)", so it cannot invoke Launch Services' open API., _LSLine=455, _LSFunction=+[_LSRemoteOpenCall(PrivateCSUIAInterface) invokeWithXPCConnection:object:]}
            let r = NSWorkspace.shared.open(url)
            print(r, url.absoluteString)
            if r {
                decisionHandler(.cancel)
                return
            }
        }
        decisionHandler(.allow)
    }
}
