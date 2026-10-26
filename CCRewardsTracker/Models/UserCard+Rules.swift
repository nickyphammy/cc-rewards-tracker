import Foundation
import SwiftData

extension UserCard {
    /// Rows that always apply (not rotating), sorted by rate with Everything Else last.
    var standardMultipliers: [Multiplier] {
        (multipliers ?? [])
            .filter { $0.rotatingQuarter == nil }
            .sorted { a, b in
                if (a.category == .other) != (b.category == .other) { return b.category == .other }
                if a.rate != b.rate { return a.rate > b.rate }
                return a.category.displayName < b.category.displayName
            }
    }

    /// Rotating bonus quarters from `fromQuarter` on, oldest first, with their categories.
    func rotatingQuarters(from fromQuarter: String) -> [(quarter: String, rate: Decimal, categories: [SpendCategory], sample: Multiplier)] {
        let rows = (multipliers ?? []).filter { ($0.rotatingQuarter ?? "") >= fromQuarter && $0.rotatingQuarter != nil }
        return Dictionary(grouping: rows) { $0.rotatingQuarter! }
            .sorted { $0.key < $1.key }
            .compactMap { quarter, rows in
                guard let first = rows.first else { return nil }
                let categories = rows.map(\.category).sorted { $0.displayName < $1.displayName }
                return (quarter, first.rate, categories, first)
            }
    }

    func isActivated(quarter: String) -> Bool {
        (categorySelections ?? []).contains { $0.quarter == quarter && $0.activated }
    }

    func setActivated(_ activated: Bool, quarter: String) {
        if let existing = (categorySelections ?? []).first(where: { $0.quarter == quarter }) {
            existing.activated = activated
        } else {
            let selection = CategorySelection(quarter: quarter, activated: activated)
            categorySelections = (categorySelections ?? []) + [selection]
        }
    }

    /// True when this quarter has rotating categories the user hasn't marked activated.
    func needsActivation(quarter: String) -> Bool {
        (multipliers ?? []).contains { $0.rotatingQuarter == quarter } && !isActivated(quarter: quarter)
    }

    var activeCredits: [Credit] {
        (credits ?? []).filter { !$0.isArchived }.sorted { $0.name < $1.name }
    }
}
