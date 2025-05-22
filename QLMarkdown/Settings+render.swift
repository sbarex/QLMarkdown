//
//  Settings+render.swift
//  QLMarkdown
//
//  Created by Sbarex on 06/05/25.
//

import Foundation
import OSLog
import SwiftSoup

extension Settings {
    func render(text: String, filename: String, forAppearance appearance: Appearance, baseDir: String) throws -> String {
        if self.renderAsCode, let code = self.renderCode(text: text, forAppearance: appearance, baseDir: baseDir) {
            return code
        }
        
        cmark_gfm_core_extensions_ensure_registered()
        cmark_gfm_extra_extensions_ensure_registered()
        
        var options = CMARK_OPT_DEFAULT
        if self.unsafeHTMLOption {
            options |= CMARK_OPT_UNSAFE
        }
        
        if self.hardBreakOption {
            options |= CMARK_OPT_HARDBREAKS
        }
        if self.noSoftBreakOption {
            options |= CMARK_OPT_NOBREAKS
        }
        if self.validateUTFOption {
            options |= CMARK_OPT_VALIDATE_UTF8
        }
        if self.smartQuotesOption {
            options |= CMARK_OPT_SMART
        }
        if self.footnotesOption {
            options |= CMARK_OPT_FOOTNOTES
        }
        
        if self.strikethroughExtension && self.strikethroughDoubleTildeOption {
            options |= CMARK_OPT_STRIKETHROUGH_DOUBLE_TILDE
        }
        
        os_log("cmark_gfm options: %{public}d.", log: OSLog.rendering, type: .debug, options)
        
        guard let parser = cmark_parser_new(options) else {
            os_log("Unable to create new cmark_parser!", log: OSLog.rendering, type: .error, options)
            throw CMARK_Error.parser_create
        }
        defer {
            cmark_parser_free(parser)
        }
        
        /*
        var extensions: UnsafeMutablePointer<cmark_llist>? = nil
        defer {
            cmark_llist_free(cmark_get_default_mem_allocator(), extensions)
        }
        */
        
        if self.tableExtension {
            if let ext = cmark_find_syntax_extension("table") {
                cmark_parser_attach_syntax_extension(parser, ext)
                os_log("Enabled markdown markdown `table` extension.", log: OSLog.rendering, type: .debug)
                // extensions = cmark_llist_append(cmark_get_default_mem_allocator(), nil, &ext)
            } else {
                os_log("Could not enable markdown `table` extension!", log: OSLog.rendering, type: .error)
            }
        }
        
        if self.autoLinkExtension {
            if let ext = cmark_find_syntax_extension("autolink") {
                cmark_parser_attach_syntax_extension(parser, ext)
                os_log("Enabled markdown `autolink` extension.", log: OSLog.rendering, type: .debug)
            } else {
                os_log("Could not enable markdown `autolink` extension!", log: OSLog.rendering, type: .error)
            }
        }
        
        if self.tagFilterExtension {
            if let ext = cmark_find_syntax_extension("tagfilter") {
                cmark_parser_attach_syntax_extension(parser, ext)
                os_log("Enabled markdown `tagfilter` extension.", log: OSLog.rendering, type: .debug)
            } else {
                os_log("Could not enable markdown `tagfilter` extension!", log: OSLog.rendering, type: .error)
            }
        }
        
        if self.taskListExtension {
            if let ext = cmark_find_syntax_extension("tasklist") {
                cmark_parser_attach_syntax_extension(parser, ext)
                os_log("Enabled markdown `tasklist` extension.",  log: OSLog.rendering, type: .debug)
            } else {
                os_log("Could not enable markdown `tasklist` extension!", log: OSLog.rendering, type: .error)
            }
        }
        
        var md_text = text
        
        var header = ""
        
        if self.yamlExtension && (self.yamlExtensionAll || filename.lowercased().hasSuffix("rmd") || filename.lowercased().hasSuffix("qmd")) && md_text.hasPrefix("---") {
            /*
             (?s): Turn on "dot matches newline" for the remainder of the regular expression. For “single line mode” makes the dot match all characters, including line breaks.
             (?<=---\n): Positive lookbehind. Matches at a position if the pattern inside the lookbehind can be matched ending at that position. Find expression .* where expression `---\n` precedes.
             (?>\n(?:---|\.\.\.):
             (?:---|\.\.\.): not capturing group
             */
            let pattern = "(?s)((?<=---\n).*?(?>\n(?:---|\\.\\.\\.)\n))"
            if let range = md_text.range(of: pattern, options: .regularExpression) {
                let yaml = String(md_text[range.lowerBound ..< md_text.index(range.upperBound, offsetBy: -4)])
                var isHTML = false
                header = self.renderYamlHeader(yaml, isHTML: &isHTML)
                if isHTML {
                    md_text = String(md_text[range.upperBound ..< md_text.endIndex])
                } else {
                    md_text = header + md_text[range.upperBound ..< md_text.endIndex]
                    header = ""
                }
            }
        }
        
        if self.strikethroughExtension {
            if let ext = cmark_find_syntax_extension("strikethrough") {
                cmark_parser_attach_syntax_extension(parser, ext)
                os_log("Enabled markdown `strikethrough` extension.", log: OSLog.rendering, type: .debug)
            } else {
                os_log("Could not enable markdown `strikethrough` extension!", log: OSLog.rendering, type: .error)
            }
        }
        
        if self.mentionExtension {
            if let ext = cmark_find_syntax_extension("mention") {
                cmark_parser_attach_syntax_extension(parser, ext)
                os_log("Enabled markdown `mention` extension.", log: OSLog.rendering, type: .debug)
            } else {
                os_log("Could not enable markdown `mention` extension!", log: OSLog.rendering, type: .error)
            }
        }
        
        if self.headsExtension {
            if let ext = cmark_find_syntax_extension("heads") {
                cmark_parser_attach_syntax_extension(parser, ext)
                os_log("Enabled markdown `heads` extension.", log: OSLog.rendering, type: .debug)
            } else {
                os_log("Could not enable markdown `heads` extension!", log: OSLog.rendering, type: .error)
            }
        }
        
        if self.highlightExtension {
            if let ext = cmark_find_syntax_extension("highlight") {
                cmark_parser_attach_syntax_extension(parser, ext)
                
                os_log(
                    "Enabled markdown `highlight` extension.",
                    log: OSLog.rendering,
                    type: .debug)
            } else {
                os_log("Could not enable markdown `highlight` extension!", log: OSLog.rendering, type: .error)
            }
        }
        
        
        if self.subExtension {
            if let ext = cmark_find_syntax_extension("sub") {
                cmark_parser_attach_syntax_extension(parser, ext)
                
                os_log(
                    "Enabled markdown `sub` extension.",
                    log: OSLog.rendering,
                    type: .debug)
            } else {
                os_log("Could not enable markdown `sub` extension!", log: OSLog.rendering, type: .error)
            }
        }
        
        if self.supExtension {
            if let ext = cmark_find_syntax_extension("sup") {
                cmark_parser_attach_syntax_extension(parser, ext)
                
                os_log(
                    "Enabled markdown `sup` extension.",
                    log: OSLog.rendering,
                    type: .debug)
            } else {
                os_log("Could not enable markdown `sup` extension!", log: OSLog.rendering, type: .error)
            }
        }
        
        if self.inlineImageExtension {
            if let ext = cmark_find_syntax_extension("inlineimage") {
                cmark_parser_attach_syntax_extension(parser, ext)
                cmark_syntax_extension_inlineimage_set_wd(ext, baseDir.cString(using: .utf8))
                cmark_syntax_extension_inlineimage_set_mime_callback(ext, { (path, context) in
                    let magic_file = Settings.getResourceBundle().path(forResource: "magic", ofType: "mgc")?.cString(using: .utf8)
                    let r = magic_get_mime_by_file(path, magic_file)
                    return r
                }, nil)
                /*
                cmark_syntax_extension_inlineimage_set_remote_data_callback(ext, { (url, context) -> UnsafeMutablePointer<Int8>? in
                    guard let uu = url, let u = URL(string: String(cString: uu)) else {
                        return nil
                    }
                    do {
                        let data = try Data(contentsOf: u)
                    } catch {
                        os_log("Error fetch data from %{public}@: %{public}@", log: OSLog.rendering, type: .error, String(cString: uu), error.localizedDescription)
                        return nil
                    }
                    return nil
                }, nil)
                */
                
                os_log("Enabled markdown `local inline image` extension with working path set to `%{public}s`.", log: OSLog.rendering, type: .debug, baseDir)
                
                if self.unsafeHTMLOption {
                    cmark_syntax_extension_inlineimage_set_unsafe_html_processor_callback(ext, { (ext, fragment, workingDir, context, code) in
                        guard let fragment = fragment else {
                            return
                        }
                        
                        let baseDir: URL
                        if let s = workingDir {
                            let b = String(cString: s)
                            baseDir = URL(fileURLWithPath: b)
                        } else {
                            baseDir = URL(fileURLWithPath: "")
                        }
                        let html = String(cString: fragment)
                        var changed = false
                        do {
                            let doc = try SwiftSoup.parseBodyFragment(html, baseDir.path)
                            for img in try doc.select("img") {
                                let src = try img.attr("src")
                                
                                guard !src.isEmpty, !src.hasPrefix("http"), !src.hasPrefix("HTTP") else {
                                    // Do not handle external image.
                                    continue
                                }
                                guard !src.hasPrefix("data:") else {
                                    // Do not reprocess data: image.
                                    continue
                                }
                                
                                let file = baseDir.appendingPathComponent(src).path
                                guard FileManager.default.fileExists(atPath: file) else {
                                    os_log("Image %{private}@ not found!", log: OSLog.rendering, type: .error)
                                    continue // File not found.
                                }
                                guard let data = get_base64_image(
                                    file.cString(using: .utf8),
                                    { (path: UnsafePointer<Int8>?, context: UnsafeMutableRawPointer?) -> UnsafeMutablePointer<Int8>? in
                                        let magic_file = Settings.getResourceBundle().path(forResource: "magic", ofType: "mgc")?.cString(using: .utf8)
                                        
                                        let r = magic_get_mime_by_file(path, magic_file)
                                        return r
                                    },
                                    nil,
                                    /*{ (url, _ )->UnsafeMutablePointer<Int8>? in
                                        guard let s = url else {
                                            return nil
                                        }
                                        let u = URL(fileURLWithPath: String(cString: s))
                                        guard let data = try? Data(contentsOf: u) else {
                                            return nil
                                        }
                                        return nil
                                    }*/ nil,
                                    nil
                                ) else {
                                    continue
                                }
                                defer {
                                    data.deallocate()
                                }
                                let img_data = String(cString: data)
                                try img.attr("src", img_data)
                                changed = true
                            }
                            if changed, let html = try doc.body()?.html(), let s = strdup(html) {
                                code?.pointee = UnsafePointer(s)
                            }
                        } catch Exception.Error(_, let message) {
                            os_log("Error processing html: %{public}@!", log: OSLog.rendering, type: .error, message)
                        } catch {
                            os_log("Error parsing html: %{public}@!", log: OSLog.rendering, type: .error, error.localizedDescription)
                        }
                    }, nil)
                }
            } else {
                os_log("Could not enable markdown `local inline image` extension!", log: OSLog.rendering, type: .error)
            }
        }
        
        if self.emojiExtension {
            if let ext = cmark_find_syntax_extension("emoji") {
                cmark_syntax_extension_emoji_set_use_characters(ext, !self.emojiImageOption)
                cmark_parser_attach_syntax_extension(parser, ext)
                os_log("Enabled markdown `emoji` extension using %{public}s.", log: OSLog.rendering, type: .debug, self.emojiImageOption ? "images" : "glyphs")
            } else {
                os_log("Could not enable markdown `emoji` extension!", log: OSLog.rendering, type: .error)
            }
        }
        
        if self.mathExtension {
            if let ext = cmark_find_syntax_extension("math") {
                cmark_parser_attach_syntax_extension(parser, ext)
                
                os_log(
                    "Enabled markdown `math` extension.",
                    log: OSLog.rendering,
                    type: .debug)
            } else {
                os_log("Could not enable markdown `math` extension!", log: OSLog.rendering, type: .error)
            }
        }
        
        if self.syntaxHighlightExtension {
            if let ext = cmark_find_syntax_extension("syntaxhighlight") {
                if let path = getHighlightSupportPath() {
                    cmark_syntax_highlight_init("\(path)/".cString(using: .utf8))
                } else {
                    os_log("Unable to found the `highlight` support dir!", log: OSLog.rendering, type: .error)
                }
                
                cmark_syntax_extension_highlight_set_theme_name(ext, "")
                cmark_syntax_extension_highlight_set_background_color(ext, nil /* "var(--hl_Background)" */)
                cmark_syntax_extension_highlight_set_line_number(ext, self.syntaxLineNumbersOption ? 1 : 0)
                cmark_syntax_extension_highlight_set_tab_spaces(ext, Int32(self.syntaxTabsOption))
                cmark_syntax_extension_highlight_set_wrap_limit(ext, Int32(self.syntaxWordWrapOption))
                cmark_syntax_extension_highlight_set_guess_language(ext, guess_type(UInt32(self.guessEngine.rawValue)))
                if self.guessEngine == .simple, let f = self.resourceBundle.path(forResource: "magic", ofType: "mgc") {
                    cmark_syntax_extension_highlight_set_magic_file(ext, f)
                }
                
                if !self.syntaxFontFamily.isEmpty {
                    cmark_syntax_extension_highlight_set_font_family(ext, self.syntaxFontFamily, Float(self.syntaxFontSize))
                } else {
                    // cmark_syntax_extension_highlight_set_font_family(ext, "-apple-system, BlinkMacSystemFont, sans-serif", 0.0)
                    // Pass a fake value, so will be used the font defined inside the main css file.
                    cmark_syntax_extension_highlight_set_font_family(ext, "-", 0.0)
                }
                
                cmark_parser_attach_syntax_extension(parser, ext)
                
                os_log(
                    "Enabled markdown `syntax highlight` extension.",
                    log: OSLog.rendering,
                    type: .debug)
            } else {
                os_log("Could not enable markdown `syntax highlight` extension!", log: OSLog.rendering, type: .error)
            }
        }
        
        cmark_parser_feed(parser, md_text, strlen(md_text))
        guard let doc = cmark_parser_finish(parser) else {
            throw CMARK_Error.parser_parse
        }
        defer {
            cmark_node_free(doc)
        }
        
        let about = self.about ? "<div style='font-size: 72%; margin-top: 1.5em; padding-top: .5em; -webkit-user-select: none;'><hr style='height: 0; border: none; border-top: 1px solid rgba(0,0,0,.5); box-shadow: 0 1px 1px rgba(255, 255, 255, .5)'/>\(self.app_version)</div>\n\(self.app_version2)" : ""
        
        let html_debug = self.renderDebugInfo(forAppearance: appearance, baseDir: baseDir)
        // Render
        if let html2 = cmark_render_html(doc, options, cmark_parser_get_syntax_extensions(parser)) {
            defer {
                free(html2)
            }
            
            return html_debug + header + String(cString: html2) + about
        } else {
            return html_debug + "<p>RENDER FAILED!</p>"
        }
    }
    
