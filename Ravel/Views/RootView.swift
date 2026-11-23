import SwiftUI

struct RootView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.scenePhase) private var scenePhase
    // `-Tab 1` opens on a given tab, for screenshots.
    @State private var tab = UserDefaults.standard.integer(forKey: "Tab")
    @State private var snapshot = UserDefaults.standard.string(forKey: "PaywallSnapshot") != nil
    @AppStorage("onboarded") private var onboarded = false
    @AppStorage(Appearance.key) private var appearance = 0
    @State private var onboarding = false
    @State private var saveFailed = false
    /// A PDF or a backup another app opened in Ravel.
    @State private var incoming: URL?

    var body: some View {
        TabView(selection: $tab) {
            ProjectsView(incoming: $incoming) { tab = 1 }
                .tabItem { Label("Projects", systemImage: "square.stack") }
                .tag(0)
            LibraryView()
                .tabItem { Label("Patterns", systemImage: "book") }
                .tag(1)
            StashView()
                .tabItem { Label("Stash", systemImage: "shippingbox") }
                .tag(2)
        }
        // Leaving the app is the last sure moment to write: nothing typed or counted waits on an autosave.
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { try? context.save() }
            // The Apple Account can change in Settings while Ravel is away.
            if phase == .background { SubscriptionService.shared.forgetPendingAnswer() }
        }
        // A count that did not reach the disk is said at once, where the knitter is, not found out at the next launch.
        .onReceive(NotificationCenter.default.publisher(for: SaveWatch.failedNotice)) { _ in saveFailed = true }
        .alert("Your last change was not saved", isPresented: $saveFailed) {} message: {
            Text("Ravel could not write to this \(UIDevice.current.model). Free up some storage, then make the change again.")
        }
        // "Open in Ravel" from Files, Mail or a browser: the projects list takes it from here.
        .onOpenURL { url in
            guard url.isFileURL else { return }
            tab = 0
            incoming = url
        }
        // Knit Again on a finished project: the design's page, in the library.
        .onReceive(NotificationCenter.default.publisher(for: LibraryView.openDesign)) { _ in tab = 1 }
        // A row counted in the app shows on the Lock Screen counter, when that project has one.
        .onReceive(NotificationCenter.default.publisher(for: Project.savedNotice)) { note in
            guard let project = note.object as? Project else { return }
            Task { await LockCounter.refresh(project) }
        }
        .onChange(of: appearance, initial: true) { _, chosen in Appearance.apply(chosen) }
        .onAppear {
            // In place from the first frame, so the tabs never flash behind it.
            var instant = Transaction()
            instant.disablesAnimations = true
            withTransaction(instant) { onboarding = Self.showsOnboarding(onboarded: onboarded) }
        }
        .task {
            // Fetched at launch, while onboarding is up, so a knitter who came for a seasonal design
            // finds it on the first visit. Seeded and test runs keep the shipped lists, so captures do not shift.
            let arguments = ProcessInfo.processInfo.arguments
            guard !arguments.contains("-SeedDemo"), !arguments.contains("-UITesting") else { return }
            async let designs: Void = TopicalStore.shared.refresh()
            await Trending.shared.refresh()
            await designs
        }
        .fullScreenCover(isPresented: $onboarding) {
            OnboardingView {
                onboarded = true
                onboarding = false
                // Everyone arrives for the patterns, trial or not: open there, not on an empty project list.
                tab = 1
            }
        }
        #if DEBUG
        // `-PaywallSnapshot yearly`, `monthly` or `lifetime` opens the paywall on that plan, for review screenshots.
        .fullScreenCover(isPresented: $snapshot) {
            let plans: [String: Offer.Term] = ["monthly": .monthly, "lifetime": .lifetime]
            PaywallView(picked: plans[UserDefaults.standard.string(forKey: "PaywallSnapshot") ?? ""] ?? .yearly)
        }
        #endif
    }

    /// A fresh install sees onboarding once. Demo, UI-test and paywall-snapshot runs skip it unless `-Onboarding` asks.
    private static func showsOnboarding(onboarded: Bool) -> Bool {
        #if DEBUG
        let arguments = ProcessInfo.processInfo.arguments
        if arguments.contains("-Onboarding") { return true }
        if arguments.contains("-SeedDemo") || arguments.contains("-UITesting") || arguments.contains("-PaywallSnapshot") { return false }
        #endif
        return !onboarded
    }
}

/// The store on disk would not open. Say so and leave it untouched; an update or a restart can still read it.
struct StoreUnavailableView: View {
    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack(spacing: 20) {
            Text("Ravel could not open your projects")
                .font(Theme.display(26, weight: .semibold))
                .multilineTextAlignment(.center)
            Text("They are still on this \(UIDevice.current.model). Restart it, then open Ravel again.")
                .foregroundStyle(Theme.secondary)
                .multilineTextAlignment(.center)
            Button("Get Help") { openURL(Links.support) }
                .frame(minHeight: 44)
        }
        .padding(32)
        .frame(maxWidth: 520)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.paper)
    }
}
