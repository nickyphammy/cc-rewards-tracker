import Foundation
import SwiftData

/// Editable copy of a card's personal details and standard earn rates. Edits are applied on Save
/// so Cancel can discard them. Rotating rows are managed by the catalog and aren't editable.
struct CardEditDraft: Equatable {
    struct Rate: Identifiable, Equatable {
        let id: UUID
        var category: SpendCategory
        var rateText: String
        /// The unconditional Everything Else row: always present, category locked.
        let isBase: Bool
        let condition: MultiplierCondition?
        let brand: String?
        fileprivate let source: PersistentIdentifier?

        var rate: Decimal? {
            guard let value = Decimal(string: rateText.trimmingCharacters(in: .whitespaces)), value > 0, value <= 100 else { return nil }
            return value
        }
    }

    var nickname: String
    var last4: String
    var network: CardNetwork
    var colorHex: String?
    var openedOn: Date?
    var rates: [Rate]

    init(card: UserCard) {
        nickname = card.nickname ?? ""
        last4 = card.last4 ?? ""
        network = card.network
        colorHex = card.colorHex
        openedOn = card.openedOn
        rates = card.standardMultipliers.map { m in
            Rate(id: UUID(), category: m.category, rateText: Formatters.number(m.rate),
                 isBase: m.category == .other && m.condition == nil,
                 condition: m.condition, brand: m.brand, source: m.persistentModelID)
        }
    }

    var last4IsValid: Bool {
        last4.isEmpty || (last4.count == 4 && last4.allSatisfy(\.isASCIIDigit))
    }

    var ratesAreValid: Bool {
        rates.allSatisfy { $0.rate != nil } && rates.filter(\.isBase).count == 1
    }

    var isValid: Bool { last4IsValid && ratesAreValid }

    mutating func addRate() {
        let used = Set(rates.map(\.category))
        let category = SpendCategory.allCases.first { !used.contains($0) && $0 != .other } ?? .dining
        rates.insert(Rate(id: UUID(), category: category, rateText: "2", isBase: false,
                          condition: nil, brand: nil, source: nil), at: 0)
    }

    /// Writes the draft to `card`. Changing rates marks a catalog card `hasLocalEdits`;
    /// personal fields (nickname, last 4, network, color, open date) don't.
    func apply(to card: UserCard, context: ModelContext) {
        card.nickname = nickname.trimmingCharacters(in: .whitespaces).isEmpty ? nil : nickname.trimmingCharacters(in: .whitespaces)
        card.last4 = last4.isEmpty ? nil : last4
        card.network = network
        card.colorHex = colorHex
        card.openedOn = openedOn

        guard ratesChanged(from: card) else { return }
        let existing = card.standardMultipliers
        let kept = Set(rates.compactMap(\.source))
        for row in existing where !kept.contains(row.persistentModelID) {
            context.delete(row)
        }
        var all = (card.multipliers ?? []).filter { kept.contains($0.persistentModelID) || $0.rotatingQuarter != nil }
        for draft in rates {
            guard let value = draft.rate else { continue }
            if let source = draft.source, let row = existing.first(where: { $0.persistentModelID == source }) {
                row.category = draft.category
                row.rate = value
            } else {
                all.append(Multiplier(category: draft.category, rate: value))
            }
        }
        card.multipliers = all
        if card.catalogID != nil { card.hasLocalEdits = true }
    }

    func hasChanges(from card: UserCard) -> Bool {
        let original = CardEditDraft(card: card)
        return nickname != original.nickname || last4 != original.last4 || network != original.network
            || colorHex != original.colorHex || openedOn != original.openedOn || ratesChanged(from: card)
    }

    func ratesChanged(from card: UserCard) -> Bool {
        let original = card.standardMultipliers.map { "\($0.category.rawValue)=\(Formatters.number($0.rate))" }
        let edited = rates.map { "\($0.category.rawValue)=\($0.rate.map(Formatters.number) ?? $0.rateText)" }
        return original.sorted() != edited.sorted()
    }
}

extension Character {
    var isASCIIDigit: Bool { ("0"..."9").contains(self) }
}