    internal func renderDebugInfo(forAppearance appearance: Appearance, baseDir: String) -> String
    {
        guard debug else {
            return ""
        }
        var html_debug = ""
        html_debug += """
<style type="text/css">
table.debug td {
    vertical-align: top;
    font-size: .8rem;
}
</style>
"""
        html_debug += "<table class='debug'>\n<caption>Debug info</caption>"
        var html_options = ""
        if self.unsafeHTMLOption || (self.emojiExtension && self.emojiImageOption) {
            html_options += "CMARK_OPT_UNSAFE "
        }
        
        if self.hardBreakOption {
            html_options += "CMARK_OPT_HARDBREAKS "
        }
        if self.noSoftBreakOption {
            html_options += "CMARK_OPT_NOBREAKS "
        }
        if self.validateUTFOption {
            html_options += "CMARK_OPT_VALIDATE_UTF8 "
        }
        if self.smartQuotesOption {
            html_options += "CMARK_OPT_SMART "
        }
        if self.footnotesOption {
            html_options += "CMARK_OPT_FOOTNOTES "
        }
        
        if self.strikethroughExtension && self.strikethroughDoubleTildeOption {
            html_options += "CMARK_OPT_STRIKETHROUGH_DOUBLE_TILDE "
        }

        html_debug += "<tr><td>options</td><td>\(html_options)</td></tr>\n"
        
        html_debug += "<tr><td>autolink extension</td><td>"
        if self.autoLinkExtension {
            html_debug += "on " + (cmark_find_syntax_extension("autolink") == nil ? " (NOT AVAILABLE" : "")
        } else {
            html_debug += "off"
        }
        html_debug += "</td></tr>\n"
        
        html_debug += "<tr><td>emoji extension</td><td>"
        if self.emojiExtension {
            html_debug += "on" + (cmark_find_syntax_extension("emoji") == nil ? " (NOT AVAILABLE" : "")
            html_debug += " / \(self.emojiImageOption ? "using images" : "using emoji")"
        } else {
            html_debug += "off"
        }
        html_debug += "</td></tr>\n"
        
        html_debug += "<tr><td>heads extension</td><td>" + (self.headsExtension ?  "on" : "off") + "</td></tr>\n"
        
        html_debug += "<tr><td>highlight extension</td><td>"
        if self.highlightExtension {
            html_debug += "on " + (cmark_find_syntax_extension("highlight") == nil ? " (NOT AVAILABLE" : "")
        } else {
            html_debug += "off"
        }
        html_debug += "</td></tr>\n"
        
        html_debug += "<tr><td>inlineimage extension</td><td>"
        if self.inlineImageExtension {
            html_debug += "on" + (cmark_find_syntax_extension("inlineimage") == nil ? " (NOT AVAILABLE" : "")
            html_debug += "<br />basedir: \(baseDir)"
        } else {
            html_debug += "off"
        }
        html_debug += "</td></tr>\n"
        
        html_debug += "<tr><td>math extension</td><td>"
        if self.mathExtension {
            html_debug += "on " + (cmark_find_syntax_extension("math") == nil ? " (NOT AVAILABLE" : "")
        } else {
            html_debug += "off"
        }
        html_debug += "</td></tr>\n"
        
        html_debug += "<tr><td>mention extension</td><td>"
        if self.mentionExtension {
            html_debug += "on " + (cmark_find_syntax_extension("mention") == nil ? " (NOT AVAILABLE" : "")
        } else {
            html_debug += "off"
        }
        html_debug += "</td></tr>\n"
        
        html_debug += "<tr><td>strikethrough extension</td><td>"
        if self.strikethroughExtension {
            html_debug += "on " + (cmark_find_syntax_extension("strikethrough") == nil ? " (NOT AVAILABLE" : "")
        } else {
            html_debug += "off"
        }
        html_debug += "</td></tr>\n"
        
        html_debug += "<tr><td>syntax highlighting extension</td><td>"
        if self.syntaxHighlightExtension {
            html_debug += "on " + (cmark_find_syntax_extension("syntaxhighlight") == nil ? " (NOT AVAILABLE" : "")
            
            html_debug += "<table>\n"
            html_debug += "<tr><td>datadir</td><td>\(getHighlightSupportPath() ?? "missing")</td></tr>\n"
            html_debug += "<tr><td>line numbers</td><td>\(self.syntaxLineNumbersOption ? "on" : "off")</td></tr>\n"
            html_debug += "<tr><td>spaces for a tab</td><td>\(self.syntaxTabsOption)</td></tr>\n"
            html_debug += "<tr><td>wrap</td><td> \(self.syntaxWordWrapOption > 0 ? "after \(self.syntaxWordWrapOption) characters" : "disabled")</td></tr>\n"
            html_debug += "<tr><td>spaces for a tab</td><td>\(self.syntaxTabsOption)</td></tr>\n"
            html_debug += "<tr><td>guess language</td><td>"
            switch self.guessEngine {
            case .none:
                html_debug += "off"
            case .simple:
                html_debug += "simple<br />"
                html_debug += "magic db: \(self.resourceBundle.path(forResource: "magic", ofType: "mgc") ?? "missing")"
            case .accurate:
                html_debug += "accurate"
            }
            html_debug += "</td></tr>\n"
            html_debug += "<tr><td>font family</td><td>\(self.syntaxFontFamily.isEmpty ? "not set" : self.syntaxFontFamily)</td></tr>\n"
            html_debug += "<tr><td>font size</td><td>\(self.syntaxFontSize > 0 ? "\(self.syntaxFontSize)" : "not set")</td></tr>\n"
            html_debug += "</table>\n"
        } else {
            html_debug += "off"
        }
        html_debug += "</td></tr>\n"
        
        html_debug += "<tr><td>sub extension</td><td>"
        if self.subExtension {
            html_debug += "on " + (cmark_find_syntax_extension("sub") == nil ? " (NOT AVAILABLE" : "")
        } else {
            html_debug += "off"
        }
        html_debug += "</td></tr>\n"
        html_debug += "<tr><td>sup extension</td><td>"
        if self.supExtension {
            html_debug += "on " + (cmark_find_syntax_extension("sup") == nil ? " (NOT AVAILABLE" : "")
        } else {
            html_debug += "off"
        }
        html_debug += "</td></tr>\n"
        
        html_debug += "<tr><td>table extension</td><td>"
        if self.tableExtension {
            html_debug += "on " + (cmark_find_syntax_extension("table") == nil ? " (NOT AVAILABLE" : "")
        } else {
            html_debug += "off"
        }
        html_debug += "</td></tr>\n"
        
        html_debug += "<tr><td>tagfilter extension</td><td>"
        if self.tagFilterExtension {
            html_debug += "on " + (cmark_find_syntax_extension("tagfilter") == nil ? " (NOT AVAILABLE" : "")
        } else {
            html_debug += "off"
        }
        html_debug += "</td></tr>\n"

        html_debug += "<tr><td>tasklist extension</td><td>"
        if self.taskListExtension {
            html_debug += "on " + (cmark_find_syntax_extension("tasklist") == nil ? " (NOT AVAILABLE" : "")
        } else {
            html_debug += "off"
        }
        html_debug += "</td></tr>\n"
        
        html_debug += "<tr><td>YAML extension</td><td>"
        if self.yamlExtension {
            html_debug += "on "+(self.yamlExtensionAll ? "for all files" : "only for .rmd and .qmd files")
        } else {
            html_debug += "off"
        }
        html_debug += "</td></tr>\n"
        
        html_debug += "<tr><td>link</td><td>" + (self.openInlineLink ? "open inline" : "open in standard browser") + "</td></tr>\n"
        
        html_debug += "</table>\n"
        
        return html_debug
    }
    
