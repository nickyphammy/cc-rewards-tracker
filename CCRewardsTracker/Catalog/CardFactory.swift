import Foundation
import SwiftData

/// Copies a catalog template into the user's store. Later catalog changes never touch the copy
/// silently; they arrive through "Terms updated" (docs/CARD_CATALOG.md).
enum CardFactory {
    @discardableResult
    static func addCard(from template: CatalogCard, sortIndex: Int, to context: ModelContext) -> UserCard {
        let card = UserCard()
        card.catalogID = template.id
        card.catalogRevision = template.revision
        card.issuer = template.issuer
        card.name = template.name
        card.shortName = template.shortName
        card.rateUnitOverride = template.rateUnit
        card.network = template.network
        card.annualFee = template.annualFee
        card.requiredMembershipName = template.requiredMembership?.name
        card.requiredMembershipMonthlyFee = template.requiredMembership?.monthlyFee
        card.requiredMembershipAnnualFee = template.requiredMembership?.annualFee
        card.rewardCurrencyID = template.rewardCurrency
        card.colorHex = TileColor.defaultFor(issuer: template.issuer).hex
        card.sortIndex = sortIndex
        context.insert(card)

        var multipliers: [Multiplier] = []
        for row in template.multipliers {
            if let rotating = row.rotating {
                // One row per quarter × category (docs/DATA_MODEL.md).
                for (quarter, categories) in rotating.quarters {
                    for category in categories {
                        let m = makeMultiplier(row, category: category)
                        m.rotatingQuarter = quarter
                        multipliers.append(m)
                    }
                }
            } else if let category = row.category ?? row.eligibleCategories?.first {
                multipliers.append(makeMultiplier(row, category: category))
            }
        }
        card.multipliers = multipliers

        card.credits = template.credits.map { c in
            let credit = Credit(name: c.name, amount: c.amount, period: c.period)
            credit.catalogCreditID = c.id
            credit.periodYears = c.periodYears
            credit.resetBasis = c.resetBasis
            credit.notes = c.notes
            credit.requiresEnrollment = c.requiresEnrollment ?? false
            return credit
        }
        return card
    }

    private static func makeMultiplier(_ row: CatalogMultiplier, category: SpendCategory) -> Multiplier {
        let m = Multiplier(category: category, rate: row.rate)
        m.capAmount = row.cap?.amount
        m.capPeriod = row.cap?.period
        m.afterCapRate = row.afterCapRate
        m.condition = row.condition
        m.brand = row.brand
        m.isUserSelectable = row.userSelectable ?? false
        m.isAutoTopCategory = row.autoTopCategory ?? false
        m.eligibleCategories = row.eligibleCategories
        return m
    }
}
