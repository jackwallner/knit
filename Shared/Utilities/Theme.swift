import SwiftUI
import UIKit

enum Theme {
    /// Warm paper behind everything.
    static let paper = Color(uiColor: UIColor { $0.userInterfaceStyle == .dark ? UIColor(red: 0.075, green: 0.07, blue: 0.065, alpha: 1) : UIColor(red: 0.975, green: 0.96, blue: 0.935, alpha: 1) })
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

    var label: String { rawValue.capitalized }

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

    private func scaled(_ factor: Double) -> Color {
        Color(red: rgb.0 * factor, green: rgb.1 * factor, blue: rgb.2 * factor)
    }

    var color: Color { scaled(1) }
    /// The leg of each stitch that sits away from the light.
    var lowlight: Color { scaled(0.9) }
    /// The gap between stitches.
    var shade: Color { scaled(0.55) }

    var uiColor: UIColor { UIColor(red: rgb.0, green: rgb.1, blue: rgb.2, alpha: 1) }
}
