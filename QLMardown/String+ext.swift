//
//  String+ext.swift
//  QLMardown
//
//  Created by Sbarex on 15/12/20.
//

import Foundation

fileprivate let badChars = CharacterSet.alphanumerics.inverted

extension String {
    func capitalizingFirstLetter() -> String {
        return self.prefix(1).capitalized + self.dropFirst()
    }

    mutating func capitalizeFirstLetter() {
        self = self.capitalizingFirstLetter()
    }
    
    var uppercasingFirst: String {
        return prefix(1).uppercased() + dropFirst()
    }

    var lowercasingFirst: String {
        return prefix(1).lowercased() + dropFirst()
    }
    
    var camelized: String {
        guard !isEmpty else {
            return ""
        }

        let parts = self.components(separatedBy: badChars)

        let first = String(describing: parts.first!).lowercasingFirst
        let rest = parts.dropFirst().map({String($0).uppercasingFirst})

        return ([first] + rest).joined(separator: "")
    }
    
    /**
     * Convert a camelized string into lowercase.
     * If a separator it is not passed to the function, '_' will be used.
     */
    func decamelizing(separator: String = "_") -> String {
        if self == "" {
            return self
        }

        if separator == "" {
            return self.lowercased()
        }

        // Initialize string range over which the regular expression will run
        let range = NSRange(location: 0, length: self.utf16.count)
        var output = self
        var counter = 0

        // Find initial index for words that are camel case
        // It takes in consideration Unicode characters, too
        let regex = try!
            NSRegularExpression(pattern: "(?=\\p{Lu}\\p{Ll})|(?<=\\p{Ll})(?=\\p{Lu})")

        // Iterate over the words' indexes, injecting the separator
        let indexes = regex.matches(in: self, options: [], range: range)

        for index in indexes {
            let start = output.startIndex
            let offset = index.range.location + counter

            output.insert(contentsOf: separator, at: output.index(start, offsetBy: offset))
            counter += separator.utf16.count
        }

        return output.dropFirst().lowercased()
    }
    
    /// Return a duplicate of the value with a suffix.
    /// - parameters:
    ///   - format: Template to output the duplicated values. Must contain _%s_ placeholder for he value, and a _%d_ for the number of copy.
    ///   - suffixPattern: Pattern used to extract the suffix and number from item in list. Must be contain a capture group named _n_ for extract the number of the copy.
    ///   - list: List of values.
    func duplicate(format: String = "%@ copy %d", suffixPattern: String = #"\s+copy\s+(?<n>\d+)"#, list: [String]) -> String {
        let string: String
        
        let regex1 = try! NSRegularExpression(pattern: #"(?<base>.+)\#(suffixPattern)$"#, options: [.caseInsensitive])
        let nsrange = NSRange(self.startIndex..<self.endIndex, in: self)
        if let match = regex1.firstMatch(in: self, options: [], range: nsrange) {
            let firstCaptureRange = Range(match.range(withName: "base"), in: self)!
            string = String(self[firstCaptureRange])
        } else {
            string = self
        }
        
        var n = 0
        let regex = try! NSRegularExpression(pattern: "^\(string)\(suffixPattern)$", options: [.caseInsensitive])
        list.forEach { (s) in
            let nsrange = NSRange(s.startIndex..<s.endIndex, in: s)
            if let match = regex.firstMatch(in: s, options: [], range: nsrange) {
                let nn: Int
                if let firstCaptureRange = Range(match.range(withName: "n"), in: s), let n1 = Int(s[firstCaptureRange]) {
                    nn = n1
                } else {
                    nn = 1
                }
                n = max(n, nn)
            }
        }
        
        let s = String(format: format, string, n+1)
        return s
    }
    
    func escapingForLua() -> String {
        var s = self.replacingOccurrences(of: "\\", with: "\\\\")
        s = s.replacingOccurrences(of: "\"", with: "\\\"")
        return s
    }
}
