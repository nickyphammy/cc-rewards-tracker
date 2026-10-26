import SwiftData
import SwiftUI

struct RootView: View {
    @AppStorage("hasSeenWelcome") private var hasSeenWelcome = false
    @Query private var cards: [UserCard]
    @Query(filter: #Predicate<Credit> { !$0.isArchived }) private var credits: [Credit]
    @Environment(\.scenePhase) private var scenePhase
    @State private var now = Date.now
    @State private var selectedTab = DebugLaunch.openTab ?? "bestCard"

    var body: some View {
        Group {
            if !hasSeenWelcome && cards.isEmpty {
                CardPickerView(mode: .onboarding, preselected: DebugLaunch.preselected) {
                    hasSeenWelcome = true
                }
            } else {
                tabs
            }
        }
        .debugSeeding()
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { now = .now }
        }
    }

    /// Credits tab badge: unused credits whose period ends within 7 days (docs/ui/SCREENS.md).
    private var dueSoonCount: Int {
        let active = credits.filter { $0.card.map { !$0.isArchived } ?? false }
        return CreditDashboard(active.map { $0.status(now: now) }, now: now, calendar: .current).dueSoonCount
    }

    private var tabs: some View {
        TabView(selection: $selectedTab) {
            Tab("Best Card", systemImage: "creditcard.and.123", value: "bestCard") {
                BestCardView()
            }
            Tab("Credits", systemImage: "gift", value: "credits") {
                CreditsView()
            }
            .badge(dueSoonCount)
            Tab("Wallet", systemImage: "wallet.bifold", value: "wallet") {
                WalletView()
            }
        }
    }
}
