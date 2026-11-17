import Foundation

/// A knitter's "this row is wrong", as an email that carries everything needed to rebuild the pattern
/// exactly: design, measurements, gauge, revision, and where they are. Triage: `.claude/rules/pattern-reports.md`.
enum PatternReport {
    struct Code: Codable, Equatable {
        var version = 1
        var app: String
        var design: String
        var revision: Int?
        var measures: [String: Double]?
        var gauge: Gauge?
        var step: Int
        var row: Int
        var taps: Int
    }

    static let prefix = "ravel-report"

    static func code(plan: PatternPlan, design: String, taps: Int) -> Code {
        let spot = plan.position(at: taps) ?? (max(plan.steps.count - 1, 0), 0)
        let info = Bundle.main.infoDictionary
        let app = "\(info?["CFBundleShortVersionString"] as? String ?? "?") (\(info?["CFBundleVersion"] as? String ?? "?"))"
        return Code(app: app, design: design, revision: plan.source?.revision, measures: plan.source?.measures,
                    gauge: plan.source?.gauge, step: spot.step, row: spot.row, taps: taps)
    }

    /// One line a person can paste back into `scripts/pattern-report.py`.
    static func line(_ code: Code) -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        let data = (try? encoder.encode(code)) ?? Data()
        return "\(prefix) \(data.base64EncodedString())"
    }

    static func decode(_ line: String) -> Code? {
        guard let range = line.range(of: "\(prefix) ") else { return nil }
        let encoded = line[range.upperBound...].prefix { !$0.isWhitespace }
        guard let data = Data(base64Encoded: String(encoded)) else { return nil }
        return try? JSONDecoder().decode(Code.self, from: data)
    }

    /// The mail: a space to say what went wrong, then the step as written and the code.
    static func mail(plan: PatternPlan, design: String, title: String, taps: Int) -> URL? {
        let code = code(plan: plan, design: design, taps: taps)
        let step = plan.steps.indices.contains(code.step) ? plan.steps[code.step] : nil
        let body = [
            String(localized: "What went wrong?", comment: "Opening line of a pattern problem email; the knitter writes below it"),
            "", "", "",
            "\(title), step \(code.step + 1) of \(plan.steps.count), row \(code.row + 1)",
            step.map { "\($0.section): \($0.text(at: code.row))" } ?? "",
            plan.source.map { source in
                let sizes = source.measures.sorted { $0.key < $1.key }.map { "\($0.key) \(Sizing.inches($0.value))" }.joined(separator: ", ")
                return "\(sizes). \(source.gauge.stitches.formatted()) stitches and \(source.gauge.rows.formatted()) rows over \(Sizing.swatch())."
            } ?? "",
            "App \(code.app)",
            line(code),
        ].joined(separator: "\n")
        var parts = URLComponents()
        parts.scheme = "mailto"
        parts.path = "jackwallner@gmail.com"
        parts.queryItems = [URLQueryItem(name: "subject", value: "Ravel pattern: \(title)"), URLQueryItem(name: "body", value: body)]
        return parts.url
    }
}
