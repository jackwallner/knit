import Foundation
import SwiftData
import UIKit

enum Persistence {
    /// Opens the knitter's store. Nil when the store on disk will not open: the app then says so
    /// and leaves the file alone, where a quiet in-memory stand-in would look like every project
    /// was gone and would lose whatever was counted next.
    @MainActor
    static func container(inMemory: Bool, at url: URL? = nil) -> ModelContainer? {
        let schema = RavelSchema.current
        if inMemory {
            return try? ModelContainer(for: schema, migrationPlan: RavelMigrationPlan.self, configurations: ModelConfiguration(schema: schema, isStoredInMemoryOnly: true))
        }
        // A fresh install has no Application Support folder; without it the first open logs a failed attempt.
        try? FileManager.default.createDirectory(at: .applicationSupportDirectory, withIntermediateDirectories: true)
        let configuration = url.map { ModelConfiguration(schema: schema, url: $0) } ?? ModelConfiguration(schema: schema)
        if let container = try? ModelContainer(for: schema, migrationPlan: RavelMigrationPlan.self, configurations: configuration) {
            return container
        }
        // A store written by a build from before the schemas were versioned matches no version in the plan.
        // The additive changes since are all lightweight, so the store opens and migrates on its own.
        // This is the same file, never an in-memory stand-in.
        return try? ModelContainer(for: schema, configurations: configuration)
    }

    #if DEBUG
    /// The seed reads in the app's language, so localized screenshots show no English sample data.
    /// English keeps the names the UI tests and the English screenshots use.
    private static var english: Bool { Bundle.main.preferredLocalizations.first?.hasPrefix("en") ?? true }

    /// A seeded project's name in the app's language; `-OpenProject` takes the English name in any language.
    static func demoName(_ english: String) -> String {
        guard !Self.english else { return english }
        return Loc.text(["Raglan Sweater": "Raglan Pullover", "Baby Blanket": "Garter Blanket"][english] ?? english)
    }

    /// `-SeedDemo`: sample data for screenshots and visual checks.
    @MainActor
    static func seedDemo(_ context: ModelContext) {
        let sweater = Project(name: demoName("Raglan Sweater"), rows: 44, color: .madder, createdAt: .now)
        sweater.repeatLength = 6
        sweater.yarn = english ? "Merino Worsted, Oatmeal" : "Merino, \(Loc.text("Oat"))"
        sweater.needles = english ? "US 7 circular" : "US 7 \(Loc.text("Circular"))"
        if !ProcessInfo.processInfo.arguments.contains("-NoPattern") {
            sweater.patternFile = samplePattern()
            markSampleRow(3, on: sweater)
        }
        let beanie = Project(name: demoName("Ribbed Beanie"), rows: 18, color: .spruce, createdAt: .now.addingTimeInterval(-86_400))
        let hat = Design.ribbedBeanie
        beanie.follow(hat.plan(measures: hat.defaultSize.values, gauge: hat.weight.gauge), of: hat)
        let blanket = Project(name: demoName("Baby Blanket"), rows: 240, color: .oat, createdAt: .now.addingTimeInterval(-30 * 86_400))
        blanket.finishedAt = .now.addingTimeInterval(-2 * 86_400)
        let merino = Yarn(name: english ? "Merino Worsted" : "Merino", brand: "Hillside Wool", colorway: english ? "Oatmeal" : Loc.text("Oat"), weight: .worsted, skeins: 6, yardsPerSkein: 200)
        merino.fiber = "100% Merino"
        merino.dyeLot = "4471"
        sweater.tallyOn = true
        sweater.tallyName = english ? "Decreases" : Loc.text("Decrease")
        sweater.tallyCount = 7
        [sweater, beanie, blanket].forEach(context.insert)
        context.insert(merino)
        sweater.stashYarn = merino
        // With `-TopicalFile`, a project cast on from the first draft, partway up its colorwork.
        if let topical = TopicalStore.shared.items.first {
            let item = LibraryItem.topical(topical)
            let project = Project(name: item.name, rows: 0, color: item.yarn, createdAt: .now.addingTimeInterval(3600))
            let plan = item.plan(measures: topical.base.defaultSize.values, gauge: item.defaultGauge)
            project.follow(plan, as: item.designRaw)
            // The tap after the first chart row, so the work shows colors.
            let chartRow = plan.steps.firstIndex { ($0.paint?.first?.count ?? 0) > 1 } ?? 0
            project.rows = plan.steps.prefix(chartRow + 1).reduce(0) { $0 + $1.rows } + 1
            context.insert(project)
        }
        context.insert(Yarn(name: english ? "Sock Yarn" : "Cashmere", brand: "Tidewater", colorway: english ? "Harbor" : Loc.text("Indigo"), weight: .fingering, skeins: 2, yardsPerSkein: 425, createdAt: .now.addingTimeInterval(-86_400)))
        context.insert(Needle(kind: .circular, millimeters: 4.5, lengthInches: 32))
        context.insert(Needle(kind: .doublePointed, millimeters: 3.25, createdAt: .now.addingTimeInterval(-86_400)))
        context.insert(Needle(kind: .hook, millimeters: 5.0, createdAt: .now.addingTimeInterval(-2 * 86_400)))
        context.insert(Yarn(name: english ? "Chunky Alpaca" : "Alpaca", colorway: Loc.text("Charcoal"), weight: .bulky, skeins: 3, createdAt: .now.addingTimeInterval(-2 * 86_400)))
    }

