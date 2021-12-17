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
        // This code will not be called on macOS 12 Monterey with QLIsDataBasedPreview set.
        
        self.launcherService = nil
    }
    
    override func loadView() {
        // This code will not be called on macOS 12 Monterey with QLIsDataBasedPreview set.
        
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
        // This code will not be called on macOS 12 Monterey with QLIsDataBasedPreview set.
        
        // Add the supported content types to the QLSupportedContentTypes array in the Info.plist of the extension.
        
        // Perform any setup necessary in order to prepare the view.
        
        // Call the completion handler so Quick Look knows that the preview is fully loaded.
        // Quick Look will display a loading spinner while the completion handler is not called.
        
        do {
            self.handler = handler
            
            let html = try renderMD(url: url)
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
    
    @available(macOSApplicationExtension 12.0, *)
    func providePreview(for request: QLFilePreviewRequest, completionHandler handler: @escaping (QLPreviewReply?, Error?) -> Void) {
        // This code will be called on macOS 12 Monterey with QLIsDataBasedPreview set.
        
        // print("providePreview for \(request.fileURL)")
        
        do {
            Settings.shared.initFromDefaults()
            let html = try renderMD(url: request.fileURL)
            let replay = QLPreviewReply(dataOfContentType: .html, contentSize: .zero) { _ in
                return html.data(using: .utf8)!
            }
            
            // replay.title = request.fileURL.lastPathComponent
            replay.stringEncoding = .utf8
            handler(replay, nil)
        } catch {
            handler(nil, error)
        }
    }
    
    func renderMD(url: URL) throws -> String {
        os_log(
            "Generating preview for file %{public}s",
            log: self.log,
            type: .info,
            url.path
        )
        
        let type = UserDefaults.standard.string(forKey: "AppleInterfaceStyle") ?? "Light"
        
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
        
        let appearance: Appearance = type == "Light" ? .light : .dark
        let text = try settings.render(file: markdown_url, forAppearance: appearance, baseDir: markdown_url.deletingLastPathComponent().path, log: self.log)
        
        let html = settings.getCompleteHTML(title: url.lastPathComponent, body: text, footer: "", basedir: url.deletingLastPathComponent(), forAppearance: appearance)
            
        return html
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
            handler(nil)
            self.handler = nil
        }
        // Show the Quick Look preview only after the complete rendering (preventing a flickering glitch).
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
