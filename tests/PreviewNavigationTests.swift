import Cocoa
import WebKit

/// Uses the production preview controller and real WebKit with a small HTML-rendering Settings
/// substitute. It tests navigation independently of the C renderer and external dependencies.
@main
struct PreviewNavigationTests {
    static func require(_ condition: @autoclosure () -> Bool, _ message: String) {
        guard condition() else { fatalError(message) }
    }

    static func wait(_ message: String = "preview", _ condition: () -> Bool) {
        let deadline = Date().addingTimeInterval(15)
        while !condition() && Date() < deadline {
            RunLoop.current.run(until: Date().addingTimeInterval(0.02))
        }
        require(condition(), "Timed out waiting for \(message)")
    }

    static func descendants(_ view: NSView) -> [NSView] {
        [view] + view.subviews.flatMap(descendants)
    }

    static func main() throws {
        _ = NSApplication.shared
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root.appendingPathComponent("docs"), withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let first = root.appendingPathComponent("index.md")
        let second = root.appendingPathComponent("docs/Other Page.MD")
        try """
        <html><body><h1>Index</h1>
        <a id="next" target="_blank" href="docs/Other%20Page.MD?view=1#details">Next</a>
        <a id="missing" href="missing.md">Missing</a>
        <a id="html" href="unsafe.html">HTML</a>
        <a id="scheme" href="custom-app://do-something">Custom scheme</a>
        </body></html>
        """.write(to: first, atomically: true, encoding: .utf8)
        try """
        <html><body><h1>Other page</h1><div style="height:2000px"></div>
        <h2 id="details">Details</h2><a id="parent" href="../index.md">Parent</a></body></html>
        """.write(to: second, atomically: true, encoding: .utf8)
        let base = first
        for path in ["docs/Other%20Page.MD#details", "../parent.markdown", "./guide.qmd?x=1"] {
            require(PreviewLink.isMarkdown(URL(string: path, relativeTo: base)!.absoluteURL), "Local Markdown must be accepted")
        }
        for link in ["https://example.com/file.md", "file://server/share/doc.md", "file:///tmp/a.html", "javascript:alert(1)"] {
            require(!PreviewLink.isMarkdown(URL(string: link)!), "Unsafe/nonlocal link must be rejected")
        }
        let queried = URL(string: "docs/Other%20Page.MD?x=1#details", relativeTo: base)!.absoluteURL
        require(PreviewLink.fileURL(queried) == second, "Query and fragment must not become part of the filename")

        let preview = PreviewProvider()
        let window = NSWindow(contentRect: NSRect(x: 100, y: 100, width: 960, height: 700),
                              styleMask: [.titled, .closable, .resizable], backing: .buffered, defer: false)
        window.title = "QLMarkdown Navigation Test"
        // Quick Look embeds the preview in its own host; reproduce those required size constraints.
        let host = NSViewController()
        host.view = NSView(frame: NSRect(x: 0, y: 0, width: 960, height: 700))
        host.addChild(preview)
        host.view.addSubview(preview.view)
        preview.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            preview.view.leadingAnchor.constraint(equalTo: host.view.leadingAnchor),
            preview.view.trailingAnchor.constraint(equalTo: host.view.trailingAnchor),
            preview.view.topAnchor.constraint(equalTo: host.view.topAnchor),
            preview.view.bottomAnchor.constraint(equalTo: host.view.bottomAnchor),
        ])
        window.contentViewController = host
        window.makeKeyAndOrderFront(nil)
        defer { window.orderOut(nil) }
        var ready = false
        preview.preparePreviewOfFile(at: first) { error in
            require(error == nil, "Initial preview must succeed")
            ready = true
        }
        let views = descendants(preview.view)
        let web = views.compactMap { $0 as? WKWebView }.first!
        let back = views.compactMap { $0 as? NSButton }.first { $0.title == "Back" }!
        let forward = views.compactMap { $0 as? NSButton }.first { $0.title == "Forward" }!
        let label = views.compactMap { $0 as? NSTextField }.first { $0.lineBreakMode == .byTruncatingMiddle }!
        func javascript(_ script: String) -> Any? {
            var done = false
            var value: Any?
            web.evaluateJavaScript(script) { result, error in
                require(error == nil, "JavaScript operation must succeed")
                value = result
                done = true
            }
            wait("JavaScript: \(script)") { done }
            return value
        }
        func click(_ id: String) { _ = javascript("document.getElementById('\(id)').click()") }
        func loaded(_ filename: String) {
            wait(filename) { label.stringValue == filename && (back.isEnabled || forward.isEnabled) && !web.isLoading && (javascript("document.readyState") as? String) == "complete" }
        }
        wait("initial HTML load") { ready }
        require(!back.isEnabled && !forward.isEnabled, "History must start empty")
        click("next")
        loaded("Other Page.MD")
        wait("Back enabled") { back.isEnabled }
        require((javascript("document.querySelector('h1').textContent") as? String) == "Other page", "Linked Markdown must be rendered")
        require((javascript("window.scrollY") as? Double ?? 0) > 0, "Cross-document fragment must scroll")
        back.performClick(nil)
        loaded("index.md")
        require(forward.isEnabled, "Back must preserve forward history")
        forward.performClick(nil)
        loaded("Other Page.MD")
        click("parent")
        loaded("index.md")
        click("missing")
        wait("missing file error") { descendants(preview.view).compactMap { $0 as? NSTextField }.contains { !$0.isHidden && $0.stringValue.contains("Unable to open") } }
        require(label.stringValue == "index.md", "Missing link must preserve current document")
        click("html")
        click("scheme")
        require(label.stringValue == "index.md", "Unsupported targets must preserve preview")
        back.performClick(nil)
        loaded("Other Page.MD")
        require(forward.isEnabled, "Back must expose previous forward destination")
        click("parent")
        loaded("index.md")
        require(!forward.isEnabled, "Following a new link must discard forward history")
        require(!descendants(preview.view).compactMap { $0 as? NSTextField }.contains {
            !$0.isHidden && $0.stringValue.contains("Unable to open")
        }, "Successful navigation must clear the error")
        // Quick Look supplies required dimensions that override the controller's size suggestion.
        NSLayoutConstraint.activate([
            preview.view.widthAnchor.constraint(equalToConstant: 320),
            preview.view.heightAnchor.constraint(equalToConstant: 500),
        ])
        window.setContentSize(NSSize(width: 320, height: 500))
        wait("narrow window resize") { preview.view.bounds.width <= 320 }
        preview.view.layoutSubtreeIfNeeded()
        wait("narrow reading area") { web.bounds.width > 200 && web.bounds.width <= 320 && web.bounds.height > 350 }
        if let snapshot = ProcessInfo.processInfo.environment["QL_PREVIEW_SNAPSHOT"] {
            let capture = Process()
            capture.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
            capture.arguments = ["-x", "-l", String(window.windowNumber), snapshot]
            try capture.run()
            capture.waitUntilExit()
            require(capture.terminationStatus == 0, "Window capture must succeed")
        }
        print("PASS: local paths, encoded names, queries, fragments, nested and parent links, Back/Forward, history branching, missing files, blocked targets, and narrow layout")
    }
}
