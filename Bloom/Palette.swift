import SwiftUI
#if os(macOS)
import AppKit
#else
import UIKit
#endif

/// A palette seed: a user-chosen color from which we derive a harmonious
/// set of colors (varying hue/saturation/brightness) for petals, leaves, etc.
///
/// Stored as RGB for JSON-friendly persistence. The derived palette is
/// computed on the fly from the seed via HSB rotation.
struct Palette: Equatable, Codable {
    var red: Double
    var green: Double
    var blue: Double
    var name: String?

    init(color: Color, name: String? = nil) {
        let c = Self.rgb(from: color)
        self.red = c.r
        self.green = c.g
        self.blue = c.b
        self.name = name
    }

    init(red: Double, green: Double, blue: Double, name: String? = nil) {
        self.red = red; self.green = green; self.blue = blue; self.name = name
    }

    /// The seed color itself.
    var seed: Color { Color(red: red, green: green, blue: blue) }

    /// Core color (used by orbs) — brighter, whiter than seed.
    var core: Color {
        let hsb = Self.hsb(from: seed)
        return Color(hue: hsb.h,
                     saturation: max(0.0, hsb.s - 0.5),
                     brightness: min(1.0, hsb.b + 0.35))
    }

    /// 6 harmonious variants around the seed, for petal/leaf colors.
    var petals: [Color] {
        let hsb = Self.hsb(from: seed)
        return (0..<6).map { i in
            let t = Double(i) / 6.0
            let hueShift = (t - 0.5) * 0.22              // ±40° hue
            let satShift = sin(t * .pi) * 0.08
            let brShift  = cos(t * .pi * 2) * 0.08
            var h = hsb.h + hueShift
            h -= floor(h)                                 // wrap 0..1
            return Color(
                hue: h,
                saturation: max(0.25, min(1, hsb.s + satShift)),
                brightness: max(0.55, min(1, hsb.b + brShift))
            )
        }
    }

    // MARK: - Presets

    static let periwinkle = Palette(red: 0.60, green: 0.55, blue: 1.00, name: "Periwinkle")
    static let rose       = Palette(red: 0.95, green: 0.55, blue: 0.70, name: "Rose")
    static let emerald    = Palette(red: 0.45, green: 0.85, blue: 0.70, name: "Emerald")
    static let sunset     = Palette(red: 1.00, green: 0.65, blue: 0.40, name: "Sunset")
    static let amethyst   = Palette(red: 0.70, green: 0.45, blue: 1.00, name: "Amethyst")
    static let ocean      = Palette(red: 0.30, green: 0.70, blue: 0.95, name: "Ocean")

    static let presets: [Palette] = [.periwinkle, .rose, .emerald, .sunset, .amethyst, .ocean]
    static let `default` = Palette.periwinkle

    // MARK: - Cross-platform color → RGB/HSB extraction

    private static func rgb(from color: Color) -> (r: Double, g: Double, b: Double) {
        #if os(macOS)
        let ns = NSColor(color).usingColorSpace(.deviceRGB) ?? NSColor.clear
        return (Double(ns.redComponent), Double(ns.greenComponent), Double(ns.blueComponent))
        #else
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(color).getRed(&r, green: &g, blue: &b, alpha: &a)
        return (Double(r), Double(g), Double(b))
        #endif
    }

    private static func hsb(from color: Color) -> (h: Double, s: Double, b: Double) {
        #if os(macOS)
        let ns = NSColor(color).usingColorSpace(.deviceRGB) ?? NSColor.clear
        var h: CGFloat = 0, s: CGFloat = 0, br: CGFloat = 0, a: CGFloat = 0
        ns.getHue(&h, saturation: &s, brightness: &br, alpha: &a)
        return (Double(h), Double(s), Double(br))
        #else
        var h: CGFloat = 0, s: CGFloat = 0, br: CGFloat = 0, a: CGFloat = 0
        UIColor(color).getHue(&h, saturation: &s, brightness: &br, alpha: &a)
        return (Double(h), Double(s), Double(br))
        #endif
    }
}
