// Run after building: swift tests/math-webkit.swift /path/to/QLMarkdown.app
import Cocoa
import WebKit

let bundle = URL(fileURLWithPath: CommandLine.arguments[1]).standardizedFileURL
let cli = bundle.appendingPathComponent("Contents/Resources/qlmarkdown_cli")
let temporary = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
try FileManager.default.createDirectory(at: temporary, withIntermediateDirectories: true)
let source = temporary.appendingPathComponent("math.md")
let formulas = #"""
Prices: $1.50 and $7.89. Code: `$x$`.

Inline: $\frac{a}{b}+\sqrt{x}$.

$$\sum_{n=1}^{\infty}\frac{1}{n^2}=\frac{\pi^2}{6}$$

```math
\begin{pmatrix}1&2\\3&4\end{pmatrix}
```

$$\begin{aligned}a&=b+c\\d&=e\end{aligned}$$

$$\gdef\R{\mathbb{R}}\tag{E}E=mc^2\label{energy}$$

$\eqref{energy}$ and $x\in\R$.

$\notACommand$ then $z^2$.

$\eqref{missing}$ then $\eqref{energy}$.
"""#
let diagram = #"""

```mermaid
graph LR
A["$$\frac{a}{b} + \mathscr{F}$$"] --> B
```
"""#
let macroOrder = #"""
$$\newcommand{\testvalue}{A} x$$

$\testvalue$

$$\renewcommand{\testvalue}{B} y$$

$\testvalue$
"""#
let referenceErrors = #"""
$\eqref{fragile}$

$$\tag{F}\label{fragile} x + \eqref{missing}$$

$$\tag{G}\label{good} y$$

$\eqref{good}$

$\ref{good} + \eqref{missing-again} + \eqref{fragile}$

$$\begin{equation}z + \eqref{missing-auto}\label{auto}\end{equation}$$

$\eqref{auto}$

$\ref{good}$

$$\tag{P}\label{__proto__}w$$

$\eqref{__proto__}$ then $\eqref{good}$
"""#
let tocMath = #"""
# Energy $E=mc^2$

## Definition $\newcommand{\tocvalue}{A}\tocvalue$

## Reference $\eqref{target}$

$$\tag{T}\label{target}z$$

## Code `$x$` and prices $1.50 and $7.89

## Comparison $a < b$ & `<literal>`

## Numbered $$\begin{equation}n=1\label{headnum}\end{equation}$$
"""#
let referenceVolume = ([#"$$\tag{T}\label{valid}x$$"#] +
    Array(repeating: #"$\eqref{valid}$"#, count: 500) +
    (0..<500).map { #"$\eqref{missing"# + String($0) + "}$" } +
    [#"$\eqref{valid}$"#]).joined(separator: "\n\n")
let cases: [(renderer: String, mode: String, diagrams: Bool, appearance: String, fixture: String)] = [
    ("temml", "embed", true, "light", "toc-math"),
    ("mathjax", "embed", true, "light", "toc-math"),
    ("temml", "off", false, "light", "toc-math"),
    ("temml", "embed", false, "light", "reference-volume"),
    ("mathjax", "embed", false, "light", "macro-order"),
    ("temml", "embed", false, "light", "reference-errors"),
    ("temml", "embed", false, "light", "standard"),
    ("temml", "embed", false, "dark", "standard"),
    ("temml", "embed", true, "light", "standard"),
    ("temml", "embed", true, "dark", "standard"),
    ("temml", "off", true, "light", "standard"),
    ("mathjax", "embed", false, "light", "standard"),
    ("mathjax", "embed", true, "dark", "standard")
].filter { CommandLine.arguments.count < 3 || $0.fixture == CommandLine.arguments[2] }

func finish(_ status: Int32) -> Never {
    try? FileManager.default.removeItem(at: temporary)
    exit(status)
}

class Check: NSObject, WKNavigationDelegate {
    let web = WKWebView(frame: NSRect(x: 0, y: 0, width: 900, height: 900))
    var index = 0
    var deadline = Date()

    func next() throws {
        let item = cases[index]
        let markdown: String
        switch item.fixture {
        case "toc-math": markdown = tocMath
        case "reference-volume": markdown = referenceVolume
        case "macro-order": markdown = macroOrder
        case "reference-errors": markdown = referenceErrors
        default: markdown = formulas
        }
        try (markdown + (item.diagrams ? diagram : "")).write(to: source, atomically: true, encoding: .utf8)
        let process = Process()
        process.executableURL = cli
        process.arguments = ["--app", bundle.path, "--math-renderer", item.renderer, "--math", item.mode,
            "--mermaid", item.diagrams ? "embed" : "off", "--mermaid-renderer", "pele",
            "--table-of-contents", item.fixture == "toc-math" ? "on" : "off",
            "--appearance", item.appearance, "--syntax-highlight", "off", "--about", "off", "--debug", "off", source.path]
        let pipe = Pipe()
        process.standardOutput = pipe
        try process.run()
        var html = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)!
        if item.fixture == "reference-volume" {
            html = html.replacingOccurrences(of: "\nrenderTemmlMath();", with: """

