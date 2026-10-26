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
///   -openCredit "Uber Cash"        push this credit's detail on the Credits tab (first match by name)
///   -openLogUsage                  open Log Usage on that credit
///   -seedUsage                     with -seedCards: use the first card's first credit fully and its second by half
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
    static var seedUsage: Bool { flag("-seedUsage") }
    static var openCredit: String? { value("-openCredit") }
    static var openLogUsage: Bool { flag("-openLogUsage") }
    static var walletEditing: Bool { flag("-walletEditing") }

    private static func flag(_ name: String) -> Bool {
        #if DEBUG
        ProcessInfo.processInfo.arguments.contains(name)
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
            if DebugLaunch.seedUsage, let first = try? context.fetch(FetchDescriptor<UserCard>(sortBy: [SortDescriptor(\.sortIndex)])).first {
                let credits = first.activeCredits
                if let a = credits.first { a.markUsed(now: .now) }
                if credits.count > 1 { credits[1].logUsage(credits[1].amount / 2, on: .now) }
            }
            try? context.save()
        }
    }
}

extension View {
    func debugSeeding() -> some View { modifier(DebugSeeding()) }
}
