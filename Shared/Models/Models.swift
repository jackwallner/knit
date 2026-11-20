import Foundation
import SwiftData

@Model
final class Project {
    var name: String
    var rows: Int
    var createdAt: Date
    var finishedAt: Date?
    var yarn: String
    var needles: String
    var notes: String
    /// File name inside `PatternStore.directory`, never a full path.
    var patternFile: String?
    var patternPage: Int
    var colorRaw: String = YarnColor.madder.rawValue
    /// Rows in one pattern repeat. 0 means the project has no repeat.
    var repeatLength: Int = 0
    /// The row count when the repeat was set. The repeat is counted from the row after it,
    /// so a repeat that follows a ribbed hem starts at 1 and not somewhere in the middle.
    var repeatStart: Int = 0
    /// The row band the knitter left on the pattern: page index (-1 for none), then its position on that page.
    var markPage: Int = -1
    var markY: Double = 0
    var markHeight: Double = 0
    /// The library design this project was cast on from.
    var designRaw: String?
    /// That design sized for this knitter, frozen so the instructions never shift under them.
    var planData: Data?
    /// The yarn picked from the stash. Free text in `yarn` stays for projects that never picked one.
    /// Deleting the yarn empties this and leaves the project as it is.
    @Relationship(deleteRule: .nullify, inverse: \Yarn.projects) var stashYarn: Yarn?
    /// An optional second counter beside the rows, for a repeat or a decrease interval. It has its own name and count
    /// and shares nothing with `rows`.
    var tallyOn: Bool = false
    var tallyName: String = ""
    var tallyCount: Int = 0
    /// When the count last moved: the list leads with what is on the needles now.
    var workedAt: Date?
    /// The reader's zoom and the point of the page at the top of the screen, put back when the pattern
    /// reopens. Zoom 0 means the page fits the width.
    var readerZoom: Double = 0
    var readerX: Double = 0
    var readerY: Double = 0
    /// The row band moves down a line with every row. `markRow` is the count it was laid at.
    var markSteps: Bool = false
    var markRow: Int = 0
    /// A picture of the finished piece: a file name in `PatternStore.directory`, never a full path.
    var finishPhoto: String?

    init(name: String, rows: Int = 0, color: YarnColor = .madder, createdAt: Date = .now) {
        self.name = name
        self.colorRaw = color.rawValue
        self.rows = rows
        self.createdAt = createdAt
        self.yarn = ""
        self.needles = ""
        self.notes = ""
        self.patternPage = 0
    }

    var isFinished: Bool { finishedAt != nil }

    /// The yarn as the project shows it: the stash yarn when one is picked, else what was typed.
    var yarnLabel: String { stashYarn?.label ?? yarn }

    /// The row a knitter means. In a library pattern the count includes setup steps (cast on, join, divide),
    /// so it is the rows actually knitted; elsewhere it is the count.
    func knittedRows(_ plan: PatternPlan?) -> Int { plan?.knitRows(upTo: rows) ?? rows }

    var color: YarnColor {
        get { YarnColor(rawValue: colorRaw) ?? .madder }
        set { colorRaw = newValue.rawValue }
    }

    /// How far into the current repeat the last finished row is, from 1 to `repeatLength`. 0 before the first row or with no repeat.
    var repeatPosition: Int {
        guard repeatLength > 0, rows > repeatStart else { return 0 }
        return (rows - repeatStart - 1) % repeatLength + 1
    }

    var plan: PatternPlan? { planData.flatMap { try? JSONDecoder().decode(PatternPlan.self, from: $0) } }

    func follow(_ plan: PatternPlan, of design: Design) { follow(plan, as: design.rawValue) }

    /// `design` is a built-in design's raw value or a topical design's `topical.` id.
    func follow(_ plan: PatternPlan, as design: String) {
        designRaw = design
        planData = try? JSONEncoder().encode(plan)
    }

    /// The shape the project draws as: its design's, or for a topical design the one kept in its own plan.
    func silhouette(_ plan: PatternPlan?) -> Design.Silhouette? {
        designRaw.flatMap(Design.init(rawValue:))?.silhouette ?? plan?.silhouette.flatMap(Design.Silhouette.init(rawValue:))
    }

    static let rowLimit = 99_999

    func increment() { move(to: rows + 1) }

    func decrement() { move(to: rows - 1) }

    /// Jumps straight to a row, for a project already under way when it was added.
    func setRows(_ count: Int) { move(to: count) }

    /// The one place the count is written. A count that moved marks the project as worked just now.
    private func move(to count: Int) {
        let next = min(max(count, 0), Self.rowLimit)
        guard next != rows else { return }
        rows = next
        workedAt = .now
    }

