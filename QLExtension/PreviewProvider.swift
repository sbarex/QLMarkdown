//
//  PreviewProvider.swift
//  QLExtension
//
//  Created by Sbarex on 16/12/20.
//

import Cocoa
import Quartz
import OSLog
import WebKit


/// View-based Quick Look preview so local documents can be rendered without leaving the panel.
class PreviewProvider: NSViewController, QLPreviewingController, WKNavigationDelegate {
    private var webView: WKWebView!
    private let backButton = NSButton(title: NSLocalizedString("Back", comment: "Preview navigation"), target: nil, action: nil)
    private let forwardButton = NSButton(title: NSLocalizedString("Forward", comment: "Preview navigation"), target: nil, action: nil)
    private let documentLabel = NSTextField(labelWithString: "")
    private let errorLabel = NSTextField(wrappingLabelWithString: "")
    private var history: [URL] = []
    private var historyIndex = -1
    private var isLoadingDocument = false
    private var initialCompletion: ((Error?) -> Void)?

    private var currentURL: URL? {
        history.indices.contains(historyIndex) ? history[historyIndex] : nil
    }

    static var previewContentSize: CGSize {
        let size = Settings.shared.qlWindowSize
        guard let screen = NSScreen.main else { return size }
        let available = screen.visibleFrame.size
        return CGSize(width: min(size.width, available.width * 0.9),
                      height: min(size.height, available.height * 0.9))
    }

