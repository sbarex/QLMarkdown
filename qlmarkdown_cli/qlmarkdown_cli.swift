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


enum BoolArgumentEnum: String, ExpressibleByArgument {
    case on, off
    
    static var allValueStrings: [String] {
        return ["on", "off"]
    }
}

enum AppearanceEnum: String, ExpressibleByArgument {
    case light, dark
    
    static var allValueStrings: [String] {
        return ["light", "dark"]
    }
}

enum EmojiArgumentEnum: String, ExpressibleByArgument {
    case font, images, off
    
    static var allValueStrings: [String] {
        return ["font", "images", "off"]
    }
    
    static var allValueDescriptions: [String : String] {
        return [
            "font": "replace with font glyphs",
            "images": "replace with web images",
            "off": "disabled"
        ]
    }
}

enum StrikethroughArgumentEnum: String, ExpressibleByArgument {
    case single, double, off
    
    static var allValueStrings: [String] {
        return ["single", "double", "off"]
    }
    static var allValueDescriptions: [String : String] {
        return [
            "single": "detect single tilde (~)",
            "double": "detect double tilde (~~)",
            "off": "disabled"
        ]
    }
}

enum YamlArgumentEnum: String, ExpressibleByArgument {
    case all, rmd, off
    
    init?(argument: String) {
        switch argument.lowercased() {
        case "rmd", "qmd":
            self = .rmd
        case "all":
            self = .all
        case "off":
            self = .off
        default:
            return nil
        }
    }
    
    static var allValueStrings: [String] {
        return ["rmd", "all", "off"]
    }
    
    static var allValueDescriptions: [String : String] {
        return [
            "rmd": "enabled only for .rmd and .qmd files",
            "all": "enabled for all files",
            "off": "disabled"
        ]
    }
}

struct OptionsOptions: ParsableArguments {
    @Option var appearance: AppearanceEnum? = nil
    
    @Option(help: ArgumentHelp("Set the base font size, in points.", valueName: "number"))
    var baseFontSize: Float? = nil
    
    @Option(help: ArgumentHelp("Parse the footnotes.", valueName: "on|off"))
    var footnotes: BoolArgumentEnum? = nil
    
    @Option(help: ArgumentHelp("Render soft-break elements as hard line breaks.", valueName: "on|off"))
    var hardBreak: BoolArgumentEnum? = nil
    
    @Option(help: ArgumentHelp("Render soft-break elements as spaces.", valueName: "on|off"))
    var noSoftBreak: BoolArgumentEnum? = nil
    
    @Option(help: ArgumentHelp("Convert straight quotes to curly.", valueName: "on|off"))
    var rawHtml: BoolArgumentEnum? = nil
    
    @Option(help: ArgumentHelp("Show the plain text file (raw version) instead of the formatted output.", valueName: "on|off"))
    var renderAsCode: BoolArgumentEnum? = nil
    
    @Option(help: ArgumentHelp("Convert straight quotes to curly.", valueName: "on|off"))
    var smartQuotes: BoolArgumentEnum? = nil
    
    @Option(help: ArgumentHelp("Validate UTF-8 in the input before parsing.", valueName: "on|off"))
    var validateUtf8: BoolArgumentEnum? = nil
    
    @Option(help: ArgumentHelp("Show/Hide a footer with info about QLMarkdown.", valueName: "on|off", visibility: .private))
    var about: BoolArgumentEnum? = nil
    
    @Option(help: ArgumentHelp("Insert in the output some debug information.", valueName: "on|off"))
    var debug: BoolArgumentEnum? = nil
}

struct ExtensionsOptions: ParsableArguments {
    @Option(help: ArgumentHelp("Automatically translate URL/email to link.", valueName: "on|off"))
    var autolink: BoolArgumentEnum? = nil
    
    @Option(help: ArgumentHelp("Translate the emoji shortcodes."))
    var emoji: EmojiArgumentEnum? = nil
    
    @Option(help: ArgumentHelp("Translate mentions to link to the GitHub account", valueName: "on|off"))
    var githubMentions: BoolArgumentEnum? = nil
    
