import SwiftData
import SwiftUI

/// Search or scroll the catalog and tick every card you have. Used as the first screen on
/// first launch, and as the Add Cards sheet from Wallet and Best Card.
struct CardPickerView: View {
    enum Mode { case onboarding, addToWallet }

    let mode: Mode
    var onFinish: () -> Void = {}

    @Environment(CatalogStore.self) private var catalog
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var walletCards: [UserCard]

    @State private var query = ""
    @State private var selected: Set<String>

    init(mode: Mode, preselected: Set<String> = [], onFinish: @escaping () -> Void = {}) {
        self.mode = mode
        self.onFinish = onFinish
        _selected = State(initialValue: preselected)
    }

    var body: some View {
        NavigationStack {
            List {
                if mode == .onboarding && query.isEmpty {
                    Section {
                        Text("Select every card you carry. We'll use them to tell you which card earns the most for each purchase.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 0, leading: 4, bottom: 0, trailing: 4))
                }

                if query.isEmpty {
                    ForEach(catalog.cardsByIssuer, id: \.issuer) { group in
                        Section(group.issuer) {
                            ForEach(group.cards) { row($0, showIssuer: false) }
                        }
                    }
                } else {
                    let results = CatalogSearch.filter(catalog.cards, query: query)
                    if results.isEmpty {
                        ContentUnavailableView.search(text: query)
                            .listRowBackground(Color.clear)
                    } else {
                        Section {
                            ForEach(results) { row($0, showIssuer: true) }
                        }
                    }
                }

                Section {
                } footer: {
                    Text("Don't see your card? Custom cards are coming soon. Card terms checked \(catalogDate).")
                }
            }
            .navigationTitle(mode == .onboarding ? "Your Cards" : "Add Cards")
            .navigationBarTitleDisplayMode(mode == .onboarding ? .large : .inline)
            .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search cards")
            .toolbar {
                if mode == .addToWallet {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
                    }
                }
            }
            .safeAreaBar(edge: .bottom) { bottomBar }
        }
    }

    private func row(_ card: CatalogCard, showIssuer: Bool) -> some View {
        let isSelected = selected.contains(card.id)
        let owned = walletCards.contains { $0.catalogID == card.id }
        let fee = Formatters.feeLine(annualFee: card.annualFee,
                                     membershipMonthly: card.requiredMembership?.monthlyFee,
                                     membershipAnnual: card.requiredMembership?.annualFee)
        return Button {
            if isSelected { selected.remove(card.id) } else { selected.insert(card.id) }
        } label: {
            HStack(spacing: 12) {
                CardTile(issuer: card.issuer, name: card.shortName, size: .small)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(card.shortName)
                        .font(.body)
                        .foregroundStyle(.primary)
                    Text(showIssuer ? "\(card.issuer) · \(fee)" : fee)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    if card.retired { StatusBadge(kind: .retired) }
                    if owned { StatusBadge(kind: .inWallet) }
                }
                Spacer(minLength: 8)
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(isSelected ? Color.accentColor : Color.secondary.opacity(0.5))
                    .contentTransition(.symbolEffect(.replace))
                    .accessibilityHidden(true)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: isSelected)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
        .accessibilityLabel("\(card.shortName), \(card.issuer), \(fee)\(card.retired ? ", no longer offered" : "")\(owned ? ", in your wallet" : "")")
    }

    private var bottomBar: some View {
        VStack(spacing: 8) {
            Button {
                addSelected()
            } label: {
                Text(addTitle)
                    .frame(maxWidth: .infinity)
            }
            .primaryActionStyle()
            .disabled(selected.isEmpty)

            if mode == .onboarding {
                Button("Skip for Now") { onFinish() }
                    .font(.subheadline)
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    private var addTitle: String {
        switch selected.count {
        case 0: "Select Your Cards"
        case 1: "Add 1 Card"
        default: "Add \(selected.count) Cards"
        }
    }

    private var catalogDate: String {
        let dates = catalog.cards.map(\.lastVerified).sorted()
        guard let latest = dates.last,
              let date = try? Date(latest, strategy: .iso8601.year().month().day()) else { return "recently" }
        return date.formatted(.dateTime.month(.abbreviated).day().year())
    }

    private func addSelected() {
        var nextIndex = (walletCards.map(\.sortIndex).max() ?? -1) + 1
        // Add in catalog display order so the wallet reads the same way the picker did.
        for template in catalog.cardsByIssuer.flatMap(\.cards) where selected.contains(template.id) {
            CardFactory.addCard(from: template, sortIndex: nextIndex, to: context)
            nextIndex += 1
        }
        try? context.save()
        onFinish()
        if mode == .addToWallet { dismiss() }
    }
}

#Preview("Onboarding") {
    CardPickerView(mode: .onboarding, preselected: ["amex_gold", "chase_freedom_flex"])
        .environment(try! CatalogStore.bundled())
        .modelContainer(for: UserCard.self, inMemory: true)
}
