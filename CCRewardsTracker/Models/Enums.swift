import Foundation

/// Spending categories. A closed set: adding one is a code change and an app release (docs/DATA_MODEL.md).
nonisolated enum SpendCategory: String, Codable, CaseIterable, Identifiable, Sendable {
    case dining
    case groceries
    case gas
    case flights
    case hotels
    case travelOther = "travel_other"
    case transit
    case streaming
    case drugstores
    case onlineRetail = "online_retail"
    case entertainment
    case homeImprovement = "home_improvement"
    case utilities
    case evCharging = "ev_charging"
    case other

    var id: String { rawValue }

    /// Full display name, used in titles and VoiceOver.
    var displayName: String {
        switch self {
        case .dining: "Dining & Restaurants"
        case .groceries: "Groceries / Supermarkets"
        case .gas: "Gas Stations"
        case .evCharging: "EV Charging"
        case .flights: "Travel – Flights"
        case .hotels: "Travel – Hotels"
        case .travelOther: "Travel – Other"
        case .transit: "Transit & Rideshare"
        case .streaming: "Streaming Services"
        case .drugstores: "Drugstores"
        case .onlineRetail: "Online Shopping"
        case .entertainment: "Entertainment"
        case .homeImprovement: "Home Improvement"
        case .utilities: "Utilities & Phone"
        case .other: "Everything Else"
        }
    }

    /// Short label for the Best Card grid.
    var shortLabel: String {
        switch self {
        case .dining: "Dining"
        case .groceries: "Groceries"
        case .gas: "Gas"
        case .evCharging: "EV Charging"
        case .flights: "Flights"
        case .hotels: "Hotels"
        case .travelOther: "Other Travel"
        case .transit: "Transit & Rideshare"
        case .streaming: "Streaming"
        case .drugstores: "Drugstores"
        case .onlineRetail: "Online Shopping"
        case .entertainment: "Entertainment"
        case .homeImprovement: "Home Improvement"
        case .utilities: "Utilities & Phone"
        case .other: "Everything Else"
        }
    }

    var symbol: String {
        switch self {
        case .dining: "fork.knife"
        case .groceries: "cart"
        case .gas: "fuelpump"
        case .evCharging: "ev.charger"
        case .flights: "airplane"
        case .hotels: "bed.double"
        case .travelOther: "car"
        case .transit: "tram"
        case .streaming: "play.tv"
        case .drugstores: "cross.case"
        case .onlineRetail: "shippingbox"
        case .entertainment: "ticket"
        case .homeImprovement: "hammer"
        case .utilities: "lightbulb"
        case .other: "ellipsis.circle"
        }
    }
}

nonisolated enum CardNetwork: String, Codable, CaseIterable, Identifiable, Sendable {
    case visa, mastercard, amex, discover

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .visa: "Visa"
        case .mastercard: "Mastercard"
        case .amex: "American Express"
        case .discover: "Discover"
        }
    }
}

nonisolated enum Period: String, Codable, Sendable {
    case monthly, quarterly, semiannual, annual
    case multiYear = "multi_year"
}

nonisolated enum ResetBasis: String, Codable, Sendable {
    case calendar
    case cardmemberYear = "cardmember_year"
}

nonisolated enum RateUnit: String, Codable, Sendable {
    case percent, multiplier
}

nonisolated enum MultiplierCondition: String, Codable, Sendable {
    case bookedViaPortal = "booked_via_portal"            // excluded from ranking by default
    case requiresActivation = "requires_activation"       // excluded from ranking until activated
    case bookedDirectOrPortal = "booked_direct_or_portal" // caveat only
    case usOnly = "us_only"                               // caveat only
    case brandOnly = "brand_only"                         // excluded from ranking, shown as a hint
}
