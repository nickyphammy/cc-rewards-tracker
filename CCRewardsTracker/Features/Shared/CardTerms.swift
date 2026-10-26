import SwiftUI

/// How a card's rates are shown: unit (% or x), the noun for estimates, and the program name.
struct CardTerms {
    let unit: RateUnit
    let unitName: String
    let programName: String

    init(card: UserCard, catalog: CatalogStore) {
        let currency = catalog.currency(id: card.rewardCurrencyID)
        unit = card.rateUnitOverride ?? currency?.rateUnit ?? (card.rewardCurrencyID == "cash" ? .percent : .multiplier)
        unitName = unit == .percent ? "cash back" : (currency?.unitName ?? "points")
        programName = currency?.name ?? "Points"
    }

    func rate(_ value: Decimal) -> String { Formatters.rate(value, unit: unit) }
    func rateFull(_ value: Decimal) -> String { Formatters.rateFull(value, unit: unit, unitName: unitName) }
    func rateSpoken(_ value: Decimal) -> String { Formatters.rateSpoken(value, unit: unit, unitName: unitName) }
}

/// Caveat and hint copy (docs/ui/SCREENS.md "Caveat and hint copy").
enum CaveatCopy {
    static func condition(_ condition: MultiplierCondition, brand: String?, issuer: String) -> String? {
        switch condition {
        case .bookedDirectOrPortal: "Only when booked directly or through the \(issuer) travel portal"
        case .bookedViaPortal: "Only when booked through the \(issuer) travel portal"
        case .usOnly: "U.S. purchases only"
        case .brandOnly: "\(brand ?? "Select brand") purchases only"
        case .requiresActivation: nil
        }
    }

    static func cap(for row: Multiplier, terms: CardTerms) -> String? {
        guard let amount = row.capAmount, let period = row.capPeriod else { return nil }
        return Formatters.cap(rate: row.rate, unit: terms.unit, amount: amount, period: period,
                              afterCapRate: row.afterCapRate ?? 1)
    }

    /// All caveats shown under a rate row on Card Detail.
    static func caveats(for row: Multiplier, terms: CardTerms, issuer: String) -> [String] {
        var lines: [String] = []
        if let condition = row.condition, let text = Self.condition(condition, brand: row.brand, issuer: issuer) {
            lines.append(text)
        }
        if let cap = cap(for: row, terms: terms) { lines.append(cap) }
        if row.isAutoTopCategory { lines.append("Only if this is your top spending category this billing cycle") }
        return lines
    }
}

struct CaveatRow: View {
    let text: String
    var symbol = "info.circle"

    var body: some View {
        Label {
            Text(text).fixedSize(horizontal: false, vertical: true)
        } icon: {
            Image(systemName: symbol)
        }
        .font(.footnote)
        .foregroundStyle(.secondary)
    }
}

struct HintRow: View {
    let text: String

    var body: some View {
        Label {
            Text(text).fixedSize(horizontal: false, vertical: true)
        } icon: {
            Image(systemName: "lightbulb.min").foregroundStyle(Color.accentColor)
        }
        .font(.footnote)
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color("HintTint"), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}
