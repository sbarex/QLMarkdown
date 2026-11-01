// Test-only renderer substitute; production uses QLMarkdown/Settings*.swift.
import Cocoa
import OSLog
class Settings {
    static let shared = Settings()
    static var renderStats = 0
    var qlWindowSize = CGSize(width: 960, height: 1000)
    func startMonitorChange() {}
    static func getMarkdownFile(from url: URL) -> URL { url }
    func render(file url: URL, baseDir: String?) throws -> String { try String(contentsOf: url, encoding: .utf8) }
    func getCompleteHTML(title: String, body: String) -> String { body }
    static func isExternalSchemeAllowed(_ url: URL) -> Bool { ["https", "http", "mailto"].contains(url.scheme ?? "") }
}
extension OSLog { static let quickLookExtension = OSLog.default }
