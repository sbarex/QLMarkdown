//
//  Theme.swift
//  QLMardown
//
//  Created by Sbarex on 14/12/20.
//

import Cocoa


class Theme: Equatable {
    enum PropertyName: String {
        case background = "Background"
                    
        case lineNumbers = "LineNumbers"
        case lineNumbersTable = "LineNumbersTable"
        case lineHighlight = "LineHighlight"
        case lineTable = "LineTable"
        case lineTableTD = "LineTableTD"
        case error = "Error"
        case other = "Other"
        case none = "None"
        case EOFType = "EOFType"
        
        // Keywords.
        case keyword = "Keyword"
        case keywordConstant = "KeywordConstant"
        case keywordDeclaration = "KeywordDeclaration"
        case keywordNamespace = "KeywordNamespace"
        case keywordPseudo = "KeywordPseudo"
        case keywordReserved = "KeywordReserved"
        case keywordType = "KeywordType"
        
        // Names.
        case name = "Name"
        case nameAttribute = "NameAttribute"
        case nameBuiltin = "NameBuiltin"
        case nameBuiltinPseudo = "NameBuiltinPseudo"
        case nameClass = "NameClass"
        case nameConstant = "NameConstant"
        case nameDecorator = "NameDecorator"
        case nameEntity = "NameEntity"
        case nameException = "NameException"
        case nameFunction = "NameFunction"
        case nameFunctionMagic = "NameFunctionMagic"
        case nameKeyword = "NameKeyword"
        case nameLabel = "NameLabel"
        case nameNamespace = "NameNamespace"
        case nameOperator = "NameOperator"
        case nameOther = "NameOther"
        case namePseudo = "NamePseudo"
        case nameProperty = "NameProperty"
        case nameTag = "NameTag"
        case nameVariable = "NameVariable"
        case nameVariableAnonymous = "NameVariableAnonymous"
        case nameVariableClass = "NameVariableClass"
        case nameVariableGlobal = "NameVariableGlobal"
        case nameVariableInstance = "NameVariableInstance"
        case nameVariableMagic = "NameVariableMagic"
        
        // Literals.
        case literal = "Literal"
        case literalDate = "LiteralDate"
        case literalOther = "LiteralOther"
        
        // Strings.
        case literalString = "LiteralString"
        case literalStringAffix = "LiteralStringAffix"
        case literalStringAtom = "LiteralStringAtom"
        case literalStringBacktick = "LiteralStringBacktick"
        case literalStringBoolean = "LiteralStringBoolean"
        case literalStringChar = "LiteralStringChar"
        case literalStringDelimiter = "LiteralStringDelimiter"
        case literalStringDoc = "LiteralStringDoc"
        case literalStringDouble = "LiteralStringDouble"
        case literalStringEscape = "LiteralStringEscape"
        case literalStringHeredoc = "LiteralStringHeredoc"
        case literalStringInterpol = "LiteralStringInterpol"
        case literalStringName = "LiteralStringName"
        case literalStringOther = "LiteralStringOther"
        case literalStringRegex = "LiteralStringRegex"
        case literalStringSingle = "LiteralStringSingle"
        case literalStringSymbol = "LiteralStringSymbol"
        
        // Numbers.
        case literalNumber = "LiteralNumber"
        case literalNumberBin = "LiteralNumberBin"
        case literalNumberFloat = "LiteralNumberFloat"
        case literalNumberHex = "LiteralNumberHex"
        case literalNumberInteger = "LiteralNumberInteger"
        case literalNumberIntegerLong = "LiteralNumberIntegerLong"
        case literalNumberOct = "LiteralNumberOct"
        
        // Operators.
        case `operator` = "Operator"
        case operatorWord = "OperatorWord"
        
        // Punctuation.
        case punctuation = "Punctuation"
        
        // Comments.
        case comment = "Comment"
        case commentHashbang = "CommentHashbang"
        case commentMultiline = "CommentMultiline"
        case commentSingle = "CommentSingle"
        case commentSpecial = "CommentSpecial"
        
        // Preprocessor "comments".
        case commentPreproc = "CommentPreproc"
        case commentPreprocFile = "CommentPreprocFile"
        
