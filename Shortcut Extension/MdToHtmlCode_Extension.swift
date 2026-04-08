//
//  Shortcut_Extension.swift
//  Shortcut Extension
//
//  Created by Sbarex on 25/12/24.
//

import AppIntents
import OSLog

enum GenerateHTMLEnum: String, AppEnum {
    case complete
    case fragment

    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "HTML code generation")

    static let caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .complete: "page",
        .fragment: "snippet",
    ]
}

enum OptionalBoolEnum: String, AppEnum {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = TypeDisplayRepresentation(name: "Option state")
    
    case predefined
    case on
    case off
    
    static let caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .predefined: "predefined",
        .on: "on",
        .off: "off",
    ]
    
    func updateValue(state: inout Bool) {
        switch self {
        case .predefined:
            break
        case .off:
            state = false
        case .on:
            state = true
        }
    }
}

enum JsLibratyOptionalEnum: String, AppEnum {
    case predefined
    case off
    case link
    case embed

    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Emoji option state")

    static let caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .predefined: "predefined",
        .off: "off",
        .link: "linked from web",
        .embed: "locally embedded",
    ]
    
    func updateValue(state: inout JSExtension) {
        switch self {
        case .predefined:
            break
        case .off:
            state = .disabled
        case .link:
            state = .link(url: nil)
        case .embed:
            state = .embed(url: nil)
        }
    }
}

enum EmojiOptionalEnum: String, AppEnum {
    case predefined
    case off
    case useFont
    case useImage

    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Emoji option state")

    static let caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .predefined: "predefined",
        .off: "off",
        .useFont: "replace using font",
        .useImage: "replace using images",
    ]
    
    func updateValue(state: inout EmojiMode) {
        switch self {
        case .predefined:
            break
        case .off:
            state = .disabled
        case .useFont:
            state = .font
        case .useImage:
            state = .images
        }
    }
}

enum StrikethroughOptionalEnum: String, AppEnum {
    case predefined
    case off
    case single
    case double

    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Strikethrough option state")

    static let caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .predefined: "predefined",
        .off: "off",
        .single: "recognize single ~",
        .double: "recognize double ~",
    ]
    
    func updateValue(state: inout StrikethroughMode) {
        switch self {
        case .predefined:
            break
        case .off:
            state = .disabled
        case .single:
            state = .single
        case .double:
            state = .double
        }
    }
}

enum YamlOptionalEnum: String, AppEnum {
    case predefined
    case off
    case rmd
    case all

    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "YAML header option state")

    static let caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .predefined: "predefined",
        .off: "off",
        .rmd: "only for .rmd and .qmd files",
        .all: "all files",
    ]
    
    func updateValue(state: inout YamlMode) {
        switch self {
        case .predefined:
            break
        case .off:
            state = .disabled
        case .rmd:
            state = .onlyRmd
        case .all:
            state = .allFiles
        }
    }
}

enum QLMError: LocalizedError {
    case noFile
    case cannotReadFile
    
    public var errorDescription: String? {
        switch self {
        case .noFile:
            return "No file selected."
        case .cannotReadFile:
            return "Cannot read file."
        }
    }
}

struct MdToHtmlCode_Extension: AppIntent {
    static var title: LocalizedStringResource { "Markdown format" }
    static var description: LocalizedStringResource { "Format a markdown file to HTML" }
    static var openAppWhenRun: Bool = false
    
    static var parameterSummary: some ParameterSummary {
        Summary("Format \(\.$inputFile) in an HTML code (\(\.$generateFullCode)).") {
            \.$smartQuotes
            \.$footNotes
            \.$hardBreak
            \.$noSoftBreak
            \.$allowInlineHtml
            \.$validateUTF8
            \.$showDebugInfo
            
            \.$autolink
            \.$emojiReplacement
            \.$headsAnchor
            \.$highlight
            \.$inlineLocalImages
            \.$mathExtension
            \.$mermaidExtension
            \.$subExtension
            \.$strikethrough
            \.$syntaxHighlight
            \.$tableExtension
            \.$tagFilter
            \.$taskExtension
            \.$yamlExtension
            
            \.$renderAsSource
        }
    }
    
    // Define the input parameter
    @Parameter(title: "Input File", description: "The Markdown file to format.")
    var inputFile: IntentFile
    
    @Parameter(title: "HTML code generation", description: "Generate a complete HTML page or only the body fragment.")
    var generateFullCode: GenerateHTMLEnum
    
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
    
    @Parameter(title: "Math extension", default: JsLibratyOptionalEnum.predefined)
    var mathExtension: JsLibratyOptionalEnum
    
    @Parameter(title: "Diagram extension", default: JsLibratyOptionalEnum.predefined)
    var mermaidExtension: JsLibratyOptionalEnum
    
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
    
    func perform() async throws -> some ReturnsValue<String> {
        guard let url = inputFile.fileURL else {
            throw QLMError.noFile
        }
        
        let _ = inputFile.data 
        
        // 
        Settings.appBundleUrl = Bundle.main.bundleURL.deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        
        let settings = Settings.shared
        
        smartQuotes.updateValue(state: &settings.smartQuotesOption)
        footNotes.updateValue(state: &settings.footnotesOption)
        hardBreak.updateValue(state: &settings.hardBreakOption)
        noSoftBreak.updateValue(state: &settings.noSoftBreakOption)
        allowInlineHtml.updateValue(state: &settings.unsafeHTMLOption)
        validateUTF8.updateValue(state: &settings.validateUTFOption)
        showDebugInfo.updateValue(state: &settings.debug)
        renderAsSource.updateValue(state: &settings.renderAsCode)
        autolink.updateValue(state: &settings.autoLinkExtension)
        emojiReplacement.updateValue(state: &settings.emojiExtension)
        headsAnchor.updateValue(state: &settings.headsExtension)
        highlight.updateValue(state: &settings.highlightExtension)
        inlineLocalImages.updateValue(state: &settings.inlineImageExtension)
        mathExtension.updateValue(state: &settings.mathExtension)
        mermaidExtension.updateValue(state: &settings.mermaidExtension)
        subExtension.updateValue(state: &settings.subExtension)
        subExtension.updateValue(state: &settings.supExtension)
        strikethrough.updateValue(state: &settings.strikethroughExtension)
        syntaxHighlight.updateValue(state: &settings.syntaxHighlightExtension)
        tableExtension.updateValue(state: &settings.tableExtension)
        tagFilter.updateValue(state: &settings.tagFilterExtension)
        taskExtension.updateValue(state: &settings.taskListExtension)
        yamlExtension.updateValue(state: &settings.yamlExtension)
        
        settings.sanitize()
        
        let markdown_url = Settings.getMarkdownFile(from: url)
        
        guard FileManager.default.isReadableFile(atPath: markdown_url.path) else {
            os_log("Unable to read the file %{public}@", log: OSLog.shortcutExtension, type: .error, markdown_url.path)
            throw QLMError.cannotReadFile
        }
         
        os_log("Processng file %{public}@", log: OSLog.shortcutExtension, type: .debug, markdown_url.path)
         
        let appearance: Appearance = Settings.isLightAppearance ? .light : .dark
        let text = try settings.render(file: markdown_url, forAppearance: appearance, baseDir: markdown_url.deletingLastPathComponent().path)
         
        let html = generateFullCode == .complete ? settings.getCompleteHTML(title: url.lastPathComponent, body: text) : text
         
        return .result(value: html)
    }
}
