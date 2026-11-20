import ActivityKit
import SwiftData
import SwiftUI

/// Counting from the Lock Screen with a Live Activity. Its buttons run `CountRowIntent` in this app's own
/// process, on the same store and the same context as every screen: the count has one writer, and it still
/// goes only through the counter rules (`knit`, `unknit`), which end in a save.
@MainActor
enum LockCounter {
    /// The app's store, set once at launch. Nil when the store would not open: nothing is counted then.
    static var container: ModelContainer?

    /// Whether this phone shows Live Activities at all: Settings can turn them off.
    static var allowed: Bool { ActivityAuthorizationInfo().areActivitiesEnabled }

    /// A project's name on its counter. Sorted keys, because the card is found again by comparing this
    /// text and plain JSON writes its keys in an order that changes from one encoding to the next.
    static func key(_ project: Project) -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        return (try? encoder.encode(project.persistentModelID).base64EncodedString()) ?? ""
    }

    static func project(_ key: String) -> Project? {
        guard let context = container?.mainContext, let data = Data(base64Encoded: key),
              let id = try? JSONDecoder().decode(PersistentIdentifier.self, from: data) else { return nil }
        return (try? context.fetch(FetchDescriptor<Project>()))?.first { $0.persistentModelID == id }
    }

    // The activities are not tied to the main actor, so each is fetched and changed in one place off it.
    nonisolated private static func activities(_ key: String?) -> [Activity<CountingAttributes>] {
        Activity<CountingAttributes>.activities.filter { key == nil || $0.attributes.project == key }
    }

    nonisolated private static func show(_ state: CountingAttributes.ContentState, for key: String) async {
        for activity in activities(key) { await activity.update(ActivityContent(state: state, staleDate: nil)) }
    }

    /// Ends a project's counter, or every counter. `last` stays on the Lock Screen as its closing words.
    nonisolated private static func end(_ key: String?, last: CountingAttributes.ContentState? = nil) async {
        for activity in activities(key) {
            await activity.end(last.map { ActivityContent(state: $0, staleDate: nil) }, dismissalPolicy: last == nil ? .immediate : .default)
        }
    }

    static func isOn(_ project: Project) -> Bool { !activities(key(project)).isEmpty }

    /// What the Lock Screen shows for a project. Nil once there is nothing left to count: a finished
    /// project, or a library pattern at its last row.
    static func state(_ project: Project) -> CountingAttributes.ContentState? {
        guard !project.isFinished else { return nil }
        let plan = project.plan
        let place = project.standing(plan)
        guard !place.isEmpty else { return nil }
        var line = "", short = String(project.rows)
        if let plan, let spot = plan.position(at: project.rows) {
            line = plan.steps[spot.step].text(at: spot.row)
            if let row = plan.sectionRow(at: project.rows) { short = String(row.row) }
        }
        return CountingAttributes.ContentState(place: place, short: short, line: line, canUndo: project.rows > 0)
    }

    /// Puts a project's counter on the Lock Screen, in place of any other: one piece of knitting at a time.
    static func start(_ project: Project) async {
        guard allowed, let state = state(project) else { return }
        await stop()
        let tint = project.color.tint
        let attributes = CountingAttributes(
            project: key(project), name: project.name, red: tint.red, green: tint.green, blue: tint.blue,
            knitLabel: String(localized: "Add a row"), undoLabel: String(localized: "Back one row")
        )
        _ = try? Activity.request(attributes: attributes, content: ActivityContent(state: state, staleDate: nil))
    }

    /// Takes a project's counter off the Lock Screen, or every counter.
    static func stop(_ project: Project? = nil) async { await drop(project.map(key)) }

    /// The same by the project's key, for a project that is being deleted.
    static func drop(_ key: String?) async { await end(key) }

    /// Brings the Lock Screen up to the count, after a row counted anywhere. Ends it when the work is done.
    static func refresh(_ project: Project) async {
        // Nearly every save has no counter to bring up to date: ask that first, before reading the plan.
        guard isOn(project) else { return }
        let key = key(project)
        if let state = state(project) { await show(state, for: key) } else { await end(key) }
    }

    /// A tap on the Lock Screen: one row on, or the last one back, by the same rules as a tap in the app.
    /// A project that is gone takes its counter with it. A row that could not be saved says so in place of
    /// the next instruction and stops the counting there, so no one knits on against a count that is not kept.
    static func count(_ key: String, back: Bool) async {
        guard let project = project(key) else { return await drop(key) }
        let plan = project.plan
        if back { project.unknit(following: plan) } else { project.knit(following: plan) }
        guard SaveWatch.isFailing, var state = state(project) else { return await refresh(project) }
        state.line = String(localized: "Your last change was not saved")
        await end(key, last: state)
    }
}