        // Generic tokens.
        case generic = "Generic"
        case genericDeleted = "GenericDeleted"
        case genericEmph = "GenericEmph"
        case genericError = "GenericError"
        case genericHeading = "GenericHeading"
        case genericInserted = "GenericInserted"
        case genericOutput = "GenericOutput"
        case genericPrompt = "GenericPrompt"
        case genericStrong = "GenericStrong"
        case genericSubheading = "GenericSubheading"
        case genericTraceback = "GenericTraceback"
        case genericUnderline = "GenericUnderline"
        
        // Text.
        case text = "Text"
        case textWhitespace = "TextWhitespace"
        case textSymbol = "TextSymbol"
        case textPunctuation = "TextPunctuation"
        
        var name: String {
            switch self {
            case .EOFType:
                return "EOF"
            
            default:
                return self.rawValue.decamelizing(separator: " ").capitalizingFirstLetter()
            }
        }
        
        /// CSS class used to render the token.
        var cssClass: String {
            switch self {
            case .background: return "chroma"
                        
            case .lineNumbers: return "ln"
            case .lineNumbersTable: return "lnt"
            case .lineHighlight: return "hl"
            case .lineTable: return "lntable"
            case .lineTableTD: return "lntd"
                
            case .error: return "err"
            case .other: return "x"
            case .none: return ""
            case .EOFType: return ""
            
            // Keywords.
            case .keyword: return "k"
            case .keywordConstant: return "kc"
            case .keywordDeclaration: return "kd"
            case .keywordNamespace: return "kn"
            case .keywordPseudo: return "kp"
            case .keywordReserved: return "kr"
            case .keywordType: return "kt"
            
            // Names.
            case .name: return "n"
            case .nameAttribute: return "na"
            case .nameBuiltin: return "nb"
            case .nameBuiltinPseudo: return "bp"
            case .nameClass: return "nc"
            case .nameConstant: return "no"
            case .nameDecorator: return "nd"
            case .nameEntity: return "ni"
            case .nameException: return "ne"
            case .nameFunction: return "nf"
            case .nameFunctionMagic: return "fm"
                case .nameKeyword: return "n" // fixme
            case .nameLabel: return "nl"
            case .nameNamespace: return "nn"
                case .nameOperator: return "o" // fixme
            case .nameOther: return "nx"
                case .namePseudo: return "bp" // fixme
            case .nameProperty: return "py"
            case .nameTag: return "nt"
            case .nameVariable: return "nv"
                case .nameVariableAnonymous: return "nv" // fixme
            case .nameVariableClass: return "vc"
            case .nameVariableGlobal: return "vg"
            case .nameVariableInstance: return "vi"
            case .nameVariableMagic: return "vm"
            
            // Literals.
            case .literal: return "l"
            case .literalDate: return "ld"
                case .literalOther: return "l" // fixme
            
            // Strings.
            case .literalString: return "s"
            case .literalStringAffix: return "sa"
                case .literalStringAtom: return "s" // fixme
            case .literalStringBacktick: return "sb"
                case .literalStringBoolean: return "s" // fixme
            case .literalStringChar: return "sc"
            case .literalStringDelimiter: return "dl"
            case .literalStringDoc: return "sd"
            case .literalStringDouble: return "s2"
            case .literalStringEscape: return "se"
            case .literalStringHeredoc: return "sh"
            case .literalStringInterpol: return "si"
                case .literalStringName: return "s" // fixme
            case .literalStringOther: return "sx"
            case .literalStringRegex: return "sr"
            case .literalStringSingle: return "s1"
            case .literalStringSymbol: return "ss"
            
            // Numbers.
            case .literalNumber: return "m"
            case .literalNumberBin: return "mb"
            case .literalNumberFloat: return "mf"
            case .literalNumberHex: return "mh"
            case .literalNumberInteger: return "mi"
            case .literalNumberIntegerLong: return "il"
            case .literalNumberOct: return "mo"
            
            // Operators.
            case .`operator`: return "o"
            case .operatorWord: return "ow"
            
            // Punctuation.
            case .punctuation: return "p"
            
            // Comments.
            case .comment: return "c"
            case .commentHashbang: return "ch"
            case .commentMultiline: return "cm"
            case .commentSingle: return "c1"
            case .commentSpecial: return "cs"
            
            // Preprocessor "comments".
            case .commentPreproc: return "cp"
            case .commentPreprocFile: return "cpf"
            
            // Generic tokens.
            case .generic: return "g"
            case .genericDeleted: return "gd"
            case .genericEmph: return "ge"
            case .genericError: return "gr"
            case .genericHeading: return "gh"
            case .genericInserted: return "gi"
            case .genericOutput: return "go"
            case .genericPrompt: return "gp"
            case .genericStrong: return "gs"
            case .genericSubheading: return "gu"
            case .genericTraceback: return "gt"
            case .genericUnderline: return "gl"
            
            // Text.
            case .text: return ""
            case .textWhitespace: return "w"
                case .textSymbol: return "" // fixme
                case .textPunctuation: return "" // fixme
            }
        }
    }
    
