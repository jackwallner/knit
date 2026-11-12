import Foundation
import SwiftData
import UIKit

enum Persistence {
    /// A store that will not open falls back to memory so the app still launches.
    @MainActor
    static func container(inMemory: Bool) -> ModelContainer {
        let schema = Schema([Project.self, Yarn.self])
        // A fresh install has no Application Support folder; without it the first open logs a failed attempt.
        try? FileManager.default.createDirectory(at: .applicationSupportDirectory, withIntermediateDirectories: true)
        if !inMemory, let disk = try? ModelContainer(for: schema, configurations: ModelConfiguration(schema: schema)) {
            return disk
        }
        // An in-memory store has nothing to migrate, so this cannot fail in practice.
        return try! ModelContainer(for: schema, configurations: ModelConfiguration(schema: schema, isStoredInMemoryOnly: true))
    }

    #if DEBUG
    /// `-SeedDemo`: sample data for screenshots and visual checks.
    @MainActor
    static func seedDemo(_ context: ModelContext) {
        let sweater = Project(name: "Raglan Sweater", rows: 42, createdAt: .now)
        sweater.yarn = "Merino Worsted, Oatmeal"
        sweater.needles = "US 7 circular"
        sweater.patternFile = samplePattern()
        let beanie = Project(name: "Ribbed Beanie", rows: 18, createdAt: .now.addingTimeInterval(-86_400))
        let blanket = Project(name: "Baby Blanket", rows: 240, createdAt: .now.addingTimeInterval(-30 * 86_400))
        blanket.finishedAt = .now.addingTimeInterval(-2 * 86_400)
        [sweater, beanie, blanket].forEach(context.insert)
        context.insert(Yarn(name: "Merino Worsted", brand: "Hillside Wool", colorway: "Oatmeal", weight: .worsted, skeins: 6))
        context.insert(Yarn(name: "Sock Yarn", brand: "Tidewater", colorway: "Harbor", weight: .fingering, skeins: 2, createdAt: .now.addingTimeInterval(-86_400)))
        context.insert(Yarn(name: "Chunky Alpaca", colorway: "Charcoal", weight: .bulky, skeins: 3, createdAt: .now.addingTimeInterval(-2 * 86_400)))
    }

    /// A three-page stand-in pattern so the reader can be checked without importing a file.
    private static func samplePattern() -> String? {
        let page = CGRect(x: 0, y: 0, width: 612, height: 792)
        let lines = ["Cast on 88 sts. Join in the round.", "Rows 1-12: K2, P2 rib.", "Row 13: Knit, placing raglan markers.", "Row 14: Knit to marker, M1R, K1, SM, K1, M1L. Repeat.", "Row 15: Knit.", "Repeat rows 14-15 until yoke measures 8 in."]
        let data = UIGraphicsPDFRenderer(bounds: page).pdfData { context in
            for number in 1...3 {
                context.beginPage()
                ("Raglan Sweater" as NSString).draw(at: CGPoint(x: 56, y: 56), withAttributes: [.font: UIFont.boldSystemFont(ofSize: 28)])
                ("Page \(number)" as NSString).draw(at: CGPoint(x: 56, y: 96), withAttributes: [.font: UIFont.systemFont(ofSize: 14), .foregroundColor: UIColor.gray])
                for (index, line) in lines.enumerated() {
                    (line as NSString).draw(at: CGPoint(x: 56, y: 150 + CGFloat(index) * 34), withAttributes: [.font: UIFont.systemFont(ofSize: 18)])
                }
            }
        }
        let source = FileManager.default.temporaryDirectory.appending(path: "sample-pattern.pdf")
        guard (try? data.write(to: source)) != nil else { return nil }
        return try? PatternStore.save(from: source)
    }
    #endif
}
