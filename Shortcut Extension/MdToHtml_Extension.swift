//
//  Shortcut_Extension.swift
//  Shortcut Extension
//
//  Created by Sbarex on 25/12/24.
//

import AppIntents
import OSLog
import UniformTypeIdentifiers

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
    
    func perform() async throws -> some ReturnsValue<IntentFile> {
        guard let url = inputFile.fileURL else {
            throw QLMError.noFile
        }
        
        let _ = inputFile.data // FIXME: consente l'accesso al file?
        
        // FIXME: L'estensione non ha i privilegi per accedere al bundle dell'applicazione.
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
         
        let html = settings.getCompleteHTML(title: url.lastPathComponent, body: text)
         
        let dst = markdown_url.deletingPathExtension().lastPathComponent + ".html"
        return .result(value: IntentFile(data: Data(html.utf8), filename: dst, type: UTType.html))
    }
}