    class PropertyStyle {
        enum Name: String {
            case italic = "italic"
            case bold = "bold"
            case underline = "underline"
            
            case foreground = "foreground"
            case background = "background"
            case border = "border"
        }
        
        var italic: Bool?
        var bold: Bool?
        var underline: Bool?
        var foreground: String?
        var background: String?
        var border: String?
        
        init(style: String) {
            var italic: Bool?
            var bold: Bool?
            var underline: Bool?
            var border: String?
            var foreground: String?
            var background: String?
            let tokens = style.split(separator: " ")
            
            for token in tokens {
                if token == "italic" {
                    italic = true;
                } else if token == "noitalic" {
                    italic = false;
                } else if token == "bold" {
                    bold = true;
                } else if token == "nobold" {
                    bold = false;
                } else if token == "underline" {
                    underline = true;
                } else if token == "nounderline" {
                    underline = false;
                } else if token.hasPrefix("bg:#") {
                    background = String(token[token.index(token.startIndex, offsetBy: 3) ..< token.endIndex])
                } else if token.hasPrefix("#") {
                    foreground = String(token)
                } else if token.hasPrefix("border:#") {
                    border = String(token[token.index(token.startIndex, offsetBy: 7) ..< token.endIndex])
                } else {
                    print("Unknown token \(token)!")
                }
            }
            self.italic = italic
            self.bold = bold
            self.underline = underline
            self.foreground = foreground
            self.background = background
            self.border = border
        }
        
        func getCSSStyle() -> String {
            var style = ""
            if let italic = self.italic {
                style += "font-style: \(italic ? "italic" : "normal"); "
            }
            if let bold = self.bold {
                style += "font-weight: \(bold ? "bold" : "normal"); "
            }
            if let underline = self.underline {
                style += "text-decoration: \(underline ? "underline" : "none"); "
            }
            if let background = self.background {
                style += "background-color: \(background); "
            }
            if let foreground = self.foreground {
                style += "color: \(foreground); "
            }
            if let border = self.border {
                style += "border: 1px solid \(border); "
            }
            
            return style
        }
        
        subscript(name: Name)->AnyHashable? {
            get {
                switch name {
                case .bold:
                    return bold
                case .italic:
                    return italic
                case .underline:
                    return underline
                case .foreground:
                    return foreground;
                case .background:
                    return background
                case .border:
                    return border
                }
            }
            set {
                switch name {
                case .bold:
                    if newValue == nil {
                        bold = nil
                    } else if let v = newValue as? Bool {
                        bold = v
                    }
                case .italic:
                    if newValue == nil {
                        italic = nil
                    } else if let v = newValue as? Bool {
                        italic = v
                    }
                case .underline:
                    if newValue == nil {
                        underline = nil
                    } else if let v = newValue as? Bool {
                        underline = v
                    }
                case .foreground:
                    if newValue == nil {
                        foreground = nil
                    } else if let v = newValue as? String {
                        foreground = v
                    }
                case .background:
                    if newValue == nil {
                        background = nil
                    } else if let v = newValue as? String {
                        background = v
                    }
                case .border:
                    if newValue == nil {
                        border = nil
                    } else if let v = newValue as? String {
                        border = v
                    }
                }
            }
        }
        
        func export() -> String {
            var export = ""
            if let italic = self.italic {
                export += italic ? "italic " : "noitalic "
            }
            if let bold = self.bold {
                export += bold ? "bold " : "nobold "
            }
            if let underline = self.underline {
                export += underline ? "underline " : "nounderline "
            }
            if let foreground = self.foreground {
                export += "\(foreground) "
            }
            if let background = self.background {
                export += "bg:\(background) "
            }
            if let border = self.border {
                export += "border:\(border) "
            }
            if export.count > 0 {
                export.removeLast()
            }
            return export
        }
        
