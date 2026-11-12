import SwiftData
import SwiftUI

@main
struct RavelApp: App {
    private let container: ModelContainer

    init() {
        let arguments = ProcessInfo.processInfo.arguments
        var inMemory = false
        #if DEBUG
        inMemory = arguments.contains("-UITesting") || arguments.contains("-SeedDemo")
        #endif
        container = Persistence.container(inMemory: inMemory)
        Theme.applyNavigationAppearance()
        #if DEBUG
        if arguments.contains("-SeedDemo") { Persistence.seedDemo(container.mainContext) }
        #endif
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(container)
    }
}
