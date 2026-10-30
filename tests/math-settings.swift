// swiftc QLMarkdown/{Settings,Settings+ext,Log,gunzip}.swift tests/math-settings.swift -o /tmp/qlmarkdown-math-settings
import Foundation

@main
struct MathSettingsCheck {
    static func main() throws {
        let fresh = Settings()
        precondition(fresh.mathRenderer == .temml)
        for json in ["{}", "{\"mathRenderer\":\"unknown\"}"] {
            let legacy = try JSONDecoder().decode(Settings.self, from: Data(json.utf8))
            precondition(legacy.mathRenderer == .temml)
        }
        let suite = "org.sbarex.qlmarkdown.math-test." + UUID().uuidString
        let preferences = UserDefaults(suiteName: suite)!
        defer { preferences.removePersistentDomain(forName: suite) }
        for renderer in [MathRenderer.temml, .mathjax] {
            fresh.mathRenderer = renderer
            let decoded = try JSONDecoder().decode(Settings.self, from: JSONEncoder().encode(fresh))
            precondition(decoded.mathRenderer == renderer)
            let copied = Settings()
            copied.update(from: decoded)
            precondition(copied.mathRenderer == renderer)
            let defaults = Settings()
            defaults.update(from: ["mathRenderer": renderer.rawValue])
            precondition(defaults.mathRenderer == renderer)
            precondition(fresh.save(toUserDefaults: preferences))
            let restored = Settings(fromUserDefaults: preferences)
            precondition(restored.mathRenderer == renderer)
        }
        print("PASS default/legacy settings, JSON round trip, settings copy and isolated defaults save/restore")
    }
}
