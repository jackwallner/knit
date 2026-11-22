import CryptoKit
import Foundation

// Prints one line per built-in design, colorwork record, size and yarn weight: the SHA-256 of its plan,
// written in US units. A design that must not change keeps every one of its lines.
// Usage: golden [records.json ...]
@main
enum Golden {
    static func main() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        func digest(_ plan: PatternPlan) -> String {
            let data = (try? encoder.encode(plan)) ?? Data()
            return SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
        }
        func label(_ input: [String: Double]) -> String {
            input.sorted { $0.key < $1.key }.map { "\($0.key)=\($0.value.formatted())" }.joined(separator: ",")
        }
        var lines: [String] = []
        for design in Design.allCases {
            for input in TopicalCheck.inputs(for: design) {
                for weight in YarnWeight.allCases {
                    lines.append("\(design.rawValue) \(label(input)) \(weight.rawValue) \(digest(design.plan(measures: input, gauge: design.gauge(for: weight))))")
                }
            }
        }
        for file in CommandLine.arguments.dropFirst() {
            guard let data = FileManager.default.contents(atPath: file) else { continue }
            for topical in Topical.parse(data).compactMap(\.topical) {
                for input in TopicalCheck.inputs(for: topical.base) {
                    for weight in topical.weights {
                        lines.append("topical.\(topical.id) \(label(input)) \(weight.rawValue) \(digest(topical.plan(measures: input, gauge: weight.gauge)))")
                    }
                }
            }
        }
        print(lines.joined(separator: "\n"))
    }
}
