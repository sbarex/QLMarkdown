//
//  NSColor+ext.swift
//  QLMarkdown
//
//  Created by Sbarex on 12/12/20.
//

import Cocoa

extension NSColor {
    convenience init?(css: String?) {
        guard let css = css, !css.isEmpty else {
            return nil
        }
        var color = css.hasPrefix("#") ? String(css.dropFirst()) : css
        if color.count == 3 {
            let red = String(color.first!) + String(color.first!)
            let green = String(css[css.index(after: css.startIndex)]) + String(css[css.index(after: css.startIndex)])
            let blue = String(css.last!) + String(css.last!)
            color = red + green + blue
        }
        var rgbValue: UInt64 = 0
        Scanner(string: color).scanHexInt64(&rgbValue)
        
        self.init(red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
                          green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
                          blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
                          alpha: CGFloat(1.0))
    }
    
    func css() -> String? {
        guard let color = self.usingColorSpace(NSColorSpace.sRGB) else {
            return nil
        }
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        red = round(red * 255.0)
        green = round(green * 255.0)
        blue = round(blue * 255.0)
        alpha = round(alpha * 255.0)
        var xred = String(Int(red), radix: 16, uppercase: true)
        if xred.count == 1 {
            xred = "0\(xred)"
        }
        var xgreen = String(Int(green), radix: 16, uppercase: true)
        if xgreen.count == 1 {
            xgreen = "0\(xgreen)"
        }
        var xblue = String(Int(blue), radix: 16, uppercase: true)
        if xblue.count == 1 {
            xblue = "0\(xblue)"
        }
        return "#\(xred)\(xgreen)\(xblue)"
    }
    /*
    func components() -> ((alpha: String, red: String, green: String, blue: String, css: String), (alpha: CGFloat, red: CGFloat, green: CGFloat, blue: CGFloat), (alpha: CGFloat, red: CGFloat, green: CGFloat, blue: CGFloat))? {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        if let color = self.usingColorSpace(NSColorSpace.sRGB) {
            color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
            let nsTuple = (alpha: alpha, red: red, green: green, blue: blue)
            red = round(red * 255.0)
            green = round(green * 255.0)
            blue = round(blue * 255.0)
            alpha = round(alpha * 255.0)
            let xalpha = String(Int(alpha), radix: 16, uppercase: true)
            var xred = String(Int(red), radix: 16, uppercase: true)
            if xred.count == 1 {
                xred = "0\(xred)"
            }
            var xgreen = String(Int(green), radix: 16, uppercase: true)
            if xgreen.count == 1 {
                xgreen = "0\(xgreen)"
            }
            var xblue = String(Int(blue), radix: 16, uppercase: true)
            if xblue.count == 1 {
                xblue = "0\(xblue)"
            }
            let css = "#\(xred)\(xgreen)\(xblue)"
            let hexTuple = (alpha: xalpha, red: xred, green: xgreen, blue: xblue, css: css)
            let rgbTuple = (alpha: alpha, red: red, green: green, blue: blue)
            return (hexTuple, rgbTuple, nsTuple)
        }
        return nil
    }
    */
}