    /// Where the row band sits on its page: where it was laid, moved down a line for every row since when it
    /// steps with the count.
    var bandY: Double { markSteps ? markY - Double(rows - markRow) * markHeight : markY }

    /// Turns stepping on from the row the knitter is on, or off with the band left where it has got to.
    func setBandSteps(_ on: Bool) {
        markY = bandY
        markRow = rows
        markSteps = on
        persist()
    }

    /// When the project was last touched: its last row, or the day it was made.
    var lastWorked: Date { workedAt ?? createdAt }

    /// Sets the rows in one repeat. A new repeat starts with the next row knitted.
    func setRepeat(_ length: Int) {
        let length = min(max(length, 0), 200)
        if repeatLength == 0 || length == 0 { repeatStart = length == 0 ? 0 : rows }
        repeatLength = length
    }

    func toggleFinished(at date: Date = .now) { finishedAt = isFinished ? nil : date }

    /// Writes the project to disk now. A row must never wait on an autosave, and a save that fails is said
    /// out loud (`SaveWatch`), never dropped.
    /// Posted after each save of a project, so anything that mirrors its count (the Lock Screen) can catch up.
    static let savedNotice = Notification.Name("Ravel.projectSaved")

    func persist() {
        guard let modelContext else { return }
        do {
            try modelContext.save()
            SaveWatch.saved()
            NotificationCenter.default.post(name: Self.savedNotice, object: self)
        } catch {
            SaveWatch.failed()
        }
    }

    /// Where the work stands, for the project list: "Row 18", or in a library pattern "Body · Round 5".
    /// Empty once a library pattern is complete.
    func standing(_ plan: PatternPlan?) -> String {
        guard let plan else { return String(localized: "Row \(rows)", comment: "Project list: rows knitted so far") }
        guard let spot = plan.position(at: rows) else { return "" }
        let section = Loc.section(plan.steps[spot.step].section)
        guard let place = plan.sectionRow(at: rows) else { return section }
        let row = plan.unit(at: rows) == "Round"
            ? String(localized: "Round \(place.row)", comment: "Guided pattern: the round within the section")
            : String(localized: "Row \(place.row)", comment: "Guided pattern: the row within the section")
        return "\(section) · \(row)"
    }
}

/// Tells the app when a change could not be written to disk, once per run of failures, so a knitter is never
/// left counting rows that are not being kept. The store saves on the main thread, like every caller here.
enum SaveWatch {
    static let failedNotice = Notification.Name("Ravel.saveFailed")
    nonisolated(unsafe) private static var failing = false

    static func failed() {
        guard !failing else { return }
        failing = true
        NotificationCenter.default.post(name: failedNotice, object: nil)
    }

    static func saved() { failing = false }

    /// True from a save that failed until the next one that works.
    static var isFailing: Bool { failing }
}

/// The counter's rules, in one place: every change to the count ends on disk.
extension Project {
    /// One tap: the next row. A library pattern stops at its last row and finishes itself there.
    func knit(following plan: PatternPlan?) {
        defer { persist() }
        guard let plan else {
            if !isFinished { increment() }
            return
        }
        guard rows < plan.totalTaps else { return }
        increment()
        if rows == plan.totalTaps, !isFinished { toggleFinished() }
    }

    /// Takes the last row back. Stepping back from the end of a library pattern puts it on the needles again.
    /// A finished project with no pattern is a record, and stays as it is until it is marked active.
    func unknit(following plan: PatternPlan?) {
        guard plan != nil || !isFinished else { return }
        decrement()
        reopenIfUnfinished(plan)
        persist()
    }

    /// Lands on a row without tapping up to it. In a library pattern the row is counted within the current
    /// section, across every step the section is written in.
    func jump(to row: Int, following plan: PatternPlan?) {
        defer { persist() }
        guard let plan else { return setRows(row) }
        guard let tap = plan.tap(ofRow: row, inSectionAt: rows) else { return }
        setRows(tap)
    }

    /// Lands on the first row of a section of a library pattern.
    func jump(toTap tap: Int, following plan: PatternPlan) {
        setRows(min(max(tap, 0), plan.totalTaps))
        reopenIfUnfinished(plan)
        persist()
    }

    /// Back to row 0, on the needles again, with any repeat counted from the first row.
    func resetCount(following plan: PatternPlan?) {
        setRows(0)
        repeatStart = 0
        if isFinished { toggleFinished() }
        persist()
    }

