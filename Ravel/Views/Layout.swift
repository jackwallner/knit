import SwiftUI

/// The widths the iPad layouts turn on. A phone never reaches them, so it keeps its own layout.
enum Widths {
    /// Lists and forms never run wider than this, so a line stays easy to read on an iPad.
    static let readable: CGFloat = 680
    /// A project puts its reading side and its work side next to each other from this width, in a
    /// window wider than it is tall: an iPad held sideways, not a Split View half.
    static let sideBySide: CGFloat = 900
    /// A screen at least this wide and tall is read from further away, propped up beside the work.
    static let farReading: CGFloat = 600
}

extension View {
    /// Keeps scrolling content in a column no wider than `width`. The background, the scroll
    /// indicator and the edge the content scrolls under keep the full width. A screen with a large title
    /// keeps its column on the leading edge, so the rows start under the title; others center it.
    func readableWidth(_ width: CGFloat = Widths.readable, leading: Bool = false) -> some View {
        modifier(ReadableWidth(limit: width, leading: leading))
    }
}

private struct ReadableWidth: ViewModifier {
    let limit: CGFloat
    let leading: Bool
    @State private var spare: CGFloat = 0

    func body(content: Content) -> some View {
        let limit = limit
        return Group {
            if leading {
                content.contentMargins(.trailing, spare, for: .scrollContent)
            } else {
                content.contentMargins(.horizontal, (spare / 2).rounded(.down), for: .scrollContent)
            }
        }
        .onGeometryChange(for: CGFloat.self) { max(0, $0.size.width - limit) } action: { spare = $0 }
    }
}
