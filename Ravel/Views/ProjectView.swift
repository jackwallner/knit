import SwiftData
import SwiftUI
import UniformTypeIdentifiers

/// One project. The screen knits with you: tap anywhere on the work and a row
/// comes off the needle. With a pattern attached, the pattern takes the top and
/// the work becomes a strip along the bottom.
struct ProjectView: View {
    @Bindable var project: Project
    @State private var importing = false
    @State private var editing = false
    @State private var confirmingReset = false
    @State private var importFailed = false
    @State private var settingRepeat = false
    @State private var repeatText = ""

    private var patternURL: URL? { project.patternFile.map(PatternStore.url(for:)) }

    var body: some View {
        Group {
            if let patternURL {
                VStack(spacing: 0) {
                    PatternView(url: patternURL, project: project)
                    work(height: 112)
                        .overlay(alignment: .trailing) { countPill.padding(.trailing, 20).padding(.top, 22) }
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
                    work(height: nil)
                }
                .ignoresSafeArea(edges: .bottom)
                .contentShape(Rectangle())
                .onTapGesture(perform: knit)
            }
        }
        .background(Theme.paper)
        .overlay(alignment: .bottomLeading) { undo }
        .navigationTitle(project.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .toolbar { ToolbarItem(placement: .primaryAction) { menu } }
        .sensoryFeedback(.impact(weight: .light), trigger: project.rows)
        .fileImporter(isPresented: $importing, allowedContentTypes: [.pdf], onCompletion: attach)
        .sheet(isPresented: $editing) { ProjectDetailsView(project: project) }
        .confirmationDialog("Reset the count to 0?", isPresented: $confirmingReset, titleVisibility: .visible) {
            Button("Reset Count", role: .destructive) { project.rows = 0 }
        }
        .alert("Rows in One Repeat", isPresented: $settingRepeat) {
            TextField("Rows", text: $repeatText).keyboardType(.numberPad)
            Button("Cancel", role: .cancel) {}
            Button("Set") { project.repeatLength = min(max(Int(repeatText) ?? 0, 0), 200) }
        }
        .alert("That PDF could not be opened", isPresented: $importFailed) {}
        // Knitting hands are busy: keep the screen on while a project is open.
        .onAppear { UIApplication.shared.isIdleTimerDisabled = true }
        .onDisappear { UIApplication.shared.isIdleTimerDisabled = false }
    }

    private func knit() { project.increment() }

    /// The needle and the fabric hanging from it. Tapping it knits a row.
    private func work(height: CGFloat?) -> some View {
        Fabric(rows: Double(project.rows), yarn: project.color, markEvery: project.repeatLength > 0 ? project.repeatLength : 10)
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
        if project.repeatLength > 1, project.repeatLength <= 24 {
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
            Button { project.decrement() } label: {
                Image(systemName: "arrow.uturn.backward")
                    .font(.title3.weight(.semibold))
                    .frame(width: 52, height: 52)
                    .background(.regularMaterial, in: Circle())
            }
            .padding(.leading, 20)
            .padding(.bottom, 8)
            .accessibilityLabel("Back one row")
            .accessibilityIdentifier("counter.minus")
            .transition(.scale.combined(with: .opacity))
        }
    }

    private var menu: some View {
        Menu {
            Button("Details", systemImage: "square.and.pencil") { editing = true }
            Button(project.patternFile == nil ? "Add Pattern" : "Replace Pattern", systemImage: "doc") { importing = true }
            if project.patternFile != nil {
                Button("Remove Pattern", systemImage: "doc.badge.minus") { setPattern(nil) }
            }
            Button("Repeat", systemImage: "repeat") {
                repeatText = project.repeatLength > 0 ? String(project.repeatLength) : ""
                settingRepeat = true
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
