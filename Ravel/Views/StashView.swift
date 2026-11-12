import SwiftData
import SwiftUI

struct StashView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Yarn.createdAt, order: .reverse) private var yarns: [Yarn]
    @State private var editing: Yarn?

    var body: some View {
        NavigationStack {
            List {
                ForEach(yarns) { yarn in
                    Button { editing = yarn } label: { row(yarn) }
                        .tint(.primary)
                }
                .onDelete { offsets in offsets.map { yarns[$0] }.forEach(context.delete) }
            }
            .overlay {
                if yarns.isEmpty {
                    ContentUnavailableView {
                        Label("No Yarn", systemImage: "shippingbox")
                    } actions: {
                        Button("Add Yarn", action: add)
                            .buttonStyle(.borderedProminent)
                            .foregroundStyle(Theme.onAccent)
                    }
                }
            }
            .navigationTitle("Stash")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Add Yarn", systemImage: "plus", action: add)
                        .accessibilityIdentifier("stash.add")
                }
            }
            .sheet(item: $editing, onDismiss: dropUnnamed) { YarnEditor(yarn: $0) }
        }
    }

    private func row(_ yarn: Yarn) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(yarn.name)
                Text(yarn.detail).font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer()
            Text(yarn.skeins, format: .number)
                .monospacedDigit()
                .foregroundStyle(.secondary)
                .accessibilityLabel("\(yarn.skeins) skeins")
        }
        .contentShape(Rectangle())
    }

    private func add() {
        let yarn = Yarn(name: "")
        context.insert(yarn)
        editing = yarn
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
