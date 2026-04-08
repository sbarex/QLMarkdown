//
//  main.swift
//  qlmarkdown_cli
//
//  Created by Sbarex on 18/10/21.
//

import Cocoa
import OSLog
import ArgumentParser

let cliUrl = URL(fileURLWithPath: CommandLine.arguments[0])

var standardError = FileHandle.standardError

extension FileHandle : @retroactive TextOutputStream {
    public func write(_ string: String) {
        guard let data = string.data(using: .utf8) else { return }
        self.write(data)
    }
}

func usage(exitCode: Int = -1) {
    let name = cliUrl.lastPathComponent
    print("\(name)")
    print("Usage: \(name) [-o <file|dir>] [-v] <file> [..]")
    print("\nArguments:")
    print(" -h\tShow this help and exit.")
    print(" -o\t<file|dir> Destination output. If you pass a directory, a new file is created with the name of the processed source with html extension. \n   \tThe destination file is always overwritten. If this argument is not provided, the output will be printed to the stdout.")
    print(" -v\tVerbose mode. Valid only with the -o option.")
    // print(" --app\t<path> Set the path of \"QLMarkdown.app\" otherwise assume that \(name) is called from the Contents/Resources of the app bundle.")
    
    print("\nOptions:")
    print(" --footnotes on|off        Parse the footnotes.")
    print(" --hard-break on|off       Render softbreak elements as hard line breaks.")
    print(" --no-soft-break on|off    Render softbreak elements as spaces.")
    print(" --raw-html on|off         Render raw HTML and unsafe links.")
    print(" --smart-quotes on|off     Convert straight quotes to curly.")
    print(" --validate-utf8 on|off    Validate UTF-8 in the input before parsing.")
    print(" --code on|off             Show the plain text file (raw version) instead of the formatted output.")
    print(" --appearance light|dark   ")
    print(" --about on|off            Show/Hide a footer with info about QLMarkdown.")
    print(" --debug on|off            Insert in the output some debug information.")
    print(" --baseFontSize number     Set the base font size in points.")
    
    print("\nExtensions:")
    print(" --autolink on|off         Automatically translate URL/email to link.")
    print(" --emoji image|font|off    Translate the emoji shortcodes.")
    print(" --github-mentions on|off  Translate mentions to link to the GitHub account.")
    print(" --heads-anchor on|off     Create anchors for the heads.")
    print(" --highlight on|off        Highlight text marked with `==`.")
    print(" --inline-images on|off    Embed the image files inside the formatted output.")
    print(" --math [off|url|path]     Format the mathematical expressions with MathJax.")
    print(" --math-embed on|off       Embed/Link the MathJax library.")
    print(" --mermaid [off|url|path]  Format the mermaid diagrams.")
    print(" --mermaid-embed on|off    Embed/Link the mermaid library.")
    print(" --table on|off            Enable table format.")
    print(" --tag-filter on|off       Strip potentially dangerous HTML tags.")
    print(" --tasklist on|off         Parse task list.")
    print(" --strikethrough single|double|off Recognize single/double `~` for the strikethrough style.")
    print(" --syntax-highlight on|off Highlight the code inside fenced block")
    print(" --sub on|off              Format subscript characters inside `~` markers.")
    print(" --sup on|off              Format superscript characters inside `^` markers.")
    print(" --yaml rmd|qmd|all|off    Render the yaml header")
    
    print("\nTo handle multiple files at time you need to pass the -o argument with a destination folder.")
    
    if exitCode >= 0 {
        exit(Int32(exitCode))
    }
}

var appUrl: URL!
var files: [URL] = []
var dest: URL?
var verbose = false

let settings = Settings.settingsFromSharedFile() ?? Settings()

var type = Settings.isLightAppearance ? "Light" : "Dark"

func parseArgOnOff(index i: Int) -> Bool {
    guard i+1 < CommandLine.arguments.count else {
        print("\(cliUrl.lastPathComponent): \(CommandLine.arguments[i]) require an on|off argument.\n", to: &standardError)
        usage(exitCode: 1)
        return false
    }
    
    let u = CommandLine.arguments[i+1]
    switch u {
    case "on", "1": return true
    case "off", "0": return false
    default:
        print("\(cliUrl.lastPathComponent): illegal argument '\(u)' for \(CommandLine.arguments[i]) option.\n", to: &standardError)
        usage(exitCode: 1)
        return false
    }
}

