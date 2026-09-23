//
//  PreviewProvider.swift
//  QLExtension
//
//  Created by Sbarex on 16/12/20.
//

import Cocoa
import Quartz
import OSLog


class PreviewViewController: QLPreviewProvider, QLPreviewingController {
    /// Size suggested to Quick Look. Reduced to fit the screen.
    static var previewContentSize: CGSize {
        let size = Settings.shared.qlWindowSize
        guard let screen = NSScreen.main else {
            return size
        }
        let available = screen.visibleFrame.size
        return CGSize(
            width: min(size.width, available.width * 0.9),
            height: min(size.height, available.height * 0.9)
        )
    }

    /// Provides HTML preview data for Quick Look.
    /// This is the primary entry point on macOS 12+ when QLIsDataBasedPreview is set to true.
    func providePreview(for request: QLFilePreviewRequest) async throws -> QLPreviewReply {
        Settings.shared.startMonitorChange()

        let html = try renderMD(url: request.fileURL)

        let reply = QLPreviewReply(dataOfContentType: .html, contentSize: Self.previewContentSize) { (replyToUpdate: QLPreviewReply) in
            replyToUpdate.stringEncoding = .utf8
            return html.data(using: .utf8)!
        }

        return reply
    }

    func renderMD(url: URL) throws -> String {
        os_log(
            "Generating preview for file %{public}s",
            log: OSLog.quickLookExtension,
            type: .info,
            url.path
        )

        let settings = Settings.shared
        Settings.renderStats += 1

        let markdown_url = Settings.getMarkdownFile(from: url)
        var text = try settings.render(file: markdown_url, baseDir: markdown_url.deletingLastPathComponent().path)
        
        if Settings.renderStats > 0 && Settings.renderStats % 100 == 0 {
            let icon: String
            if let url = Bundle.main.url(forResource: "icon", withExtension: "png"), let data = try? Data(contentsOf: url) {
                icon = data.base64EncodedString()
            } else {
                icon = ""
            }
            
            let stats = String.localizedStringWithFormat(NSLocalizedString("Thanks to this application you have viewed over <b>%d files</b>.", comment: "Quick Look about stats"), Settings.renderStats)
            let donation = NSLocalizedString("If you find it useful and you have the possibility, consider <a href=\"https://buymeacoffee.com/sbarex\"><b>buying me a coffee!</b></a>", comment: "Quick Look about donation link")
            let credit = String.localizedStringWithFormat(NSLocalizedString("Developed by SBAREX with ❤️ | <a href=\"%@\">%@</a>", comment: "Quick Look about developer credit"), "https://github.com/sbarex/QLMarkdown", "https://github.com/sbarex/QLMarkdown")
            
            let msg =
                """
                        <div id="container" style="font-size: 1.5rem">
                            <h1><img src="data:image/png;base64,\(icon)" width="75" height="75" alt="logo" id="logo" /> QLMarkdown</h1>
                            <p>\(stats)</p>
                            <p>\(donation)</p>
                            <br />
                            <hr size="1" />
                            <p class="small">\(credit)</p>
                            </p>
                        </div>
                """

            text += msg
        }

        let html = settings.getCompleteHTML(title: url.lastPathComponent, body: text)

        return html
    }
}
