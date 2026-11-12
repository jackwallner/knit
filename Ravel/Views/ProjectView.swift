import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct ProjectView: View {
    @Bindable var project: Project
    @State private var importing = false
    @State private var editing = false
    @State private var confirmingReset = false
    @State private var importFailed = false

    private var patternURL: URL? { project.patternFile.map(PatternStore.url(for:)) }

    var body: some View {
        Group {
            if let patternURL {
                PatternView(url: patternURL, page: $project.patternPage)
                    .ignoresSafeArea(edges: .bottom)
                    .safeAreaInset(edge: .bottom) {
                        controls(showsCount: true)
                            .padding(.horizontal)
                            .padding(.vertical, 10)
                            .background(.bar)
                    }
            } else {
                VStack(spacing: 0) {
                    Spacer()
                    count(size: 132)
                    Spacer()
                    controls(showsCount: false)
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                }
            }
        }
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
        .alert("That PDF could not be opened", isPresented: $importFailed) {}
        // Knitting hands are busy: keep the screen on while a project is open.
        .onAppear { UIApplication.shared.isIdleTimerDisabled = true }
        .onDisappear { UIApplication.shared.isIdleTimerDisabled = false }
    }

    private func count(size: CGFloat) -> some View {
        Text(project.rows, format: .number)
            .font(.system(size: size, weight: .semibold, design: .rounded))
            .monospacedDigit()
            .minimumScaleFactor(0.4)
            .lineLimit(1)
            .contentTransition(.numericText(value: Double(project.rows)))
            .animation(.snappy, value: project.rows)
            .accessibilityLabel("Row \(project.rows)")
            .accessibilityIdentifier("counter.value")
    }

    private func controls(showsCount: Bool) -> some View {
        HStack(spacing: 12) {
            Button { project.decrement() } label: { Image(systemName: "minus") }
                .buttonStyle(CounterButtonStyle(prominent: false))
                .disabled(project.rows == 0)
                .accessibilityLabel("Back one row")
                .accessibilityIdentifier("counter.minus")
            if showsCount {
                count(size: 44).frame(minWidth: 72)
            }
            Button { project.increment() } label: { Image(systemName: "plus") }
                .buttonStyle(CounterButtonStyle(prominent: true))
                .accessibilityLabel("Add a row")
                .accessibilityIdentifier("counter.plus")
        }
    }

    private var menu: some View {
        Menu {
            Button("Details", systemImage: "square.and.pencil") { editing = true }
            Button(project.patternFile == nil ? "Add Pattern" : "Replace Pattern", systemImage: "doc") { importing = true }
            if project.patternFile != nil {
                Button("Remove Pattern", systemImage: "doc.badge.minus") { setPattern(nil) }
            }
            Button(project.isFinished ? "Mark Active" : "Mark Finished", systemImage: project.isFinished ? "arrow.uturn.backward" : "checkmark") {
                project.toggleFinished()
            }
            Button("Reset Count", systemImage: "arrow.counterclockwise", role: .destructive) { confirmingReset = true }
                .disabled(project.rows == 0)
        } label: {
            Image(systemName: "ellipsis.circle")
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
