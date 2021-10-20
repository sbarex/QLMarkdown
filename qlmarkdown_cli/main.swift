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
    print("Usage: \(name) [--app <path>] [-o <file|dir>] [-v] <file> [..]")
    print("\nArguments:")
    print(" -h\tShow this help and exit.")
    print(" -o\t<file|dir> Destination output. If you pass a directory, a new file is created with the name of the processed source with html extension. \n   \tThe destination file is always overwritten. If this argument is not provided, the output will be printed to the stdout.")
    print(" -v\tVerbose mode. Valid only with the -o option.")
    // print(" --app\t<path> Set the path of \"QLMarkdown.app\" otherwise assume that \(name) is called from the Contents/Resources of the app bundle.")
    print("\nTo handle multiple files at time you need to pass the -o arguments with a destination folder.")
    print("\nPlease use the main app to customize the rendering settings.")
    
    if exitCode >= 0 {
        exit(Int32(exitCode))
    }
}

var appUrl: URL!
var files: [URL] = []
var dest: URL?
var verbose = false

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
                i += 1
                appUrl = URL(fileURLWithPath: u)
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
        print("Error: to process multiple files you must use the -o arguments with a folder path!", to: &standardError)
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
let settings = Settings.shared

let type = UserDefaults.standard.string(forKey: "AppleInterfaceStyle") ?? "Light"

if verbose {
    print("\(cliUrl.lastPathComponent):")
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
        if !FileManager.default.isReadableFile(atPath: markdown_url.path) {
            print("Unable to read the file \(markdown_url.path)", to: &standardError)
            exit(127)
        }
        if verbose {
            print("- processing \(markdown_url.path) ...")
        }
        let text = try settings.render(file: markdown_url, forAppearance: type == "Light" ? .light : .dark, baseDir: markdown_url.deletingLastPathComponent().path, log: nil)
        
        let html = settings.getCompleteHTML(title: url.lastPathComponent, body: text)
        
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
        exit(1)
    }
}
