import Foundation

// Ranks the wallet for one spending category by raw multiplier (docs/RECOMMENDATION_ENGINE.md).
// Plain value types only, so tests build fixtures without SwiftData.

nonisolated struct MultiplierSnapshot: Sendable, Hashable {
    var category: SpendCategory
    var rate: Decimal
    var capAmount: Decimal?
    var capPeriod: Period?
    var afterCapRate: Decimal?
    var condition: MultiplierCondition?
    var brand: String?
    var rotatingQuarter: String?
    var isUserSelectable = false
    var isAutoTopCategory = false
    var eligibleCategories: [SpendCategory]?

    var isBase: Bool {
        category == .other && condition == nil && rotatingQuarter == nil && !isUserSelectable
    }
}

nonisolated struct CardSnapshot: Sendable, Identifiable {
    let id: UUID
    let name: String
    let rewardCurrencyID: String
    let rateUnit: RateUnit
    let multipliers: [MultiplierSnapshot]
    var activatedRotating: Set<String> = []
    var selectedCategories: Set<SpendCategory> = []

    var isCashBack: Bool { rewardCurrencyID == "cash" }
}

nonisolated struct RecommendationRequest: Sendable {
    let category: SpendCategory
    let date: Date
    var includePortalRates = false
    var calendar = Calendar.current
}

nonisolated enum Caveat: Sendable, Hashable {
    case condition(MultiplierCondition, brand: String?)
    case activatedBonus(quarter: String)
    case cap(amount: Decimal, period: Period, afterCapRate: Decimal)
    case betterRateAvailable(rate: Decimal, reason: MultiplierCondition, brand: String?, quarter: String?)
    case chooseCategory(rate: Decimal)
    case dependsOnSpendMix

    var isHint: Bool {
        switch self {
        case .betterRateAvailable, .chooseCategory: true
        default: false
        }
    }
}

nonisolated struct CardRecommendation: Sendable, Identifiable {
    let cardID: UUID
    let name: String
    let rate: Decimal
    let rateUnit: RateUnit
    let isCategorySpecific: Bool
    let isCashBack: Bool
    let caveats: [Caveat]
    var isTie = false

    var id: UUID { cardID }
}

nonisolated enum RecommendationEngine {
    static func recommend(_ request: RecommendationRequest, wallet: [CardSnapshot]) -> [CardRecommendation] {
        let quarter = Quarter.key(for: request.date, calendar: request.calendar)
        var results = wallet.map { evaluate($0, request: request, quarter: quarter) }

        results.sort { a, b in
            if a.rate != b.rate { return a.rate > b.rate }
            if a.isCategorySpecific != b.isCategorySpecific { return a.isCategorySpecific }
            if a.isCashBack != b.isCashBack { return a.isCashBack }
            let aClean = a.caveats.isEmpty, bClean = b.caveats.isEmpty
            if aClean != bClean { return aClean }
            return a.name.localizedStandardCompare(b.name) == .orderedAscending
        }
        for i in results.indices {
            let sameAsPrevious = i > 0 && results[i - 1].rate == results[i].rate
            let sameAsNext = i + 1 < results.count && results[i + 1].rate == results[i].rate
            results[i].isTie = sameAsPrevious || sameAsNext
        }
        return results
    }

    private static func evaluate(_ card: CardSnapshot, request: RecommendationRequest, quarter: String) -> CardRecommendation {
        var applied: [MultiplierSnapshot] = []
        var hints: [Caveat] = []
        var chooseRate: Decimal?

        for row in card.multipliers {
            if let rowQuarter = row.rotatingQuarter {
                guard rowQuarter == quarter, row.category == request.category else { continue }
                if card.activatedRotating.contains(rowQuarter) {
                    applied.append(row)
                } else {
                    hints.append(.betterRateAvailable(rate: row.rate, reason: .requiresActivation, brand: nil, quarter: rowQuarter))
                }
                continue
            }
            if row.isUserSelectable {
                let eligible = Set(row.eligibleCategories ?? [row.category])
                guard eligible.contains(request.category) else { continue }
                if card.selectedCategories.isDisjoint(with: eligible) {
                    chooseRate = max(chooseRate ?? 0, row.rate)
                } else if card.selectedCategories.contains(request.category) {
                    applied.append(row)
                }
                continue
            }
            guard row.category == request.category else { continue }
            switch row.condition {
            case .bookedViaPortal where !request.includePortalRates:
                hints.append(.betterRateAvailable(rate: row.rate, reason: .bookedViaPortal, brand: nil, quarter: nil))
            case .brandOnly:
                hints.append(.betterRateAvailable(rate: row.rate, reason: .brandOnly, brand: row.brand, quarter: nil))
            case .requiresActivation:
                hints.append(.betterRateAvailable(rate: row.rate, reason: .requiresActivation, brand: nil, quarter: nil))
            default:
                applied.append(row)
            }
        }

        let chosen = applied.max { $0.rate < $1.rate } ?? card.multipliers.first(where: \.isBase)
        let rate = chosen?.rate ?? 1

        var caveats: [Caveat] = []
        if let chosen {
            if let q = chosen.rotatingQuarter {
                caveats.append(.activatedBonus(quarter: q))
            } else if let condition = chosen.condition {
                caveats.append(.condition(condition, brand: chosen.brand))
            }
            if let amount = chosen.capAmount, let period = chosen.capPeriod {
                caveats.append(.cap(amount: amount, period: period, afterCapRate: chosen.afterCapRate ?? 1))
            }
            if chosen.isAutoTopCategory { caveats.append(.dependsOnSpendMix) }
        }
        caveats += bestHints(hints, above: rate)
        if let chooseRate, chooseRate > rate { caveats.append(.chooseCategory(rate: chooseRate)) }

        return CardRecommendation(
            cardID: card.id, name: card.name, rate: rate, rateUnit: card.rateUnit,
            isCategorySpecific: chosen.map { !$0.isBase } ?? false,
            isCashBack: card.isCashBack, caveats: caveats
        )
    }

    /// Keeps only hints better than the rate used, one per reason/brand (the highest), best first.
    private static func bestHints(_ hints: [Caveat], above rate: Decimal) -> [Caveat] {
        var best: [String: (Decimal, Caveat)] = [:]
        for hint in hints {
            guard case let .betterRateAvailable(hintRate, reason, brand, _) = hint, hintRate > rate else { continue }
            let key = "\(reason.rawValue)|\(brand ?? "")"
            if (best[key]?.0 ?? 0) < hintRate { best[key] = (hintRate, hint) }
        }
        return best.values.sorted { $0.0 > $1.0 }.map(\.1)
    }
}
