import SwiftData
import SwiftUI

/// The pattern library: every design drawn as the finished thing.
struct LibraryView: View {
    // `-OpenDesign raglanPullover` lands on a design, for screenshots. A topical id works too.
    @State private var path: [LibraryItem] = UserDefaults.standard.string(forKey: "OpenDesign").flatMap { raw in
        Design(rawValue: raw).map(LibraryItem.builtIn) ?? TopicalStore.shared.item(raw).map(LibraryItem.topical)
    }.map { [$0] } ?? []

    @Environment(\.dynamicTypeSize) private var typeSize
    private let trending = Trending.shared
    private let topical = TopicalStore.shared

    /// Two tiles a row on a phone, more on a wide screen, one at the accessibility text sizes so names never get cut.
    private var columns: [GridItem] {
        typeSize.isAccessibilitySize
            ? [GridItem(.flexible())]
            : [GridItem(.adaptive(minimum: 150, maximum: 240), spacing: 16)]
    }

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 36) {
                    if !trending.items.isEmpty || !topical.items.isEmpty { trendingShelf }
                    ForEach(Design.Shelf.allCases) { shelf in
                        VStack(alignment: .leading, spacing: 14) {
                            Text(shelf.rawValue)
                                .font(Theme.display(22, weight: .semibold))
                                .accessibilityAddTraits(.isHeader)
                            LazyVGrid(columns: columns, alignment: .leading, spacing: 22) {
                                ForEach(items(on: shelf)) { item in
                                    NavigationLink(value: item) { tile(item, note: item.isFree ? "Free" : item.level.rawValue) }
                                        .buttonStyle(.plain)
                                        .accessibilityIdentifier("design.\(item.designRaw)")
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
            .navigationDestination(for: LibraryItem.self) { DesignView(item: $0) }
            .task {
                // Seeded and test runs keep the list that ships in the app, so captures do not shift.
                let arguments = ProcessInfo.processInfo.arguments
                guard !arguments.contains("-SeedDemo"), !arguments.contains("-UITesting") else { return }
                async let designs: Void = topical.refresh()
                await trending.refresh()
                await designs
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
                    ForEach(shelved) { entry in
                        NavigationLink(value: entry.item) { tile(entry.item, note: entry.tag) }
                            .buttonStyle(.plain)
                            .containerRelativeFrame(.horizontal) { width, _ in
                                typeSize.isAccessibilitySize ? (width - 72) / 1.3 : min((width - 72) / 2.3, 220)
                            }
                            .accessibilityIdentifier("trending.\(entry.item.designRaw)")
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.horizontal, -20)
        }
    }

    /// Topical designs lead the shelf, each with its own tag, then the list from the site.
    private var shelved: [Shelved] {
        topical.items.map { Shelved(item: .topical($0), tag: $0.tag) } + trending.items.map { Shelved(item: .builtIn($0.design), tag: $0.tag) }
    }

    private struct Shelved: Identifiable {
        var item: LibraryItem
        var tag: String
        var id: String { item.id }
    }

    /// A shelf's designs: the library's own, then the topical ones on its shapes, which already lead Trending.
    private func items(on shelf: Design.Shelf) -> [LibraryItem] {
        Design.allCases.filter { $0.shelf == shelf }.map(LibraryItem.builtIn) + topical.items.filter { $0.base.shelf == shelf }.map(LibraryItem.topical)
    }

    private func tile(_ item: LibraryItem, note: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Garment(silhouette: item.silhouette, yarn: item.yarn, colorwork: item.preview)
                .padding(14)
                .background(.primary.opacity(0.045), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(Theme.display(18))
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                Text(note)
                    .font(.subheadline)
                    .foregroundStyle(Theme.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .contentShape(Rectangle())
    }
}

/// One design. Pick a size and a yarn and the pattern rewrites itself to fit.
struct DesignView: View {
    let item: LibraryItem
    @Environment(\.modelContext) private var context
    @State private var values: [String: Double]
    @State private var gauge: Gauge
    @State private var opened: Project?
    @State private var showingPaywall = false
    private let subscription = SubscriptionService.shared

    init(item: LibraryItem) {
        self.item = item
        _values = State(initialValue: item.base.defaultSize.values)
        _gauge = State(initialValue: item.defaultGauge)
    }

    private var design: Design { item.base }

    private var plan: PatternPlan { item.plan(measures: values, gauge: gauge) }

    var body: some View {
        let plan = plan
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                VStack(spacing: 14) {
                    Garment(silhouette: item.silhouette, yarn: item.yarn, colorwork: plan.palette == nil ? nil : plan)
                        .frame(height: 210)
                    Text("\(item.level.rawValue) · \(Sizing.yardage(plan.yards))")
                        .font(.subheadline)
                        .monospacedDigit()
                        .foregroundStyle(Theme.secondary)
                        .contentTransition(.numericText(value: Double(plan.yards)))
                        .motion(.snappy, value: plan.yards)
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
                    chips(item.weights.map(\.label), selected: item.weights.first { $0.gauge == gauge }?.label) { label in
                        if let weight = item.weights.first(where: { $0.label == label }) { gauge = weight.gauge }
                    }
                    adjuster("Stitches over \(Sizing.swatch())", value: $gauge.stitches, range: item.stitchRange, step: 0.5)
                    adjuster("Rows over \(Sizing.swatch())", value: $gauge.rows, range: item.rowRange, step: 1)
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
        .navigationTitle(item.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .safeAreaInset(edge: .bottom) {
            let fits = !subscription.canOpen(item) || item.fits(measures: values, gauge: gauge)
            Button(action: castOn) {
                Text(!subscription.canOpen(item) ? "Unlock Patterns" : fits ? "Cast On" : "Chart Does Not Fit This Gauge")
                    .font(.headline)
                    .foregroundStyle(Theme.onAccent)
                    .frame(maxWidth: .infinity, minHeight: 54)
                    .background(Color.accentColor.opacity(fits ? 1 : 0.35), in: Capsule())
            }
            .disabled(!fits)
            .accessibilityIdentifier("design.castOn")
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            // The page fades into the button instead of being cut off by it.
            .background(alignment: .top) {
                LinearGradient(colors: [Theme.paper.opacity(0), Theme.paper], startPoint: .top, endPoint: .bottom)
                    .frame(height: 28)
                    .offset(y: -28)
                    .allowsHitTesting(false)
            }
            .background(Theme.paper)
        }
        .navigationDestination(item: $opened) { ProjectView(project: $0) }
        .sheet(isPresented: $showingPaywall) { PaywallView() }
    }

    private func castOn() {
        guard subscription.canOpen(item) else {
            showingPaywall = true
            return
        }
        // A second quick tap must not cast on twice.
        guard opened == nil else { return }
        let project = Project(name: item.name, color: item.yarn)
        project.follow(plan, as: item.designRaw)
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
                .motion(.snappy, value: value.wrappedValue)
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
