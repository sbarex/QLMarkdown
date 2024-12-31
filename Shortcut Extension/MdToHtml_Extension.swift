//
//  Shortcut_Extension.swift
//  Shortcut Extension
//
//  Created by Sbarex on 25/12/24.
//

import AppIntents
import OSLog
import UniformTypeIdentifiers

enum QLMError: Error {
    case noFile
    case cannotReadFile
}
extension QLMError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .noFile:
            return "No file selected."
        case .cannotReadFile:
            return "Cannot read file."
        }
    }
}


struct MdToHtml_Extension: AppIntent {
    static var title: LocalizedStringResource { "Markdown convert" }
    static var description: LocalizedStringResource { "Convert a Markdown file to HTML." }
    static var openAppWhenRun: Bool = false
    
    static var parameterSummary: some ParameterSummary {
        Summary("Convert \(\.$inputFile) into a HTML file.") {
            \.$smartQuotes
            \.$footNotes
            \.$hardBreak
            \.$noSoftBreak
            \.$allowInlineHtml
            \.$validateUTF8
            \.$showDebugInfo
            \.$renderAsSource
            \.$autolink
            \.$emojiReplacement
            \.$headsAnchor
            \.$highlight
            \.$inlineLocalImages
            \.$mathExtension
            \.$subExtension
            \.$strikethrough
            \.$syntaxHighlight
            \.$tableExtension
            \.$tagFilter
            \.$taskExtension
            \.$yamlExtension
        }
    }
    
    // Define the input parameter
    @Parameter(title: "Input File",
                  description: "The Markdown file to convert.",
               supportedContentTypes: [UTType(filenameExtension: "md")!, UTType.text, UTType.item])
    var inputFile: IntentFile
    
    @Parameter(title: "Smart quotes", default: OptionalBoolEnum.predefined)
    var smartQuotes: OptionalBoolEnum
    
    @Parameter(title: "Footnotes", default: OptionalBoolEnum.predefined)
    var footNotes: OptionalBoolEnum
    
    @Parameter(title: "Hard breaks", default: OptionalBoolEnum.predefined)
    var hardBreak: OptionalBoolEnum
    
    @Parameter(title: "No soft breaks", default: OptionalBoolEnum.predefined)
    var noSoftBreak: OptionalBoolEnum
    
    @Parameter(title: "Allow inline HTML (unsafe)", default: OptionalBoolEnum.predefined)
    var allowInlineHtml: OptionalBoolEnum
    
    @Parameter(title: "Validate UTF8", default: OptionalBoolEnum.predefined)
    var validateUTF8: OptionalBoolEnum
    
    @Parameter(title: "Show debug info", default: OptionalBoolEnum.predefined)
    var showDebugInfo: OptionalBoolEnum
    
    @Parameter(title: "Render as source code", default: OptionalBoolEnum.predefined)
    var renderAsSource: OptionalBoolEnum
    
    @Parameter(title: "Autolink", default: OptionalBoolEnum.predefined)
    var autolink: OptionalBoolEnum
    
    @Parameter(title: "Emoji replacement", default: EmojiOptionalEnum.predefined)
    var emojiReplacement: EmojiOptionalEnum
    
    @Parameter(title: "Heads anchor", default: OptionalBoolEnum.predefined)
    var headsAnchor: OptionalBoolEnum
    
    @Parameter(title: "Highlight", default: OptionalBoolEnum.predefined)
    var highlight: OptionalBoolEnum
    
    @Parameter(title: "Embed local images", default: OptionalBoolEnum.predefined)
    var inlineLocalImages: OptionalBoolEnum
    
    @Parameter(title: "Math extension", default: OptionalBoolEnum.predefined)
    var mathExtension: OptionalBoolEnum
    
    @Parameter(title: "Sub/Superscript extension", default: OptionalBoolEnum.predefined)
    var subExtension: OptionalBoolEnum
    
    @Parameter(title: "Strikethrough extension", default: StrikethroughOptionalEnum.predefined)
    var strikethrough: StrikethroughOptionalEnum
    
    @Parameter(title: "Syntax highlight extension", default: OptionalBoolEnum.predefined)
    var syntaxHighlight: OptionalBoolEnum
    
    @Parameter(title: "Table extension", default: OptionalBoolEnum.predefined)
    var tableExtension: OptionalBoolEnum
    