var mermaid_embedded = false
var mermaid_file: URL? = nil

var math_embedded = false
var math_file: URL? = nil

var i = 1
while i < Int(CommandLine.argc) {
    var arg = CommandLine.arguments[i]
    if arg.hasPrefix("-") {
        if arg.hasPrefix("--") {
            // process a --arg
            switch arg {
            case "--help":
                usage(exitCode: 0)
            case "--baseFontSize":
                let u = CommandLine.arguments[i+1]
                if let n = Double(u) {
                    settings.baseFontSize = CGFloat(n)
                }
            case "--app":
                let u = CommandLine.arguments[i+1]
                appUrl = URL(fileURLWithPath: u)
                i += 1
            case "--smart-quotes":
                settings.smartQuotesOption = parseArgOnOff(index: i)
                i += 1
            case "--footnotes":
                settings.footnotesOption = parseArgOnOff(index: i)
                i += 1
            case "--emoji":
                let opt = CommandLine.arguments[i+1]
                switch opt {
                case "off":
                    settings.emojiExtension = .disabled
                case "image":
                    settings.emojiExtension = .images
                default:
                    settings.emojiExtension = .font
                }
                i += 1
            case "--math":
                if i < CommandLine.argc - 1 {
                    let u = CommandLine.arguments[i+1]
                    if u == "off" {
                        settings.mathExtension = .disabled
                    } else {
                        settings.mathExtension = .link(url: math_file)
                        if u != "on" {
                            mermaid_file = URL(string: u)
                        }
                    }
                } else {
                    settings.mathExtension = .link(url: nil)
                }
                i += 1
            case "--math-embed":
                math_embedded = parseArgOnOff(index: i)
                i += 1
            case "--mermaid":
                if i < CommandLine.argc - 1 {
                    let u = CommandLine.arguments[i+1]
                    if u == "off" {
                        settings.mermaidExtension = .disabled
                    } else {
                        settings.mermaidExtension = .link(url: mermaid_file)
                        if u != "on" {
                            mermaid_file = URL(string: u)
                        }
                    }
                } else {
                    settings.mermaidExtension = .link(url: nil)
                }
                i += 1
            case "--mermaid-embed":
                mermaid_embedded = parseArgOnOff(index: i)
                i += 1
                
            case "--highlight":
                settings.highlightExtension = parseArgOnOff(index: i)
                i += 1
            case "--table":
                settings.tableExtension = parseArgOnOff(index: i)
                i += 1
            case "--strikethrough":
                let opt = CommandLine.arguments[i+1]
                settings.strikethroughExtension = opt != "off"
                settings.strikethroughDoubleTildeOption = opt == "double"
                i += 1
            case "--syntax-highlight":
                settings.syntaxHighlightExtension = parseArgOnOff(index: i)
                i += 1
            case "--sub":
                settings.subExtension = parseArgOnOff(index: i)
                i += 1
            case "--sup":
                settings.supExtension = parseArgOnOff(index: i)
                i += 1
            case "--hard-break":
                settings.hardBreakOption = parseArgOnOff(index: i)
                i += 1
            case "--no-soft-break":
                settings.noSoftBreakOption = parseArgOnOff(index: i)
                i += 1
            case "--validate-utf8":
                settings.validateUTFOption = parseArgOnOff(index: i)
                i += 1
            case "--raw-html":
                settings.unsafeHTMLOption = parseArgOnOff(index: i)
                i += 1
            case "--autolink":
                settings.autoLinkExtension = parseArgOnOff(index: i)
                i += 1
            case "--github-mentions":
                settings.mentionExtension = parseArgOnOff(index: i)
                i += 1
            case "--heads-anchor":
                settings.headsExtension = parseArgOnOff(index: i)
                i += 1
            case "--inline-images":
                settings.inlineImageExtension = parseArgOnOff(index: i)
                i += 1
            case "--tag-filter":
                settings.tagFilterExtension = parseArgOnOff(index: i)
                i += 1
            case "--tasklist":
                settings.taskListExtension = parseArgOnOff(index: i)
                i += 1
            case "--yaml":
                let opt = CommandLine.arguments[i+1]
                switch opt {
                case "all":
                    settings.yamlExtension = .allFiles
                case "off":
                    settings.yamlExtension = .disabled
                default:
                    settings.yamlExtension = .onlyRmd
                }
                i += 1
            case "--debug":
                settings.debug = parseArgOnOff(index: i)
                i += 1
            case "--code":
                settings.renderAsCode = parseArgOnOff(index: i)
                i += 1
            case "--appearance":
                let opt = CommandLine.arguments[i+1]
                type = opt.lowercased() == "light" ? "Light" : "Dark"
            case "--about":
                settings.about = parseArgOnOff(index: i)
                i += 1
            default:
                print("\(cliUrl.lastPathComponent): illegal option -\(arg)\n", to: &standardError)
                usage(exitCode: 1)
            }
        } else {
            // process a -arg
            arg.removeFirst()
            for (j, arg1) in arg.enumerated() {
                switch arg1 {
                case "h":
                    usage(exitCode: 0)
                case "o":
                    if j + 1 == arg.count {
                        if CommandLine.arguments[i+1].description.hasPrefix("-") {
                            print("\(cliUrl.lastPathComponent): option -\(arg1) require a destination path\n", to: &standardError)
                            usage(exitCode: 1)
                        }
                        dest = URL(fileURLWithPath: CommandLine.arguments[i+1])
                        i += 1
                    } else {
                        print("\(cliUrl.lastPathComponent): option -\(arg1) require a destination path\n", to: &standardError)
                        usage(exitCode: 1)
                    }
                case "v":
                    verbose = true
                default:
                    print("\(cliUrl.lastPathComponent): illegal option -\(arg1)\n", to: &standardError)
                    usage(exitCode: 1)
                }
            }
        }
    } else {
        files.append(URL(fileURLWithPath: arg))
    }
    /*
    switch arg {
    case "--help", "-h":
        usage()
        exit(0)
    case "--app":
        let u = CommandLine.arguments[i+1]
        i += 1
        appUrl = URL(fileURLWithPath: u)
    case "-o":
        dest = URL(fileURLWithPath: CommandLine.arguments[i+1])
        i += 1
    case "-v":
        verbose = true
    default:
        if arg.hasPrefix("-") {
            print("\(cliUrl.lastPathComponent): illegal option \(arg)", to: &standardError)
            usage()
            exit(1)
        }
        files.append(URL(fileURLWithPath: arg))
    }
    */
    i += 1
}