    func renderCode(text: String, forAppearance appearance: Appearance, baseDir: String) -> String? {
        if let path = getHighlightSupportPath() {
            cmark_syntax_highlight_init("\(path)/".cString(using: .utf8))
        } else {
            os_log("Unable to found the `highlight` support dir!", log: OSLog.rendering, type: .error)
        }
        
        let theme = Self.isLightAppearance ? "acid" : "zenburn"
        
        // Initialize a new generator and clear previous settings.
        highlight_init_generator()
        
        highlight_set_print_line_numbers(self.syntaxLineNumbersOption ? 1 : 0)
        highlight_set_formatting_mode(Int32(self.syntaxWordWrapOption), Int32(self.syntaxTabsOption))
        
        if !self.syntaxFontFamily.isEmpty {
            highlight_set_current_font(self.syntaxFontFamily, self.syntaxFontSize > 0 ? String(format: "%.02f", self.syntaxFontSize) : "1rem") // 1rem is rendered as 1rempt, so it is ignored.
        } else {
            highlight_set_current_font("ui-monospace, -apple-system, BlinkMacSystemFont, sans-serif", "10");
        }
        
        if let s = colorizeCode(text, "md", theme, true, self.syntaxLineNumbersOption) {
            defer {
                s.deallocate()
            }
            let code = String(cString: s)
            return code
        } else {
            return nil
        }
    }
    