    @Parameter(title: "Tag filter", default: OptionalBoolEnum.predefined)
    var tagFilter: OptionalBoolEnum
    
    @Parameter(title: "Task list", default: OptionalBoolEnum.predefined)
    var taskExtension: OptionalBoolEnum
    
    @Parameter(title: "YAML header", default: YamlOptionalEnum.predefined)
    var yamlExtension: YamlOptionalEnum
    
    func perform() async throws -> some ReturnsValue<IntentFile> {
        guard let url = inputFile.fileURL else {
            throw QLMError.noFile
        }
        
        let _ = inputFile.data // FIXME: consente l'accesso al file?
        
        // FIXME: L'estensione non ha i privilegi per accedere al bundle dell'applicazione.
        Settings.appBundleUrl = Bundle.main.bundleURL.deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("Contents/Resources")
        let settings = Settings.shared
        
        if self.smartQuotes != .predefined {
            settings.smartQuotesOption = self.smartQuotes == .on
        }
        if self.footNotes != .predefined {
            settings.footnotesOption = self.footNotes == .on
        }
        if self.hardBreak != .predefined {
            settings.hardBreakOption = self.hardBreak == .on
        }
        if self.noSoftBreak != .predefined {
            settings.noSoftBreakOption = self.noSoftBreak == .on
        }
        if self.allowInlineHtml != .predefined {
            settings.unsafeHTMLOption = self.allowInlineHtml == .on
        }
        if self.validateUTF8 != .predefined {
            settings.validateUTFOption = self.validateUTF8 == .on
        }
        if self.showDebugInfo != .predefined {
            settings.debug = self.showDebugInfo == .on
        }
        if self.renderAsSource != .predefined {
            settings.renderAsCode = self.renderAsSource == .on
        }
        
        
        if self.autolink != .predefined {
            settings.autoLinkExtension = self.autolink == .on
        }
        
        if self.emojiReplacement != .predefined {
            settings.emojiExtension = self.emojiReplacement != .off
            settings.emojiImageOption = self.emojiReplacement == .useImage
        }
        
        if self.headsAnchor != .predefined {
            settings.headsExtension = self.headsAnchor == .on
        }
        if self.highlight != .predefined {
            settings.highlightExtension = self.highlight == .on
        }
        if self.inlineLocalImages != .predefined {
            settings.inlineImageExtension = self.inlineLocalImages == .on
        }
        if self.mathExtension != .predefined {
            settings.mathExtension = self.mathExtension == .on
        }
        if self.subExtension != .predefined {
            settings.supExtension = self.subExtension == .on
            settings.supExtension = self.subExtension == .on
        }
        if self.strikethrough != .predefined {
            settings.strikethroughExtension = self.strikethrough != .off
            settings.strikethroughDoubleTildeOption = self.strikethrough == .double
        }
        if self.syntaxHighlight != .predefined {
            settings.syntaxHighlightExtension = self.syntaxHighlight == .on
        }
        if self.tableExtension != .predefined {
            settings.tableExtension = self.tableExtension == .on
        }
        if self.tagFilter != .predefined {
            settings.tagFilterExtension = self.tagFilter == .on
        }
        if self.taskExtension != .predefined {
            settings.taskListExtension = self.taskExtension == .on
        }
        if self.yamlExtension != .predefined {
            settings.yamlExtension = self.yamlExtension != .off
            settings.yamlExtensionAll = self.yamlExtension == .all
        }
        
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
        
        guard FileManager.default.isReadableFile(atPath: markdown_url.path) else {
            os_log("Unable to read the file %{private}@", log: OSLog.shortcutExtension, type: .error, markdown_url.path)
            throw QLMError.cannotReadFile
        }
         
        os_log("Processng file %{private}@", log: OSLog.shortcutExtension, type: .debug, markdown_url.path)
         
        let appearance: Appearance = (UserDefaults.standard.string(forKey: "AppleInterfaceStyle") ?? "Light") == "Light" ? .light : .dark
        let text = try settings.render(file: markdown_url, forAppearance: appearance, baseDir: markdown_url.deletingLastPathComponent().path)
         
        let html = settings.getCompleteHTML(title: url.lastPathComponent, body: text, basedir: markdown_url.deletingLastPathComponent(), forAppearance: appearance)
         
        let dst = markdown_url.deletingPathExtension().lastPathComponent + ".html"
        return .result(value: IntentFile(data: Data(html.utf8), filename: dst, type: UTType.html))
    }
}
