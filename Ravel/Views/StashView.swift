import SwiftData
import SwiftUI

struct StashView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Yarn.createdAt, order: .reverse) private var yarns: [Yarn]
    @Query(sort: \Needle.millimeters) private var needles: [Needle]
    @State private var editingYarn: Yarn?
    @State private var editingNeedle: Needle?
    /// The yarn whose editor is open and the name it had, put back if the editor closes with the name cleared.
    @State private var opened: Yarn?
    @State private var nameBefore = ""

    var body: some View {
        NavigationStack {
            List {
                if !yarns.isEmpty {
                    Section {
                        ForEach(yarns) { yarn in
                            Button {
                                opened = yarn
                                nameBefore = yarn.name
                                editingYarn = yarn
                            } label: {
                                row(title: yarn.name, detail: [yarn.detail, yarn.totalLength].compactMap { $0 }.joined(separator: " · "), count: yarn.skeins, countLabel: String(localized: "\(yarn.skeins) skeins", comment: "VoiceOver label for the number of skeins of a yarn"))
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
            .readableWidth(leading: true)
            .scrollContentBackground(.hidden)
            .background(Theme.paper)
            .overlay {
                if yarns.isEmpty && needles.isEmpty { empty }
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
            #if DEBUG
            // `-OpenYarn` lands in the first yarn's editor, for screenshots.
            .task {
                guard ProcessInfo.processInfo.arguments.contains("-OpenYarn"), editingYarn == nil, let first = yarns.first else { return }
                opened = first
                nameBefore = first.name
                editingYarn = first
            }
            #endif
            .sheet(item: $editingYarn, onDismiss: dropUnnamed) { YarnEditor(yarn: $0) }
            .sheet(item: $editingNeedle) { NeedleEditor(needle: $0) }
        }
    }

    /// Both things a stash holds.
    private var empty: some View {
        VStack(spacing: 12) {
            Button("Add Yarn", action: addYarn)
                .font(.headline)
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.onAccent)
                .padding(.horizontal, 28)
                .frame(minHeight: 50)
                .background(Color.accentColor, in: Capsule())
            Button("Add Needles", action: addNeedle)
                .font(.headline)
                .multilineTextAlignment(.center)
                .frame(minHeight: 44)
        }
    }

    private func header(_ title: LocalizedStringKey) -> some View {
        Text(title).font(.subheadline.weight(.semibold)).foregroundStyle(Theme.secondary).textCase(nil)
    }

    private func row(title: String, detail: String, count: Int?, countLabel: String) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(Theme.display(19)).foregroundStyle(.primary)
                Text(detail).font(.subheadline).foregroundStyle(Theme.secondary)
                    .accessibilityIdentifier("stash.detail")
            }
            Spacer()
            // "3 skeins", never a bare number.
            if count != nil {
                Text(countLabel)
                    .font(Theme.display(19, weight: .regular))
                    .monospacedDigit()
                    .foregroundStyle(Theme.secondary)
            }
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
    }

    private func addYarn() {
        let yarn = Yarn(name: "")
        context.insert(yarn)
        // Saved before the sheet opens: a first save swaps the yarn's ID, which would
        // close and reopen the editor and drop the yarn while it is still unnamed.
        try? context.save()
        opened = nil
        editingYarn = yarn
    }

    private func addNeedle() {
        let needle = Needle()
        context.insert(needle)
        try? context.save()
        editingNeedle = needle
    }

    /// A new yarn closed without a name was never really added. A yarn already in the stash keeps its name.
    private func dropUnnamed() {
        defer {
            opened = nil
            try? context.save()
        }
        for yarn in yarns where yarn.name.trimmingCharacters(in: .whitespaces).isEmpty {
            if yarn === opened, !nameBefore.isEmpty { yarn.name = nameBefore } else { context.delete(yarn) }
        }
    }
}

struct YarnEditor: View {
    @Bindable var yarn: Yarn
    @Environment(\.dismiss) private var dismiss
    @FocusState private var nameFocused: Bool
    @State private var lengthText = ""
    private let lengthLabel: LocalizedStringKey = Units.current == .metric ? "Meters per Skein" : "Yards per Skein"

    /// A labeled row whose value is typed on the right, so a filled-in field still says what it is.
    private func field(_ label: LocalizedStringKey, text: Binding<String>) -> some View {
        LabeledContent(label) {
            TextField("", text: text).multilineTextAlignment(.trailing).accessibilityLabel(label)
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $yarn.name).focused($nameFocused).accessibilityLabel("Name")
                        .accessibilityIdentifier("yarn.name")
                    field("Brand", text: $yarn.brand)
                    field("Color", text: $yarn.colorway)
                    field("Fiber", text: $yarn.fiber).accessibilityIdentifier("yarn.fiber")
                    field("Dye Lot", text: $yarn.dyeLot).accessibilityIdentifier("yarn.dyeLot")
                }
                Section {
                    Picker("Weight", selection: $yarn.weight) {
                        ForEach(YarnWeight.allCases) { Text($0.title).tag($0) }
                    }
                    Stepper(value: $yarn.skeins, in: 0...999) {
                        LabeledContent("Skeins", value: yarn.skeins, format: .number)
                    }
                    .accessibilityIdentifier("yarn.skeins")
                    field(lengthLabel, text: $lengthText)
                        .keyboardType(.numberPad)
                        .accessibilityIdentifier("yarn.length")
                        .onChange(of: lengthText) { _, text in
                            let shown = min(Int(text) ?? 0, 99_999)
                            if shown != yarn.lengthPerSkein { yarn.lengthPerSkein = shown }
                        }
                }
                if !yarn.projects.isEmpty {
                    Section {
                        ForEach(yarn.projects.sorted { $0.createdAt > $1.createdAt }) { Text($0.name) }
                    } header: {
                        Text("Projects").textCase(nil)
                    }
                }
            }
            .navigationTitle("Yarn")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
            .onAppear {
                nameFocused = yarn.name.isEmpty
                lengthText = yarn.lengthPerSkein > 0 ? String(yarn.lengthPerSkein) : ""
            }
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
                    ForEach(NeedleKind.allCases) { Text($0.title).tag($0) }
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
            .navigationTitle(needle.kind == .hook ? LocalizedStringKey("Hook") : LocalizedStringKey("Needle"))
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
