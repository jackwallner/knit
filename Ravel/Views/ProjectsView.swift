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
                    Section("Finished") { rows(finished) }
                }
            }
            .overlay {
                if projects.isEmpty {
                    ContentUnavailableView {
                        Label("No Projects", systemImage: "square.stack")
                    } actions: {
                        Button("New Project") { naming = true }
                            .buttonStyle(.borderedProminent)
                            .foregroundStyle(Theme.onAccent)
                    }
                }
            }
            .navigationTitle("Projects")
            .navigationDestination(for: Project.self) { ProjectView(project: $0) }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("New Project", systemImage: "plus") { naming = true }
                        .accessibilityIdentifier("projects.add")
                }
            }
            .alert("New Project", isPresented: $naming) {
                TextField("Name", text: $name)
                Button("Cancel", role: .cancel) { name = "" }
                Button("Create", action: create)
            }
        }
    }

    private func rows(_ list: [Project]) -> some View {
        ForEach(list) { project in
            NavigationLink(value: project) {
                HStack {
                    Text(project.name)
                    Spacer()
                    Text(project.rows, format: .number)
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
            }
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
        let project = Project(name: trimmed.isEmpty ? "Untitled" : trimmed)
        context.insert(project)
        name = ""
        path = [project]
    }
}
