import StoreKit
import SwiftData
import SwiftUI

struct ProjectsView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.openURL) private var openURL
    @Environment(\.requestReview) private var requestReview
    @Environment(\.dynamicTypeSize) private var typeSize
    /// A file another app handed over ("Open in Ravel"): a pattern to start a project from, or a backup.
    @Binding var incoming: URL?
    /// Opens the Patterns tab.
    var browse: () -> Void = {}
    @Query(sort: \Project.createdAt, order: .reverse) private var projects: [Project]
    @State private var path: [Project] = []
    @State private var naming = false
    @State private var name = ""
    @State private var deleting: Project?
    @State private var importing = false
    @State private var importFailed = false
    @State private var showingSettings = false
    @State private var backupFailed = false
    /// How many projects the last restore added, while its result is on screen.
    @State private var restored: Int?

    init(incoming: Binding<URL?> = .constant(nil), browse: @escaping () -> Void = {}) {
        _incoming = incoming
        self.browse = browse
    }

    /// What was worked last leads, so the piece on the needles is the first row of the list.
    private var active: [Project] { projects.filter { !$0.isFinished }.sorted { $0.lastWorked > $1.lastWorked } }
    private var finished: [Project] { projects.filter(\.isFinished).sorted { ($0.finishedAt ?? .distantPast) > ($1.finishedAt ?? .distantPast) } }

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
                    // Every way in, named: a counter, the knitter's own pattern (free, like the rest of the tracker), or the library.
                    Menu {
                        Button("Row Counter", systemImage: "number") { naming = true }
                            .accessibilityIdentifier("projects.add.counter")
                        Button("My Own Pattern", systemImage: "doc") { importing = true }
                            .accessibilityIdentifier("projects.add.pdf")
                        Button("From the Library", systemImage: "books.vertical", action: browse)
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("New Project")
                    .accessibilityIdentifier("projects.add")
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button("Settings", systemImage: "gearshape") { showingSettings = true }
                        .accessibilityIdentifier("projects.settings")
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
            .sheet(isPresented: $showingSettings) { SettingsView() }
            .fileImporter(isPresented: $importing, allowedContentTypes: [.pdf, .image]) { result in
                if case let .success(url) = result { start(url) }
            }
            .onChange(of: incoming, initial: true) { _, url in
                guard let url else { return }
                incoming = nil
                if url.pathExtension.lowercased() == Backup.fileExtension { restore(url) } else { start(url) }
            }
            .alert("That pattern could not be opened", isPresented: $importFailed) {}
            .alert("That backup could not be opened", isPresented: $backupFailed) {}
            .alert("Backup Restored", isPresented: Binding(get: { restored != nil }, set: { if !$0 { restored = nil } })) {} message: {
                if let restored, restored > 0 { Text("\(restored) projects added") } else { Text("Everything in this backup is already here") }
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
            VStack(spacing: 0) {
                Button("Browse Patterns", action: browse)
                    .accessibilityIdentifier("projects.browse")
                // A knitter who arrives with a PDF starts from it, without hunting through the plus menu.
                Button("Import a Pattern") { importing = true }
                    .accessibilityIdentifier("projects.import")
            }
            .font(.headline)
            .multilineTextAlignment(.center)
            .buttonStyle(.borderless)
            .controlSize(.large)
            .padding(.top, -14)
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
                if project.rows > 0 || project.tallyCount > 0 || project.patternFile != nil { deleting = project } else { remove(project) }
            }
        }
    }

    /// The name, and under it where the work stands ("Row 18", "Body · Round 5") or the day it was finished:
    /// never a bare number.
    private func row(_ project: Project) -> some View {
        let plan = project.plan
        let standing = project.isFinished
            ? project.finishedAt.map { $0.formatted(.dateTime.day().month(.abbreviated).year()) } ?? ""
            : project.standing(plan)
        return HStack(spacing: 16) {
            thumbnail(project, plan)
            VStack(alignment: .leading, spacing: 3) {
                // At the accessibility text sizes the name runs as long as it needs, so it is never cut.
                Text(project.name).font(Theme.display(22)).lineLimit(typeSize.isAccessibilitySize ? nil : 2)
                if !standing.isEmpty {
                    Text(standing)
                        .font(.subheadline)
                        .monospacedDigit()
                        .foregroundStyle(Theme.secondary)
                        .accessibilityIdentifier("projects.standing")
                }
            }
            Spacer(minLength: 0)
        }
    }

    /// A library project shows the piece, filled as far as it is knitted; any other shows its fabric.
    @ViewBuilder
    private func thumbnail(_ project: Project, _ plan: PatternPlan?) -> some View {
        let side: CGFloat = 64
        if let photo = project.finishPhoto, let image = UIImage(contentsOfFile: PatternStore.url(for: photo).path) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: side, height: side)
                .clipShape(RoundedRectangle(cornerRadius: side * 0.27, style: .continuous))
                .accessibilityHidden(true)
        } else if let plan, let silhouette = project.silhouette(plan), plan.totalTaps > 0 {
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
        PatternStore.delete(project.finishPhoto)
        // Its Lock Screen counter goes first, while the project can still be named.
        let gone = LockCounter.key(project)
        Task { await LockCounter.drop(gone) }
        context.delete(project)
        try? context.save()
    }

    /// Adds what a backup holds that this device does not. Projects already here are never changed.
    private func restore(_ url: URL) {
        defer { Self.clearInbox(url) }
        guard let kept = try? Backup.read(url), let added = try? kept.restore(into: context) else { return backupFailed = true }
        restored = added
    }

    /// A file handed over by another app is a copy in the app's Inbox: gone once it has been read.
    private static func clearInbox(_ url: URL) {
        if url.pathComponents.contains("Inbox") { try? FileManager.default.removeItem(at: url) }
    }

    /// A project made from the knitter's own pattern file, named after it, opened at its first page.
    private func start(_ url: URL) {
        let title = url.deletingPathExtension().lastPathComponent
        Task {
            let saved = await Task.detached(operation: { try? PatternStore.save(from: url) }).value
            Self.clearInbox(url)
            guard let file = saved else {
                importFailed = true
                return
            }
            let color = YarnColor.allCases[projects.count % YarnColor.allCases.count]
            let project = Project(name: title.isEmpty ? String(localized: "Untitled", comment: "Name of a project the knitter did not name") : title, color: color)
            project.patternFile = file
            context.insert(project)
            try? context.save()
            path = [project]
        }
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
