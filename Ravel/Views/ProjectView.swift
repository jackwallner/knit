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
    /// The fixed pattern when this project's design was corrected after it was cast on.
    @State private var correction: PatternPlan?
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
    @State private var namingTally = false
    @State private var tallyText = ""
    @State private var confirmingTallyRemove = false
    @Environment(\.openURL) private var openURL
    /// Rows knitted since this project was opened.
    @State private var rowsThisVisit = 0
    /// The space the project has, which picks its layout.
    @State private var size = CGSize.zero

    /// An iPad held sideways: the reading side (count, instruction or PDF) on the leading half, the work beside it.
    private var sideBySide: Bool { size.width >= Widths.sideBySide && size.width > size.height }
    /// An iPad sits further from the eye than a phone in the hand, so the count and the instruction set larger.
    private var far: Bool { min(size.width, size.height) >= Widths.farReading }

    private var patternURL: URL? { project.patternFile.map(PatternStore.url(for:)) }

    init(project: Project) {
        _project = Bindable(wrappedValue: project)
        _plan = State(initialValue: project.plan)
        _correction = State(initialValue: project.plan.flatMap(Design.correction(for:)))
    }

    var body: some View {
        Group {
            if let plan {
                guided(plan)
            } else if let patternURL {
                reader(patternURL)
            } else {
                counter
            }
        }
        .onGeometryChange(for: CGSize.self) { $0.size } action: { size = $0 }
        .safeAreaInset(edge: .top, spacing: 0) {
            VStack(spacing: 0) {
                if correction != nil { correctionBar }
                if project.tallyOn { tallyBar }
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
        .alert(inSection, isPresented: $settingRow) {
            TextField(isRound ? "Round" : "Row", text: $rowText).keyboardType(.numberPad)
            Button("Cancel", role: .cancel) {}
            Button("Set") { if let row = Int(rowText) { project.jump(to: row, following: plan) } }
        }
        .alert("Counter Name", isPresented: $namingTally) {
            TextField("Name", text: $tallyText).accessibilityLabel("Name").accessibilityIdentifier("tally.nameField")
            Button("Cancel", role: .cancel) {}
            Button(project.tallyOn ? LocalizedStringKey("Rename") : LocalizedStringKey("Add")) {
                if project.tallyOn { project.renameTally(tallyText) } else { project.addTally(named: tallyText) }
            }
        }
        .confirmationDialog("Remove the counter?", isPresented: $confirmingTallyRemove, titleVisibility: .visible) {
            Button("Remove Counter", role: .destructive) { project.removeTally() }
        }
        .alert("That pattern could not be opened", isPresented: $importFailed) {}
        // Knitting hands are busy: keep the screen on while a project is open.
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = true
            #if DEBUG
            // `-OpenDetails` opens the details sheet, for screenshots.
            if ProcessInfo.processInfo.arguments.contains("-OpenDetails") { editing = true }
            #endif
        }
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

    private func tally(_ step: Int) {
        project.tally(by: step)
        guard UIAccessibility.isVoiceOverRunning else { return }
        AccessibilityNotification.Announcement("\(project.tallyTitle) \(project.tallyCount)").post()
    }

    private func back() {
        project.unknit(following: plan)
        announce()
    }

    /// True while a library pattern is worked in the round, so labels say Round and not Row.
    private var isRound: Bool { plan?.unit(at: project.rows) == "Round" }

    private var inSection: LocalizedStringKey { isRound ? "Round in This Section" : "Row in This Section" }

    /// What the count or the pattern now says, for VoiceOver.
    private var spoken: String {
        guard let plan else { return String(localized: "Row \(project.rows)", comment: "VoiceOver: the row count") }
        guard let spot = plan.position(at: project.rows) else { return String(localized: "Finished") }
        return plan.steps[spot.step].text(at: spot.row)
    }

    /// Eyes on the knitting: VoiceOver reads each new row out without the knitter hunting for it.
    private func announce() {
        guard UIAccessibility.isVoiceOverRunning else { return }
        AccessibilityNotification.Announcement(spoken).post()
    }

    /// A finished project is the moment to ask for a rating, once the screen has settled.
    /// Offered, never applied on its own: the knitter keeps their place on the corrected pattern.
    private var correctionBar: some View {
        HStack(spacing: 12) {
            Text("This pattern was corrected")
                .font(.subheadline.weight(.medium))
                .frame(maxWidth: .infinity, alignment: .leading)
            Button("Update") {
                guard let correction else { return }
                project.adopt(correction)
                plan = project.plan
                self.correction = nil
            }
            .font(.subheadline.weight(.semibold))
            .frame(minHeight: 44)
            .accessibilityIdentifier("guide.update")
        }
        .padding(.horizontal, 20)
        .background(.primary.opacity(0.05))
    }

    private func report(_ plan: PatternPlan) {
        guard let url = PatternReport.mail(plan: plan, design: project.designRaw ?? "", title: project.name, taps: project.rows) else { return }
        openURL(url) { opened in if !opened { openURL(Links.support) } }
    }

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

    /// A plain counter: the count over the work, or beside it on an iPad held sideways. Tap anywhere for a row.
    private var counter: some View {
        let readout = VStack(spacing: 18) {
            count(size: far ? 200 : 128)
            if project.isFinished { finishedMark } else { repeatDots }
        }
        return Group {
            if sideBySide {
                HStack(spacing: 0) {
                    readout.frame(maxWidth: .infinity, maxHeight: .infinity)
                    work(height: nil, tags: true).frame(width: (size.width * 0.5).rounded())
                }
            } else {
                VStack(spacing: 0) {
                    VStack(spacing: 18) {
                        Spacer(minLength: 0)
                        readout
                        Spacer(minLength: 0)
                    }
                    .containerRelativeFrame(.vertical) { length, _ in length * 0.4 }
                    work(height: nil, tags: true)
                }
            }
        }
        .overlay(alignment: .bottomLeading) { undo.padding(.leading, 8) }
        .ignoresSafeArea(edges: .bottom)
        .contentShape(Rectangle())
        .onTapGesture(perform: knit)
    }

    /// A PDF pattern. On a phone the work is a strip under the page; on an iPad held sideways the page
    /// takes the leading side and a counter of its own stands beside it, the whole of it one tap target.
    @ViewBuilder
    private func reader(_ url: URL) -> some View {
        if sideBySide {
            HStack(spacing: 0) {
                PatternView(url: url, project: project)
                Rectangle().fill(.primary.opacity(0.08)).frame(width: 1)
                VStack(spacing: 0) {
                    VStack(spacing: 14) {
                        count(size: 96)
                        if project.isFinished { finishedMark } else { repeatDots }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 28)
                    work(height: nil, tags: true)
                }
                .frame(width: min(440, (size.width * 0.34).rounded()))
                .overlay(alignment: .bottomLeading) { undo.padding(.leading, 8) }
                .contentShape(Rectangle())
                .onTapGesture(perform: knit)
            }
            .ignoresSafeArea(edges: .bottom)
        } else {
            VStack(spacing: 0) {
                PatternView(url: url, project: project)
                work(height: 112, tags: false, taps: true)
                    .overlay(alignment: .trailing) { countPill.padding(.trailing, 20).padding(.top, 22) }
                    .overlay(alignment: .leading) { undo.padding(.leading, 8).padding(.top, 22) }
            }
            .ignoresSafeArea(edges: .bottom)
        }
    }

    /// A library pattern: the instruction for this row over the work, or beside it on an iPad held sideways.
    /// Tap anywhere for the next row.
    private func guided(_ plan: PatternPlan) -> some View {
        // The piece and its instruction sit together as one group, centered in the space it has.
        let reading = VStack(spacing: far ? 32 : 20) {
            // The piece itself, filling with fabric as the pattern goes on: where the knitter is in the whole.
            if let silhouette = project.silhouette(plan) {
                Garment(silhouette: silhouette, yarn: project.color,
                        progress: plan.totalTaps > 0 ? Double(project.rows) / Double(plan.totalTaps) : 0,
                        colorwork: plan.palette == nil ? nil : plan)
                    .frame(width: far ? 200 : 120, height: far ? 200 : 120)
                    .motion(.smooth, value: project.rows)
            }
            instruction(plan).layoutPriority(1)
        }
        // A line of pattern stays a readable length on a wide screen.
        .frame(maxWidth: 640)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, far ? 40 : 24)
        .padding(.top, 8)
        let fabric = work(height: nil, tags: true, rows: plan.knitRows(upTo: project.rows))
        return Group {
            if sideBySide {
                HStack(spacing: 0) {
                    reading.padding(.bottom, 8)
                    fabric.frame(width: (size.width * 0.45).rounded())
                }
            } else {
                VStack(spacing: 0) {
                    reading.containerRelativeFrame(.vertical) { length, _ in length * 0.46 }
                    fabric
                }
            }
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
            let said = step.text(at: spot.row)
            let detail = [
                step.rows > 1 ? String(localized: "\(spot.row + 1) of \(step.rows)", comment: "Position in a run of rows: 3 of 40") : nil,
                // Not repeated when the instruction already says it ("Cast on 32 stitches.").
                step.stitches(after: spot.row).flatMap { said.contains("\($0) st") ? nil : String(localized: "\($0) stitches", comment: "Stitches on the needle after this row") },
            ].compactMap { $0 }.joined(separator: " · ")
            VStack(spacing: 16) {
                Text(Loc.section(step.section))
                    .font(far ? .subheadline.weight(.semibold) : .footnote.weight(.semibold))
                    .textCase(.uppercase)
                    .tracking(1.4)
                    .foregroundStyle(Theme.secondary)
                let text = step.text(at: spot.row)
                // A long row, such as a sweater's divide, sets smaller so it stays whole at large text sizes.
                // The star stays on the line with "repeat from", never alone at the start of the next.
                Text(text.replacingOccurrences(of: "from *", with: "from\u{00A0}*"))
                    .font(Theme.display((text.count > 140 ? 20 : text.count > 70 ? 24 : 30) * (far ? 1.4 : 1)))
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.4)
                    .accessibilityIdentifier("guide.instruction")
                Text(detail)
                    .font(far ? .title3 : .subheadline)
                    .monospacedDigit()
                    .foregroundStyle(Theme.secondary)
                    .contentTransition(.numericText(value: Double(spot.row)))
                    .accessibilityIdentifier("guide.detail")
            }
            .frame(maxWidth: .infinity)
            .motion(.snappy, value: project.rows)
        } else {
            Text("Finished")
                .font(Theme.display(far ? 60 : 44))
                .frame(maxWidth: .infinity)
        }
    }

    /// The second counter: a slim bar under the title with its own name, count and plus and minus.
    /// It sits outside the tap area, so a press here never knits a row.
    private var tallyBar: some View {
        let title = project.tallyTitle
        let takeOff = String(localized: "Take one off \(title)", comment: "VoiceOver: minus button of the second counter; the argument is its name")
        let addTo = String(localized: "Add one to \(title)", comment: "VoiceOver: plus button of the second counter; the argument is its name")
        return ViewThatFits(in: .horizontal) {
            HStack(spacing: 4) {
                tallyButton("minus", takeOff, id: "tally.minus", step: -1)
                tallyReadout(title).frame(maxWidth: .infinity)
                tallyButton("plus", addTo, id: "tally.plus", step: 1)
            }
            VStack(spacing: 4) {
                tallyReadout(title)
                HStack(spacing: 4) {
                    tallyButton("minus", takeOff, id: "tally.minus", step: -1)
                    Spacer(minLength: 0)
                    tallyButton("plus", addTo, id: "tally.plus", step: 1)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
        // Plus and minus stay within reach of each other on a wide screen.
        .frame(maxWidth: 520)
        .frame(maxWidth: .infinity)
        .background(Theme.paper)
        .sensoryFeedback(.impact(weight: .light), trigger: project.tallyCount)
    }

    private func tallyReadout(_ title: String) -> some View {
        HStack(spacing: 10) {
            Text(title).font(.subheadline).foregroundStyle(Theme.secondary).lineLimit(1)
            Text(project.tallyCount, format: .number)
                .font(Theme.display(24, weight: .regular))
                .monospacedDigit()
                .contentTransition(.numericText(value: Double(project.tallyCount)))
                .motion(.snappy, value: project.tallyCount)
                .accessibilityIdentifier("tally.value")
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityValue("\(project.tallyCount)")
    }

    private func tallyButton(_ symbol: String, _ label: String, id: String, step: Int) -> some View {
        Button { tally(step) } label: {
            Image(systemName: symbol)
                .font(.body.weight(.semibold))
                .frame(width: 44, height: 44)
                .background(.primary.opacity(0.07), in: Circle())
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .accessibilityIdentifier(id)
        .disabled(step < 0 && project.tallyCount == 0)
    }

    /// The needle and the fabric hanging from it. Tapping it knits a row.
    /// `taps`: the PDF strip counts its own taps. Elsewhere the whole screen does, so the fabric must not count too.
    private func work(height: CGFloat?, tags: Bool, rows: Int? = nil, taps: Bool = false) -> some View {
        // The full-screen work knits in big stitches over a ruled chart; the PDF strip stays small and plain.
        Fabric(rows: Double(rows ?? project.rows), yarn: project.color, markEvery: !tags ? 0 : project.repeatLength > 0 ? project.repeatLength : 10,
               markFrom: plan == nil ? project.repeatStart : 0, stitch: height == nil ? 0 : 24, chart: height == nil,
               paints: plan?.paints() ?? [], palette: plan?.palette ?? [], focus: plan?.front ?? 0.5)
            .motion(.smooth(duration: 0.32), value: project.rows)
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
            .motion(.snappy, value: project.rows)
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
            .background(Theme.paper.opacity(0.94), in: Capsule())
            .allowsHitTesting(false)
    }

    /// One dot per row of the repeat, filled up to the row just finished.
    @ViewBuilder
    private var repeatDots: some View {
        if project.repeatLength > 24 {
            Text("\(project.repeatPosition) of \(project.repeatLength)")
                .font(.title3)
                .monospacedDigit()
                .foregroundStyle(Theme.secondary)
                .contentTransition(.numericText(value: Double(project.repeatPosition)))
                .motion(.snappy, value: project.repeatPosition)
                .frame(minWidth: 44, minHeight: 44)
                .contentShape(Rectangle())
                .accessibilityLabel("Row \(project.repeatPosition) of \(project.repeatLength) in the repeat")
        } else if project.repeatLength > 1 {
            HStack(spacing: 6) {
                ForEach(1...project.repeatLength, id: \.self) { row in
                    Circle()
                        .fill(row <= project.repeatPosition ? AnyShapeStyle(project.color.color) : AnyShapeStyle(.primary.opacity(0.14)))
                        .frame(width: 8, height: 8)
                }
            }
            .motion(.snappy, value: project.repeatPosition)
            .frame(minWidth: 44, minHeight: 44)
            .contentShape(Rectangle())
            .accessibilityElement()
            .accessibilityLabel("Row \(project.repeatPosition) of \(project.repeatLength) in the repeat")
        }
    }

    private var finishedMark: some View {
        Label("Finished", systemImage: "checkmark")
            .font(.title3)
            .foregroundStyle(Theme.secondary)
    }

    /// Stays in place with nothing to take back, unseen but still a button, so a second quick tap is taken here and
    /// cannot fall through to the fabric and knit a row. The touch area runs past the circle for the
    /// same reason: a near miss with yarn in hand must not count.
    private var undo: some View {
        Button(action: back) {
            Image(systemName: "arrow.uturn.backward")
                .font(.title3.weight(.semibold))
                .frame(width: 52, height: 52)
                .background(.regularMaterial, in: Circle())
                // Faded here, inside the touch area: a view at zero opacity takes no taps, the area around it still does.
                .opacity(canUndo ? 1 : 0)
                .padding(12)
                .contentShape(Rectangle())
        }
        .accessibilityLabel("Back one row")
        .accessibilityIdentifier("counter.minus")
        .motion(.snappy, value: canUndo)
        .accessibilityHidden(!canUndo)
    }

    /// Nothing to take back at row 0, or on a finished project with no pattern, which no longer counts.
    private var canUndo: Bool { project.rows > 0 && (plan != nil || !project.isFinished) }

    private var menu: some View {
        Menu {
            Button("Details", systemImage: "square.and.pencil") { editing = true }
            if let plan {
                Button("Materials", systemImage: "list.bullet") { showingMaterials = true }
                if let spot = plan.position(at: project.rows), plan.steps[spot.step].rows > 1 {
                    Button(isRound ? "Go to Round" : "Go to Row", systemImage: "number") {
                        rowText = ""
                        settingRow = true
                    }
                }
                Menu("Go to Section", systemImage: "list.number") {
                    ForEach(plan.sections, id: \.tap) { section in
                        Button(Loc.section(section.name)) { project.jump(toTap: section.tap, following: plan) }
                    }
                }
                Button("Report a Problem", systemImage: "exclamationmark.bubble") { report(plan) }
                    .accessibilityIdentifier("guide.report")
            } else {
                // One import at a time: a second would race the first for the project's pattern.
                Group {
                    Button(project.patternFile == nil ? "Add Pattern" : "Replace Pattern", systemImage: "doc") { importing = true }
                    if project.patternFile == nil {
                        Button("Add Photos", systemImage: "photo") { pickingPhotos = true }
                    } else {
                        Button("Remove Pattern", systemImage: "trash", role: .destructive) { confirmingRemove = true }
                    }
                }
                .disabled(bindingPhotos)
                Button("Set Row", systemImage: "number") {
                    rowText = ""
                    settingRow = true
                }
                Button("Repeat", systemImage: "repeat") {
                    repeatText = project.repeatLength > 0 ? String(project.repeatLength) : ""
                    settingRepeat = true
                }
            }
            if project.tallyOn {
                Menu("Counter", systemImage: "plusminus.circle") {
                    Button("Rename", systemImage: "pencil") {
                        tallyText = project.tallyName
                        namingTally = true
                    }
                    .accessibilityIdentifier("tally.rename")
                    Button("Reset to 0", systemImage: "arrow.counterclockwise") { project.resetTally() }
                        .disabled(project.tallyCount == 0)
                        .accessibilityIdentifier("tally.reset")
                    Button("Remove", systemImage: "trash", role: .destructive) {
                        if project.tallyCount > 0 { confirmingTallyRemove = true } else { project.removeTally() }
                    }
                    .accessibilityIdentifier("tally.remove")
                }
            } else {
                Button("Add Counter", systemImage: "plusminus.circle") {
                    tallyText = ""
                    namingTally = true
                }
                .accessibilityIdentifier("tally.add")
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
        bindingPhotos = true
        Task {
            defer { bindingPhotos = false }
            // A picture is cut to reading size on the way in, which is too slow for the main thread.
            guard let file = await Task.detached(operation: { try? PatternStore.save(from: url) }).value else {
                importFailed = true
                return
            }
            guard project.modelContext != nil, !project.isDeleted else { return PatternStore.delete(file) }
            setPattern(file)
        }
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
    @Query(sort: \Yarn.name) private var stash: [Yarn]

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
                    LabeledContent("Yarn") {
                        HStack(spacing: 4) {
                            if let linked = project.stashYarn {
                                Text(linked.label).multilineTextAlignment(.trailing).accessibilityIdentifier("project.yarnName")
                            } else {
                                TextField("", text: $project.yarn).multilineTextAlignment(.trailing)
                                    .accessibilityIdentifier("project.yarnField")
                            }
                            if !stash.isEmpty { yarnMenu }
                        }
                    }
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

    /// Picks the yarn from the stash. The typed name is kept underneath, for the day the link is taken off.
    private var yarnMenu: some View {
        Menu {
            ForEach(stash) { yarn in
                Button { link(yarn) } label: {
                    if project.stashYarn === yarn { Label(yarn.label, systemImage: "checkmark") } else { Text(yarn.label) }
                }
            }
            if project.stashYarn != nil {
                Button("Not from Stash", systemImage: "xmark") { link(nil) }
            }
        } label: {
            Image(systemName: "tray.full").frame(minWidth: 44, minHeight: 44)
        }
        .accessibilityLabel("Choose yarn from stash")
        .accessibilityIdentifier("project.yarnPicker")
    }

    private func link(_ yarn: Yarn?) {
        project.stashYarn = yarn
        project.persist()
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
                                Text(Loc.text(entry.meaning)).foregroundStyle(Theme.secondary)
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
