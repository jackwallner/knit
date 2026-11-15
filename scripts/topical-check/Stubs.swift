// The app's yarn colors come from Theme.swift, which needs UIKit. The check only needs their names.
enum YarnColor: String, CaseIterable, Identifiable, Sendable {
    case madder, marigold, moss, spruce, indigo, plum, oat, charcoal

    var id: String { rawValue }
}
