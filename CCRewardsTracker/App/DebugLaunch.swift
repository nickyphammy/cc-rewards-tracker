import SwiftData
import SwiftUI

/// Debug-only launch arguments used to put the app into a known state for simulator screenshots.
///   -inMemoryStore                 start with an empty, throwaway store
///   -seedCards id1,id2             add these catalog cards on launch (if the wallet is empty)
///   -preselect id1,id2             pre-tick these cards in the onboarding picker
///   -openTab wallet|bestCard       start on this tab
///   -openCategory dining           push the Best Card result for this category
///   -openCard <catalog id>         push this card's detail screen
///   -amount 85.40                  prefill the Best Card amount field
///   -walletEditing                 start the Wallet list in edit mode
/// `-hasSeenWelcome YES` works through UserDefaults' argument domain.
enum DebugLaunch {
    private static func value(_ flag: String) -> String? {
        #if DEBUG
        let args = ProcessInfo.processInfo.arguments
        guard let i = args.firstIndex(of: flag), i + 1 < args.count else { return nil }
        return args[i + 1]
        #else
        return nil
        #endif
    }

    private static func list(_ flag: String) -> [String] {
        value(flag)?.split(separator: ",").map(String.init) ?? []
    }

    static var preselected: Set<String> { Set(list("-preselect")) }
    static var seedCards: [String] { list("-seedCards") }
    static var openTab: String? { value("-openTab") }
    static var openCategory: SpendCategory? { value("-openCategory").flatMap(SpendCategory.init(rawValue:)) }
    static var openCard: String? { value("-openCard") }
    static var amount: String? { value("-amount") }
    static var walletEditing: Bool {
        #if DEBUG
        ProcessInfo.processInfo.arguments.contains("-walletEditing")
        #else
        false
        #endif
    }
}

private struct DebugSeeding: ViewModifier {
    @Environment(CatalogStore.self) private var catalog
    @Environment(\.modelContext) private var context

    func body(content: Content) -> some View {
        content.task {
            let ids = DebugLaunch.seedCards
            guard !ids.isEmpty, (try? context.fetchCount(FetchDescriptor<UserCard>())) == 0 else { return }
            for (index, id) in ids.enumerated() {
                if let template = catalog.card(id: id) {
                    CardFactory.addCard(from: template, sortIndex: index, to: context)
                }
            }
            try? context.save()
        }
    }
}

extension View {
    func debugSeeding() -> some View { modifier(DebugSeeding()) }
}
