import ActivityKit
import AppIntents
import SwiftUI
import WidgetKit

@main
struct RavelWidgets: WidgetBundle {
    var body: some Widget {
        CountingActivity()
    }
}

/// The row counter on the Lock Screen and in the Dynamic Island: where the work stands, the next row of a
/// library pattern, one large button to count a row and a small one to take it back.
struct CountingActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: CountingAttributes.self) { context in
            HStack(spacing: 12) {
                standing(context)
                Spacer(minLength: 8)
                undo(context, size: 40)
                knit(context, size: 60)
            }
            .padding(16)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Text(context.state.place)
                        .font(.headline)
                        .monospacedDigit()
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    HStack(spacing: 10) {
                        undo(context, size: 36)
                        knit(context, size: 44)
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    if !context.state.line.isEmpty {
                        Text(context.state.line)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            } compactLeading: {
                Circle().fill(yarn(context)).frame(width: 14, height: 14)
                    .accessibilityLabel(context.attributes.name)
            } compactTrailing: {
                Text(context.state.short).monospacedDigit()
            } minimal: {
                Text(context.state.short).monospacedDigit().minimumScaleFactor(0.6)
            }
        }
    }

    private func yarn(_ context: ActivityViewContext<CountingAttributes>) -> Color {
        Color(red: context.attributes.red, green: context.attributes.green, blue: context.attributes.blue)
    }

    private func standing(_ context: ActivityViewContext<CountingAttributes>) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 6) {
                Circle().fill(yarn(context)).frame(width: 10, height: 10)
                Text(context.attributes.name)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Text(context.state.place)
                .font(.title3.weight(.semibold))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            if !context.state.line.isEmpty {
                Text(context.state.line)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
    }

    /// The glyph is cut out of the disc, so the button reads on the Lock Screen's light and dark alike.
    private func knit(_ context: ActivityViewContext<CountingAttributes>, size: CGFloat) -> some View {
        Button(intent: CountRowIntent(project: context.attributes.project, back: false)) {
            ZStack {
                Circle().fill(.primary)
                Image(systemName: "plus")
                    .font(.system(size: size * 0.42, weight: .bold))
                    .blendMode(.destinationOut)
            }
            .compositingGroup()
            .frame(width: size, height: size)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(context.attributes.knitLabel)
    }

    private func undo(_ context: ActivityViewContext<CountingAttributes>, size: CGFloat) -> some View {
        Button(intent: CountRowIntent(project: context.attributes.project, back: true)) {
            Image(systemName: "arrow.uturn.backward")
                .font(.system(size: size * 0.4, weight: .semibold))
                .frame(width: size, height: size)
                .background(.primary.opacity(0.12), in: Circle())
        }
        .buttonStyle(.plain)
        .disabled(!context.state.canUndo)
        .opacity(context.state.canUndo ? 1 : 0.35)
        .accessibilityLabel(context.attributes.undoLabel)
    }
}
