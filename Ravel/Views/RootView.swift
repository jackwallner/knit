import SwiftUI

struct RootView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.scenePhase) private var scenePhase
    // `-Tab 1` opens on a given tab, for screenshots.
    @State private var tab = UserDefaults.standard.integer(forKey: "Tab")
    @State private var snapshot = UserDefaults.standard.string(forKey: "PaywallSnapshot") != nil

    var body: some View {
        TabView(selection: $tab) {
            ProjectsView()
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
        .onChange(of: scenePhase) { _, phase in if phase != .active { try? context.save() } }
        #if DEBUG
        // `-PaywallSnapshot yearly`, `monthly` or `lifetime` opens the paywall on that plan, for review screenshots.
        .fullScreenCover(isPresented: $snapshot) {
            let plans: [String: Offer.Term] = ["monthly": .monthly, "lifetime": .lifetime]
            PaywallView(picked: plans[UserDefaults.standard.string(forKey: "PaywallSnapshot") ?? ""] ?? .yearly)
        }
        #endif
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
            Text("They are still on this iPhone. Restart it, then open Ravel again.")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Get Help") { openURL(Links.support) }
                .frame(minHeight: 44)
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.paper)
    }
}
