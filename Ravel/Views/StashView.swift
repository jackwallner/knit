import SwiftData
import SwiftUI

struct StashView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Yarn.createdAt, order: .reverse) private var yarns: [Yarn]
    @Query(sort: \Needle.millimeters) private var needles: [Needle]
    @State private var editingYarn: Yarn?
    @State private var editingNeedle: Needle?

    var body: some View {
        NavigationStack {
            List {
                if !yarns.isEmpty {
                    Section {
                        ForEach(yarns) { yarn in
                            Button { editingYarn = yarn } label: {
                                row(title: yarn.name, detail: yarn.detail, count: yarn.skeins, countLabel: "\(yarn.skeins) skeins")
                            }
                        }
                        .onDelete { offsets in offsets.map { yarns[$0] }.forEach(context.delete) }
                        .listRowBackground(Theme.paper)
                        .listRowSeparatorTint(.primary.opacity(0.08))
                    } header: { header("Yarn") }
                }
                if !needles.isEmpty {
                    Section {
                        ForEach(needles) { needle in
                            Button { editingNeedle = needle } label: {
                                row(title: needle.size.label, detail: needle.detail, count: nil, countLabel: "")
                            }
                        }
                        .onDelete { offsets in offsets.map { needles[$0] }.forEach(context.delete) }
                        .listRowBackground(Theme.paper)
                        .listRowSeparatorTint(.primary.opacity(0.08))
                    } header: { header("Needles & Hooks") }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Theme.paper)
            .overlay {
                if yarns.isEmpty && needles.isEmpty {
                    Button("Add Yarn", action: addYarn)
                        .font(.headline)
                        .foregroundStyle(Theme.onAccent)
                        .padding(.horizontal, 28)
                        .frame(minHeight: 50)
                        .background(Color.accentColor, in: Capsule())
                }
            }
            .navigationTitle("Stash")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button("Yarn", action: addYarn)
                        Button("Needle or Hook", action: addNeedle)
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add to Stash")
                    .accessibilityIdentifier("stash.add")
                }
            }
            .sheet(item: $editingYarn, onDismiss: dropUnnamed) { YarnEditor(yarn: $0) }
            .sheet(item: $editingNeedle) { NeedleEditor(needle: $0) }
        }
    }

    private func header(_ title: String) -> some View {
        Text(title).font(.subheadline.weight(.semibold)).foregroundStyle(.secondary).textCase(nil)
    }

    private func row(title: String, detail: String, count: Int?, countLabel: String) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(Theme.display(19)).foregroundStyle(.primary)
                Text(detail).font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer()
            if let count {
                Text(count, format: .number)
                    .font(Theme.display(19, weight: .regular))
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                    .accessibilityLabel(countLabel)
            }
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
    }

    private func addYarn() {
        let yarn = Yarn(name: "")
        context.insert(yarn)
        editingYarn = yarn
    }

    private func addNeedle() {
        let needle = Needle()
        context.insert(needle)
        editingNeedle = needle
    }

    /// A yarn closed without a name was never really added.
    private func dropUnnamed() {
        yarns.filter { $0.name.trimmingCharacters(in: .whitespaces).isEmpty }.forEach(context.delete)
    }
}

struct YarnEditor: View {
    @Bindable var yarn: Yarn
    @Environment(\.dismiss) private var dismiss
    @FocusState private var nameFocused: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $yarn.name).focused($nameFocused)
                    LabeledContent("Brand") { TextField("", text: $yarn.brand).multilineTextAlignment(.trailing) }
                    LabeledContent("Color") { TextField("", text: $yarn.colorway).multilineTextAlignment(.trailing) }
                }
                Section {
                    Picker("Weight", selection: $yarn.weight) {
                        ForEach(YarnWeight.allCases) { Text($0.label).tag($0) }
                    }
                    Stepper(value: $yarn.skeins, in: 0...999) {
                        LabeledContent("Skeins", value: yarn.skeins, format: .number)
                    }
                }
            }
            .navigationTitle("Yarn")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
            .onAppear { nameFocused = yarn.name.isEmpty }
        }
    }
}

struct NeedleEditor: View {
    @Bindable var needle: Needle
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Picker("Type", selection: $needle.kind) {
                    ForEach(NeedleKind.allCases) { Text($0.label).tag($0) }
                }
                Picker("Size", selection: $needle.millimeters) {
                    ForEach(NeedleSize.all(hook: needle.kind == .hook)) { Text($0.label).tag($0.millimeters) }
                }
                if needle.kind == .circular {
                    Picker("Length", selection: $needle.lengthInches) {
                        Text("Any").tag(0)
                        ForEach([9, 16, 24, 32, 40, 47, 60], id: \.self) { Text(Sizing.cable($0)).tag($0) }
                    }
                }
            }
            .navigationTitle(needle.kind == .hook ? "Hook" : "Needle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
            // Hooks and needles use different size charts; keep the size on one that exists.
            .onChange(of: needle.kind) { _, kind in
                needle.millimeters = NeedleSize.nearest(to: needle.millimeters, hook: kind == .hook).millimeters
                if kind != .circular { needle.lengthInches = 0 }
            }
        }
    }
}
