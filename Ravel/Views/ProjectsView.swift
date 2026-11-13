import SwiftData
import SwiftUI

struct ProjectsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Project.createdAt, order: .reverse) private var projects: [Project]
    @State private var path: [Project] = []
    @State private var naming = false
    @State private var name = ""

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
                        Text("Finished").font(.subheadline.weight(.semibold)).foregroundStyle(.secondary).textCase(nil)
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Theme.paper)
            .overlay { if projects.isEmpty { empty } }
            .navigationTitle("Projects")
            .navigationDestination(for: Project.self) { ProjectView(project: $0) }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("New Project", systemImage: "plus") { naming = true }
                        .accessibilityIdentifier("projects.add")
                }
            }
            #if DEBUG
            // `-OpenFirst` lands on the newest project and `-OpenProject <name>` on a named one, for screenshots.
            .task {
                guard path.isEmpty else { return }
                if let name = UserDefaults.standard.string(forKey: "OpenProject"), let match = projects.first(where: { $0.name == name }) {
                    path = [match]
                } else if ProcessInfo.processInfo.arguments.contains("-OpenFirst"), let first = active.first {
                    path = [first]
                }
            }
            #endif
            .alert("New Project", isPresented: $naming) {
                TextField("Name", text: $name)
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
            Button("Cast On") { naming = true }
                .font(.headline)
                .foregroundStyle(Theme.onAccent)
                .padding(.horizontal, 28)
                .frame(minHeight: 50)
                .background(Color.accentColor, in: Capsule())
                .accessibilityIdentifier("projects.castOn")
        }
    }

    private func rows(_ list: [Project]) -> some View {
        ForEach(list) { project in
            NavigationLink(value: project) {
                HStack(spacing: 16) {
                    Swatch(yarn: project.color)
                    Text(project.name)
                        .font(Theme.display(20))
                        .lineLimit(2)
                    Spacer(minLength: 8)
                    Text(project.rows, format: .number)
                        .font(Theme.display(20, weight: .regular))
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                        .accessibilityLabel("Row \(project.rows)")
                }
                .padding(.vertical, 6)
            }
            .listRowBackground(Theme.paper)
            .listRowSeparator(.hidden)
        }
        .onDelete { offsets in
            for project in offsets.map({ list[$0] }) {
                PatternStore.delete(project.patternFile)
                context.delete(project)
            }
        }
    }

    private func create() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        // Each new project takes the next yarn so the list reads at a glance.
        let color = YarnColor.allCases[projects.count % YarnColor.allCases.count]
        let project = Project(name: trimmed.isEmpty ? "Untitled" : trimmed, color: color)
        context.insert(project)
        name = ""
        path = [project]
    }
}