    @Option(help: ArgumentHelp("Create anchors for the heads.", valueName: "on|off"))
    var headsAnchor: BoolArgumentEnum? = nil
    
    @Option(help: ArgumentHelp("Highlight text marked with `==`.", valueName: "on|off"))
    var highlight: BoolArgumentEnum? = nil
    
    @Option(help: ArgumentHelp("Embed local image files inside the formatted output.", valueName: "on|off"))
    var inlineImages: BoolArgumentEnum? = nil
    
    @Option(help: ArgumentHelp("Format the mathematical expressions with MathJax. You can specify the path or url of the MathJax.js library.", valueName: "path|url"))
    var math: String? = nil
    
    @Option(help: ArgumentHelp("Embed/Link the MathJax library.", valueName: "on|off"))
    var mathEmbed: BoolArgumentEnum? = nil
    
    @Option(help: ArgumentHelp("Format the mermaid diagrams. You can specify the path or url of the Mermaid.js library.", valueName: "path|url"))
    var mermaid: String? = nil
    
    @Option(help: ArgumentHelp("Embed/Link the Mermaid library.", valueName: "on|off"))
    var mermaidEmbed: BoolArgumentEnum? = nil
    
    @Option(help: ArgumentHelp("Enable table extension.", valueName: "on|off"))
    var table: BoolArgumentEnum? = nil
    
    @Option(help: ArgumentHelp("Strip potentially dangerous HTML tags.", valueName: "on|off"))
    var tagFilter: BoolArgumentEnum? = nil
    
    @Option(help: ArgumentHelp("Parse task list.", valueName: "on|off"))
    var tasklist: BoolArgumentEnum? = nil
    
    @Option(help: "Recognize single/double `~` for the strikethrough style.")
    var strikethrough: StrikethroughArgumentEnum? = nil
    
    @Option(help: ArgumentHelp("Highlight the code inside fenced block.", valueName: "on|off"))
    var syntaxHighlight: BoolArgumentEnum? = nil
    
    @Option(help: ArgumentHelp("Format subscript characters inside `~` markers.", valueName: "on|off"))
    var sub: BoolArgumentEnum? = nil
    
    @Option(help: ArgumentHelp("Format superscript characters inside `^` markers.", valueName: "on|off"))
    var sup: BoolArgumentEnum? = nil
    
    @Option(help: "Render the yaml header.")
    var yaml: YamlArgumentEnum? = nil
}

@main
struct QLMarkdownCLI: ParsableCommand {
    enum QLError: LocalizedError, CustomStringConvertible {
        case destinationMustBeAFolder
        case unableToReadSource(path: String)
        case processError(path: String, error: Error?)
        
        var description: String {
            switch self {
            case .processError(let path, let error): return "Error processing the source file \(path)\(error != nil ? ": \(error!.localizedDescription)" : "")"
            case .destinationMustBeAFolder: return "Destination path must be a folder!"
            case .unableToReadSource(let path): return "Unable to read the source file (\(path))!"
            }
        }
    }
    
    static var configuration = CommandConfiguration(
        abstract: "Command line tool to convert markdown files to html.",
        discussion: "Developed by SBAREX 2020 - 2026.\nhttps://github.com/sbarex/QLMarkdown"
    )
    
    @Flag var help: Bool = false
    @Option(name: .customShort("o"), help: ArgumentHelp("Destination output. If you pass a directory, a new file is created with the name of the processed source with .html extension. \nThe destination file is always overwritten. If this argument is not provided, the output will be printed to the stdout.\nTo handle multiple files at time you need to pass the -o argument with a destination folder.", valueName: "path"))
    var dest: String? = nil
    
    @Flag(name: NameSpecification.shortAndLong, help: "Verbose mode. Valid only with the -o option.")
    var verbose: Bool = false
    
    @OptionGroup(title: "Markdown Options")
    var options: OptionsOptions
    @OptionGroup(title: "Markdown Extensions")
    var extensions: ExtensionsOptions
    
