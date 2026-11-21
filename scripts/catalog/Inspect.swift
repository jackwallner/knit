import Foundation

// Checks one built-in design the way PatternTests does, at every named size, both ends of every measure
// and every yarn weight, and prints its pattern at the smallest and largest named size.
// Usage: inspect <Design raw value> [weight] [stitch], a stitch to print the shape worked in that stitch
@main
struct Inspect {
    static func main() {
        let arguments = CommandLine.arguments.dropFirst()
        guard let raw = arguments.first, let design = Design(rawValue: raw) else {
            print("usage: inspect <design> [weight]")
            exit(2)
        }
        var fit = Engines.Fit()
        fit.stitch = arguments.compactMap(Stitch.init(rawValue:)).first
        var failures = 0
        for input in TopicalCheck.inputs(for: design) {
            for weight in YarnWeight.allCases {
                let plan = design.plan(measures: input, gauge: design.gauge(for: weight), fit: fit)
                let problems = PlanCheck.problems(plan)
                if !problems.isEmpty {
                    failures += 1
                    print("FAIL \(weight.rawValue) \(input.sorted { $0.key < $1.key }): \(problems.prefix(5))")
                }
            }
        }
        print(failures == 0 ? "ok   \(design.name): \(TopicalCheck.inputs(for: design).count) sizes x \(YarnWeight.allCases.count) weights" : "\(failures) failing plans")
        let weight = arguments.compactMap(YarnWeight.init(rawValue:)).first ?? design.weight
        for size in [design.sizes.first!, design.sizes.last!] {
            let plan = design.plan(measures: size.values, gauge: design.gauge(for: weight), fit: fit)
            print("\n== \(design.name), \(size.name), \(weight.label), \(plan.yards) yd\n\(plan.finished)")
            for line in plan.materials { print("  \(line)") }
            for step in plan.steps {
                let count = step.stitches.map { " [\($0)\(step.stitches(after: step.rows - 1).map { $0 == step.stitches ? "" : " to \($0)" } ?? "")]" } ?? ""
                print("\(step.section) x\(step.rows)\(count): \(step.texts.joined(separator: " / "))")
            }
        }
        exit(failures == 0 ? 0 : 1)
    }
}
