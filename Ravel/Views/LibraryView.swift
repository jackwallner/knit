import SwiftData
import SwiftUI

/// The pattern library: every design drawn as the finished thing.
struct LibraryView: View {
    // `-OpenDesign raglanPullover` lands on a design, for screenshots. A topical id works too.
    @State private var path: [LibraryItem] = UserDefaults.standard.string(forKey: "OpenDesign").flatMap { raw in
        Design(rawValue: raw).map(LibraryItem.builtIn) ?? TopicalStore.shared.item(raw).map(LibraryItem.topical)
    }.map { [$0] } ?? []

    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.horizontalSizeClass) private var sizeClass
    @State private var query = ""
    private let trending = Trending.shared
    private let topical = TopicalStore.shared

    /// Two tiles a row on a phone, four to six on an iPad, one at the accessibility text sizes on a phone so names
    /// never get cut, two on an iPad.
    private var columns: [GridItem] {
        let regular = sizeClass == .regular
        if typeSize.isAccessibilitySize { return Array(repeating: GridItem(.flexible(), spacing: 20), count: regular ? 2 : 1) }
        return [GridItem(.adaptive(minimum: regular ? 190 : 150, maximum: 240), spacing: regular ? 20 : 16)]
    }

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                // Each case keeps its own stack: a branch inside one lazy stack hides its shelves from VoiceOver.
                Group {
                    if searching.isEmpty {
                        LazyVStack(alignment: .leading, spacing: 36) {
                            if !shelved.isEmpty { row("Trending", shelved, id: "trending") }
                            // The patterns that need no purchase, together near the top so they are easy to find.
                            // A row that scrolls sideways, like Trending: set as a grid beside the shelves in this
                            // lazy stack, it hid every shelf after it from VoiceOver.
                            if !free.isEmpty { row("Free", free.map { Shelved(item: $0, tag: $0.level.rawValue) }, id: "free") }
                            ForEach(Design.Shelf.allCases) { shelf in
                                self.shelf(shelf.title, items: items(on: shelf))
                            }
                        }
                    } else if matches.isEmpty {
                        ContentUnavailableView.search(text: searching)
                    } else {
                        grid(matches)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
            .background(Theme.paper)
            .navigationTitle("Patterns")
            .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: Text("Hats, mittens, scarves"))
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

    private var searching: String { query.trimmingCharacters(in: .whitespaces) }

    private func shelf(_ title: String, items: [LibraryItem]) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(Theme.display(22, weight: .semibold))
                .accessibilityAddTraits(.isHeader)
            grid(items)
        }
    }

    private func grid(_ items: [LibraryItem]) -> some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 22) {
            ForEach(items) { item in
                NavigationLink(value: item) { tile(item, note: note(item)) }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("design.\(item.designRaw)")
            }
        }
    }

    /// The level, and for a design that needs no purchase, that too: a free tile still says how hard it is.
    private func note(_ item: LibraryItem) -> String {
        guard item.isFree else { return item.level.title }
        return "\(String(localized: "Free", comment: "Label under a design that needs no purchase")) · \(item.level.title)"
    }

    /// Every design in the library, in shelf order, once each.
    private var everything: [LibraryItem] {
        var seen = Set<String>()
        return Design.Shelf.allCases.flatMap(items(on:)).filter { seen.insert($0.id).inserted }
    }

    private var free: [LibraryItem] { everything.filter(\.isFree) }

    /// Designs that have every word searched for in their name, shelf, level or size names ("baby hat",
    /// "child mittens"), in the knitter's language or in English. "Kids" finds the child sizes.
    /// Typed the way people talk ("hat for kids", "a baby blanket"): small words are dropped, and if no design
    /// has every word, designs with any of them are shown rather than nothing.
    private var matches: [LibraryItem] {
        let skipped: Set<String> = ["a", "an", "the", "for", "to", "of", "and", "with", "my", "in", "on", "pattern", "patterns",
                                     // Sizes are letters or measurements, not genders: "men sweater" looks for sweaters.
                                     "men", "man", "mens", "women", "woman", "womens"]
        let words = searching.lowercased().split(whereSeparator: { $0 == " " || $0 == "," }).map { word -> String in
            let one = word.hasSuffix("s") && word.count > 3 ? String(word.dropLast()) : String(word)
            return ["kid": "child", "children": "child", "beanie": "hat", "newborn": "baby", "glove": "mitten"][one] ?? one
        }.filter { !skipped.contains($0) }
        guard !words.isEmpty else { return everything }
        let found = everything.map { item -> (LibraryItem, Int) in
            let sizes = item.base.sizes.flatMap { [$0.name, Loc.text($0.name)] }
            let free = item.isFree ? String(localized: "Free", comment: "Label under a design that needs no purchase") : ""
            // Blankets come in stroller, crib and throw sizes: a baby blanket is one of the first two.
            let baby = item.base.sizes.contains { ["Stroller", "Crib"].contains($0.name) } ? "baby" : ""
            let haystack = ([item.title, item.name, item.base.shelf.title, item.base.shelf.rawValue, item.level.title, free, baby] + sizes)
                .joined(separator: " ").lowercased()
            return (item, words.filter(haystack.contains).count)
        }
        let all = found.filter { $0.1 == words.count }.map(\.0)
        guard all.isEmpty else { return all }
        return found.filter { $0.1 > 0 }.sorted { $0.1 > $1.1 }.map(\.0)
    }

    /// A row that scrolls sideways: Trending (new designs and what suits the season) or the free patterns.
    private func row(_ title: LocalizedStringKey, _ entries: [Shelved], id: String) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(Theme.display(22, weight: .semibold))
                .accessibilityAddTraits(.isHeader)
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(alignment: .top, spacing: 16) {
                    ForEach(entries) { entry in
                        NavigationLink(value: entry.item) { tile(entry.item, note: Loc.text(entry.tag)) }
                            .buttonStyle(.plain)
                            .containerRelativeFrame(.horizontal) { width, _ in
                                typeSize.isAccessibilitySize ? min((width - 72) / 1.3, 420) : min((width - 72) / 2.3, 220)
                            }
                            .accessibilityIdentifier("\(id).\(entry.item.designRaw)")
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.horizontal, -20)
        }
    }

    /// Topical designs lead the shelf, each with its own tag, then the list from the site, which can name any
    /// design in the library, built-in or colorwork. Each design shows once, where it first appears.
    private var shelved: [Shelved] {
        let listed = trending.items.compactMap { trend -> Shelved? in
            let item = trend.design.map(LibraryItem.builtIn) ?? topical.item(trend.id).map(LibraryItem.topical)
            return item.map { Shelved(item: $0, tag: trend.tag) }
        }
        let all = topical.items.map { Shelved(item: .topical($0), tag: $0.tag) }
            + TopicalStore.collection.filter { $0.tag == "New" }.map { Shelved(item: .topical($0), tag: $0.tag) }
            + listed
        var seen = Set<String>()
        return all.filter { seen.insert($0.id).inserted }
    }

    private struct Shelved: Identifiable {
        var item: LibraryItem
        var tag: String
        var id: String { item.id }
    }

    /// A shelf's designs: the newest first, then the colorwork collection, the rest of the library's own,
    /// and the topical ones on its shapes, which already lead Trending.
    private func items(on shelf: Design.Shelf) -> [LibraryItem] {
        let own = Design.allCases.filter { $0.shelf == shelf }
        let newest: Set<Design> = [.dropShoulder, .pompomBonnet, .beret, .keyholeScarf, .slippers, .babyBooties]
        return own.filter(newest.contains).map(LibraryItem.builtIn)
            + TopicalStore.collection.filter { $0.base.shelf == shelf }.map(LibraryItem.topical)
            + own.filter { !newest.contains($0) }.map(LibraryItem.builtIn)
            + topical.items.filter { $0.base.shelf == shelf }.map(LibraryItem.topical)
    }

    private func tile(_ item: LibraryItem, note: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            // The knitted sample where there is one, so a tile shows what the piece really looks like.
            if let photo = item.photo {
                Color.clear
                    .aspectRatio(1, contentMode: .fit)
                    .overlay { Image(decorative: photo).resizable().scaledToFill() }
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            } else {
                Garment(silhouette: item.silhouette, yarn: item.yarn, colorwork: item.preview)
                    .padding(14)
                    .background(.primary.opacity(0.045), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                    // Decorative like the photo: the title under it names the tile.
                    .accessibilityHidden(true)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
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
    /// The project cast on from this page, and the size and gauge it was cast on at. Back on the page with
    /// the same numbers, the button opens that project again instead of casting on a second copy.
    @State private var cast: (project: Project, values: [String: Double], gauge: Gauge)?
    /// Every project, to find one already cast on from this design at these numbers on a later visit.
    @Query private var projects: [Project]
    @State private var showingPaywall = false
    /// Wide enough for the piece on the leading side and its settings beside it.
    @State private var wide = false
    private let subscription = SubscriptionService.shared

    init(item: LibraryItem) {
        self.item = item
        // Opens at the size and gauge last cast on from this design: the same child, the same yarn.
        let kept = Self.remembered(item)
        var start = kept?.values ?? item.base.defaultSize.values
        #if DEBUG
        // `-DesignSize Child` opens at a named size, for screenshots.
        if let name = UserDefaults.standard.string(forKey: "DesignSize"), let size = item.base.sizes.first(where: { $0.name == name }) { start = size.values }
        #endif
        _values = State(initialValue: start)
        _gauge = State(initialValue: kept?.gauge ?? item.defaultGauge)
    }

    private struct Remembered: Codable {
        var values: [String: Double]
        var gauge: Gauge
    }

    private static func remembered(_ item: LibraryItem) -> (values: [String: Double], gauge: Gauge)? {
        guard let data = UserDefaults.standard.data(forKey: "design.last.\(item.designRaw)"),
              let kept = try? JSONDecoder().decode(Remembered.self, from: data),
              Set(kept.values.keys) == Set(item.base.defaultSize.values.keys) else { return nil }
        return (kept.values, kept.gauge)
    }

    private func remember() {
        guard let data = try? JSONEncoder().encode(Remembered(values: values, gauge: gauge)) else { return }
        UserDefaults.standard.set(data, forKey: "design.last.\(item.designRaw)")
    }

    /// The design's name with the size picked, so three hats in three sizes are told apart in every list.
    private var projectName: String {
        guard let size = design.sizes.first(where: { $0.values == values }) else { return item.title }
        return "\(item.title), \(Loc.text(size.name))"
    }

    private var design: Design { item.base }

    private var plan: PatternPlan { item.plan(measures: values, gauge: gauge) }

    var body: some View {
        let plan = plan
        Group {
            if wide {
                // An iPad: the piece on the leading side, the settings and Cast On in a column beside it.
                HStack(spacing: 0) {
                    hero(plan, height: 420).frame(maxWidth: .infinity, maxHeight: .infinity).padding(.horizontal, 32)
                    ScrollView { settings(plan).padding(.horizontal, 28).padding(.vertical, 24) }
                        .safeAreaInset(edge: .bottom) { castOnBar }
                        .frame(width: 480)
                }
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 32) {
                        hero(plan, height: 210).frame(maxWidth: .infinity)
                        settings(plan)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 24)
                }
                .readableWidth(600)
                .safeAreaInset(edge: .bottom) { castOnBar.frame(maxWidth: 600) }
            }
        }
        .onGeometryChange(for: Bool.self) { $0.size.width >= Widths.sideBySide } action: { wide = $0 }
        .background(Theme.paper)
        .navigationTitle(item.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .navigationDestination(item: $opened) { ProjectView(project: $0) }
        .sheet(isPresented: $showingPaywall) { PaywallView() }
    }

    private func hero(_ plan: PatternPlan, height: CGFloat) -> some View {
        VStack(spacing: 14) {
            if let photo = item.photo {
                // A knitted sample: the finished thing, as it looks off the needles.
                Image(photo)
                    .resizable()
                    .aspectRatio(1, contentMode: .fit)
                    .frame(maxWidth: height * 1.7)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .accessibilityElement()
                    .accessibilityLabel(Text(verbatim: item.title))
                    .accessibilityAddTraits(.isImage)
            } else {
                Garment(silhouette: item.silhouette, yarn: item.yarn, colorwork: plan.palette == nil ? nil : plan)
                    .frame(height: height)
            }
            Text("\(item.level.title) · \(Sizing.yardage(plan.yards))")
                .font(.subheadline)
                .monospacedDigit()
                .foregroundStyle(Theme.secondary)
                .contentTransition(.numericText(value: Double(plan.yards)))
                .motion(.snappy, value: plan.yards)
        }
    }

    private func settings(_ plan: PatternPlan) -> some View {
        VStack(alignment: .leading, spacing: 32) {
            group("Size") {
                chips(design.sizes.map { ($0.name, Loc.text($0.name)) }, selected: design.sizes.first { $0.values == values }?.name) { name in
                    if let size = design.sizes.first(where: { $0.name == name }) { values = size.values }
                }
                ForEach(design.measures) { measure in
                    adjuster(Loc.text(measure.label), value: Binding(get: { values[measure.key] ?? measure.range.lowerBound }, set: { values[measure.key] = $0 }), range: measure.range, step: measure.step, length: true)
                }
            }

            group("Gauge") {
                chips(item.weights.map { ($0.label, $0.title) }, selected: item.weights.first { item.gauge(for: $0) == gauge }?.label) { label in
                    if let weight = item.weights.first(where: { $0.label == label }) { gauge = item.gauge(for: weight) }
                }
                adjuster(String(localized: "Stitches over \(Sizing.swatch())", comment: "Gauge: stitches counted across a swatch; the argument is its width such as 4 in or 10 cm"), value: $gauge.stitches, range: item.stitchRange, step: 0.5)
                adjuster(String(localized: "Rows over \(Sizing.swatch())", comment: "Gauge: rows counted down a swatch; the argument is its height such as 4 in or 10 cm"), value: $gauge.rows, range: item.rowRange, step: 1)
            }

            group("Materials") {
                Text(plan.finished).frame(maxWidth: .infinity, alignment: .leading)
                ForEach(plan.materials, id: \.self) { line in
                    Text(line).frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            if let preview = plan.preview() {
                // The opening rows at the knitter's own size and gauge, before anything is paid for or cast on.
                group("Pattern") {
                    ForEach(Array(preview.blocks.enumerated()), id: \.offset) { _, block in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(Loc.section(block.section)).font(.headline)
                            ForEach(Array(block.lines.enumerated()), id: \.offset) { _, line in
                                Text(line).frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    }
                    if !preview.later.isEmpty {
                        Text(verbatim: preview.later.map(Loc.section).joined(separator: ", "))
                            .foregroundStyle(Theme.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .accessibilityIdentifier("design.preview")
            }
        }
    }

    /// The project this page already cast on at the numbers now set, while it still exists.
    private var castHere: Project? {
        if let cast, cast.values == values, cast.gauge == gauge, !cast.project.isDeleted, cast.project.modelContext != nil { return cast.project }
        // Back from the library another day: an unfinished project from this design at the same size and yarn
        // opens again, rather than a second copy at row 0 that looks like a lost count.
        return projects.first { project in
            guard !project.isFinished, project.designRaw == item.designRaw, let source = project.plan?.source else { return false }
            return source.measures == values && source.gauge == gauge
        }
    }

    private var castOnTitle: LocalizedStringKey {
        // A pattern already cast on stays open after a trial lapses: it is the knitter's to keep.
        if castHere != nil { return "Open Project" }
        if !subscription.canOpen(item) { return "Unlock Patterns" }
        return item.fits(measures: values, gauge: gauge) ? "Cast On" : "Chart Does Not Fit This Gauge"
    }

    private var castOnBar: some View {
        let fits = !subscription.canOpen(item) || castHere != nil || item.fits(measures: values, gauge: gauge)
        return Button(action: castOn) {
            Text(castOnTitle)
                .font(.headline)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
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

    private func castOn() {
        // A second quick tap must not cast on twice, and coming back to the page reopens what was cast on,
        // with or without a subscription.
        guard opened == nil else { return }
        if let project = castHere {
            opened = project
            return
        }
        guard subscription.canOpen(item) else {
            showingPaywall = true
            return
        }
        let project = Project(name: projectName, color: item.yarn)
        var kept = plan
        kept.source = PlanSource(design: item.designRaw, measures: values, gauge: gauge, revision: item.revision)
        project.follow(kept, as: item.designRaw)
        project.needles = gauge.needle.label
        context.insert(project)
        try? context.save()
        cast = (project, values, gauge)
        remember()
        opened = project
    }

    private func group(_ title: LocalizedStringKey, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(Theme.display(22, weight: .semibold))
                .accessibilityAddTraits(.isHeader)
            content()
        }
    }

    /// Each chip is an id the code matches on and the title the knitter reads.
    private func chips(_ names: [(id: String, title: String)], selected: String?, pick: @escaping (String) -> Void) -> some View {
        Wrap(spacing: 8) {
                ForEach(names, id: \.id) { name in
                    let isOn = name.id == selected
                    Button { pick(name.id) } label: {
                        Text(name.title)
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
        // Right to left languages fill each line from the trailing edge.
        let reversed = subviews.layoutDirection == .rightToLeft
        for row in arrange(subviews, in: bounds.width) {
            var x = reversed ? bounds.maxX : bounds.minX
            for index in row.items {
                let size = subviews[index].sizeThatFits(.unspecified)
                if reversed { x -= size.width }
                subviews[index].place(at: CGPoint(x: x, y: bounds.minY + row.y), proposal: ProposedViewSize(size))
                x += reversed ? -spacing : size.width + spacing
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
