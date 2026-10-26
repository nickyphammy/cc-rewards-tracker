import Foundation
import Testing
@testable import CCRewardsTracker

/// Fixtures from docs/RECOMMENDATION_ENGINE.md "Examples (test fixtures)".
struct RecommendationEngineTests {
    let a = CardSnapshot(id: UUID(), name: "A", rewardCurrencyID: "points", rateUnit: .multiplier, multipliers: [
        .init(category: .dining, rate: 4),
        .init(category: .groceries, rate: 4, capAmount: 25000, capPeriod: .annual, afterCapRate: 1),
        .init(category: .flights, rate: 3),
        .init(category: .other, rate: 1),
    ])
    let b = CardSnapshot(id: UUID(), name: "B", rewardCurrencyID: "cash", rateUnit: .percent, multipliers: [
        .init(category: .dining, rate: 3),
        .init(category: .groceries, rate: 3),
        .init(category: .other, rate: 1.5),
    ])
    let c = CardSnapshot(id: UUID(), name: "C", rewardCurrencyID: "points", rateUnit: .multiplier, multipliers: [
        .init(category: .dining, rate: 3),
        .init(category: .flights, rate: 5, condition: .bookedViaPortal),
        .init(category: .other, rate: 1),
    ])
    let oct2026 = Calendar(identifier: .gregorian).date(from: DateComponents(year: 2026, month: 10, day: 26))!

    private func rank(_ category: SpendCategory, portal: Bool = false, wallet: [CardSnapshot]? = nil) -> [CardRecommendation] {
        RecommendationEngine.recommend(
            RecommendationRequest(category: category, date: oct2026, includePortalRates: portal,
                                  calendar: Calendar(identifier: .gregorian)),
            wallet: wallet ?? [c, b, a]
        )
    }

    @Test func dining() {
        let r = rank(.dining)
        #expect(r.map(\.name) == ["A", "B", "C"])
        #expect(r.map(\.rate) == [4, 3, 3])
        #expect(r.map(\.isTie) == [false, true, true])
    }

    @Test func groceriesShowsCapAndFallsBackToBase() {
        let r = rank(.groceries)
        #expect(r.map(\.name) == ["A", "B", "C"])
        #expect(r[0].caveats == [.cap(amount: 25000, period: .annual, afterCapRate: 1)])
        #expect(r[2].rate == 1)
    }

    @Test func flightsExcludesPortalRateButHintsIt() {
        let r = rank(.flights)
        #expect(r.map(\.name) == ["A", "B", "C"])
        #expect(r.map(\.rate) == [3, 1.5, 1])
        #expect(r[2].caveats == [.betterRateAvailable(rate: 5, reason: .bookedViaPortal, brand: nil, quarter: nil)])
    }

    @Test func flightsWithPortalRatesIncluded() {
        let r = rank(.flights, portal: true)
        #expect(r.first?.name == "C")
        #expect(r.first?.rate == 5)
        #expect(r.first?.caveats == [.condition(.bookedViaPortal, brand: nil)])
    }

    @Test func gasComparesBaseRatesAndBreaksTieAlphabetically() {
        let r = rank(.gas)
        #expect(r.map(\.name) == ["B", "A", "C"])
        #expect(r.map(\.isTie) == [false, true, true])
    }

    @Test func rotatingBonusNeedsActivation() {
        var flex = CardSnapshot(id: UUID(), name: "Flex", rewardCurrencyID: "chase_ur", rateUnit: .percent, multipliers: [
            .init(category: .dining, rate: 5, condition: .requiresActivation, rotatingQuarter: "2026Q4"),
            .init(category: .dining, rate: 3),
            .init(category: .other, rate: 1),
        ])
        let before = rank(.dining, wallet: [flex])[0]
        #expect(before.rate == 3)
        #expect(before.caveats == [.betterRateAvailable(rate: 5, reason: .requiresActivation, brand: nil, quarter: "2026Q4")])

        flex.activatedRotating = ["2026Q4"]
        let after = rank(.dining, wallet: [flex])[0]
        #expect(after.rate == 5)
        #expect(after.caveats == [.activatedBonus(quarter: "2026Q4")])

        // Last quarter's activation doesn't carry over.
        flex.activatedRotating = ["2026Q3"]
        #expect(rank(.dining, wallet: [flex])[0].rate == 3)
    }

    @Test func brandOnlyIsAlwaysAHint() {
        let card = CardSnapshot(id: UUID(), name: "Reserve", rewardCurrencyID: "chase_ur", rateUnit: .multiplier, multipliers: [
            .init(category: .transit, rate: 5, condition: .brandOnly, brand: "Lyft"),
            .init(category: .other, rate: 1),
        ])
        let r = rank(.transit, portal: true, wallet: [card])[0]
        #expect(r.rate == 1)
        #expect(r.caveats == [.betterRateAvailable(rate: 5, reason: .brandOnly, brand: "Lyft", quarter: nil)])
    }

    @Test func unchosenSelectableCategoryPromptsChoice() {
        var card = CardSnapshot(id: UUID(), name: "Custom Cash", rewardCurrencyID: "cash", rateUnit: .percent, multipliers: [
            .init(category: .dining, rate: 3, isUserSelectable: true, eligibleCategories: [.dining, .gas]),
            .init(category: .other, rate: 1),
        ])
        #expect(rank(.gas, wallet: [card])[0].caveats == [.chooseCategory(rate: 3)])
        card.selectedCategories = [.gas]
        #expect(rank(.gas, wallet: [card])[0].rate == 3)
        #expect(rank(.dining, wallet: [card])[0].rate == 1)
    }

    @Test func singleCardIsNeverATie() {
        #expect(rank(.dining, wallet: [a]).map(\.isTie) == [false])
    }
}
