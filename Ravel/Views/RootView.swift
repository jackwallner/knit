import SwiftUI

struct RootView: View {
    // `-Tab 1` opens on a given tab, for screenshots.
    @State private var tab = UserDefaults.standard.integer(forKey: "Tab")

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
    }
}
