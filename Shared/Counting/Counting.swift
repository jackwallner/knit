import ActivityKit
import AppIntents
import Foundation

/// The counter on the Lock Screen: one project, where its work stands, and the two buttons.
struct CountingAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable, Sendable {
        /// "Row 18", or in a library pattern "Body · Round 5".
        var place: String
        /// The bare number, for the Dynamic Island.
        var short: String
        /// The row to work next in a library pattern. Empty for a plain counter.
        var line: String
        var canUndo: Bool
    }

    /// Which project the buttons count.
    var project: String
    var name: String
    /// The project's yarn color.
    var red: Double
    var green: Double
    var blue: Double
    /// The buttons' names for VoiceOver, in the app's language: the widget carries no words of its own.
    var knitLabel: String
    var undoLabel: String
}

/// A tap on the Lock Screen counter. A `LiveActivityIntent` runs in the app's own process, so the count is
/// written by the one store and the one context every screen uses, through the same counter rules.
struct CountRowIntent: LiveActivityIntent {
    static let title = LocalizedStringResource("Count a Row")
    static let openAppWhenRun = false
    static let isDiscoverable = false
    /// Counting works without unlocking, like the stitch counter it stands in for.
    static let authenticationPolicy: IntentAuthenticationPolicy = .alwaysAllowed

    @Parameter(title: "Project")
    var project: String

    @Parameter(title: "Back")
    var back: Bool

    init() {
        project = ""
        back = false
    }

    init(project: String, back: Bool) {
        self.project = project
        self.back = back
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        #if !RAVEL_WIDGETS
        await LockCounter.count(project, back: back)
        #endif
        return .result()
    }
}