loadTemml().then(() => {
    const postProcess = temml.postProcess;
    window.postProcessCalls = 0;
    temml.postProcess = (...args) => { window.postProcessCalls++; return postProcess(...args); };
    return renderTemmlMath();
});
""")
        }
        process.waitUntilExit()
        precondition(process.terminationStatus == 0)
        deadline = Date().addingTimeInterval(30)
        web.navigationDelegate = self
        web.loadHTMLString(html, baseURL: temporary)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) { poll() }

    func poll() {
        let item = cases[index]
        let count: Int
        switch item.fixture {
        case "toc-math": count = 6
        case "reference-volume": count = 1002
        case "macro-order": count = 4
        case "reference-errors": count = 11
        default: count = 11
        }
        web.evaluateJavaScript("""
        (() => {
            const bodyReady = \(item.mode == "off" ? "true" : item.renderer == "temml"
                ? "document.querySelectorAll('[data-math-renderer]').length === \(count)"
                : "!!window.MathJax?.startup?.document && document.querySelectorAll('.hl.math mjx-container').length === \(count)");
            return bodyReady && (\(item.diagrams ? "document.querySelector('.mermaid')?.dataset.renderer === 'pele'" : "true"));
        })()
        """) { value, error in
            guard error == nil else { print("FAIL JavaScript: \(error!)"); finish(1) }
            guard value as? Bool == true else {
                if Date() > self.deadline { print("FAIL timeout: \(item)"); finish(1) }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { self.poll() }
                return
            }
            self.verify()
        }
    }

    func verify() {
        let item = cases[index]
        web.evaluateJavaScript("""
        (() => {
            const nodes = Array.from(document.querySelectorAll('.hl.math'));
            if (\(item.fixture == "toc-math")) {
                const toc = document.querySelector('.toc-sidebar');
                const copies = toc.querySelectorAll('math, mjx-container');
                if (\(item.mode == "off")) {
                    if (copies.length || nodes.length) throw new Error('Disabled math rendered in TOC');
                    return true;
                }
                if (copies.length !== 5) throw new Error('TOC must show all five heading formulas');
                if (toc.querySelector('[id], [data-math-renderer], .hl.math')) throw new Error('TOC copied math identity or renderer markers');
                const links = toc.querySelectorAll('a');
                if (links.length !== 6) throw new Error('Formula references created nested TOC links');
                for (const link of links) {
                    const heading = document.getElementById(link.getAttribute('href').slice(1));
                    if (heading?.querySelector('.tml-eqn')) {
                        if (!link.textContent.includes('(1)') || link.querySelector('.tml-eqn, .tml-label, .tml-tageqn')) throw new Error('TOC changed automatic equation numbering');
                        continue;
                    }
                    if (!heading || heading.textContent.replace(/\\s+/g, ' ').trim() !== link.textContent.replace(/\\s+/g, ' ').trim()) throw new Error('TOC does not match its rendered heading');
                }
                if (!toc.textContent.includes('$1.50') || !toc.textContent.includes('$x$') || !toc.textContent.includes('<literal>') || toc.querySelector('literal')) throw new Error('TOC changed currency/code or parsed title text as HTML');
                if (\(item.renderer == "mathjax") && Array.from(MathJax.startup.document.math).length !== 6) throw new Error('TOC formulas were compiled a second time');
                if (!document.querySelector('.mermaid math mfrac')) throw new Error('TOC rendering interfered with Pele');
                return true;
            }
            if (\(item.fixture == "reference-volume")) {
                if (nodes.filter(n => n.dataset.mathRenderer === 'error').length !== 500 || nodes.at(-1).textContent !== '(T)') throw new Error('Bulk reference isolation failed');
                if (window.postProcessCalls !== 1) throw new Error('Bulk missing references must need only one document postProcess, got ' + window.postProcessCalls);
                return true;
            }
            if (\(item.fixture == "macro-order")) {
                const math = Array.from(MathJax.startup.document.math);
                if (math[1].root.toString() !== 'math([mi(A)])' || math[3].root.toString() !== 'math([mi(B)])') throw new Error('MathJax must define/redefine macros in document order');
                return true;
            }
            if (\(item.fixture == "reference-errors")) {
                for (const [index, text] of [[0, '(F)'], [3, '(G)'], [6, '(1)'], [7, 'G']]) {
                    if (nodes[index].dataset.mathRenderer !== 'temml' || nodes[index].textContent !== text) throw new Error('Valid reference lost at formula ' + index);
                }
                for (const [index, label, missing] of [[1, 'fragile', 'missing'], [5, 'auto', 'missing-auto']]) {
                    if (!nodes[index].querySelector('[id="' + label + '"]') || nodes[index].dataset.mathRenderer !== 'error' || !nodes[index].textContent.includes(missing)) throw new Error('Reference error removed an equation label: ' + label);
                }
                if (nodes[9].dataset.mathRenderer !== 'error' || !nodes[9].textContent.includes('__proto__') || nodes[10].textContent !== '(G)') throw new Error('Reserved tag key blocked subsequent references');
                if (nodes[4].dataset.mathRenderer !== 'error' || !nodes[4].textContent.includes('missing-again') || !nodes[4].textContent.includes('G') || !nodes[4].textContent.includes('(F)')) throw new Error('Reference error damaged siblings in the same formula');
                if (window.MathJax) throw new Error('Unexpected MathJax fallback');
                return true;
            }
            if (!document.body.textContent.includes('Prices: $1.50 and $7.89.') || document.querySelector('code')?.textContent !== '$x$') throw new Error('Currency or code changed');
            if (\(item.mode != "off" && item.renderer == "temml")) {
                if (window.MathJax || document.getElementById('MathJax-script')) throw new Error('Unexpected MathJax fallback');
                if (nodes.length !== 11 || nodes[7].dataset.mathRenderer !== 'error' || !nodes[7].textContent.includes('notACommand')) throw new Error('Formula error was not preserved');
                for (const index of [0, 1, 2, 3, 4, 6, 8]) {
                    const math = nodes[index].querySelector('math');
                    const rect = math?.getBoundingClientRect();
                    if (!rect || rect.width <= 0 || rect.height <= 0) throw new Error('Missing MathML layout: ' + index);
                }
                if (!nodes[0].querySelector('mfrac') || !nodes[0].querySelector('msqrt') || nodes[0].querySelector('.tml-display')) throw new Error('Inline formula failed');
                if (!nodes[1].querySelector('.tml-display')) throw new Error('Display formula failed');
                if (nodes[2].querySelectorAll('mtr').length !== 2 || nodes[3].querySelectorAll('mtr').length !== 2) throw new Error('Matrix/aligned failed');
                if (nodes[9].dataset.mathRenderer !== 'error' || !nodes[9].textContent.includes('missing') || !nodes[10].textContent.includes('E')) throw new Error('Unresolved reference blocked a valid reference');
                if (!nodes[5].textContent.includes('E') || !nodes[6].textContent.includes('ℝ')) throw new Error('References/macros failed');
            }
            if (\(item.mode == "off")) {
                if (nodes.length || document.querySelector('[data-math-renderer]')) throw new Error('Disabled body math rendered');
            }
            if (\(item.diagrams)) {
                if (!document.querySelector('.mermaid math mfrac') || document.querySelector('.mermaid mjx-container')) throw new Error('Pele math was replaced or missing');
            }
            if (typeof qlmarkdownMathOptions !== 'undefined') {
                const loads = Array.from(document.scripts).filter(s => s.textContent === qlmarkdownMathOptions.mathCode);
                if (loads.length !== 1) throw new Error('Temml must load exactly once');
            }
            return true;
        })()
        """) { _, error in
            if let error { print("FAIL \(item): \(error)"); finish(1) }
            print("PASS WebKit: \(item)")
            self.index += 1
            if self.index == cases.count { finish(0) }
            try! self.next()
        }
    }
}

let app = NSApplication.shared
app.setActivationPolicy(.prohibited)
let check = Check()
try check.next()
app.run()
