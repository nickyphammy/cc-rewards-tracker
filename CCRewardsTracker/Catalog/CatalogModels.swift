import Foundation

// Decodable mirror of catalog/catalog.json (docs/CARD_CATALOG.md).

nonisolated struct CatalogFile: Decodable, Sendable {
    let schemaVersion: Int
    let catalogVersion: Int
    let publishedAt: String
    let currencies: [CatalogCurrency]
    let cards: [CatalogCard]

    static let supportedSchemaVersion = 1

    enum CodingKeys: String, CodingKey {
        case schemaVersion, catalogVersion, publishedAt, currencies, cards
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        schemaVersion = try c.decode(Int.self, forKey: .schemaVersion)
        guard schemaVersion <= Self.supportedSchemaVersion else {
            throw CatalogError.unsupportedSchema(schemaVersion)
        }
        catalogVersion = try c.decode(Int.self, forKey: .catalogVersion)
        publishedAt = try c.decode(String.self, forKey: .publishedAt)
        currencies = try c.decode([CatalogCurrency].self, forKey: .currencies)
        // Card-level rule: a card this build can't read (e.g. an unknown category) is skipped, not fatal.
        let currencyIDs = Set(currencies.map(\.id))
        cards = try c.decode([Lossy<CatalogCard>].self, forKey: .cards)
            .compactMap(\.value)
            .filter { $0.isValid(currencyIDs: currencyIDs) }
    }
}

nonisolated enum CatalogError: Error, Equatable {
    case unsupportedSchema(Int)
    case missingBundledCatalog
}

nonisolated struct CatalogCurrency: Decodable, Sendable, Hashable {
    let id: String
    let name: String
    let unitName: String
    let rateUnit: RateUnit
}

nonisolated struct CatalogCard: Decodable, Sendable, Identifiable, Hashable {
    let id: String
    let revision: Int
    let issuer: String
    let name: String
    let shortName: String
    let rateUnit: RateUnit?
    let network: CardNetwork
    let annualFee: Decimal
    let requiredMembership: CatalogMembership?
    let rewardCurrency: String
    let lastVerified: String
    let retired: Bool
    let multipliers: [CatalogMultiplier]
    let credits: [CatalogCredit]

    /// Rules the decoder can't express: exactly one unconditional "other" row, unique credit ids.
    func isValid(currencyIDs: Set<String>) -> Bool {
        let baseRows = multipliers.filter { $0.category == .other && $0.condition == nil && $0.rotating == nil }
        let creditIDs = credits.map(\.id)
        return baseRows.count == 1
            && currencyIDs.contains(rewardCurrency)
            && Set(creditIDs).count == creditIDs.count
    }

    var baseRate: Decimal {
        multipliers.first { $0.category == .other && $0.condition == nil && $0.rotating == nil }?.rate ?? 1
    }
}

nonisolated struct CatalogMembership: Decodable, Sendable, Hashable {
    let name: String
    let monthlyFee: Decimal?
    let annualFee: Decimal?
}

nonisolated struct CatalogMultiplier: Decodable, Sendable, Hashable {
    let category: SpendCategory?
    let rate: Decimal
    let cap: CatalogCap?
    let afterCapRate: Decimal?
    let condition: MultiplierCondition?
    let brand: String?
    let rotating: CatalogRotating?
    let userSelectable: Bool?
    let autoTopCategory: Bool?
    let eligibleCategories: [SpendCategory]?
}

nonisolated struct CatalogCap: Decodable, Sendable, Hashable {
    let amount: Decimal
    let period: Period
}

nonisolated struct CatalogRotating: Decodable, Sendable, Hashable {
    let quarters: [String: [SpendCategory]]
}

nonisolated struct CatalogCredit: Decodable, Sendable, Hashable {
    let id: String
    let name: String
    let amount: Decimal
    let period: Period
    let periodYears: Int?
    let resetBasis: ResetBasis
    let requiresEnrollment: Bool?
    let notes: String?
}

/// Decodes `T` if it can, otherwise `nil`, so one bad element doesn't fail the whole array.
nonisolated struct Lossy<T: Decodable & Sendable>: Decodable, Sendable {
    let value: T?

    init(from decoder: Decoder) throws {
        value = try? T(from: decoder)
    }
}
