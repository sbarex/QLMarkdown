//
//  main.swift
//  qlmarkdown_cli
//
//  Created by Sbarex on 18/10/21.
//

import Cocoa
import OSLog

let cliUrl = URL(fileURLWithPath: CommandLine.arguments[0])

var standardError = FileHandle.standardError

extension FileHandle : TextOutputStream {
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
    print(" --footnotes on|off")
    print(" --hard-break on|off")
    print(" --no-soft-break on|off")
    print(" --raw-html on|off")
    print(" --smart-quotes on|off")
    print(" --validate-utf8 on|off")
    print(" --code on|off")
    print(" --appearance light|dark.")
    print(" --debug on|off")
    
    print("\nExtensions:")
    print(" --autolink on|off")
    print(" --emoji image|font|off")
    print(" --github-mentions on|off")
    print(" --heads-anchor on|off")
    print(" --inline-images on|off")
    print(" --table on|off")
    print(" --tag-filter on|off")
    print(" --tasklist on|off")
    print(" --strikethrough single|double|off")
    print(" --syntax-highlight on|off")
    print(" --yaml rmd|qmd|all|off")
    
    print("\nUnspecified rendering options will use the settings defined in the main application.")

    print("\nTo handle multiple files at time you need to pass the -o argument with a destination folder.")
    
    if exitCode >= 0 {
        exit(Int32(exitCode))
    }
}

var appUrl: URL!
var files: [URL] = []
var dest: URL?
var verbose = false

let settings = Settings.shared
var type = UserDefaults.standard.string(forKey: "AppleInterfaceStyle") ?? "Light"

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

var i = 1
while i < Int(CommandLine.argc) {
    var arg = CommandLine.arguments[i]
    if arg.hasPrefix("-") {
        if arg.hasPrefix("--") {
            // process a --arg
            switch arg {
            case "--help":
                usage(exitCode: 0)
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
                settings.emojiExtension = opt != "off"
                settings.emojiImageOption = opt == "image"
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
                settings.yamlExtension = opt != "off"
                settings.yamlExtensionAll = opt == "all"
                i += 1
            case "--debug":
                settings.debug = parseArgOnOff(index: i)
                i += 1
            case "--code":
                settings.renderAsCode = parseArgOnOff(index: i)
                i += 1
            case "--appearance":
                let opt = CommandLine.arguments[i+1]
                type = opt.lowercased() == "light" ? "Lifht" : "Dark"
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
    print("    emoji: \(settings.emojiExtension ? (settings.emojiImageOption ? "as image" : "as font") : "off")")
    print("    github-mentions: \(settings.mentionExtension ? "on" : "off")")
    print("    heads-anchor: \(settings.headsExtension ? "on" : "off")")
    print("    inline-images: \(settings.inlineImageExtension ? "on" : "off")")
    print("    table: \(settings.tableExtension ? "on" : "off")")
    print("    tag-filter: \(settings.tagFilterExtension ? "on" : "off")")
    print("    tasklist: \(settings.taskListExtension ? "on" : "off")")
    print("    strikethrough: \(settings.strikethroughExtension ? (settings.strikethroughDoubleTildeOption ? "double tilde" : "single tilde") : "off")")
    print("    syntax-highlight: \(settings.syntaxHighlightExtension ? "on" : "off")")
    print("    yaml: \(settings.yamlExtension ? (settings.yamlExtensionAll ? "for all files" : "only for .rmd and .qmd files") : "off")")
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
        
        let html = settings.getCompleteHTML(title: url.lastPathComponent, body: text, basedir: markdown_url.deletingLastPathComponent(), forAppearance: appearance)
        
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
