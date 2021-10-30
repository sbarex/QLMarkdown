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
import external_launcher

class MyWKWebView: WKWebView {
    override var canBecomeKeyView: Bool {
        return false
    }
    
    override func becomeFirstResponder() -> Bool {
        // Quick Look window do not allow first responder child.
        return false
    }
}

@available(macOS, deprecated: 10.14)
class MyWebView: WebView {
    override var canBecomeKeyView: Bool {
        return false
    }
    
    override func becomeFirstResponder() -> Bool {
        // Quick Look window do not allow first responder child.
        return false
    }
}

class PreviewViewController: NSViewController, QLPreviewingController {
    var webView: MyWKWebView!
    
    private let log = {
        return OSLog(subsystem: Bundle.main.bundleIdentifier!, category: "quicklook.qlmarkdown-extension")
    }()
    
    var handler: ((Error?) -> Void)? = nil
    
    override var nibName: NSNib.Name? {
        return NSNib.Name("PreviewViewController")
    }
    
    var launcherService: ExternalLauncherProtocol?

    deinit {
        Settings.shared.stopMonitorChange()
    }
    
    override func viewDidDisappear() {
        self.launcherService = nil
        // Releases the script handler which retain a strong reference to self which prevents the WebKit process from being released.
        self.webView.configuration.userContentController.removeScriptMessageHandler(forName: "imageExtensionHandler")
    }
    
    override func loadView() {
        super.loadView()
        // Do any additional setup after loading the view.
        
        Settings.shared.startMonitorChange()
        
        if #available(macOS 11, *) {
            let connection = NSXPCConnection(serviceName: "org.sbarex.qlmarkdown.external-launcher")
            
            connection.remoteObjectInterface = NSXPCInterface(with: ExternalLauncherProtocol.self)
            connection.resume()
            
            self.launcherService = connection.synchronousRemoteObjectProxyWithErrorHandler { error in
                print("Received error:", error)
            } as? ExternalLauncherProtocol
        }
        
        let settings = Settings.shared
        
