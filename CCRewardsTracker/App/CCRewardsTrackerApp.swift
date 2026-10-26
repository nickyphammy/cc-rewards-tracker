import SwiftData
import SwiftUI

@main
struct CCRewardsTrackerApp: App {
    @State private var catalog: CatalogStore
    private let container: ModelContainer

    init() {
        do {
            _catalog = State(initialValue: try CatalogStore.bundled())
        } catch {
            fatalError("Bundled catalog.json is missing or invalid: \(error)")
        }
        let schema = Schema([UserCard.self, Multiplier.self, Credit.self, CreditUsage.self, CategorySelection.self])
        #if DEBUG
        let inMemory = ProcessInfo.processInfo.arguments.contains("-inMemoryStore")
        #else
        let inMemory = false
        #endif
        do {
            container = try ModelContainer(for: schema, configurations: ModelConfiguration(isStoredInMemoryOnly: inMemory))
        } catch {
            fatalError("Could not open the data store: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(catalog)
        }
        .modelContainer(container)
    }
}