    @Option(help: ArgumentHelp("Path of the main QLMarkdown.app application.", valueName: "path"))
    var app: String? = nil
    
    @Argument(help: "File to be processed.")
    var files: [String] = []
    
    @Flag(help: ArgumentHelp("Show the customized settings and exit."))
    var showSettings: Bool = false
    
    @Flag(help: ArgumentHelp("Show the version number and exit.", visibility: .hidden))
    var version: Bool = false
    
    var appUrl: URL {
        if let app {
            return URL(fileURLWithPath: app)
        } else {
            return cliUrl.deletingLastPathComponent().deletingLastPathComponent()
        }
    }
    
    var settings: Settings!
    
    func getSettings() -> Settings {
        let settings = Settings.settingsFromSharedFile() ?? Settings()
        
        // options
        if let o = options.footnotes {
            settings.footnotesOption = o == .on
        }
        if let o = options.hardBreak {
            settings.hardBreakOption = o == .on
        }
        if let o = options.noSoftBreak {
            settings.noSoftBreakOption = o == .on
        }
        if let o = options.rawHtml {
            settings.unsafeHTMLOption = o == .on
        }
        if let o = options.smartQuotes {
            settings.smartQuotesOption = o == .on
        }
        if let o = options.validateUtf8 {
            settings.validateUTFOption = o == .on
        }
        if let o = options.renderAsCode {
            settings.renderAsCode = o == .on
        }
        if let size = options.baseFontSize {
            settings.baseFontSize = CGFloat(size)
        }
        if let o = options.about {
            settings.about = o == .on
        }
        if let o = options.debug {
            settings.debug = o == .on
        }
        
        // extensions
        
        if let o = extensions.autolink {
            settings.autoLinkExtension = o == .on
        }
        if let o = extensions.emoji {
            switch o {
            case .font:
                settings.emojiExtension = .font
            case .images:
                settings.emojiExtension = .images
            case .off:
                settings.emojiExtension = .disabled
            }
        }
        if let o = extensions.githubMentions {
            settings.mentionExtension = o == .on
        }
        if let o = extensions.headsAnchor {
            settings.headsExtension = o == .on
        }
        if let o = extensions.highlight {
            settings.highlightExtension = o == .on
        }
        if let o = extensions.inlineImages {
            settings.inlineImageExtension = o == .on
        }
        if let o = extensions.math {
            if o == "off" {
                settings.mathExtension = .disabled
            } else {
                switch extensions.mathEmbed ?? (settings.mathExtension.getMode()?.embed ?? false ? .off : .on) {
                case .on:
                    settings.mathExtension = .embed(url: o.isEmpty ? nil : URL(string: o))
                case .off:
                    settings.mathExtension = .link(url: o.isEmpty ? nil : URL(string: o))
                }
            }
        }
        
        if let o = extensions.mermaid {
            if o == "off" {
                settings.mermaidExtension = .disabled
            } else {
                switch extensions.mermaidEmbed ?? (settings.mermaidExtension.getMode()?.embed ?? false ? .off : .on) {
                case .on:
                    settings.mermaidExtension = .embed(url: o.isEmpty ? nil : URL(string: o))
                case .off:
                    settings.mermaidExtension = .link(url: o.isEmpty ? nil : URL(string: o))
                }
            }
        }
        if let o = extensions.table {
            settings.tableExtension = o == .on
        }
        if let o = extensions.tagFilter {
            settings.tagFilterExtension = o == .on
        }
        if let o = extensions.tasklist {
            settings.taskListExtension = o == .on
        }
        if let o = extensions.strikethrough {
            switch o {
            case .single:
                settings.strikethroughExtension = .single
            case .double:
                settings.strikethroughExtension = .double
            case .off:
                settings.strikethroughExtension = .disabled
            }
        }
        if let o = extensions.syntaxHighlight {
            settings.syntaxHighlightExtension = o == .on
        }
        if let o = extensions.sub {
            settings.subExtension = o == .on
        }
        if let o = extensions.sup {
            settings.supExtension = o == .on
        }
        if let o = extensions.yaml {
            switch o {
            case .all:
                settings.yamlExtension = .allFiles
            case .rmd:
                settings.yamlExtension = .onlyRmd
            case .off:
                settings.yamlExtension = .disabled
            }
        }
        
        var messages: [String] = []
        settings.sanitize(allowLinkFile: true, messages: &messages)
        if !messages.isEmpty {
            print("Warning: there are some errors on the config settings: ")
            messages.forEach({print($0)})
        }
        return settings
    }
    
