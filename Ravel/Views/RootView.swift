import SwiftUI

struct RootView: View {
    var body: some View {
        TabView {
            ProjectsView()
                .tabItem { Label("Projects", systemImage: "square.stack") }
            StashView()
                .tabItem { Label("Stash", systemImage: "shippingbox") }
        }
    }
}
