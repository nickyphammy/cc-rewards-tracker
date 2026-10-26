import SwiftData
import SwiftUI

/// BC-1: the at-the-register screen. One tap on a category shows the answer.
struct BestCardView: View {
    @Query(filter: #Predicate<UserCard> { !$0.isArchived }) private var cards: [UserCard]
    @AppStorage("includePortalRates") private var includePortalRates = false
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var path = NavigationPath()
    @State private var showingPicker = false

    static let gridOrder: [SpendCategory] = [
        .dining, .groceries, .gas, .flights, .hotels, .travelOther, .transit, .streaming,
        .drugstores, .onlineRetail, .entertainment, .homeImprovement, .utilities, .evCharging, .other,
    ]

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if cards.isEmpty {
                    ContentUnavailableView {
                        Label("Add a card to get started", systemImage: "creditcard")
                    } description: {
                        Text("Add the cards you carry and we'll show which one earns the most for each purchase.")
                    } actions: {
                        Button("Add Cards") { showingPicker = true }
                            .primaryActionStyle()
                    }
                } else if typeSize >= .accessibility3 {
                    List(Self.gridOrder) { category in
                        NavigationLink(value: category) {
                            Label(category.displayName, systemImage: category.symbol)
                        }
                    }
                } else {
                    grid
                }
            }
            .navigationTitle("Best Card")
            .navigationDestination(for: SpendCategory.self) { BestCardResultView(category: $0) }
            .navigationDestination(for: UserCard.self) { CardDetailView(card: $0) }
            .navigationDestination(for: Credit.self) { CreditDetailView(credit: $0) }
            .sheet(isPresented: $showingPicker) { CardPickerView(mode: .addToWallet) }
            .task {
                if path.isEmpty, let category = DebugLaunch.openCategory { path.append(category) }
            }
            // Archiving or deleting the last card (e.g. from a result's card detail) leaves nothing to rank.
            .onChange(of: cards.isEmpty) { _, isEmpty in
                if isEmpty { path = NavigationPath() }
            }
        }
    }

    private var grid: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("What are you paying for?")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: typeSize.isAccessibilitySize ? 2 : 3),
                          spacing: 12) {
                    ForEach(Self.gridOrder) { category in
                        NavigationLink(value: category) { CategoryTile(category: category) }
                            .buttonStyle(CategoryTileButtonStyle())
                            .accessibilityLabel(category.displayName)
                            .accessibilityHint("Shows your best card")
                    }
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(cards.count == 1 ? "Comparing 1 card" : "Comparing \(cards.count) cards")
                    if includePortalRates { Text("Portal booking rates included.") }
                }
                .font(.footnote)
                .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .background(Color(.systemGroupedBackground))
    }
}

private struct CategoryTile: View {
    let category: SpendCategory

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: category.symbol)
                .font(.title2)
                .foregroundStyle(Color.accentColor)
            Text(category.shortLabel)
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity, minHeight: 88)
        .padding(.horizontal, 6)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

private struct CategoryTileButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.8 : 1)
            .animation(.snappy(duration: 0.15), value: configuration.isPressed)
            .sensoryFeedback(.selection, trigger: configuration.isPressed) { _, pressed in pressed }
    }
}
