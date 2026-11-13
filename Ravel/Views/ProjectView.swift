import PhotosUI
import StoreKit
import SwiftData
import SwiftUI
import UniformTypeIdentifiers

/// One project. The screen knits with you: tap anywhere on the work and a row
/// comes off the needle. With a pattern attached, the pattern takes the top and
/// the work becomes a strip along the bottom. A project cast on from the library
/// reads its own instructions out, one row a tap.
struct ProjectView: View {
    @Bindable var project: Project
    @Environment(\.requestReview) private var requestReview
    @State private var plan: PatternPlan?
    @State private var showingMaterials = false
    @State private var importing = false
    @State private var editing = false
    @State private var confirmingReset = false
    @State private var importFailed = false
    @State private var settingRepeat = false
    @State private var repeatText = ""
    @State private var settingRow = false
    @State private var rowText = ""
    @State private var pickingPhotos = false
    @State private var photos: [PhotosPickerItem] = []

    private var patternURL: URL? { project.patternFile.map(PatternStore.url(for:)) }

    init(project: Project) {
        _project = Bindable(wrappedValue: project)
        _plan = State(initialValue: project.plan)
    }

    var body: some View {
        Group {
            if let plan {
                guided(plan)
            } else if let patternURL {
                VStack(spacing: 0) {
                    PatternView(url: patternURL, project: project)
                    work(height: 112, tags: false)
                        .overlay(alignment: .trailing) { countPill.padding(.trailing, 20).padding(.top, 22) }
                        .overlay(alignment: .leading) { undo.padding(.leading, 20).padding(.top, 22) }
                }
                .ignoresSafeArea(edges: .bottom)
            } else {
                VStack(spacing: 0) {
                    VStack(spacing: 18) {
                        Spacer(minLength: 0)
                        count(size: 128)
                        repeatDots
                        Spacer(minLength: 0)
                    }
                    .containerRelativeFrame(.vertical) { length, _ in length * 0.4 }
                    work(height: nil, tags: true)
                }
                .overlay(alignment: .bottomLeading) { undo.padding(.leading, 20).padding(.bottom, 8) }
                .ignoresSafeArea(edges: .bottom)
                .contentShape(Rectangle())
                .onTapGesture(perform: knit)
            }
        }
        .background(Theme.paper)
        .navigationTitle(project.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .toolbar { ToolbarItem(placement: .primaryAction) { menu } }
        .sensoryFeedback(.impact(weight: .light), trigger: project.rows)
        .fileImporter(isPresented: $importing, allowedContentTypes: [.pdf, .image], onCompletion: attach)
        .photosPicker(isPresented: $pickingPhotos, selection: $photos, maxSelectionCount: 20, matching: .images)
        .onChange(of: photos) { _, picked in if !picked.isEmpty { attach(picked) } }
        .sheet(isPresented: $editing) { ProjectDetailsView(project: project) }
        .sheet(isPresented: $showingMaterials) { if let plan { MaterialsView(plan: plan) } }
        .onChange(of: project.isFinished) { _, finished in if finished { celebrate() } }
        .confirmationDialog("Reset the count to 0?", isPresented: $confirmingReset, titleVisibility: .visible) {
            Button("Reset Count", role: .destructive) { project.rows = 0 }
        }
        .alert("Rows in One Repeat", isPresented: $settingRepeat) {
            TextField("Rows", text: $repeatText).keyboardType(.numberPad)
            Button("Cancel", role: .cancel) {}
            Button("Set") { project.repeatLength = min(max(Int(repeatText) ?? 0, 0), 200) }
        }
        .alert(plan == nil ? "Row" : "Row in This Section", isPresented: $settingRow) {
            TextField("Row", text: $rowText).keyboardType(.numberPad)
            Button("Cancel", role: .cancel) {}
            Button("Set") { if let row = Int(rowText) { jump(to: row) } }
        }
        .alert("That pattern could not be opened", isPresented: $importFailed) {}
        // Knitting hands are busy: keep the screen on while a project is open.
        .onAppear { UIApplication.shared.isIdleTimerDisabled = true }
        .onDisappear { UIApplication.shared.isIdleTimerDisabled = false }
    }

    private func knit() {
        guard let plan else { return project.increment() }
        guard project.rows < plan.totalTaps else { return }
        project.increment()
        if project.rows == plan.totalTaps, !project.isFinished { project.toggleFinished() }
    }

    /// Lands on a row without tapping up to it. In a library pattern the row is counted within the current section.
    private func jump(to row: Int) {
        guard let plan else { return project.setRows(row) }
        guard let spot = plan.position(at: project.rows) else { return }
        let start = project.rows - spot.row
        project.setRows(start + min(max(row, 1), plan.steps[spot.step].rows) - 1)
    }

    private func back() {
        project.decrement()
        // Stepping back from the last row of a library pattern puts it on the needles again.
        if let plan, project.isFinished, project.rows < plan.totalTaps { project.toggleFinished() }
    }

    /// A finished project is the moment to ask for a rating, once the screen has settled.
    private func celebrate() {
        let prompt = ReviewPrompt()
        prompt.recordPositiveMoment()
        Task {
            try? await Task.sleep(for: .seconds(3))
            guard !editing, !showingMaterials, !confirmingReset, prompt.shouldAsk() else { return }
            prompt.markAsked()
            requestReview()
        }
    }

    /// A library pattern: the instruction for this row on top, the work below. Tap anywhere for the next row.
    private func guided(_ plan: PatternPlan) -> some View {
        VStack(spacing: 0) {
            instruction(plan)
                .padding(.horizontal, 24)
                .containerRelativeFrame(.vertical) { length, _ in length * 0.46 }
            work(height: nil, tags: true, rows: plan.knitRows(upTo: project.rows))
        }
        .overlay(alignment: .top) {
            Rectangle()
                .fill(project.color.color)
                .frame(height: 3)
                .scaleEffect(x: plan.totalTaps > 0 ? CGFloat(project.rows) / CGFloat(plan.totalTaps) : 0, anchor: .leading)
                .animation(.smooth, value: project.rows)
                .accessibilityHidden(true)
        }
        .overlay(alignment: .bottomLeading) { undo.padding(.leading, 20).padding(.bottom, 8) }
        .ignoresSafeArea(edges: .bottom)
        .contentShape(Rectangle())
        .onTapGesture(perform: knit)
    }

    @ViewBuilder
    private func instruction(_ plan: PatternPlan) -> some View {
        if let spot = plan.position(at: project.rows) {
            let step = plan.steps[spot.step]
            let detail = [
                step.rows > 1 ? "\(spot.row + 1) of \(step.rows)" : nil,
                step.stitches(after: spot.row).map { "\($0) stitches" },
            ].compactMap { $0 }.joined(separator: " · ")
            VStack(spacing: 16) {
                Text(step.section)
                    .font(.footnote.weight(.semibold))
                    .textCase(.uppercase)
                    .tracking(1.4)
                    .foregroundStyle(.secondary)
                Text(step.text(at: spot.row))
                    .font(Theme.display(30))
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.4)
                    .accessibilityIdentifier("guide.instruction")
                Text(detail)
                    .font(.subheadline)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                    .contentTransition(.numericText(value: Double(spot.row)))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .animation(.snappy, value: project.rows)
        } else {
            Text("Finished")
                .font(Theme.display(44))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    /// The needle and the fabric hanging from it. Tapping it knits a row.
    private func work(height: CGFloat?, tags: Bool, rows: Int? = nil) -> some View {
        Fabric(rows: Double(rows ?? project.rows), yarn: project.color, markEvery: !tags ? 0 : project.repeatLength > 0 ? project.repeatLength : 10)
            .animation(.smooth(duration: 0.32), value: project.rows)
            .frame(height: height)
            .frame(maxHeight: height == nil ? .infinity : nil)
            .background(Theme.paper)
            .contentShape(Rectangle())
            .onTapGesture(perform: knit)
            .accessibilityElement()
            .accessibilityAddTraits(.isButton)
            .accessibilityLabel("Add a row")
            .accessibilityIdentifier("counter.plus")
    }

    private func count(size: CGFloat) -> some View {
        Text(project.rows, format: .number)
            .font(Theme.display(size, weight: .regular))
            .monospacedDigit()
            .minimumScaleFactor(0.4)
            .lineLimit(1)
            .contentTransition(.numericText(value: Double(project.rows)))
            .animation(.snappy, value: project.rows)
            .accessibilityLabel("Row \(project.rows)")
            .accessibilityIdentifier("counter.value")
    }

    private var countPill: some View {
        count(size: 34)
            .padding(.horizontal, 18)
            .frame(minWidth: 64, minHeight: 52)
            .background(.regularMaterial, in: Capsule())
            .allowsHitTesting(false)
    }

    /// One dot per row of the repeat, filled up to the row just finished.
    @ViewBuilder
    private var repeatDots: some View {
        if project.repeatLength > 24 {
            Text("\(project.repeatPosition) of \(project.repeatLength)")
                .font(.title3)
                .monospacedDigit()
                .foregroundStyle(.secondary)
                .contentTransition(.numericText(value: Double(project.repeatPosition)))
                .animation(.snappy, value: project.repeatPosition)
                .accessibilityLabel("Row \(project.repeatPosition) of \(project.repeatLength) in the repeat")
        } else if project.repeatLength > 1 {
            HStack(spacing: 6) {
                ForEach(1...project.repeatLength, id: \.self) { row in
                    Circle()
                        .fill(row <= project.repeatPosition ? AnyShapeStyle(project.color.color) : AnyShapeStyle(.primary.opacity(0.14)))
                        .frame(width: 8, height: 8)
                }
            }
            .animation(.snappy, value: project.repeatPosition)
            .accessibilityElement()
            .accessibilityLabel("Row \(project.repeatPosition) of \(project.repeatLength) in the repeat")
        }
    }

    @ViewBuilder
    private var undo: some View {
        if project.rows > 0 {
            Button(action: back) {
                Image(systemName: "arrow.uturn.backward")
                    .font(.title3.weight(.semibold))
                    .frame(width: 52, height: 52)
                    .background(.regularMaterial, in: Circle())
            }
            .accessibilityLabel("Back one row")
            .accessibilityIdentifier("counter.minus")
            .transition(.scale.combined(with: .opacity))
        }
    }

    private var menu: some View {
        Menu {
            Button("Details", systemImage: "square.and.pencil") { editing = true }
            if let plan {
                Button("Materials", systemImage: "list.bullet") { showingMaterials = true }
                if let spot = plan.position(at: project.rows), plan.steps[spot.step].rows > 1 {
                    Button("Go to Row", systemImage: "number") {
                        rowText = ""
                        settingRow = true
                    }
                }
            } else {
                Button(project.patternFile == nil ? "Add Pattern" : "Replace Pattern", systemImage: "doc") { importing = true }
                if project.patternFile == nil {
                    Button("Add Photos", systemImage: "photo") { pickingPhotos = true }
                } else {
                    Button("Remove Pattern", systemImage: "trash") { setPattern(nil) }
                }
                Button("Set Row", systemImage: "number") {
                    rowText = ""
                    settingRow = true
                }
                Button("Repeat", systemImage: "repeat") {
                    repeatText = project.repeatLength > 0 ? String(project.repeatLength) : ""
                    settingRepeat = true
                }
            }
            Button(project.isFinished ? "Mark Active" : "Mark Finished", systemImage: project.isFinished ? "arrow.uturn.backward" : "checkmark") {
                project.toggleFinished()
            }
            Button("Reset Count", systemImage: "arrow.counterclockwise", role: .destructive) { confirmingReset = true }
                .disabled(project.rows == 0)
        } label: {
            Image(systemName: "ellipsis")
        }
        .accessibilityLabel("Project options")
        .accessibilityIdentifier("project.menu")
    }

    private func attach(_ result: Result<URL, Error>) {
        guard case let .success(url) = result else { return }
        do { setPattern(try PatternStore.save(from: url)) } catch { importFailed = true }
    }

    /// Photos of a printed pattern become its pages, in the order they were picked.
    private func attach(_ picked: [PhotosPickerItem]) {
        photos = []
        Task {
            var pages: [UIImage] = []
            for item in picked {
                if let data = try? await item.loadTransferable(type: Data.self), let image = UIImage(data: data) { pages.append(image) }
            }
            do { setPattern(try PatternStore.save(pages: pages)) } catch { importFailed = true }
        }
    }

    private func setPattern(_ file: String?) {
        PatternStore.delete(project.patternFile)
        project.patternFile = file
        project.patternPage = 0
        project.markPage = -1
    }
}

struct ProjectDetailsView: View {
    @Bindable var project: Project
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $project.name)
                    HStack(spacing: 0) {
                        ForEach(YarnColor.allCases) { yarn in
                            Button { project.color = yarn } label: {
                                Circle()
                                    .fill(yarn.color)
                                    .frame(width: 28, height: 28)
                                    .overlay { Circle().strokeBorder(.primary, lineWidth: project.color == yarn ? 2.5 : 0).padding(-5) }
                                    .frame(maxWidth: .infinity, minHeight: 44)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(yarn.label)
                            .accessibilityAddTraits(project.color == yarn ? .isSelected : [])
                        }
                    }
                }
                Section {
                    LabeledContent("Yarn") { TextField("", text: $project.yarn).multilineTextAlignment(.trailing) }
                    LabeledContent("Needles") { TextField("", text: $project.needles).multilineTextAlignment(.trailing) }
                }
                Section {
                    TextField("Notes", text: $project.notes, axis: .vertical)
                        .lineLimit(4...)
                }
            }
            .navigationTitle("Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
        }
    }
}

/// What a library pattern needs, its finished size, and its abbreviations spelled out.
struct MaterialsView: View {
    let plan: PatternPlan
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text(plan.finished)
                    ForEach(plan.materials, id: \.self) { Text($0) }
                }
                if !plan.abbreviations.isEmpty {
                    Section("Abbreviations") {
                        ForEach(plan.abbreviations, id: \.term) { entry in
                            VStack(alignment: .leading, spacing: 2) {
                                Text(entry.term).font(.headline)
                                Text(entry.meaning).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Materials")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
        }
    }
}