    override func loadView() {
        view = NSView(frame: NSRect(origin: .zero, size: Self.previewContentSize))
        preferredContentSize = Self.previewContentSize
        let configuration = WKWebViewConfiguration()
        // WebKit can reject unreadable file targets before calling the navigation delegate.
        // Capture anchor activation in the main document so missing links still report an error.
        configuration.userContentController.addUserScript(WKUserScript(source: """
            document.addEventListener('click', function(event) {
                const link = event.target.closest ? event.target.closest('a[href]') : null;
                if (!link || event.defaultPrevented || event.button !== 0) return;
                event.preventDefault();
                window.webkit.messageHandlers.previewLink.postMessage(link.href);
            });
            """, injectionTime: .atDocumentStart, forMainFrameOnly: true))
        configuration.userContentController.add(PreviewLinkMessageHandler { [weak self] message in
            guard message.frameInfo.isMainFrame, let href = message.body as? String,
                  let url = URL(string: href) else { return }
            self?.openLink(url)
        }, name: "previewLink")
        webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = self
        webView.allowsLinkPreview = false
        backButton.target = self
        backButton.action = #selector(goBack)
        forwardButton.target = self
        forwardButton.action = #selector(goForward)
        for button in [backButton, forwardButton] {
            button.bezelStyle = .rounded
        }
        documentLabel.lineBreakMode = .byTruncatingMiddle
        documentLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        let toolbar = NSStackView(views: [backButton, forwardButton, documentLabel])
        toolbar.spacing = 8
        errorLabel.textColor = .secondaryLabelColor
        errorLabel.isHidden = true
        let stack = NSStackView(views: [toolbar, errorLabel, webView])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8),
            stack.topAnchor.constraint(equalTo: view.topAnchor, constant: 8),
            stack.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            toolbar.widthAnchor.constraint(equalTo: stack.widthAnchor),
            errorLabel.widthAnchor.constraint(equalTo: stack.widthAnchor),
            webView.widthAnchor.constraint(equalTo: stack.widthAnchor),
        ])
        updateNavigation()
    }

    func preparePreviewOfFile(at url: URL, completionHandler handler: @escaping (Error?) -> Void) {
        _ = view
        Settings.shared.startMonitorChange()
        initialCompletion?(NSError(domain: NSCocoaErrorDomain, code: NSUserCancelledError))
        initialCompletion = handler
        webView.stopLoading()
        isLoadingDocument = false
        history = []
        historyIndex = -1
        showDocument(url)
    }

    private func showDocument(_ url: URL, historyPosition: Int? = nil) {
        guard !isLoadingDocument else { return }
        do {
            // Read failures must leave the current preview and its history intact.
            let file = Settings.getMarkdownFile(from: PreviewLink.fileURL(url))
            _ = try Data(contentsOf: file)
            let html = try renderMD(url: PreviewLink.fileURL(url))
            if let position = historyPosition {
                historyIndex = position
            } else {
                history = Array(history.prefix(historyIndex + 1))
                history.append(url)
                historyIndex = history.count - 1
            }
            errorLabel.isHidden = true
            isLoadingDocument = true
            updateNavigation()
            // Using the document URL makes both relative paths and #fragments resolve correctly.
            webView.loadHTMLString(html, baseURL: file)
        } catch {
            errorLabel.stringValue = String.localizedStringWithFormat(
                NSLocalizedString("Unable to open “%@”. Check that the file exists and is readable.", comment: "Preview link error"),
                url.lastPathComponent)
            errorLabel.isHidden = false
            finishInitialPreview(error)
        }
    }

    private func updateNavigation() {
        backButton.isEnabled = !isLoadingDocument && historyIndex > 0
        forwardButton.isEnabled = !isLoadingDocument && historyIndex + 1 < history.count
        documentLabel.stringValue = currentURL?.lastPathComponent ?? ""
        documentLabel.toolTip = currentURL?.path
    }

    @objc private func goBack() {
        guard historyIndex > 0 else { return }
        showDocument(history[historyIndex - 1], historyPosition: historyIndex - 1)
    }

    @objc private func goForward() {
        guard historyIndex + 1 < history.count else { return }
        showDocument(history[historyIndex + 1], historyPosition: historyIndex + 1)
    }

    private func finishInitialPreview(_ error: Error?) {
        let completion = initialCompletion
        initialCompletion = nil
        completion?(error)
    }

    private func scrollToFragment(_ fragment: String?) {
        guard let fragment = fragment, !fragment.isEmpty,
              let data = try? JSONSerialization.data(withJSONObject: [fragment]),
              let json = String(data: data, encoding: .utf8) else { return }
        webView.evaluateJavaScript("(document.getElementById(\(json)[0]) || document.getElementsByName(\(json)[0])[0])?.scrollIntoView()", completionHandler: nil)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        isLoadingDocument = false
        scrollToFragment(currentURL?.fragment?.removingPercentEncoding)
        updateNavigation()
        finishInitialPreview(nil)
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        navigationFailed(error)
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        navigationFailed(error)
    }

    private func navigationFailed(_ error: Error) {
        isLoadingDocument = false
        errorLabel.stringValue = NSLocalizedString("The preview could not be loaded. Try reopening Quick Look.", comment: "Preview load error")
        errorLabel.isHidden = false
        updateNavigation()
        finishInitialPreview(error)
    }

    func webView(_ webView: WKWebView, decidePolicyFor action: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard action.navigationType == .linkActivated else {
            // Only our own HTML load may replace the main document. Embedded frames cannot navigate it.
            let documentURL = currentURL.map { Settings.getMarkdownFile(from: PreviewLink.fileURL($0)) }
            let isHTMLLoad = isLoadingDocument && action.targetFrame?.isMainFrame == true
                && (action.request.url == documentURL || action.request.url?.absoluteString == "about:blank")
            decisionHandler(isHTMLLoad ? .allow : .cancel)
            return
        }
        decisionHandler(.cancel)
        guard action.sourceFrame.isMainFrame, let url = action.request.url else { return }
        openLink(url)
    }

    private func openLink(_ url: URL) {
        guard !isLoadingDocument else { return }
        if PreviewLink.isMarkdown(url) {
            showDocument(url)
        } else if url.isFileURL {
            // Fragment links in non-Markdown previews (for example .mermaid or textbundles).
            if let current = currentURL,
               PreviewLink.fileURL(url) == Settings.getMarkdownFile(from: PreviewLink.fileURL(current)) {
                scrollToFragment(url.fragment?.removingPercentEncoding)
            }
        } else if Settings.isExternalSchemeAllowed(url) {
            NSWorkspace.shared.open(url)
        }
    }

    func renderMD(url: URL) throws -> String {
        os_log(
            "Generating preview for file %{public}s",
            log: OSLog.quickLookExtension,
            type: .info,
            url.path
        )

        let settings = Settings.shared
        Settings.renderStats += 1

        let markdown_url = Settings.getMarkdownFile(from: url)
        var text = try settings.render(file: markdown_url, baseDir: markdown_url.deletingLastPathComponent().path)
        
        if Settings.renderStats > 0 && Settings.renderStats % 100 == 0 {
            let icon: String
            if let url = Bundle.main.url(forResource: "icon", withExtension: "png"), let data = try? Data(contentsOf: url) {
                icon = data.base64EncodedString()
            } else {
                icon = ""
            }
            
            let stats = String.localizedStringWithFormat(NSLocalizedString("Thanks to this application you have viewed over <b>%d files</b>.", comment: "Quick Look about stats"), Settings.renderStats)
            let donation = NSLocalizedString("If you find it useful and you have the possibility, consider <a href=\"https://buymeacoffee.com/sbarex\"><b>buying me a coffee!</b></a>", comment: "Quick Look about donation link")
            let credit = String.localizedStringWithFormat(NSLocalizedString("Developed by SBAREX with ❤️ | <a href=\"%@\">%@</a>", comment: "Quick Look about developer credit"), "https://github.com/sbarex/QLMarkdown", "https://github.com/sbarex/QLMarkdown")
            
            let msg =
                """
                        <div id="container" style="font-size: 1.5rem">
                            <h1><img src="data:image/png;base64,\(icon)" width="75" height="75" alt="logo" id="logo" /> QLMarkdown</h1>
                            <p>\(stats)</p>
                            <p>\(donation)</p>
                            <br />
                            <hr size="1" />
                            <p class="small">\(credit)</p>
                            </p>
                        </div>
                """

            text += msg
        }

        let html = settings.getCompleteHTML(title: url.lastPathComponent, body: text)

        return html
    }
}

/// Keep URL classification independent of WebKit so encoded paths and query strings can be tested.
enum PreviewLink {
    static func fileURL(_ url: URL) -> URL {
        var components = URLComponents(url: url, resolvingAgainstBaseURL: true)!
        components.query = nil
        components.fragment = nil
        return components.url!.standardizedFileURL
    }

    static func isMarkdown(_ url: URL) -> Bool {
        guard url.isFileURL, url.host == nil || url.host == "" || url.host == "localhost" else { return false }
        return ["md", "markdown", "mdown", "mkd", "mkdn", "mdx", "mdc", "rmd", "qmd", "apib"]
            .contains(fileURL(url).pathExtension.lowercased())
    }
}

/// The content controller retains its handlers; the closure captures the preview weakly.
private class PreviewLinkMessageHandler: NSObject, WKScriptMessageHandler {
    private let handle: (WKScriptMessage) -> Void

    init(handle: @escaping (WKScriptMessage) -> Void) {
        self.handle = handle
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        handle(message)
    }
}
