import SwiftUI

/// The whole written pattern, for reading ahead or looking back, with the line being worked marked.
/// The instructions stay English like the steps; only the section names are translated.
struct WholePatternView: View {
    let plan: PatternPlan
    /// The project's count, which picks the marked line.
    let taps: Int
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        let current = plan.currentLine(at: taps)
        let blocks = plan.written()
        NavigationStack {
            ScrollViewReader { proxy in
                List {
                    ForEach(blocks.indices, id: \.self) { index in
                        Section {
                            ForEach(blocks[index].lines) { line in
                                let isCurrent = line.id == current
                                HStack(alignment: .firstTextBaseline, spacing: 10) {
                                    Circle()
                                        .fill(Color.accentColor)
                                        .frame(width: 7, height: 7)
                                        .opacity(isCurrent ? 1 : 0)
                                        .accessibilityHidden(true)
                                    Text(line.text)
                                        .fontWeight(isCurrent ? .semibold : .regular)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .id(line.id)
                                .accessibilityElement(children: .combine)
                                .accessibilityAddTraits(isCurrent ? .isSelected : [])
                                .listRowBackground(Theme.paper)
                                .listRowSeparatorTint(.primary.opacity(0.08))
                            }
                        } header: {
                            Text(Loc.section(blocks[index].section))
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Theme.secondary)
                                .textCase(nil)
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(Theme.paper)
                .onAppear { if let current { proxy.scrollTo(current, anchor: .center) } }
            }
            .navigationTitle("Whole Pattern")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
        }
    }
}