if !settings.mermaidExtension.isDisabled {
    settings.mermaidExtension = mermaid_embedded ? .embed(url: mermaid_file) : .link(url: mermaid_file)
}

settings.sanitize()

verbose = verbose && dest != nil
if verbose {
    print("\n\(cliUrl.lastPathComponent)")
    print("    appearance: \(type)")
    
    print("\n- options:")
    print("    footnotes: \(settings.footnotesOption ? "on" : "off")")
    print("    hard-break: \(settings.hardBreakOption ? "on" : "off")")
    print("    no-soft-break: \(settings.noSoftBreakOption ? "on" : "off")")
    print("    raw-html: \(settings.unsafeHTMLOption ? "on" : "off")")
    print("    smart-quotes: \(settings.smartQuotesOption ? "on" : "off")")
    print("    validate-utf8: \(settings.validateUTFOption ? "on" : "off")")
    print("    render source code: \(settings.renderAsCode ? "on" : "off")")
    print("    debug: \(settings.debug ? "on" : "off")")
    
    print("\n- extensions:")
    print("    autolink: \(settings.autoLinkExtension ? "on" : "off")")
    switch settings.emojiExtension {
    case .disabled:
        print("    emoji: off")
    case .font:
        print("    emoji: using font glyphs")
    case .images:
        print("    emoji: using images")
    }
    print("    github-mentions: \(settings.mentionExtension ? "on" : "off")")
    print("    heads-anchor: \(settings.headsExtension ? "on" : "off")")
    print("    inline-images: \(settings.inlineImageExtension ? "on" : "off")")
    switch settings.mathExtension {
    case .disabled:
        print("    math: off")
    case .embed:
        print("    math: embedded\(math_file != nil ? " (\(math_file!))" : "")")
    case .link:
        print("    math: linked\(math_file != nil ? " (\(math_file!))" : "")")
    }
    
    switch settings.mermaidExtension {
    case .disabled:
        print("    mermaid: off")
    case .embed:
        print("    mermaid: embedded\(mermaid_file != nil ? " (\(mermaid_file!))" : "")")
    case .link:
        print("    mermaid: linked\(mermaid_file != nil ? " (\(mermaid_file!))" : "")")
    }
    print("    highlight: \(settings.highlightExtension ? "on" : "off")")
    print("    table: \(settings.tableExtension ? "on" : "off")")
    print("    tag-filter: \(settings.tagFilterExtension ? "on" : "off")")
    print("    tasklist: \(settings.taskListExtension ? "on" : "off")")
    print("    strikethrough: \(settings.strikethroughExtension ? (settings.strikethroughDoubleTildeOption ? "double tilde" : "single tilde") : "off")")
    print("    syntax-highlight: \(settings.syntaxHighlightExtension ? "on" : "off")")
    switch settings.yamlExtension {
    case .disabled:
        print("    yaml: off")
    case .allFiles:
        print("    yaml: for all files")
    case .onlyRmd:
        print("    yaml: only for .rmd and .qmd files")
    }
    print("")
}

