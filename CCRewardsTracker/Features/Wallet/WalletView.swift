import SwiftData
import SwiftUI

/// WA-1: the user's cards. Tap for detail, swipe to archive or delete, drag to reorder.
struct WalletView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \UserCard.sortIndex) private var cards: [UserCard]
    @State private var path: [UserCard] = []
    @State private var showingPicker = false
    @State private var pendingDelete: UserCard?
    @State private var showArchived = false

    private var active: [UserCard] { cards.filter { !$0.isArchived } }
    private var archived: [UserCard] { cards.filter(\.isArchived) }

    var body: some View {
        NavigationStack(path: $path) {
            List {
                if !active.isEmpty {
                    Section {
                        ForEach(active) { card in
                            NavigationLink(value: card) { WalletRow(card: card) }
                                .swipeActions {
                                    Button("Delete", systemImage: "trash", role: .destructive) { pendingDelete = card }
                                    Button("Archive", systemImage: "archivebox") { card.isArchived = true }
                                        .tint(.gray)
                                }
                        }
                        .onMove(perform: move)
                    }
                }
                if !archived.isEmpty {
                    Section {
                        DisclosureGroup("Archived (\(archived.count))", isExpanded: $showArchived) {
                            ForEach(archived) { card in
                                NavigationLink(value: card) { WalletRow(card: card) }
                                    .swipeActions {
                                        Button("Delete", systemImage: "trash", role: .destructive) { pendingDelete = card }
                                        Button("Unarchive", systemImage: "tray.and.arrow.up") { card.isArchived = false }
                                    }
                            }
                        }
                    }
                }
            }
            .overlay {
                if active.isEmpty {
                    ContentUnavailableView {
                        Label("Your wallet is empty", systemImage: "wallet.bifold")
                    } description: {
                        Text("Add the cards you carry from the catalog.")
                    } actions: {
                        Button("Add Cards") { showingPicker = true }
                            .primaryActionStyle()
                    }
                }
            }
            .navigationTitle("Wallet")
            .navigationDestination(for: UserCard.self) { CardDetailView(card: $0) }
            .toolbar {
                if active.count >= 2 {
                    ToolbarItem(placement: .topBarLeading) { EditButton() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Add Cards", systemImage: "plus") { showingPicker = true }
                }
            }
            .sheet(isPresented: $showingPicker) { CardPickerView(mode: .addToWallet) }
            .deleteConfirmation(for: $pendingDelete) { path.removeAll() }
            .task { openDebugCard() }
        }
    }

    private func move(from source: IndexSet, to destination: Int) {
        var reordered = active
        reordered.move(fromOffsets: source, toOffset: destination)
        for (index, card) in reordered.enumerated() { card.sortIndex = index }
    }

    private func openDebugCard() {
        guard path.isEmpty, let id = DebugLaunch.openCard,
              let card = cards.first(where: { $0.catalogID == id }) else { return }
        path = [card]
    }
}

private struct WalletRow: View {
    @Environment(CatalogStore.self) private var catalog
    let card: UserCard

    var body: some View {
        HStack(spacing: 12) {
            CardTile(card: card, size: .small)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(card.displayName)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                if card.isArchived {
                    StatusBadge(kind: .archived)
                } else if card.needsActivation(quarter: Quarter.key(for: .now)) {
                    StatusBadge(kind: .activate(Formatters.quarter(Quarter.key(for: .now)).components(separatedBy: " ").first ?? ""))
                } else if card.hasLocalEdits {
                    StatusBadge(kind: .localEdits)
                }
            }
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
    }

    private var subtitle: String {
        var issuerPart = card.issuer
        if let last4 = card.last4, !last4.isEmpty { issuerPart += " ••\(last4)" }
        let fee = Formatters.feeLine(annualFee: card.annualFee,
                                     membershipMonthly: card.requiredMembershipMonthlyFee,
                                     membershipAnnual: card.requiredMembershipAnnualFee)
        let credits = card.activeCredits.count
        let creditPart = credits == 0 ? nil : (credits == 1 ? "1 credit" : "\(credits) credits")
        return ([issuerPart, fee] + [creditPart].compactMap { $0 }).joined(separator: " · ")
    }
}

extension View {
    /// The delete confirmation used by Wallet and Card Detail (docs/ui/FLOWS.md F9).
    func deleteConfirmation(for card: Binding<UserCard?>, onDeleted: @escaping () -> Void = {}) -> some View {
        modifier(DeleteConfirmation(card: card, onDeleted: onDeleted))
    }
}

private struct DeleteConfirmation: ViewModifier {
    @Environment(\.modelContext) private var context
    @Binding var card: UserCard?
    let onDeleted: () -> Void

    func body(content: Content) -> some View {
        content.confirmationDialog(
            "Delete \(card?.displayName ?? "card")?",
            isPresented: Binding(get: { card != nil }, set: { if !$0 { card = nil } }),
            titleVisibility: .visible,
            presenting: card
        ) { target in
            Button("Delete Card", role: .destructive) {
                context.delete(target)
                try? context.save()
                card = nil
                onDeleted()
            }
            Button("Archive Instead") {
                target.isArchived = true
                card = nil
            }
        } message: { _ in
            Text("This removes the card and its credit history. Archive it instead to keep the history.")
        }
    }
}
