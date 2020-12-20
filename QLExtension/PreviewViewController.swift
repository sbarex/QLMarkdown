//
//  PreviewViewController.swift
//  QLExtension
//
//  Created by Sbarex on 16/12/20.
//

import Cocoa
import Quartz
import WebKit
import OSLog

enum CMARK_Error: Error {
    case parser_create
    case parser_parse
}
class PreviewViewController: NSViewController, QLPreviewingController {
    private let log = {
        return OSLog(subsystem: Bundle.main.bundleIdentifier!, category: "quicklook.qlmarkdown-extension")
    }()
    
    @IBOutlet weak var webView: WKWebView!
    var handler: ((Error?) -> Void)? = nil
    
    override var nibName: NSNib.Name? {
        return NSNib.Name("PreviewViewController")
    }

    override func loadView() {
        super.loadView()
        // Do any additional setup after loading the view.
    }
    
    internal func getBundleContents(forResource: String, ofType: String) -> String?
    {
        if let p = Bundle.main.path(forResource: forResource, ofType: ofType), let data = FileManager.default.contents(atPath: p), let s = String(data: data, encoding: .utf8) {
            return s
        } else {
            return nil
        }
    }

    /*
     * Implement this method and set QLSupportsSearchableItems to YES in the Info.plist of the extension if you support CoreSpotlight.
     *
    func preparePreviewOfSearchableItem(identifier: String, queryString: String?, completionHandler handler: @escaping (Error?) -> Void) {
        // Perform any setup necessary in order to prepare the view.
        
        // Call the completion handler so Quick Look knows that the preview is fully loaded.
        // Quick Look will display a loading spinner while the completion handler is not called.
        handler(nil)
    }
     */
    