    func printSettings(_ settings: Settings) {
        print("\n\(cliUrl.lastPathComponent) settings")
        let appearance = self.options.appearance != nil ? self.options.appearance!.rawValue.capitalized : (Settings.isLightAppearance ? "Light" : "Dark")
        
        print("\nMain app path: \(self.appUrl.path)")
        
        print("\nMARKDOWN OPTIONS:")
        print("    --appearance: \(appearance)")
        print("    --base-font-size: \(settings.baseFontSize > 0 ? "\(settings.baseFontSize) pt" : "auto")")
        print("    --footnotes: \(settings.footnotesOption ? "on" : "off")")
        print("    --hard-break: \(settings.hardBreakOption ? "on" : "off")")
        print("    --no-soft-break: \(settings.noSoftBreakOption ? "on" : "off")")
        print("    --raw-html: \(settings.unsafeHTMLOption ? "on" : "off")")
        print("    --smart-quotes: \(settings.smartQuotesOption ? "on" : "off")")
        print("    --validate-utf8: \(settings.validateUTFOption ? "on" : "off")")
        print("    --render-as-code: \(settings.renderAsCode ? "on" : "off")")
        print("    --debug: \(settings.debug ? "on" : "off")")
        
        print("\nMARKDOWN EXTENSIONS:")
        print("    --autolink: \(settings.autoLinkExtension ? "on" : "off")")
        switch settings.emojiExtension {
        case .disabled:
            print("    --emoji: off")
        case .font:
            print("    --emoji: using font glyphs")
        case .images:
            print("    --emoji: using images")
        }
        print("    --github-mentions: \(settings.mentionExtension ? "on" : "off")")
        print("    --heads-anchor: \(settings.headsExtension ? "on" : "off")")
        print("    --highlight: \(settings.highlightExtension ? "on" : "off")")
        print("    --inline-images: \(settings.inlineImageExtension ? "on" : "off")")
        switch settings.mathExtension {
        case .disabled:
            print("    --math: off")
        case .embed(let url):
            let url = url ?? settings.mathJaxFileUrl ?? Settings.mathJaxWebUrl
            print("    --math: embedded \(url.absoluteString))")
        case .link(let url):
            let url = url ?? settings.mathJaxFileUrl ?? Settings.mathJaxWebUrl
            print("    --math: linked \(url.absoluteString)")
        }
        
        switch settings.mermaidExtension {
        case .disabled:
            print("    --mermaid: off")
        case .embed(let url):
            let url = url ?? settings.mermaidFileUrl ?? Settings.mermaidWebUrl
            print("    --mermaid: embedded \(url.absoluteString)")
        case .link(let url):
            let url = url ?? settings.mermaidFileUrl ?? Settings.mermaidWebUrl
            print("    --mermaid: linked \(url.absoluteString)")
        }
        print("    --table: \(settings.tableExtension ? "on" : "off")")
        print("    --tasklist: \(settings.taskListExtension ? "on" : "off")")
        print("    --tag-filter: \(settings.tagFilterExtension ? "on" : "off")")
        switch settings.strikethroughExtension {
        case .disabled:
            print("    --strikethrough: off")
        case .single:
            print("    --strikethrough: single tilde")
        case .double:
            print("    --strikethrough: double tilde")
        }
        print("    --syntax-highlight: \(settings.syntaxHighlightExtension ? "on" : "off")")
        switch settings.yamlExtension {
        case .disabled:
            print("    --yaml: off")
        case .allFiles:
            print("    --yaml: for all files")
        case .onlyRmd:
            print("    --yaml: only for .rmd and .qmd files")
        }
        print("")
    }

