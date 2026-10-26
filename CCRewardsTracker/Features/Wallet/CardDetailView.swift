import SwiftData
import SwiftUI

/// WA-2: rates, bonus-category activation, credits and personal details for one card.
struct CardDetailView: View {
    @Environment(CatalogStore.self) private var catalog
    @Environment(\.dismiss) private var dismiss
    @Bindable var card: UserCard
    @State private var editing = false
    @State private var pendingDelete: UserCard?

    private var terms: CardTerms { CardTerms(card: card, catalog: catalog) }
    private var currentQuarter: String { Quarter.key(for: .now) }

    var body: some View {
        List {
            Section {
                CardTile(card: card, size: .large)
                    .frame(maxWidth: .infinity)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
            }

            if card.isArchived {
                Section {
                    HStack {
                        Label("Archived. Not used in recommendations.", systemImage: "archivebox")
                            .font(.subheadline)
                        Spacer()
                        Button("Unarchive") { card.isArchived = false }
                    }
                }
            }

            bonusCategories

            Section {
                ForEach(card.standardMultipliers) { row in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Label(row.category.displayName, systemImage: row.category.symbol)
                            Spacer()
                            Text(terms.rate(row.rate))
                                .font(.body.weight(.semibold).monospacedDigit())
                        }
                        ForEach(CaveatCopy.caveats(for: row, terms: terms, issuer: card.issuer), id: \.self) {
                            CaveatRow(text: $0)
                        }
                    }
                    .accessibilityElement(children: .combine)
                }
            } header: {
                Text("Earn Rates")
            } footer: {
                Text(terms.unit == .percent ? "Cash back" : terms.programName)
            }

            Section("Credits") {
                if card.activeCredits.isEmpty {
                    Text("No credits").foregroundStyle(.secondary)
                } else {
                    ForEach(card.activeCredits) { CreditSummaryRow(credit: $0) }
                }
            }

            details
        }
        .navigationTitle(card.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu("More", systemImage: "ellipsis") {
                    Button("Edit Details", systemImage: "pencil") { editing = true }
                    if card.isArchived {
                        Button("Unarchive", systemImage: "tray.and.arrow.up") { card.isArchived = false }
                    } else {
                        Button("Archive", systemImage: "archivebox") { card.isArchived = true }
                    }
                    Button("Delete", systemImage: "trash", role: .destructive) { pendingDelete = card }
                }
            }
        }
        .sheet(isPresented: $editing) { CardEditorView(card: card) }
        .deleteConfirmation(for: $pendingDelete) { dismiss() }
        .onAppear {
            if ProcessInfo.processInfo.arguments.contains("-openEdit") { editing = true }
        }
    }

    @ViewBuilder private var bonusCategories: some View {
        let quarters = card.rotatingQuarters(from: currentQuarter)
        if !quarters.isEmpty {
            Section {
                ForEach(quarters, id: \.quarter) { q in
                    VStack(alignment: .leading, spacing: 6) {
                        Text("\(Formatters.quarter(q.quarter)) · \(terms.rate(q.rate))")
                            .font(.headline)
                        Text(q.categories.map(\.shortLabel).formatted(.list(type: .and)))
                            .font(.subheadline)
                        if let cap = CaveatCopy.cap(for: q.sample, terms: terms) { CaveatRow(text: cap) }
                        Toggle("Activated", isOn: Binding(
                            get: { card.isActivated(quarter: q.quarter) },
                            set: { card.setActivated($0, quarter: q.quarter) }
                        ))
                    }
                }
            } header: {
                Text("Bonus Categories")
            } footer: {
                Text("Activate each quarter on the \(card.issuer) site or app, then turn it on here.")
            }
        }
    }

    private var details: some View {
        Section {
            LabeledContent("Annual fee", value: card.annualFee > 0 ? Formatters.money(card.annualFee) : "None")
            if let membership = card.requiredMembershipName {
                LabeledContent("Requires", value: membershipText(membership))
            }
            Picker("Network", selection: $card.network) {
                ForEach(CardNetwork.allCases) { Text($0.displayName).tag($0) }
            }
            .pickerStyle(.menu)
            LabeledContent("Nickname", value: card.nickname?.isEmpty == false ? card.nickname! : "—")
            LabeledContent("Last 4", value: card.last4?.isEmpty == false ? card.last4! : "—")
            LabeledContent("Card opened", value: card.openedOn?.formatted(.dateTime.month(.wide).year()) ?? "—")
            LabeledContent("Rewards", value: terms.programName)
        } header: {
            Text("Details")
        } footer: {
            Text(termsFooter)
        }
    }

    private func membershipText(_ name: String) -> String {
        if let monthly = card.requiredMembershipMonthlyFee { return "\(name) · \(Formatters.money(monthly))/mo" }
        if let annual = card.requiredMembershipAnnualFee { return "\(name) · \(Formatters.money(annual))/yr" }
        return name
    }

    private var termsFooter: String {
        guard let template = catalog.card(id: card.catalogID) else {
            return card.catalogID == nil ? "Custom card. You entered these terms." : "Terms details unavailable on this app version."
        }
        var lines: [String] = []
        if template.retired { lines.append("No longer offered to new applicants. Your terms stay as they are.") }
        if let date = try? Date(template.lastVerified, strategy: .iso8601.year().month().day()) {
            lines.append("Terms checked \(date.formatted(.dateTime.month(.abbreviated).day().year())). Rates and credits can change; confirm with \(card.issuer).")
        }
        return lines.joined(separator: "\n")
    }
}

private struct CreditSummaryRow: View {
    let credit: Credit

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline) {
                Text(credit.name)
                Spacer()
                Text(Formatters.money(credit.amount))
                    .font(.body.weight(.semibold).monospacedDigit())
            }
            Text(Formatters.period(credit.period, years: credit.periodYears))
                .font(.subheadline)
                .foregroundStyle(.secondary)
            if credit.requiresEnrollment && !credit.isEnrolled {
                Label("Enroll first", systemImage: "person.badge.clock")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color("Caution"))
            }
            if let notes = credit.notes, !notes.isEmpty {
                Text(notes)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }
        }
        .accessibilityElement(children: .combine)
    }
}