    func preparePreviewOfFile(at url: URL, completionHandler handler: @escaping (Error?) -> Void) {
        
        // Add the supported content types to the QLSupportedContentTypes array in the Info.plist of the extension.
        
        // Perform any setup necessary in order to prepare the view.
        
        // Call the completion handler so Quick Look knows that the preview is fully loaded.
        // Quick Look will display a loading spinner while the completion handler is not called.
        
        os_log(
            "Generating preview for file %{public}s",
            log: self.log,
            type: .info,
            url.path
        )
        
        let settings = Settings.shared
        
        cmark_gfm_core_extensions_ensure_registered()
        
        var options = CMARK_OPT_DEFAULT
        if settings.emojiExtension {
            options |= CMARK_OPT_UNSAFE
        }
        
        if settings.hardBreakOption {
            options |= CMARK_OPT_HARDBREAKS
        }
        if settings.noSoftBreakOption {
            options |= CMARK_OPT_NOBREAKS
        }
        if settings.unsafeHTMLOption {
            options |= CMARK_OPT_UNSAFE
        }
        if settings.validateUTFOption {
            options |= CMARK_OPT_VALIDATE_UTF8
        }
        if settings.smartQuotesOption {
            options |= CMARK_OPT_SMART
        }
        if settings.footnotesOption {
            options |= CMARK_OPT_FOOTNOTES
        }
        
        if settings.strikethroughExtension && settings.strikethroughDoubleTildeOption {
            options |= CMARK_OPT_STRIKETHROUGH_DOUBLE_TILDE
        }
        
        os_log(
            "cmark_gfm options: %{public}d.",
            log: self.log,
            type: .debug,
            options
        )
        
        // Modified version of cmark_parse_document in blocks.c
        guard let parser = cmark_parser_new(options) else {
            handler(CMARK_Error.parser_create)
            return
        }
        defer {
            cmark_parser_free(parser)
        }
        
        if settings.tableExtension, let ext = cmark_find_syntax_extension("table") {
            cmark_parser_attach_syntax_extension(parser, ext)
            os_log(
                "Enbaled markdown `table` extension.",
                log: self.log,
                type: .debug
            )
        }
        if settings.autoLinkExtension, let ext = cmark_find_syntax_extension("autolink") {
            cmark_parser_attach_syntax_extension(parser, ext)
            os_log(
                "Enbaled markdown `autolink` extension.",
                log: self.log,
                type: .debug
            )
        }
        if settings.tagFilterExtension, let ext = cmark_find_syntax_extension("tagfilter") {
            cmark_parser_attach_syntax_extension(parser, ext)
            os_log(
                "Enbaled markdown `tagfilter` extension.",
                log: self.log,
                type: .debug
            )
        }
        if settings.taskListExtension, let ext = cmark_find_syntax_extension("tasklist") {
            cmark_parser_attach_syntax_extension(parser, ext)
            os_log(
                "Enbaled markdown `tasklist` extension.",
                log: self.log,
                type: .debug
            )
        }
        if settings.strikethroughExtension, let ext = cmark_find_syntax_extension("strikethrough") {
            cmark_parser_attach_syntax_extension(parser, ext)
            os_log(
                "Enbaled markdown `strikethrough` extension.",
                log: self.log,
                type: .debug
            )
        }
        
        if settings.mentionExtension, let ext = cmark_find_syntax_extension("mention") {
            cmark_parser_attach_syntax_extension(parser, ext)
            os_log(
                "Enbaled markdown `mention` extension.",
                log: self.log,
                type: .debug
            )
        }
        /*
        if settings.checkboxExtension, let ext = cmark_find_syntax_extension("checkbox") {
            cmark_parser_attach_syntax_extension(parser, ext)
        }
 */
        
        if settings.inlineImageExtension, let ext = cmark_find_syntax_extension("inlineimage") {
            let path = url.deletingLastPathComponent().path
            cmark_parser_attach_syntax_extension(parser, ext)
            
            cmark_syntax_extension_inlineimage_set_wd(ext, path.cString(using: .utf8))
            
            os_log(
                "Enbaled markdown `local inline image` extension with working path set to `%{public}s.",
                log: self.log,
                type: .debug,
                path
            )
        }
        
        if settings.emojiExtension, let ext = cmark_find_syntax_extension("emoji") {
            cmark_syntax_extension_emoji_set_use_characters(ext, !settings.emojiImageOption)
            cmark_parser_attach_syntax_extension(parser, ext)
            os_log(
                "Enbaled markdown `emoji` extension using %{public}%s.",
                log: self.log,
                type: .debug,
                settings.emojiImageOption ? "images" : "glyphs"
            )
        }
        
        if settings.syntaxHighlightExtension, let ext = cmark_find_syntax_extension("syntaxhighlight") {
            let theme = settings.syntaxThemeLight
            let background = settings.syntaxBackgroundColorLight
            
            cmark_syntax_extension_highlight_set_theme_name(ext, theme)
            if background == "" {
                cmark_syntax_extension_highlight_set_background_color(ext, nil)
            } else if background == "ignore" {
                cmark_syntax_extension_highlight_set_background_color(ext, "ignore")
            } else {
                cmark_syntax_extension_highlight_set_background_color(ext, background)
            }
            
            cmark_parser_attach_syntax_extension(parser, ext)
            
            os_log(
                "Enbaled markdown `syntax highlight` extension.\n Theme: %{public}s, background color: %{public}s",
                log: self.log,
                type: .debug,
                theme, background
            )
        }
        
        if let data = FileManager.default.contents(atPath: url.path), let markdown_string = String(data: data, encoding: .utf8) {
        
            cmark_parser_feed(parser, markdown_string, strlen(markdown_string))
            guard let doc = cmark_parser_finish(parser) else {
                handler(CMARK_Error.parser_parse)
                return
            }
            defer {
                cmark_node_free(doc)
            }
        
            // Render
            let html2 = cmark_render_html(doc, options, nil)
            defer {
                free(html2)
            }
        
            let html = String(cString: html2!)
            let css1 = getBundleContents(forResource: "markdown", ofType: "css") ?? ""
            let css2 = getBundleContents(forResource: "syntax", ofType: "css") ?? ""
            
            self.handler = handler
            webView.loadHTMLString(
"""
<!doctype html>
<html>
<head>
<meta charset='utf-8'>
<meta name='viewport' content='width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=0'>
<title>\(url.lastPathComponent)</title>
<base href="\(url.deletingLastPathComponent().path)" />
<style type='text/css'>
\(css1)
\(css2)
</style>
</head>
<body class="markdown-body">
\(html)
</body>
</html>
""", baseURL: url.deletingLastPathComponent())
        
        } else {
            webView.loadHTMLString("Error!", baseURL: nil)
        }
    }
}

extension PreviewViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if let handler = self.handler {
            // Show the quicklook preview only after the complete rendering (preventing a flickering glitch).
            
            handler(nil)
            self.handler = nil
        }
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        if let handler = self.handler {
            handler(error)
            self.handler = nil
        }
    }
}