        func getFormattedString(_ text: String, font: NSFont, defaultBackground background: NSColor, foreground: NSColor) -> NSAttributedString {
            var attributes: [NSAttributedString.Key: Any] = [:]
            if let c = self.background, let cc = NSColor(css: c) {
                attributes[.backgroundColor] = cc
            } else {
                attributes[.backgroundColor] = background
            }
            if let c = self.foreground, let cc = NSColor(css: c) {
                attributes[.foregroundColor] = cc
            } else {
                attributes[.foregroundColor] = foreground
            }
            if let underline = self.underline {
                attributes[.underlineStyle] = underline ? NSUnderlineStyle.single : 0
                attributes[.underlineColor] = attributes[.foregroundColor]
            }
            var fontTraits: NSFontTraitMask = []
            if let bold = self.bold {
                fontTraits.insert(bold ? .boldFontMask : .unboldFontMask)
            }
            if let italic = self.italic {
                fontTraits.insert(italic ? .italicFontMask : .unitalicFontMask)
            }
            if !fontTraits.isEmpty, let f = NSFontManager.shared.font(withFamily: font.familyName ?? font.fontName, traits: fontTraits, weight: 0, size: font.pointSize) {
                attributes[.font] = f
            } else {
                attributes[.font] = font
            }
            return NSAttributedString(string: text, attributes: attributes)
        }
    }
    
    public static func == (lhs: Theme, rhs: Theme) -> Bool {
        return lhs.name == rhs.name
    }
    
    var name: String
    var styles: [PropertyName: PropertyStyle] = [:]
    
    var isStandalone: Bool {
        return !name.hasPrefix("*")
    }
    
    var isDirty: Bool = false
    
    fileprivate(set) var image: NSImage?
    
    convenience init (name: String, styles: [String: String]) {
        var s: [PropertyName: PropertyStyle] = [:]
        for (key, value) in styles {
            if let p = PropertyName(rawValue: key) {
                s[p] = PropertyStyle(style: value)
            }
        }
        self.init(name: name, styles: s)
    }
    
    init(name: String, styles: [PropertyName: PropertyStyle] = [:]) {
        self.name = name
        self.styles = styles
    }
    
    func getHtmlExample() -> String {
        var css = ""
        if let backgroundStyle = self.styles[.background], let background = backgroundStyle.background {
            css += "body { background-color: \(background); }"
        }
        if let backgroundStyle = self.styles[.background], let color = backgroundStyle.foreground {
            css += "body { color: \(color); }"
        }
        var s = """
<html>
<head>
        <title>\(self.name)</title>
<style type="text/css">
\(css)
</style>
</style>
</head>
<body>
    <pre><table style="width: 100%">
"""
        for (key, style) in self.styles  {
            s += """
        <tr>
            <td style="\(style.getCSSStyle())" id="\(key.rawValue)">\(key.name)</td>
        </tr>
"""
        }
        
        s += """
    </table></pre>
</body>
</html>
"""
        return s
    }
    
    /*
    /// Get a html code for preview the theme settings.
    public func getHtmlExample(fontName: String = "Menlo", fontSize: CGFloat = 12, smartCaption: Bool = false, showColorCodes: Bool = true, extraCSS css: String = "") -> String {
        var cssFont = ""
        if fontName != "" {
            cssFont = "    font-family: \(fontName);\n    font-size: \(fontSize)pt;\n"
        }
        
        let exportProperty = { (name: Property.Name, property: SCSHThemePropertyProtocol)->String in
            return "." + name.getCSSClasses().joined(separator: ".") + " {\n" + property.toCSSStyle() + cssFont + " } \n"
        }
        var style = ""
        
        for name in Property.Name.allCases {
            guard !name.isKeyword else {
                break
            }
            guard let prop = self[name] else {
                continue
            }
            
            style += exportProperty(name, prop)
        }
        
        for (i, keyword) in keywords.enumerated() {
            if let name = Property.Name.keywordAtIndex(i) {
                style += exportProperty(name, keyword)
            }
        }
        
        let textColor = plain.toCSSStyle()
        var s = """
<html>
<head>
        <title>\(self.name).theme :: \(self.desc)</title>
<style>
* {
    box-sizing: border-box;
}
html, body {
    background-color: \(self.canvas.color);
\(cssFont)
    user-select: none;
    -webkit-user-select: none;
    margin: 0;
    height: 100%;
}
body {
    padding: 1em;
}
.color_code {
\(cssFont)
\(textColor)
    display: \(showColorCodes ? "initial" : "none");
    text-align: right;
}
table {
    width: 100%;
    border-collapse: collapse;
}
td {
    padding: 2px;
    background-color: \(self.canvas.color);
}
        
\(style)
        
\(css)
</style>
</head>
<body class="hl">
    <pre class="hl"><table>
"""
        for name in Property.Name.allCases  {
            if name == .canvas {
                continue
            }
            guard let prop = self[name] else {
                break
            }
            s += """
        <tr>
            <td class="\(name.getCSSClasses().joined(separator: " "))">\(smartCaption ? name.rawValue : name.description)</td>
            <td class="color_code">\(prop.color)</td>
        </tr>
"""
        }
        
        s += """
    </table></pre>
</body>
</html>
"""
        return s
    }
    */
    
