import SwiftData
import SwiftUI

/// How the app looks: as the device does, or always light or dark.
enum Appearance {
    static let key = "appearance"

    /// 0 follows the device, 1 is light, 2 is dark: the raw values of `UIUserInterfaceStyle`.
    /// Set on the windows, so sheets, the onboarding and the paywall follow at once.
    @MainActor
    static func apply(_ raw: Int) {
        let style = UIUserInterfaceStyle(rawValue: raw) ?? .unspecified
        for case let scene as UIWindowScene in UIApplication.shared.connectedScenes {
            for window in scene.windows { window.overrideUserInterfaceStyle = style }
        }
    }
}

/// Everything about the app that is not a project, a pattern or a yarn.
struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @AppStorage(Appearance.key) private var appearance = 0
    @State private var restoring = false
    /// A backup written and waiting to be put where the knitter picks.
    @State private var backup: URL?
    @State private var backupFailed = false
    /// How many projects the last restore added, while its result is on screen.
    @State private var restored: Int?

    var body: some View {
        NavigationStack {
            Form {
                Section("Appearance") {
                    Picker("Appearance", selection: $appearance) {
                        Text("Automatic").tag(0)
                        Text("Light").tag(1)
                        Text("Dark").tag(2)
                    }
                    .pickerStyle(.segmented)
                    .accessibilityIdentifier("settings.appearance")
                }
                // Kept by hand, wherever the knitter likes: Files, iCloud Drive, a computer. No account.
                Section {
                    Button("Save a Backup", systemImage: "square.and.arrow.down", action: saveBackup)
                        .accessibilityIdentifier("settings.backup")
                    Button("Restore a Backup", systemImage: "arrow.counterclockwise") { restoring = true }
                        .accessibilityIdentifier("settings.restore")
                }
                Section {
                    Button("Rate Ravel", systemImage: "star") {
                        ReviewPrompt().markOpenedStore()
                        openURL(Links.writeReview)
                    }
                    // With no Mail account the address cannot open; the help page carries it too.
                    Button("Send Feedback", systemImage: "envelope") {
                        openURL(Links.feedback) { opened in if !opened { openURL(Links.support) } }
                    }
                    Button("Help", systemImage: "questionmark.circle") { openURL(Links.support) }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
            .fileImporter(isPresented: $restoring, allowedContentTypes: [.ravelBackup]) { result in
                if case let .success(url) = result { restore(url) }
            }
            .fileMover(isPresented: Binding(get: { backup != nil }, set: { if !$0 { backup = nil } }), file: backup) { _ in backup = nil }
            .alert("That backup could not be opened", isPresented: $backupFailed) {}
            .alert("Backup Restored", isPresented: Binding(get: { restored != nil }, set: { if !$0 { restored = nil } })) {} message: {
                if let restored, restored > 0 { Text("\(restored) projects added") } else { Text("Everything in this backup is already here") }
            }
        }
    }

    private func saveBackup() {
        // What is on screen is on disk first, so the backup holds the last row counted.
        try? context.save()
        guard let url = try? Backup.write(from: context) else { return backupFailed = true }
        backup = url
    }

    /// Adds what a backup holds that this device does not. Projects already here are never changed.
    private func restore(_ url: URL) {
        guard let kept = try? Backup.read(url), let added = try? kept.restore(into: context) else { return backupFailed = true }
        restored = added
    }
}