    private static let samplePage = CGRect(x: 0, y: 0, width: 420, height: 595)
    private static let sampleRows = [
        "Cast on 88 sts. Join in the round.",
        "Rows 1-12: K2, P2 rib.",
        "Row 13: Knit, placing 4 raglan markers.",
        "Row 14: *Knit to 1 st before marker,",
        "M1R, K1, SM, K1, M1L; rep from *.",
        "Row 15: Knit.",
        "Repeat rows 14-15 until the yoke",
        "measures 8 in from the cast on.",
    ]
    private static func sampleRowTop(_ index: Int) -> CGFloat { 196 + CGFloat(index) * 32 }

    /// A three-page stand-in pattern so the reader can be checked without importing a file.
    private static func samplePattern() -> String? {
        let body = UIFont.systemFont(ofSize: 17)
        let small: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 13), .foregroundColor: UIColor.darkGray]
        let data = UIGraphicsPDFRenderer(bounds: samplePage).pdfData { context in
            for (number, part) in ["Yoke", "Body", "Sleeves"].enumerated() {
                context.beginPage()
                ("Raglan Sweater" as NSString).draw(at: CGPoint(x: 36, y: 44), withAttributes: [.font: UIFont.boldSystemFont(ofSize: 28)])
                ("Worsted · US 7 circular · 18 sts and 24 rows over 4 in" as NSString).draw(at: CGPoint(x: 36, y: 84), withAttributes: small)
                (part as NSString).draw(at: CGPoint(x: 36, y: 140), withAttributes: [.font: UIFont.boldSystemFont(ofSize: 20)])
                for (index, line) in sampleRows.enumerated() {
                    (line as NSString).draw(at: CGPoint(x: 36, y: sampleRowTop(index)), withAttributes: [.font: body])
                }
                ("\(number + 1)" as NSString).draw(at: CGPoint(x: 36, y: 548), withAttributes: small)
            }
        }
        let source = FileManager.default.temporaryDirectory.appending(path: "sample-pattern.pdf")
        guard (try? data.write(to: source)) != nil else { return nil }
        return try? PatternStore.save(from: source)
    }

    /// Leaves the row band on one line of the sample pattern, the way a tap would.
    private static func markSampleRow(_ index: Int, on project: Project) {
        let line = UIFont.systemFont(ofSize: 17).lineHeight
        project.markPage = 0
        project.markHeight = line + 4
        project.markY = samplePage.height - sampleRowTop(index) - line - 2
    }
    #endif
}