    /// Takes a corrected pattern in place of the frozen one, at the same step and row the knitter was on.
    func adopt(_ corrected: PatternPlan) {
        defer { persist() }
        let old = plan
        planData = try? JSONEncoder().encode(corrected)
        guard let old, let spot = old.position(at: rows) else { return setRows(corrected.totalTaps) }
        // The same section, and the same distance into it, so a fix that adds or drops a step elsewhere never
        // moves the knitter into unrelated work.
        let section = old.steps[spot.step].section
        let into = old.steps[..<spot.step].filter { $0.section == section }.reduce(0) { $0 + $1.rows } + spot.row
        guard let first = corrected.steps.firstIndex(where: { $0.section == section }) else { return setRows(corrected.totalTaps) }
        let tap = corrected.steps[..<first].reduce(0) { $0 + $1.rows }
        let length = corrected.steps[first...].prefix { $0.section == section }.reduce(0) { $0 + $1.rows }
        setRows(tap + min(into, max(length - 1, 0)))
        reopenIfUnfinished(corrected)
    }

    private func reopenIfUnfinished(_ plan: PatternPlan?) {
        if let plan, isFinished, rows < plan.totalTaps { toggleFinished() }
    }
}

/// The second counter's rules. None of these reads or writes `rows`, and each ends on disk like the main count.
extension Project {
    static let tallyNameLimit = 40

    func addTally(named name: String) {
        tallyOn = true
        tallyName = Self.tidy(name)
        tallyCount = 0
        persist()
    }

    func renameTally(_ name: String) {
        tallyName = Self.tidy(name)
        persist()
    }

    /// One step on the second counter, never below 0.
    func tally(by step: Int) {
        guard tallyOn else { return }
        tallyCount = min(max(tallyCount + step, 0), Self.rowLimit)
        persist()
    }

    func resetTally() {
        tallyCount = 0
        persist()
    }

    func removeTally() {
        tallyOn = false
        tallyName = ""
        tallyCount = 0
        persist()
    }

    /// What the counter is called: its name, or "Counter" when left blank.
    var tallyTitle: String { tallyName.isEmpty ? String(localized: "Counter", comment: "Name of the second counter when the knitter left it blank") : tallyName }

    private static func tidy(_ name: String) -> String {
        String(name.trimmingCharacters(in: .whitespacesAndNewlines).prefix(tallyNameLimit))
    }
}

@Model
final class Yarn {
    var name: String
    var brand: String
    var colorway: String
    var weightRaw: String
    var skeins: Int
    var createdAt: Date
    /// Length of one skein in yards, whatever units it is shown in. 0 when the knitter did not say.
    var yardsPerSkein: Int = 0
    var fiber: String = ""
    var dyeLot: String = ""
    /// Projects knitted from this yarn. The link is on the project's side.
    var projects: [Project] = []

    init(name: String, brand: String = "", colorway: String = "", weight: YarnWeight = .worsted, skeins: Int = 1, yardsPerSkein: Int = 0, createdAt: Date = .now) {
        self.name = name
        self.brand = brand
        self.colorway = colorway
        self.weightRaw = weight.rawValue
        self.skeins = skeins
        self.yardsPerSkein = yardsPerSkein
        self.createdAt = createdAt
    }

    var weight: YarnWeight {
        get { YarnWeight(rawValue: weightRaw) ?? .worsted }
        set { weightRaw = newValue.rawValue }
    }

    var detail: String {
        [brand, colorway, weight.title]
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .joined(separator: " · ")
    }

    /// The name, with the color when it has one: how a project refers to this yarn.
    var label: String {
        let color = colorway.trimmingCharacters(in: .whitespaces)
        return color.isEmpty ? name : "\(name), \(color)"
    }

    /// A new yarn nobody typed into: no text, no length, the weight and skein count it opened with.
    var isBlank: Bool {
        [name, brand, colorway, fiber, dyeLot].allSatisfy { $0.trimmingCharacters(in: .whitespaces).isEmpty }
            && yardsPerSkein == 0 && skeins == 1 && weight == .worsted
    }

    /// What a yarn saved without a name is called: its fiber, else its brand or color, else its weight.
    var fallbackName: String {
        [fiber, brand, colorway].map { $0.trimmingCharacters(in: .whitespaces) }.first { !$0.isEmpty } ?? weight.title
    }

    /// Yards in the whole lot. 0 when the length of a skein is not known.
    var totalYards: Int { yardsPerSkein * skeins }

    /// The total as a knitter reads it, nil when the length of a skein is not known.
    var totalLength: String? { totalYards > 0 ? Sizing.yardage(totalYards) : nil }

    /// A skein's length as typed or shown in the knitter's units, for the editor.
    var lengthPerSkein: Int {
        get { Self.shown(yards: yardsPerSkein) }
        set { yardsPerSkein = Self.yards(shown: newValue) }
    }

