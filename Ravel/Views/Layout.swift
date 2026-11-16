import SwiftUI

/// The widths the iPad layouts turn on. A phone never reaches them, so it keeps its own layout.
enum Layout {
    /// Lists and forms never run wider than this, so a line stays easy to read on an iPad.
    static let readable: CGFloat = 680
    /// A project puts its reading side and its work side next to each other from this width, in a
    /// window wider than it is tall: an iPad held sideways, not a Split View half.
    static let sideBySide: CGFloat = 900
    /// A screen at least this wide and tall is read from further away, propped up beside the work.
    static let farReading: CGFloat = 600
}

extension View {
    /// Keeps scrolling content in a centered column no wider than `width`. The background, the scroll
    /// indicator and the edge the content scrolls under keep the full width.
    func readableWidth(_ width: CGFloat = Layout.readable) -> some View {
        modifier(ReadableWidth(limit: width))
    }
}

private struct ReadableWidth: ViewModifier {
    let limit: CGFloat
    @State private var margin: CGFloat = 0

    func body(content: Content) -> some View {
        let limit = limit
        return content
            .contentMargins(.horizontal, margin, for: .scrollContent)
            .onGeometryChange(for: CGFloat.self) { max(0, (($0.size.width - limit) / 2).rounded(.down)) } action: { margin = $0 }
    }
}