        let previewRect: CGRect
        if #available(macOS 11, *) {
            previewRect = self.view.bounds
        } else {
            previewRect = self.view.bounds.insetBy(dx: 2, dy: 2)
        }
        
        /*
        if #available(macOS 11, *) {
            // On Big Sur there are some bugs with the current WKWebView:
            // - WKWebView crash on launch because ignore the com.apple.security.network.client entitlement (workaround setting the com.apple.security.temporary-exception.mach-lookup.global-name exception for com.apple.nsurlsessiond
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
            // Create a configuration for the preferences
            let configuration = WKWebViewConfiguration()
            configuration.preferences.javaScriptEnabled = settings.unsafeHTMLOption && settings.inlineImageExtension
            configuration.allowsAirPlayForMediaPlayback = false
        
            // Handler to replace raw <image> src with the embedded data.
            configuration.userContentController.add(self, name: "imageExtensionHandler")
        
            self.webView = MyWKWebView(frame: previewRect, configuration: configuration)
            self.webView.autoresizingMask = [.height, .width]
            
            self.webView.wantsLayer = true
            if #available(macOS 11, *) {
                self.webView.layer?.borderWidth = 0
            } else {
                // Draw a border around the web view
                self.webView.layer?.borderColor = NSColor.gridColor.cgColor
                self.webView.layer?.borderWidth = 1
            }
        
            self.webView.navigationDelegate = self
            // webView.uiDelegate = self

            self.view.addSubview(self.webView)
        
            /*
            self.webView.translatesAutoresizingMaskIntoConstraints = false
            var padding: CGFloat = 2
            if #available(macOS 11, *) {
                padding = 0
            }
        
            NSLayoutConstraint(item: self.webView!, attribute: .leading, relatedBy: .equal, toItem: view, attribute: .leading, multiplier: 1.0, constant: padding).isActive = true
            NSLayoutConstraint(item: self.webView!, attribute: .trailing, relatedBy: .equal, toItem: view, attribute: .trailing, multiplier: 1.0, constant: padding).isActive = true
            NSLayoutConstraint(item: self.webView!, attribute: .top, relatedBy: .equal, toItem: view, attribute: .top, multiplier: 1.0, constant: padding).isActive = true
            NSLayoutConstraint(item: self.webView!, attribute: .bottom, relatedBy: .equal, toItem: view, attribute: .bottom, multiplier: 1.0, constant: padding).isActive = true
            */
            
       /* } */
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
        
        let markdown_url: URL
        if let typeIdentifier = (try? url.resourceValues(forKeys: [.typeIdentifierKey]))?.typeIdentifier, typeIdentifier == "org.textbundle.package" {
            if FileManager.default.fileExists(atPath: url.appendingPathComponent("text.md").path) {
                markdown_url = url.appendingPathComponent("text.md")
            } else {
                markdown_url = url.appendingPathComponent("text.markdown")
            }
        } else {
            markdown_url = url
        }
        
        do {
            let text = try settings.render(file: markdown_url, forAppearance: type == "Light" ? .light : .dark, baseDir: markdown_url.deletingLastPathComponent().path, log: self.log)
            
            let extrajs: String
            if settings.unsafeHTMLOption && settings.inlineImageExtension {
                extrajs = "<script type=\"text/javascript\">" + (settings.getBundleContents(forResource: "inlineimages", ofType: "js") ?? "") + "</script>\n";
            } else {
                extrajs = ""
            }
            let html = settings.getCompleteHTML(title: url.lastPathComponent, body: text, footer: extrajs)
            /*
            if #available(macOS 11, *) {
                self.webView.mainFrame.loadHTMLString(html, baseURL: nil)
            } else {
            */
            self.webView.isHidden = true // hide the webview until complete rendering
            self.webView.loadHTMLString(html, baseURL: url.deletingLastPathComponent())
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

extension PreviewViewController: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == "imageExtensionHandler", Settings.shared.unsafeHTMLOption && Settings.shared.inlineImageExtension else {
            return
        }
        guard let dict = message.body as? [String : AnyObject], let src = dict["src"] as? String, let id = dict["id"] as? String else {
            return
        }

        guard let data = get_base64_image(
            src.cString(using: .utf8),
            { (path: UnsafePointer<Int8>?, context: UnsafeMutableRawPointer?) -> UnsafeMutablePointer<Int8>? in
                let magic_file = Settings.shared.getResourceBundle().path(forResource: "magic", ofType: "mgc")?.cString(using: .utf8)
                
                let r = magic_get_mime_by_file(path, magic_file)
                return r
            },
            nil
        ) else {
            return
        }
        defer {
            data.deallocate()
        }
        let response: [String: String] = [
            "src": src,
            "id": id,
            "data": String(cString: data)
        ]
        let encoder = JSONEncoder()
        guard let j = try? encoder.encode(response), let js = String(data: j, encoding: .utf8) else {
            return
        }

        message.webView?.evaluateJavaScript("replaceImageSrc(\(js))") { (r, error) in
            if let result = r as? Bool, !result {
                os_log(
                    "Unable to replace <img> src %{public}s with the inline data.",
                    log: self.log,
                    type: .error,
                    src
                )
            }
            if let error = error {
                os_log(
                    "Unable to replace <img> src %{public}s with the inline data: %{public}s.",
                    log: self.log,
                    type: .error,
                    src, error.localizedDescription
                )
            }
        }
    }
}

extension PreviewViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if let handler = self.handler {
            // Show the Quick Look preview only after the complete rendering (preventing a flickering glitch).
            
            handler(nil)
            self.handler = nil
        }
        // Wait to show the webview to prevent a resize glitch.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.webView.isHidden = false
        }
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        if let handler = self.handler {
            handler(error)
            self.handler = nil
            self.webView.isHidden = false
        }
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if !Settings.shared.openInlineLink, navigationAction.navigationType == .linkActivated, let url = navigationAction.request.url, url.scheme != "file" {
            if #available(macOS 11, *) {
                // On Big Sur NSWorkspace.shared.open fail with this error on Console:
                // Launch Services generated an error at +[_LSRemoteOpenCall(PrivateCSUIAInterface) invokeWithXPCConnection:object:]:455, converting to OSStatus -54: Error Domain=NSOSStatusErrorDomain Code=-54 "The sandbox profile of this process is missing "(allow lsopen)", so it cannot invoke Launch Services' open API." UserInfo={NSDebugDescription=The sandbox profile of this process is missing "(allow lsopen)", so it cannot invoke Launch Services' open API., _LSLine=455, _LSFunction=+[_LSRemoteOpenCall(PrivateCSUIAInterface) invokeWithXPCConnection:object:]}
                // Using a XPC service is a valid workaround.
                launcherService?.open(url, withReply: { r in
                    // print("open result: \(r)")
                })
                decisionHandler(.cancel)
                return
            } else {
                let r = NSWorkspace.shared.open(url)
                if r {
                    decisionHandler(.cancel)
                    return
                }
            }
        }
        decisionHandler(.allow)
    }
}
