import SwiftUI
import UIKit

enum Theme {
    /// Warm paper behind everything.
    static let paper = Color(uiColor: UIColor { $0.userInterfaceStyle == .dark ? UIColor(red: 0.075, green: 0.07, blue: 0.065, alpha: 1) : UIColor(red: 0.975, green: 0.96, blue: 0.935, alpha: 1) })
    /// Quieter text that still reads at 4.5:1 or better on paper, darker again with Increase Contrast.
    static let secondary = Color(uiColor: UIColor { traits in
        let high = traits.accessibilityContrast == .high
        if traits.userInterfaceStyle == .dark {
            return high ? UIColor(red: 0.80, green: 0.78, blue: 0.75, alpha: 1) : UIColor(red: 0.67, green: 0.65, blue: 0.62, alpha: 1)
        }
        return high ? UIColor(red: 0.25, green: 0.23, blue: 0.21, alpha: 1) : UIColor(red: 0.37, green: 0.35, blue: 0.32, alpha: 1)
    })
    /// Text on top of the ink-colored accent.
    static let onAccent = Color(uiColor: UIColor { $0.userInterfaceStyle == .dark ? UIColor(red: 0.075, green: 0.07, blue: 0.065, alpha: 1) : UIColor(red: 0.975, green: 0.96, blue: 0.935, alpha: 1) })

    /// Serif for names and numerals; chrome stays in the system face.
    static func display(_ size: CGFloat, weight: Font.Weight = .medium) -> Font {
        // Follows the reader's text size. Big numerals grow less, so a counter never outgrows its screen.
        let limit: CGFloat = size >= 40 ? 1.25 : 1.8
        let scaled = min(UIFontMetrics.default.scaledValue(for: size), size * limit)
        return .system(size: scaled, weight: weight, design: .serif)
    }

    /// Serif navigation titles everywhere.
    @MainActor
    static func applyNavigationAppearance() {
        func serif(_ size: CGFloat, _ weight: UIFont.Weight) -> UIFont {
            let base = UIFont.systemFont(ofSize: size, weight: weight)
            return base.fontDescriptor.withDesign(.serif).map { UIFont(descriptor: $0, size: size) } ?? base
        }
        let bar = UINavigationBar.appearance()
        bar.largeTitleTextAttributes = [.font: serif(34, .semibold)]
        bar.titleTextAttributes = [.font: serif(18, .semibold)]
    }
}

/// The yarn a project is drawn in.
enum YarnColor: String, CaseIterable, Identifiable, Sendable {
    case madder, marigold, moss, spruce, indigo, plum, oat, charcoal

    var id: String { rawValue }

    var label: String { Loc.text(rawValue.capitalized) }

    private var rgb: (Double, Double, Double) {
        switch self {
        case .madder: (0.64, 0.23, 0.24)
        case .marigold: (0.86, 0.61, 0.20)
        case .moss: (0.44, 0.51, 0.30)
        case .spruce: (0.17, 0.40, 0.38)
        case .indigo: (0.23, 0.30, 0.56)
        case .plum: (0.45, 0.26, 0.46)
        case .oat: (0.79, 0.70, 0.57)
        case .charcoal: (0.30, 0.30, 0.32)
        }
    }

    var tint: Tint { Tint(red: rgb.0, green: rgb.1, blue: rgb.2) }

    var color: Color { tint.color }
    /// The leg of each stitch that sits away from the light.
    var lowlight: Color { tint.lowlight }
    /// The gap between stitches.
    var shade: Color { tint.shade }

    var uiColor: UIColor { UIColor(red: rgb.0, green: rgb.1, blue: rgb.2, alpha: 1) }
}

extension View {
    /// `.animation(_:value:)` that stands still when the reader has Reduce Motion on.
    func motion<V: Equatable>(_ animation: Animation, value: V) -> some View {
        modifier(Motion(animation: animation, value: value))
    }
}

private struct Motion<V: Equatable>: ViewModifier {
    let animation: Animation
    let value: V
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content.animation(reduceMotion ? nil : animation, value: value)
    }
}

/// A yarn's color with the darker tones a stitch is drawn in.
struct Tint: Sendable {
    var red: Double
    var green: Double
    var blue: Double

    private func scaled(_ factor: Double) -> Color { Color(red: red * factor, green: green * factor, blue: blue * factor) }

    var color: Color { scaled(1) }
    var lowlight: Color { scaled(0.9) }
    var shade: Color { scaled(0.55) }
}

extension Shade {
    var tint: Tint { rgb.map { Tint(red: $0.red, green: $0.green, blue: $0.blue) } ?? YarnColor.oat.tint }
}

extension YarnColor {
    /// The library color closest to a colorwork yarn, for the places a project shows one color.
    static func nearest(to shade: Shade?) -> YarnColor {
        guard let rgb = shade?.rgb else { return .oat }
        return allCases.min { a, b in
            func distance(_ c: YarnColor) -> Double { pow(c.rgb.0 - rgb.red, 2) + pow(c.rgb.1 - rgb.green, 2) + pow(c.rgb.2 - rgb.blue, 2) }
            return distance(a) < distance(b)
        } ?? .oat
    }
}
