import SwiftData
import SwiftUI

/// BC-2: which card to use for one category, why, and how the rest of the wallet ranks.
struct BestCardResultView: View {
    let category: SpendCategory

    @Environment(CatalogStore.self) private var catalog
    @Query(filter: #Predicate<UserCard> { !$0.isArchived }, sort: \UserCard.sortIndex) private var cards: [UserCard]
    @AppStorage("includePortalRates") private var includePortalRates = false
    @State private var amountText = DebugLaunch.amount ?? ""
    @State private var showingPicker = false

    private var amount: Decimal? {
        guard let value = Decimal(string: amountText), value > 0 else { return nil }
        return value
    }

    private var results: [CardRecommendation] {
        let request = RecommendationRequest(category: category, date: .now, includePortalRates: includePortalRates)
        return RecommendationEngine.recommend(request, wallet: cards.map { CardSnapshot(card: $0, catalog: catalog) })
    }

    var body: some View {
        let ranked = results
        let topRate = ranked.first?.rate
        let winners = ranked.prefix { $0.rate == topRate }
        let others = Array(ranked.dropFirst(winners.count))

        List {
            Section {
                hero(Array(winners))
            }

            Section {
                AmountField(text: $amountText)
            }

            if others.isEmpty {
                Section {
                    Button("Add Cards", systemImage: "plus") { showingPicker = true }
                } footer: {
                    Text("Add more cards to compare.")
                }
            } else {
                Section {
                    ForEach(Array(others.enumerated()), id: \.element.id) { offset, result in
                        let position = winners.count + offset
                        if result.isTie, offset == 0 || others[offset - 1].rate != result.rate {
                            TieHeader(rank: position + 1,
                                      count: ranked.filter { $0.rate == result.rate }.count,
                                      rate: result.rate)
                        }
                        if let card = card(for: result) {
                            NavigationLink(value: card) {
                                ResultRow(card: card, result: result, amount: amount, terms: CardTerms(card: card, catalog: catalog))
                            }
                        }
                    }
                } header: {
                    Text("Other Cards")
                } footer: {
                    Text("Ranked by earn rate. 1x points counts the same as 1% cash back. Terms can change; check each card for details.")
                }
            }
        }
        .navigationTitle(category.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .animation(.default, value: amountText)
        .sheet(isPresented: $showingPicker) { CardPickerView(mode: .addToWallet) }
    }

    private func card(for result: CardRecommendation) -> UserCard? {
        cards.first { $0.id == result.cardID }
    }

    @ViewBuilder private func hero(_ winners: [CardRecommendation]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            if winners.count > 1, let rate = winners.first?.rate {
                Label("TIE · \(winners.count == 2 ? "EITHER CARD" : "ANY OF THESE") EARNS \(Formatters.number(rate))",
                      systemImage: "equal.circle")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            } else {
                Text("USE THIS CARD")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            ForEach(Array(winners.enumerated()), id: \.element.id) { index, result in
                if index > 0 { Divider() }
                if let card = card(for: result) {
                    NavigationLink(value: card) {
                        HeroCard(card: card, result: result, amount: amount, terms: CardTerms(card: card, catalog: catalog),
                                 category: category, isTie: winners.count > 1)
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }
}

private struct HeroCard: View {
    let card: UserCard
    let result: CardRecommendation
    let amount: Decimal?
    let terms: CardTerms
    let category: SpendCategory
    let isTie: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                CardTile(card: card, size: .medium)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(card.displayName)
                        .font(.title2.weight(.semibold))
                    Text(issuerLine(card))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            Text(terms.rateFull(result.rate))
                .font(.largeTitle.weight(.bold))
                .fontDesign(.rounded)
                .monospacedDigit()
                .foregroundStyle(Color.accentColor)
                .contentTransition(.numericText())
            if let amount {
                Text(Formatters.estimate(amount: amount, rate: result.rate, unit: terms.unit, unitName: terms.unitName))
                    .font(.subheadline.monospacedDigit())
                    .contentTransition(.numericText())
            }
            CaveatList(caveats: result.caveats, card: card, terms: terms)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(isTie ? "Tied for best" : "Best card"): \(card.displayName), \(issuerLine(card)). \(terms.rateSpoken(result.rate)) on \(category.shortLabel.lowercased()).")
    }
}

private struct ResultRow: View {
    let card: UserCard
    let result: CardRecommendation
    let amount: Decimal?
    let terms: CardTerms

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 12) {
                CardTile(card: card, size: .small)
                    .accessibilityHidden(true)
                Text(card.displayName)
                Spacer()
                Text(terms.rate(result.rate))
                    .font(.body.weight(.semibold).monospacedDigit())
            }
            if let amount {
                Text(Formatters.estimate(amount: amount, rate: result.rate, unit: terms.unit, unitName: terms.unitName))
                    .font(.footnote.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .padding(.leading, 56)
            }
            CaveatList(caveats: result.caveats, card: card, terms: terms)
                .padding(.leading, 56)
        }
        .accessibilityElement(children: .combine)
    }
}

private struct TieHeader: View {
    let rank: Int
    let count: Int
    let rate: Decimal

    var body: some View {
        Label("Tied for \(Formatters.ordinal(rank)) · \(count == 2 ? "both" : "all") earn \(Formatters.number(rate))",
              systemImage: "equal.circle")
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
    }
}

/// Caveats first, then hints. Never truncated.
private struct CaveatList: View {
    let caveats: [Caveat]
    let card: UserCard
    let terms: CardTerms

    var body: some View {
        let caveatLines = caveats.filter { !$0.isHint }
        let hintLines = caveats.filter(\.isHint)
        if !caveats.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                ForEach(caveatLines, id: \.self) { caveat in
                    if let text = text(for: caveat) {
                        CaveatRow(text: text, symbol: caveat == .dependsOnSpendMix ? "chart.bar" : "info.circle")
                    }
                }
                ForEach(hintLines, id: \.self) { hint in
                    if let text = text(for: hint) { HintRow(text: text) }
                }
            }
        }
    }

    private func text(for caveat: Caveat) -> String? {
        switch caveat {
        case let .condition(condition, brand):
            return CaveatCopy.condition(condition, brand: brand, issuer: card.issuer)
        case let .activatedBonus(quarter):
            return "\(Formatters.quarter(quarter)) bonus category, activated"
        case let .cap(amount, period, afterCapRate):
            return capText(amount: amount, period: period, afterCapRate: afterCapRate)
        case let .betterRateAvailable(rate, reason, brand, _):
            let r = terms.rate(rate)
            switch reason {
            case .bookedViaPortal: return "\(r) if booked through the \(card.issuer) travel portal"
            case .requiresActivation: return "\(r) this quarter if you activate it"
            case .brandOnly: return "\(r) if it's a \(brand ?? "select brand") purchase"
            default: return nil
            }
        case let .chooseCategory(rate):
            return "Choose your \(terms.rate(rate)) category"
        case .dependsOnSpendMix:
            return "Only if this is your top spending category this billing cycle"
        }
    }

    private func capText(amount: Decimal, period: Period, afterCapRate: Decimal) -> String {
        let rate = card.multipliers?.first { $0.capAmount == amount && $0.capPeriod == period }?.rate ?? afterCapRate
        return Formatters.cap(rate: rate, unit: terms.unit, amount: amount, period: period, afterCapRate: afterCapRate)
    }
}

private func issuerLine(_ card: UserCard) -> String {
    if let last4 = card.last4, !last4.isEmpty { return "\(card.issuer) ••\(last4)" }
    return card.issuer
}

extension CardSnapshot {
    init(card: UserCard, catalog: CatalogStore) {
        self.init(
            id: card.id,
            name: card.displayName,
            rewardCurrencyID: card.rewardCurrencyID,
            rateUnit: CardTerms(card: card, catalog: catalog).unit,
            multipliers: (card.multipliers ?? []).map {
                MultiplierSnapshot(category: $0.category, rate: $0.rate, capAmount: $0.capAmount, capPeriod: $0.capPeriod,
                                   afterCapRate: $0.afterCapRate, condition: $0.condition, brand: $0.brand,
                                   rotatingQuarter: $0.rotatingQuarter, isUserSelectable: $0.isUserSelectable,
                                   isAutoTopCategory: $0.isAutoTopCategory, eligibleCategories: $0.eligibleCategories)
            },
            activatedRotating: Set((card.categorySelections ?? []).filter(\.activated).compactMap(\.quarter)),
            selectedCategories: Set((card.categorySelections ?? []).filter { $0.quarter == nil }.compactMap(\.category))
        )
    }
}