    func render(file url: URL, forAppearance appearance: Appearance, baseDir: String?) throws -> String {
        guard let data = FileManager.default.contents(atPath: url.path) else {
            os_log("Unable to read the file %{private}@", log: OSLog.rendering, type: .error, url.path)
            return ""
        }
        
        return try self.render(data: data, forAppearance: appearance, filename: url.lastPathComponent, baseDir: baseDir ?? url.deletingLastPathComponent().path)
    }
    
    func render(data: Data, forAppearance appearance: Appearance, filename: String = "file.md", baseDir: String) throws -> String {
        guard let markdown_string = String(data: data, encoding: .utf8) else {
            os_log("Unable to read the data %{private}@", log: OSLog.rendering, type: .error, data.base64EncodedString())
            return ""
        }
        
        return try self.render(text: markdown_string, filename: filename, forAppearance: appearance, baseDir: baseDir)
    }
    
    func getCompleteHTML(title: String, body: String, header: String = "", footer: String = "", basedir: URL, forAppearance appearance: Appearance) -> String {
        
        let css_doc: String
        let css_doc_extended: String
        
        var s_header = header
        var s_footer = footer
        
        let formatCSS = { (code: String?) -> String in
            guard let css = code, !css.isEmpty else {
                return ""
            }
            return "<style type='text/css'>\(css)\n</style>\n"
        }
        
        if !self.renderAsCode {
            if let css = self.getCustomCSSCode() {
                css_doc_extended = formatCSS(css)
                if !self.customCSSOverride {
                    css_doc = formatCSS(getBundleContents(forResource: "default", ofType: "css"))
                } else {
                    css_doc = ""
                }
            } else {
                css_doc_extended = ""
                css_doc = formatCSS(getBundleContents(forResource: "default", ofType: "css"))
            }
            // css_doc = "<style type=\"text/css\">\n\(css_doc)\n</style>\n"
        } else {
            css_doc_extended = ""
            css_doc = ""
        }
            
        var css_highlight: String = ""
        if self.renderAsCode {
            var exit_code: Int32 = 0
            
            exit_code = 0
            let p = highlight_format_style2(&exit_code, nil)
            defer {
                p?.deallocate()
            }
            css_highlight += "pre.hl { white-space: pre; }\n"
            if exit_code == EXIT_SUCCESS, let p = p {
                css_highlight = String(cString: p) + "\n"
            }
        } else if self.syntaxHighlightExtension, let ext = cmark_find_syntax_extension("syntaxhighlight"), cmark_syntax_extension_highlight_get_rendered_count(ext) > 0 {
            let theme = ""
            if !theme.isEmpty, let p = cmark_syntax_extension_get_style(ext) {
                // Embed the theme style.
                css_highlight = String(cString: p)
                p.deallocate()
            } else {
                if let s = cmark_syntax_extension_highlight_get_background_color(ext) {
                    let background_color = String(cString: s)
                    if background_color != "ignore" && !background_color.isEmpty {
                        css_highlight += "body.hl, pre.hl { background-color: \(background_color); }\n"
                    }
                }
            }
            if let s = cmark_syntax_extension_highlight_get_font_family(ext) {
                let font_name = String(cString: s)
                if !font_name.isEmpty && font_name != "-" {
                    let font = "\"\(font_name)\", ui-monospace, -apple-system, Menlo, monospace"
                    css_highlight += "body.hl, pre.hl, pre.hl code { font-family: \(font); }\n"
                }
            }
            let size = cmark_syntax_extension_highlight_get_font_size(ext)
            if size > 0 {
                css_highlight += "body.hl, pre.hl, pre.hl code { font-size: \(size)pt; }\n"
            }
        }
        css_highlight = formatCSS(css_highlight)
        
        if !self.renderAsCode, self.mathExtension, let ext = cmark_find_syntax_extension("math"), cmark_syntax_extension_math_get_rendered_count(ext) > 0 || body.contains("$") {
            s_header += """
<script type="text/javascript">
MathJax = {
  options: {
    enableMenu: \(self.debug ? "true" : "false"),
  },
  tex: {
    // packages: ['base'],        // extensions to use
    inlineMath: [              // start/end delimiter pairs for in-line math
      ['$', '$']
      // , ['\\(', '\\)']
    ],
    displayMath: [             // start/end delimiter pairs for display math
      ['$$', '$$']
      //, ['\\[', '\\]']
    ],
    processEscapes: true,       // use \\$ to produce a literal dollar sign
    processEnvironments: false
  }
};
</script>
"""
            s_footer += """
<script type="text/javascript" id="MathJax-script" async
  src="https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-mml-chtml.js">
</script>
"""
        }
        
        let style = css_doc + css_highlight + css_doc_extended
        let wrapper_open = self.renderAsCode ? "<pre class='hl'>" : "<article class='markdown-body'>"
        let wrapper_close = self.renderAsCode ? "</pre>" : "</article>"
        let body_style = self.renderAsCode ? " class='hl'" : ""
        let html =
"""
<!doctype html>
<html>
<head>
<meta charset='utf-8'>
<meta name='viewport' content='width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=0'>
<title>\(title)</title>
\(style)
\(s_header)
</head>
<body\(body_style)>
\(wrapper_open)
\(body)
\(wrapper_close)
\(s_footer)
</body>
</html>
"""
        return html
    }
}