if appUrl == nil {
    appUrl = cliUrl.deletingLastPathComponent().deletingLastPathComponent()
}

let appBundleUrl = appUrl.appendingPathComponent("Contents/Resources")

if files.count > 1 {
    var isDir: ObjCBool = false
    if let dest = dest {
        FileManager.default.fileExists(atPath: dest.path, isDirectory: &isDir)
    }
    if !isDir.boolValue {
        print("Error: to process multiple files you must use the -o argument with a folder path!", to: &standardError)
        exit(1)
    }
}

var n = 0
defer {
    if verbose {
        print(n != 1 ? "Processed \(n) files." : "Processed 1 file.")
    }
}

Settings.appBundleUrl = appBundleUrl

if files.isEmpty {
    usage(exitCode: 1)
}

for url in files {
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
        guard FileManager.default.isReadableFile(atPath: markdown_url.path) else {
            print("Unable to read the file \(markdown_url.path)", to: &standardError)
            os_log("Unable to read the file %{private}@", log: OSLog.cli, type: .error, markdown_url.path)
            exit(127)
        }
        if verbose {
            print("- processing \(markdown_url.path) ...")
        }
        let appearance: Appearance = type == "Light" ? .light : .dark
        let text = try settings.render(file: markdown_url, forAppearance: appearance, baseDir: markdown_url.deletingLastPathComponent().path)
        
        let html = settings.getCompleteHTML(title: url.lastPathComponent, body: text, basedir: markdown_url.deletingLastPathComponent(), forAppearance: appearance, mermaidPath: mermaid_file)
        
        Settings.renderStats += 1
        if Settings.renderStats > 0 && Settings.renderStats % 100 == 0 {
            print("""
*** *** *** *** *** ***
Thanks to this application you have viewed over \(Settings.renderStats) files.
If you find it useful and you have the possibility, consider buying me a coffee! (https://buymeacoffee.com/sbarex)
*** *** *** *** *** ***
""")
        }
        
        var output: URL?
        if let dest = dest {
            var isDir: ObjCBool = false
            FileManager.default.fileExists(atPath: dest.path, isDirectory: &isDir)
            if isDir.boolValue {
                output = dest.appendingPathComponent(url.deletingPathExtension().lastPathComponent).appendingPathExtension("html")
            } else {
                output = dest
            }
            /*
            if !(output?.pathExtension.lowercased().hasPrefix("htm") ?? false) {
                output?.appendPathExtension("html")
            }
            */
        }
        
        if let output = output {
            try html.write(to: output, atomically: true, encoding: .utf8)
            if verbose {
                print("  ... stored in \(output.path)")
            }
            n += 1
        } else {
            FileHandle.standardOutput.write(html)
            n += 1
        }
    } catch {
        print("Error processing \(url.path): \(error.localizedDescription)", to: &standardError)
        os_log("Error processing the file %{private}@: %{public}@", log: OSLog.cli, type: .error, url.path, error.localizedDescription)
        exit(1)
    }
}
