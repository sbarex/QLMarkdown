// Run on macOS with: swift tests/mermaid-webkit.swift
import Cocoa
import WebKit

let resources = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("Resources")
func resource(_ name: String) throws -> String {
    let url = resources.appendingPathComponent(name)
    if !name.hasSuffix(".gz") { return try String(contentsOf: url, encoding: .utf8) }
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/gunzip")
    process.arguments = ["-c", url.path]
    let pipe = Pipe()
    process.standardOutput = pipe
    try process.run()
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    process.waitUntilExit()
    precondition(process.terminationStatus == 0)
    return String(data: data, encoding: .utf8)!
}

let pele = try resource("pele.global.js.gz")
let renderer = try resource("mermaid-renderer.js")
let mathRenderer = try resource("math-renderer.js")
let icons = try resource("pele-icons.js")
let temml = try resource("temml.min.js.gz")
let mathCSS = try resource("Temml-Local.css")
let baseCSS = try resource("pele.css")
let bundledCSS = try resource("default.css")
let cases: [(name: String, dark: Bool, bundled: Bool, custom: String, stroke: String)] = [
    ("custom dark", true, false, "body { background: #111; color: #eee; }", "rgb(201, 209, 217)"),
    ("custom light", false, false, "body { background: #fff; color: #222; }", "rgb(36, 41, 46)"),
    ("custom Pele colors", true, false, ".mermaid { --pele-line: #ff0000; }", "rgb(255, 0, 0)"),
    ("custom document colors", true, false, ":root { --textPrimary: #00ff00; }", "rgb(0, 255, 0)"),
    ("bundled dark", true, true, "", "rgb(201, 209, 217)")
]

class Check: NSObject, WKNavigationDelegate {
    let web = WKWebView(frame: NSRect(x: 0, y: 0, width: 900, height: 600))
    var index = 0

    func next() throws {
        let item = cases[index]
        let css = ((item.bundled ? bundledCSS : "") + baseCSS + item.custom)
            .replacingOccurrences(of: "@media (prefers-color-scheme: dark)", with: item.dark ? "@media all" : "@media not all")
        let data = try JSONSerialization.data(withJSONObject: ["nonce": "test", "mathCode": temml, "mathCSS": mathCSS])
        let options = String(data: data, encoding: .utf8)!.replacingOccurrences(of: "<", with: "\\u003c")
        let html = """
        <!doctype html><html><head><meta http-equiv="Content-Security-Policy" content="default-src 'none'; script-src 'nonce-test'; style-src 'unsafe-inline'; font-src data:; img-src file:"><style>\(css)</style></head>
        <body><div class="mermaid">graph LR; A[开始] --> B[结束]</div>
        <div class="mermaid" id="unsupported">zenuml
        Alice-&gt;Bob: Hi
        </div>
        <div class="mermaid" id="formula">graph LR; A["$$\\frac{a}{b} + \\mathscr{F}$$"] --> B["$$x^2$$"]</div>
        <div class="mermaid" id="encoded-formula">graph LR; A["&#36;&#x24;x^2&dollar;&dollar;"]</div>
        <div class="mermaid" id="nested">%%{init: {"theme": "forest"}}%%
        flowchart TD
        subgraph Outer
        subgraph Inner
        A["First&lt;br/&gt;Second"] --> B["fa:fa-car"]
        end
        end
        </div>
        <div class="mermaid" id="picture">flowchart LR; A@{ img: "icon.png" }</div>
        <div class="mermaid" id="broken">graph LR
        A[Unclosed
        </div>
        <script nonce="test">\(pele)
        try { pele.render(document.querySelector('#broken').textContent); }
        catch (error) { window.expectedPeleError = error.message; }
        try { pele.render(document.querySelector('#unsupported').textContent); }
        catch (error) { window.expectedUnsupportedError = error.message; }
        </script><script nonce="test">const qlmarkdownMathOptions = \(options);
        \(mathRenderer)
        \(icons)\n\(renderer)
        renderMermaidDiagrams().then(() => { window.finished = true; });
        </script></body></html>
        """
        web.navigationDelegate = self
        web.loadHTMLString(html, baseURL: resources.deletingLastPathComponent().appendingPathComponent("assets/img", isDirectory: true))
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) { poll() }

    func poll() {
        web.evaluateJavaScript("window.finished === true") { value, error in
            precondition(error == nil, "\(String(describing: error))")
            guard value as? Bool == true else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { self.poll() }
                return
            }
            self.web.evaluateJavaScript("""
            (() => {
                const unsupported = document.querySelector('#unsupported');
                if (unsupported.dataset.renderer !== 'error' || !window.expectedUnsupportedError || !unsupported.textContent.endsWith(window.expectedUnsupportedError)) throw new Error('Unsupported type did not show Pele error');
                if (document.querySelector('[data-renderer=mermaid]')) throw new Error('Unexpected Mermaid fallback');
                const math = document.querySelector('#formula math');
                const rect = math?.getBoundingClientRect();
                if (!rect || rect.width <= 0 || rect.height <= 0 || !math.querySelector('mfrac')) throw new Error('MathML was not laid out');
                if (document.querySelector('#formula').dataset.renderer !== 'pele') throw new Error('Formula fell back');
                if (!document.querySelector('#encoded-formula math msup')) throw new Error('Entity-encoded formula missing');
                if (document.querySelector('#nested').dataset.renderer !== 'pele' || !document.querySelector('#nested circle')) throw new Error('Nested subgraphs or icons failed');
                if (document.querySelector('#picture').dataset.renderer !== 'pele' || !document.querySelector('#picture image')) throw new Error('Image missing');
                if (document.querySelector('#picture image').getAttribute('href') !== 'icon.png') throw new Error('Image URL changed');
                const broken = document.querySelector('#broken');
                if (broken.dataset.renderer !== 'error' || !window.expectedPeleError || !broken.textContent.endsWith(window.expectedPeleError) || broken.querySelector('svg')) throw new Error('Pele error was not displayed');
                if (document.querySelectorAll('script').length !== 3) throw new Error('Unexpected library loading');
                return getComputedStyle(document.querySelector('.pele path')).stroke;
            })()
            """) { value, error in
                guard let actual = value as? String, error == nil else {
                    print("FAIL \(cases[self.index].name): \(String(describing: error))"); exit(1)
                }
                let item = cases[self.index]
                guard actual == item.stroke else {
                    print("FAIL \(item.name): got \(actual), expected \(item.stroke)"); exit(1)
                }
                print("PASS \(item.name): colors, MathML layout, icons, image URLs, nested/configured Pele and Pele errors")
                self.index += 1
                if self.index == cases.count { exit(0) }
                try! self.next()
            }
        }
    }
}

let app = NSApplication.shared
app.setActivationPolicy(.prohibited)
let check = Check()
try check.next()
DispatchQueue.main.asyncAfter(deadline: .now() + 30) { print("FAIL: WebKit timed out"); exit(1) }
app.run()
