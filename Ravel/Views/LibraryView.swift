import SwiftData
import SwiftUI

/// The pattern library: every design drawn as the finished thing.
struct LibraryView: View {
    // `-OpenDesign raglanPullover` lands on a design, for screenshots.
    @State private var path: [Design] = UserDefaults.standard.string(forKey: "OpenDesign").flatMap(Design.init(rawValue:)).map { [$0] } ?? []

    private let columns = [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)]
    private let trending = Trending.shared

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 36) {
                    if !trending.items.isEmpty { trendingShelf }
                    ForEach(Design.Shelf.allCases) { shelf in
                        VStack(alignment: .leading, spacing: 14) {
                            Text(shelf.rawValue)
                                .font(Theme.display(22, weight: .semibold))
                                .accessibilityAddTraits(.isHeader)
                            LazyVGrid(columns: columns, alignment: .leading, spacing: 22) {
                                ForEach(Design.allCases.filter { $0.shelf == shelf }) { design in
                                    NavigationLink(value: design) { tile(design, note: design.isFree ? "Free" : design.level.rawValue) }
                                        .buttonStyle(.plain)
                                        .accessibilityIdentifier("design.\(design.rawValue)")
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
            .background(Theme.paper)
            .navigationTitle("Patterns")
            .navigationDestination(for: Design.self) { DesignView(design: $0) }
            .task {
                // Seeded and test runs keep the list that ships in the app, so captures do not shift.
                let arguments = ProcessInfo.processInfo.arguments
                guard !arguments.contains("-SeedDemo"), !arguments.contains("-UITesting") else { return }
                await trending.refresh()
            }
        }
    }

    /// New designs and what suits the season, in a row that scrolls sideways.
    private var trendingShelf: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Trending")
                .font(Theme.display(22, weight: .semibold))
                .accessibilityAddTraits(.isHeader)
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(alignment: .top, spacing: 16) {
                    ForEach(trending.items) { trend in
                        NavigationLink(value: trend.design) { tile(trend.design, note: trend.tag) }
                            .buttonStyle(.plain)
                            .containerRelativeFrame(.horizontal) { width, _ in (width - 40 - 32) / 2.3 }
                            .accessibilityIdentifier("trending.\(trend.design.rawValue)")
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.horizontal, -20)
        }
    }

    private func tile(_ design: Design, note: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Garment(silhouette: design.silhouette, yarn: design.yarn)
                .padding(14)
                .background(.primary.opacity(0.045), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text(design.name)
                    .font(Theme.display(18))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                Text(note)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .contentShape(Rectangle())
    }
}

/// One design. Pick a size and a yarn and the pattern rewrites itself to fit.
struct DesignView: View {
    let design: Design
    @Environment(\.modelContext) private var context
    @State private var values: [String: Double]
    @State private var gauge: Gauge
    @State private var opened: Project?
    @State private var showingPaywall = false
    private let subscription = SubscriptionService.shared

    init(design: Design) {
        self.design = design
        _values = State(initialValue: design.defaultSize.values)
        _gauge = State(initialValue: design.weight.gauge)
    }

    private var plan: PatternPlan { design.plan(measures: values, gauge: gauge) }

    var body: some View {
        let plan = plan
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                VStack(spacing: 14) {
                    Garment(silhouette: design.silhouette, yarn: design.yarn)
                        .frame(height: 210)
                    Text("\(design.level.rawValue) · \(Sizing.yardage(plan.yards))")
                        .font(.subheadline)
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                        .contentTransition(.numericText(value: Double(plan.yards)))
                        .animation(.snappy, value: plan.yards)
                }
                .frame(maxWidth: .infinity)

                group("Size") {
                    chips(design.sizes.map(\.name), selected: design.sizes.first { $0.values == values }?.name) { name in
                        if let size = design.sizes.first(where: { $0.name == name }) { values = size.values }
                    }
                    ForEach(design.measures) { measure in
                        adjuster(measure.label, value: Binding(get: { values[measure.key] ?? measure.range.lowerBound }, set: { values[measure.key] = $0 }), range: measure.range, step: measure.step, length: true)
                    }
                }

                group("Gauge") {
                    chips(YarnWeight.allCases.map(\.label), selected: YarnWeight.allCases.first { $0.gauge == gauge }?.label) { label in
                        if let weight = YarnWeight.allCases.first(where: { $0.label == label }) { gauge = weight.gauge }
                    }
                    adjuster("Stitches over \(Sizing.swatch())", value: $gauge.stitches, range: 8...40, step: 0.5)
                    adjuster("Rows over \(Sizing.swatch())", value: $gauge.rows, range: 10...56, step: 1)
                }

                group("Materials") {
                    Text(plan.finished).frame(maxWidth: .infinity, alignment: .leading)
                    ForEach(plan.materials, id: \.self) { line in
                        Text(line).frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .background(Theme.paper)
        .navigationTitle(design.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .safeAreaInset(edge: .bottom) {
            Button(action: castOn) {
                Text(subscription.canOpen(design) ? "Cast On" : "Unlock Patterns")
                    .font(.headline)
                    .foregroundStyle(Theme.onAccent)
                    .frame(maxWidth: .infinity, minHeight: 54)
                    .background(Color.accentColor, in: Capsule())
            }
            .accessibilityIdentifier("design.castOn")
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(Theme.paper)
        }
        .navigationDestination(item: $opened) { ProjectView(project: $0) }
        .sheet(isPresented: $showingPaywall) { PaywallView() }
    }

    private func castOn() {
        guard subscription.canOpen(design) else {
            showingPaywall = true
            return
        }
        // A second quick tap must not cast on twice.
        guard opened == nil else { return }
        let project = Project(name: design.name, color: design.yarn)
        project.follow(plan, of: design)
        project.needles = gauge.needle.label
        context.insert(project)
        try? context.save()
        opened = project
    }

    private func group(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(Theme.display(22, weight: .semibold))
                .accessibilityAddTraits(.isHeader)
            content()
        }
    }

    private func chips(_ names: [String], selected: String?, pick: @escaping (String) -> Void) -> some View {
        Wrap(spacing: 8) {
                ForEach(names, id: \.self) { name in
                    let isOn = name == selected
                    Button { pick(name) } label: {
                        Text(name)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(isOn ? Theme.onAccent : .primary)
                            .padding(.horizontal, 16)
                            .frame(minHeight: 40)
                            .background(isOn ? AnyShapeStyle(Color.accentColor) : AnyShapeStyle(.primary.opacity(0.07)), in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(isOn ? .isSelected : [])
                }
        }
    }

    private func adjuster(_ label: String, value: Binding<Double>, range: ClosedRange<Double>, step: Double, length: Bool = false) -> some View {
        let shown = length ? Sizing.inches(value.wrappedValue) : value.wrappedValue.formatted(.number.precision(.fractionLength(0...2)))
        func move(_ by: Double) { value.wrappedValue = min(max(value.wrappedValue + by, range.lowerBound), range.upperBound) }
        return HStack(spacing: 4) {
            Text(label)
            Spacer(minLength: 8)
            nudge("minus") { move(-step) }.disabled(value.wrappedValue <= range.lowerBound)
            Text(shown)
                .font(Theme.display(20))
                .monospacedDigit()
                .frame(minWidth: 76)
                .contentTransition(.numericText(value: value.wrappedValue))
                .animation(.snappy, value: value.wrappedValue)
            nudge("plus") { move(step) }.disabled(value.wrappedValue >= range.upperBound)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
        .accessibilityValue(shown)
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: move(step)
            case .decrement: move(-step)
            @unknown default: break
            }
        }
    }

    private func nudge(_ symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.body.weight(.semibold))
                .frame(width: 44, height: 44)
                .background(.primary.opacity(0.07), in: Circle())
        }
        .buttonStyle(.plain)
        .buttonRepeatBehavior(.enabled)
    }
}

/// Lays chips out left to right and wraps to the next line, so none hide off the edge.
struct Wrap: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? .infinity
        let rows = arrange(subviews, in: width)
        return CGSize(width: proposal.width ?? rows.map(\.width).max() ?? 0, height: rows.last.map { $0.y + $0.height } ?? 0)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        for row in arrange(subviews, in: bounds.width) {
            var x = bounds.minX
            for index in row.items {
                let size = subviews[index].sizeThatFits(.unspecified)
                subviews[index].place(at: CGPoint(x: x, y: bounds.minY + row.y), proposal: ProposedViewSize(size))
                x += size.width + spacing
            }
        }
    }

    private struct Row {
        var items: [Int] = []
        var width: CGFloat = 0
        var height: CGFloat = 0
        var y: CGFloat = 0
    }

    private func arrange(_ subviews: Subviews, in width: CGFloat) -> [Row] {
        var rows = [Row()]
        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(.unspecified)
            var row = rows[rows.count - 1]
            if !row.items.isEmpty, row.width + spacing + size.width > width {
                rows.append(Row(y: row.y + row.height + spacing))
                row = rows[rows.count - 1]
            }
            row.width += (row.items.isEmpty ? 0 : spacing) + size.width
            row.height = max(row.height, size.height)
            row.items.append(index)
            rows[rows.count - 1] = row
        }
        return rows
    }
}