    /// Get a NSAttributedString for preview the theme settings in the icon.
    /// This code don't call internally the getHtmlExample and is more (about 6x)  fast!
    internal func getAttributedExampleForIcon(font: NSFont) -> NSAttributedString {
        let background: NSColor
        if let c = self.styles[.background]?.background, let cc = NSColor(css: c) {
            background = cc
        } else {
            background = NSColor.clear
        }
        
        let s = NSMutableAttributedString()
        for (key, style) in self.styles {
            var attributes: [NSAttributedString.Key: Any] = [:]
            if let c = style.background, let cc = NSColor(css: c) {
                attributes[.backgroundColor] = cc
            } else {
                attributes[.backgroundColor] = background
            }
            if let c = style.foreground, let cc = NSColor(css: c) {
                attributes[.foregroundColor] = cc
            } else {
                attributes[.foregroundColor] = NSColor.clear
            }
            /*
            if let underline = style.underline {
                attributes[.underlineStyle] = underline ? NSUnderlineStyle.single : 0
                if let c = style.foreground, let cc = NSColor(css: c) {
                    attributes[.underlineColor] = cc
                } else {
                    attributes[.underlineColor] = NSColor.black
                }
            }
            */
            var fontTraits: NSFontTraitMask = []
            if let bold = style.bold {
                fontTraits.insert(bold ? .boldFontMask : .unboldFontMask)
            }
            if let italic = style.italic {
                fontTraits.insert(italic ? .italicFontMask : .unitalicFontMask)
            }
            if !fontTraits.isEmpty, let f = NSFontManager.shared.font(withFamily: font.familyName ?? font.fontName, traits: fontTraits, weight: 0, size: font.pointSize) {
                attributes[.font] = f
            } else {
                attributes[.font] = font
            }
            s.append(NSAttributedString(string: key.rawValue + "\n", attributes: attributes))
        }
        
        return s
    }
    
    
    func generateImage(forSize size: CGSize, font: NSFont) {
        self.image = nil
        
        let format = getAttributedExampleForIcon(font: font)
        
        let rect = CGRect(origin: .zero, size: size)
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        if let context = CGContext(
            data: nil,
            width: Int(rect.width),
            height: Int(rect.height),
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: bitmapInfo.rawValue) {
            
            if let c = self.styles[.background]?.background, let cc = NSColor(css: c) {
                context.setFillColor(cc.cgColor)
                context.fill(rect)
            }
            
            let c = NSGraphicsContext.current
            let graphicsContext = NSGraphicsContext(cgContext: context, flipped: false)
            NSGraphicsContext.current = graphicsContext
            
            format.draw(in: rect.insetBy(dx: 6, dy: 6))
            
            // Restore the context.
            NSGraphicsContext.current = c
            
            if !isStandalone {
                // Fill a corner to notify that this is a custom theme.
                context.setLineWidth(0)
                context.setFillColor(NSColor.controlAccentColor.cgColor)
                context.move(to: CGPoint(x: rect.maxX, y: rect.minY))
                context.addLine(to: CGPoint(x: rect.maxX-20, y: rect.minY))
                context.addLine(to: CGPoint(x: rect.maxX, y: rect.minY+20))
                context.fillPath()
            }
            
            if let image = context.makeImage() {
                self.image = NSImage(cgImage: image, size: CGSize(width: context.width, height: context.height))
            }
        }
    }
}
