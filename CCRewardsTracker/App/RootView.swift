import SwiftData
import SwiftUI

struct RootView: View {
    @AppStorage("hasSeenWelcome") private var hasSeenWelcome = false
    @Query private var cards: [UserCard]

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
    }

    private var tabs: some View {
        TabView {
            Tab("Best Card", systemImage: "creditcard.and.123") {
                NavigationStack {
                    Text("Best Card")
                        .navigationTitle("Best Card")
                }
            }
            Tab("Wallet", systemImage: "wallet.bifold") {
                NavigationStack {
                    Text("\(cards.count) cards")
                        .navigationTitle("Wallet")
                }
            }
        }
    }
}
