import StoreKit
import SwiftData
import SwiftUI

struct ProjectsView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.openURL) private var openURL
    @Environment(\.requestReview) private var requestReview
    @Environment(\.dynamicTypeSize) private var typeSize
    /// Opens the Patterns tab.
    var browse: () -> Void = {}
    @Query(sort: \Project.createdAt, order: .reverse) private var projects: [Project]
    @State private var path: [Project] = []
    @State private var naming = false
    @State private var name = ""
    @State private var deleting: Project?

    private var active: [Project] { projects.filter { !$0.isFinished } }
    private var finished: [Project] { projects.filter(\.isFinished) }

    var body: some View {
        NavigationStack(path: $path) {
            List {
                if !active.isEmpty {
                    Section { rows(active) }
                }
                if !finished.isEmpty {
                    Section {
                        rows(finished)
                    } header: {
                        Text("Finished").font(.subheadline.weight(.semibold)).foregroundStyle(Theme.secondary).textCase(nil)
                    }
                }
            }
            .listStyle(.plain)
            .readableWidth(leading: true)
            .scrollContentBackground(.hidden)
            .background(Theme.paper)
            .overlay { if projects.isEmpty { empty } }
            .navigationTitle("Projects")
            .navigationDestination(for: Project.self) { ProjectView(project: $0) }
            .onChange(of: path) { _, open in if open.isEmpty { askForRatingIfDue() } }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("New Project", systemImage: "plus") { naming = true }
                        .accessibilityIdentifier("projects.add")
                }
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Button("Rate Ravel", systemImage: "star") {
                            ReviewPrompt().markOpenedStore()
                            openURL(Links.writeReview)
                        }
                        // With no Mail account the address cannot open; the help page carries it too.
                        Button("Send Feedback", systemImage: "envelope") {
                            openURL(Links.feedback) { opened in if !opened { openURL(Links.support) } }
                        }
                        Button("Help", systemImage: "questionmark.circle") { openURL(Links.support) }
                    } label: {
                        Image(systemName: "ellipsis")
                    }
                    .accessibilityLabel("More")
                    .accessibilityIdentifier("projects.more")
                }
            }
            #if DEBUG
            // `-OpenFirst` lands on the newest project and `-OpenProject <name>` on a named one, for screenshots.
            .task {
                guard path.isEmpty else { return }
                if let name = UserDefaults.standard.string(forKey: "OpenProject"), let match = projects.first(where: { $0.name == name || $0.name == Persistence.demoName(name) }) {
                    path = [match]
                } else if ProcessInfo.processInfo.arguments.contains("-OpenFirst"), let first = active.first {
                    path = [first]
                }
            }
            #endif
            .confirmationDialog(
                "Delete \(deleting?.name ?? "")?",
                isPresented: Binding(get: { deleting != nil }, set: { if !$0 { deleting = nil } }),
                titleVisibility: .visible
            ) {
                Button("Delete Project", role: .destructive) { if let deleting { remove(deleting) } }
            }
            .alert("New Project", isPresented: $naming) {
                TextField("Name", text: $name).accessibilityLabel("Name").autocorrectionDisabled()
                Button("Cancel", role: .cancel) { name = "" }
                Button("Cast On", action: create)
            }
        }
    }

    /// Bare needle, stitches cast on, one way forward.
    private var empty: some View {
        VStack(spacing: 28) {
            Fabric(rows: 0, yarn: .madder, markEvery: 0)
                .frame(width: 240, height: 40)
            Button("Start Row Counter") { naming = true }
                .font(.headline)
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.onAccent)
                .padding(.horizontal, 28)
                .frame(minHeight: 50)
                .background(Color.accentColor, in: Capsule())
                .accessibilityIdentifier("projects.castOn")
            Button("Browse Patterns", action: browse)
                .font(.headline)
                .multilineTextAlignment(.center)
                .frame(minHeight: 44)
                .padding(.top, -14)
                .accessibilityIdentifier("projects.browse")
        }
    }

    private func rows(_ list: [Project]) -> some View {
        ForEach(list) { project in
            NavigationLink(value: project) {
                row(project).padding(.vertical, 8)
            }
            .listRowBackground(Theme.paper)
            .listRowSeparator(.hidden)
        }
        .onDelete { offsets in
            for project in offsets.map({ list[$0] }) {
                // A swipe must not throw away rows already knitted: ask first.
                if project.rows > 0 || project.patternFile != nil { deleting = project } else { remove(project) }
            }
        }
    }

    /// At the accessibility text sizes the name gets its own line, so it is never cut.
    @ViewBuilder
    private func row(_ project: Project) -> some View {
        let plan = project.plan
        let rows = project.knittedRows(plan)
        let name = Text(project.name).font(Theme.display(22))
        let count = Text(rows, format: .number)
            .font(Theme.display(22, weight: .regular))
            .monospacedDigit()
            .foregroundStyle(Theme.secondary)
            .accessibilityLabel("Row \(rows)")
        if typeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    thumbnail(project, plan)
                    Spacer(minLength: 8)
                    count
                }
                name
            }
        } else {
            HStack(spacing: 16) {
                thumbnail(project, plan)
                name.lineLimit(2)
                Spacer(minLength: 8)
                count
            }
        }
    }

    /// A library project shows the piece, filled as far as it is knitted; any other shows its fabric.
    @ViewBuilder
    private func thumbnail(_ project: Project, _ plan: PatternPlan?) -> some View {
        let side: CGFloat = 64
        if let plan, let silhouette = project.silhouette(plan), plan.totalTaps > 0 {
            Garment(silhouette: silhouette, yarn: project.color, progress: Double(project.rows) / Double(plan.totalTaps), colorwork: plan.palette == nil ? nil : plan)
                .padding(6)
                .frame(width: side, height: side)
                .background(.primary.opacity(0.045), in: RoundedRectangle(cornerRadius: side * 0.27, style: .continuous))
        } else {
            Swatch(yarn: project.color, size: side)
        }
    }

    /// Back at the list with the knitting set down: the ask comes here, never over the work itself.
    private func askForRatingIfDue() {
        let prompt = ReviewPrompt()
        Task {
            try? await Task.sleep(for: .seconds(1.5))
            guard path.isEmpty, !naming, deleting == nil, prompt.shouldAsk() else { return }
            prompt.markAsked()
            requestReview()
        }
    }

    private func remove(_ project: Project) {
        PatternStore.delete(project.patternFile)
        context.delete(project)
        try? context.save()
    }

    private func create() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        // Each new project takes the next yarn so the list reads at a glance.
        let color = YarnColor.allCases[projects.count % YarnColor.allCases.count]
        let project = Project(name: trimmed.isEmpty ? String(localized: "Untitled", comment: "Name of a project the knitter did not name") : trimmed, color: color)
        context.insert(project)
        try? context.save()
        name = ""
        path = [project]
    }
}