    static func shown(yards: Int, units: Units = .current) -> Int {
        units == .metric ? Int((Double(yards) * 0.9144).rounded()) : yards
    }

    static func yards(shown: Int, units: Units = .current) -> Int {
        max(0, units == .metric ? Int((Double(shown) / 0.9144).rounded()) : shown)
    }
}

enum YarnWeight: String, CaseIterable, Identifiable {
    case lace, fingering, sport, dk, worsted, aran, bulky, superBulky

    var id: String { rawValue }

    var label: String {
        switch self {
        case .lace: "Lace"
        case .fingering: "Fingering"
        case .sport: "Sport"
        case .dk: "DK"
        case .worsted: "Worsted"
        case .aran: "Aran"
        case .bulky: "Bulky"
        case .superBulky: "Super Bulky"
        }
    }

    /// The label in the knitter's language. `label` stays English: the engines write it into materials lines.
    var title: String { Loc.text(label) }
}

/// A needle or hook in the stash.
@Model
final class Needle {
    var kindRaw: String
    var millimeters: Double
    /// Cable or shaft length in inches. 0 when the knitter did not say.
    var lengthInches: Int
    var createdAt: Date

    init(kind: NeedleKind = .circular, millimeters: Double = 4.5, lengthInches: Int = 0, createdAt: Date = .now) {
        self.kindRaw = kind.rawValue
        self.millimeters = millimeters
        self.lengthInches = lengthInches
        self.createdAt = createdAt
    }

    var kind: NeedleKind {
        get { NeedleKind(rawValue: kindRaw) ?? .circular }
        set { kindRaw = newValue.rawValue }
    }

    var size: NeedleSize { NeedleSize.nearest(to: millimeters, hook: kind == .hook) }

    var detail: String {
        lengthInches > 0 ? "\(kind.title) · \(Sizing.cable(lengthInches))" : kind.title
    }

    /// Still exactly the needle a new one starts as.
    var isUntouched: Bool { kind == .circular && millimeters == 4.5 && lengthInches == 0 }
}

enum NeedleKind: String, CaseIterable, Identifiable {
    case circular, straight, doublePointed, hook

    var id: String { rawValue }

    var label: String {
        switch self {
        case .circular: "Circular"
        case .straight: "Straight"
        case .doublePointed: "Double-Pointed"
        case .hook: "Crochet Hook"
        }
    }

    var title: String { Loc.text(label) }
}

/// A standard size: metric diameter plus the US name knitters and crocheters use for it.
struct NeedleSize: Hashable, Identifiable {
    let millimeters: Double
    let us: String

    var id: Double { millimeters }

    var label: String { "US \(us) · \(millimeters.formatted(.number.precision(.fractionLength(0...2)))) mm" }

    static let needles: [NeedleSize] = [
        .init(millimeters: 2.0, us: "0"), .init(millimeters: 2.25, us: "1"), .init(millimeters: 2.75, us: "2"),
        .init(millimeters: 3.25, us: "3"), .init(millimeters: 3.5, us: "4"), .init(millimeters: 3.75, us: "5"),
        .init(millimeters: 4.0, us: "6"), .init(millimeters: 4.5, us: "7"), .init(millimeters: 5.0, us: "8"),
        .init(millimeters: 5.5, us: "9"), .init(millimeters: 6.0, us: "10"), .init(millimeters: 6.5, us: "10.5"),
        .init(millimeters: 8.0, us: "11"), .init(millimeters: 9.0, us: "13"), .init(millimeters: 10.0, us: "15"),
        .init(millimeters: 12.75, us: "17"), .init(millimeters: 15.0, us: "19"),
    ]

    static let hooks: [NeedleSize] = [
        .init(millimeters: 2.25, us: "B"), .init(millimeters: 2.75, us: "C"), .init(millimeters: 3.25, us: "D"),
        .init(millimeters: 3.5, us: "E"), .init(millimeters: 3.75, us: "F"), .init(millimeters: 4.0, us: "G"),
        .init(millimeters: 4.5, us: "7"), .init(millimeters: 5.0, us: "H"), .init(millimeters: 5.5, us: "I"),
        .init(millimeters: 6.0, us: "J"), .init(millimeters: 6.5, us: "K"), .init(millimeters: 8.0, us: "L"),
        .init(millimeters: 9.0, us: "M"), .init(millimeters: 10.0, us: "N"),
    ]

    static func all(hook: Bool) -> [NeedleSize] { hook ? hooks : needles }

    static func nearest(to millimeters: Double, hook: Bool) -> NeedleSize {
        all(hook: hook).min { abs($0.millimeters - millimeters) < abs($1.millimeters - millimeters) } ?? needles[7]
    }
}
