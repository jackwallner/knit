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
    @State private var bindingPhotos = false
    @State private var confirmingRemove = false
    /// Rows knitted since this project was opened.
    @State private var rowsThisVisit = 0

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
                    work(height: 112, tags: false, taps: true)
                        .overlay(alignment: .trailing) { countPill.padding(.trailing, 20).padding(.top, 22) }
                        .overlay(alignment: .leading) { undo.padding(.leading, 8).padding(.top, 22) }
                }
                .ignoresSafeArea(edges: .bottom)
            } else {
                VStack(spacing: 0) {
                    VStack(spacing: 18) {
                        Spacer(minLength: 0)
                        count(size: 128)
                        if project.isFinished { finishedMark } else { repeatDots }
                        Spacer(minLength: 0)
                    }
                    .containerRelativeFrame(.vertical) { length, _ in length * 0.4 }
                    work(height: nil, tags: true)
                }
                .overlay(alignment: .bottomLeading) { undo.padding(.leading, 8) }
                .ignoresSafeArea(edges: .bottom)
                .contentShape(Rectangle())
                .onTapGesture(perform: knit)
            }
        }
        .background(Theme.paper)
        .overlay { if bindingPhotos { ProgressView().controlSize(.large).padding(28).background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous)) } }
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
            Button("Reset Count", role: .destructive) { project.resetCount(following: plan) }
        }
        .confirmationDialog("Remove the pattern from this project?", isPresented: $confirmingRemove, titleVisibility: .visible) {
            Button("Remove Pattern", role: .destructive) { setPattern(nil) }
        }
        .alert("Rows in One Repeat", isPresented: $settingRepeat) {
            TextField("Rows", text: $repeatText).keyboardType(.numberPad)
            Button("Cancel", role: .cancel) {}
            Button("Set") {
                project.setRepeat(Int(repeatText) ?? 0)
                project.persist()
            }
        } message: {
            if project.rows > 0, project.repeatLength == 0 { Text("The repeat starts with your next row.") }
        }
        .alert(plan == nil ? "Row" : "Row in This Section", isPresented: $settingRow) {
            TextField("Row", text: $rowText).keyboardType(.numberPad)
            Button("Cancel", role: .cancel) {}
            Button("Set") { if let row = Int(rowText) { project.jump(to: row, following: plan) } }
        }
        .alert("That pattern could not be opened", isPresented: $importFailed) {}
        // Knitting hands are busy: keep the screen on while a project is open.
        .onAppear { UIApplication.shared.isIdleTimerDisabled = true }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
            project.persist()
            // Setting the work down after a good stretch of rows is a fair moment to ask for a rating.
            if rowsThisVisit >= 20 { ReviewPrompt().recordPositiveMoment() }
        }
    }

    private func knit() {
        let before = project.rows
        project.knit(following: plan)
        if project.rows > before { rowsThisVisit += 1 }
        announce()
    }

    private func back() {
        project.unknit(following: plan)
        announce()
    }

    /// What the count or the pattern now says, for VoiceOver.
    private var spoken: String {
        guard let plan else { return "Row \(project.rows)" }
        guard let spot = plan.position(at: project.rows) else { return "Finished" }
        return plan.steps[spot.step].text(at: spot.row)
    }

    /// Eyes on the knitting: VoiceOver reads each new row out without the knitter hunting for it.
    private func announce() {
        guard UIAccessibility.isVoiceOverRunning else { return }
        AccessibilityNotification.Announcement(spoken).post()
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
        .overlay(alignment: .bottomLeading) { undo.padding(.leading, 8) }
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
                let text = step.text(at: spot.row)
                // A long row, such as a sweater's divide, sets smaller so it stays whole at large text sizes.
                // The star stays on the line with "repeat from", never alone at the start of the next.
                Text(text.replacingOccurrences(of: "from *", with: "from\u{00A0}*"))
                    .font(Theme.display(text.count > 140 ? 20 : text.count > 70 ? 24 : 30))
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
    /// `taps`: the PDF strip counts its own taps. Elsewhere the whole screen does, so the fabric must not count too.
    private func work(height: CGFloat?, tags: Bool, rows: Int? = nil, taps: Bool = false) -> some View {
        Fabric(rows: Double(rows ?? project.rows), yarn: project.color, markEvery: !tags ? 0 : project.repeatLength > 0 ? project.repeatLength : 10)
            .animation(.smooth(duration: 0.32), value: project.rows)
            .frame(height: height)
            .frame(maxHeight: height == nil ? .infinity : nil)
            .background(Theme.paper)
            .contentShape(Rectangle())
            .onTapGesture { if taps { knit() } }
            .allowsHitTesting(taps)
            .accessibilityElement()
            .accessibilityAddTraits(.isButton)
            .accessibilityLabel("Add a row")
            .accessibilityValue(spoken)
            .accessibilityAction(.default, knit)
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
        HStack(spacing: 8) {
            if project.isFinished { Image(systemName: "checkmark").font(.headline).accessibilityLabel("Finished") }
            count(size: 34)
        }
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

    private var finishedMark: some View {
        Label("Finished", systemImage: "checkmark")
            .font(.title3)
            .foregroundStyle(.secondary)
    }

    /// Stays in place at row 0, unseen but still a button, so a second quick tap is taken here and
    /// cannot fall through to the fabric and knit a row. The touch area runs past the circle for the
    /// same reason: a near miss with yarn in hand must not count.
    private var undo: some View {
        Button(action: back) {
            Image(systemName: "arrow.uturn.backward")
                .font(.title3.weight(.semibold))
                .frame(width: 52, height: 52)
                .background(.regularMaterial, in: Circle())
                // Faded here, inside the touch area: a view at zero opacity takes no taps, the area around it still does.
                .opacity(project.rows == 0 ? 0 : 1)
                .padding(12)
                .contentShape(Rectangle())
        }
        .accessibilityLabel("Back one row")
        .accessibilityIdentifier("counter.minus")
        .animation(.snappy, value: project.rows == 0)
        .accessibilityHidden(project.rows == 0)
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
                Menu("Go to Section", systemImage: "list.number") {
                    ForEach(plan.sections, id: \.tap) { section in
                        Button(section.name) { project.jump(toTap: section.tap, following: plan) }
                    }
                }
            } else {
                Button(project.patternFile == nil ? "Add Pattern" : "Replace Pattern", systemImage: "doc") { importing = true }
                if project.patternFile == nil {
                    Button("Add Photos", systemImage: "photo") { pickingPhotos = true }
                } else {
                    Button("Remove Pattern", systemImage: "trash", role: .destructive) { confirmingRemove = true }
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
            // A library pattern at its last row is finished; stepping back a row is how it reopens.
            if plan.map({ project.rows < $0.totalTaps }) ?? true {
                Button(project.isFinished ? "Mark Active" : "Mark Finished", systemImage: project.isFinished ? "arrow.uturn.backward" : "checkmark") {
                    project.toggleFinished()
                    project.persist()
                }
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
        bindingPhotos = true
        Task {
            defer { bindingPhotos = false }
            // One photo at a time, each shrunk to reading size before the next loads.
            var pages: [Data] = []
            for item in picked {
                guard let data = try? await item.loadTransferable(type: Data.self) else { continue }
                if let page = await Task.detached(operation: { PatternStore.page(from: data) }).value { pages.append(page) }
            }
            guard let file = try? PatternStore.save(pages: pages) else {
                importFailed = true
                return
            }
            // The project may have been deleted while the photos loaded.
            guard project.modelContext != nil, !project.isDeleted else { return PatternStore.delete(file) }
            setPattern(file)
        }
    }

    private func setPattern(_ file: String?) {
        PatternStore.delete(project.patternFile)
        project.patternFile = file
        project.patternPage = 0
        project.markPage = -1
        project.persist()
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