    mutating func validate() throws {
        verbose = verbose && self.dest != nil
        
        settings = self.getSettings()
        
        if !showSettings {
            if files.isEmpty {
                print(QLMarkdownCLI.helpMessage(for: QLMarkdownCLI.self))
                QLMarkdownCLI.exit()
            } else if files.count > 1 {
                var isDir: ObjCBool = false
                if let dest = dest {
                    FileManager.default.fileExists(atPath: dest, isDirectory: &isDir)
                }
                
                if !isDir.boolValue {
                    QLMarkdownCLI.exit(withError: QLError.destinationMustBeAFolder) // "Error: to process multiple files you must use the -o argument with a folder path!"
                }
            }
        }
        
        let appBundleUrl = appUrl 
        Settings.appBundleUrl = appUrl
        
        if let v = Settings.getResourceBundle().object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String {
            Self.configuration.version = v // Change the version at runtime do not reflect in the usage screen :(
        } else {
            Self.configuration.version = "N/D"
        }
        
        if version {
            // Print the version number and exit.
            
            // print(Self.usageString() + "\n")
            print("Version \(Self.configuration.version)")
            QLMarkdownCLI.exit()
        }
    }
    
    mutating func run() throws {
        let files: [URL] = self.files.map { URL(fileURLWithPath: $0) }
        let dest: URL? = self.dest != nil ? URL(string: self.dest!) : nil
        
        var isDir: ObjCBool = false
        if let dest {
            FileManager.default.fileExists(atPath: dest.path, isDirectory: &isDir)
        }
        
        let appearance: Appearance
        if let a = self.options.appearance {
            switch a {
            case .light:
                appearance = .light
            case .dark:
                appearance = .dark
            }
        } else {
            appearance = Settings.isLightAppearance ? .light : .dark
        }
        
        if verbose || showSettings {
            printSettings(settings)
            if showSettings {
                QLMarkdownCLI.exit()
            }
        }

        var show_stats = false
        var n = 0
        defer {
            if verbose {
                print(n != 1 ? "Processed \(n) files." : "Processed 1 file.")
            }
            
            if show_stats {
                print("""
    *** *** *** *** *** ***
    Thanks to this tool you have converted over \(Settings.renderStats) files.
    If you find it useful and you have the possibility, consider buying me a coffee! (https://buymeacoffee.com/sbarex)
    *** *** *** *** *** ***
    """)
            }
        }
        
        for url in files {
            let markdown_url = Settings.getMarkdownFile(from: url)
            
            do {
                guard FileManager.default.isReadableFile(atPath: markdown_url.path) else {
                    // print("Unable to read the file \(markdown_url.path)", to: &standardError)
                    os_log("Unable to read the file %{public}@", log: OSLog.cli, type: .error, markdown_url.path)
                    QLMarkdownCLI.exit(withError: QLError.unableToReadSource(path: markdown_url.path))
                }
                if verbose {
                    print("- processing \(markdown_url.path) ...")
                }
                
                let text = try settings.render(file: markdown_url, forAppearance: appearance, baseDir: markdown_url.deletingLastPathComponent().path)
                let html = settings.getCompleteHTML(title: url.lastPathComponent, body: text)
                
                Settings.renderStats += 1
                if !show_stats && Settings.renderStats > 0 && Settings.renderStats % 100 == 0 {
                    show_stats = true
                }
                
                var output: URL?
                if let dest {
                    if isDir.boolValue {
                        output = dest.appendingPathComponent(url.deletingPathExtension().lastPathComponent).appendingPathExtension("html")
                    } else {
                        output = dest
                    }
                }
                
                if let output {
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
                // print("Error processing \(url.path): \(error.localizedDescription)", to: &standardError)
                os_log("Error processing the file %{public}@: %{public}@", log: OSLog.cli, type: .error, url.path, error.localizedDescription)
                QLMarkdownCLI.exit(withError: QLError.processError(path: url.path, error: error))
            }
        }

    }
}
