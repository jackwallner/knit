import SwiftUI
import UIKit

enum Theme {
    /// Ink on top of the accent color: white on the dark wool red, near-black on the light dark-mode tint.
    static let onAccent = Color(uiColor: UIColor { $0.userInterfaceStyle == .dark ? UIColor(red: 0.16, green: 0.08, blue: 0.09, alpha: 1) : .white })
}

/// The two counter buttons. The plus is filled, the minus is quiet.
struct CounterButtonStyle: ButtonStyle {
    var prominent: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.title.weight(.semibold))
            .foregroundStyle(prominent ? Theme.onAccent : Color.accentColor)
            .frame(maxWidth: prominent ? .infinity : nil)
            .frame(minWidth: 72, minHeight: 72)
            .background(prominent ? AnyShapeStyle(Color.accentColor) : AnyShapeStyle(Color.accentColor.opacity(0.14)), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .opacity(configuration.isPressed ? 0.7 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.snappy(duration: 0.12), value: configuration.isPressed)
    }
}
