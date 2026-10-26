import Foundation
import SwiftData

// SwiftData models (docs/DATA_MODEL.md). Every property has a default and every relationship is
// optional so CloudKit sync can be turned on later without a migration.

@Model final class UserCard {
    var id: UUID = UUID()
    var catalogID: String?
    var catalogRevision: Int?
    var hasLocalEdits: Bool = false
    var issuer: String = ""
    var name: String = ""
    var shortName: String?
    var rateUnitOverride: RateUnit?
    var nickname: String?
    var last4: String?
    var network: CardNetwork = CardNetwork.visa
    var annualFee: Decimal = 0
    var requiredMembershipName: String?
    var requiredMembershipMonthlyFee: Decimal?
    var requiredMembershipAnnualFee: Decimal?
    var rewardCurrencyID: String = "cash"
    var openedOn: Date?
    var colorHex: String?
    var isArchived: Bool = false
    var sortIndex: Int = 0
    var addedAt: Date = Date()
    @Relationship(deleteRule: .cascade, inverse: \Multiplier.card) var multipliers: [Multiplier]? = []
    @Relationship(deleteRule: .cascade, inverse: \Credit.card) var credits: [Credit]? = []
    @Relationship(deleteRule: .cascade, inverse: \CategorySelection.card) var categorySelections: [CategorySelection]? = []

    init() {}

    /// Name shown in lists: the user's nickname, else the catalog short name, else the full name.
    var displayName: String {
        if let nickname, !nickname.isEmpty { return nickname }
        return shortName ?? name
    }
}

@Model final class Multiplier {
    var category: SpendCategory = SpendCategory.other
    var rate: Decimal = 1
    var capAmount: Decimal?
    var capPeriod: Period?
    var afterCapRate: Decimal?
    var condition: MultiplierCondition?
    var brand: String?
    var rotatingQuarter: String?
    var isUserSelectable: Bool = false
    var isAutoTopCategory: Bool = false
    var eligibleCategories: [SpendCategory]?
    var card: UserCard?

    init(category: SpendCategory, rate: Decimal) {
        self.category = category
        self.rate = rate
    }
}

@Model final class Credit {
    var id: UUID = UUID()
    var catalogCreditID: String?
    var isArchived: Bool = false
    var name: String = ""
    var amount: Decimal = 0
    var period: Period = Period.monthly
    var periodYears: Int?
    var resetBasis: ResetBasis = ResetBasis.calendar
    var notes: String?
    var requiresEnrollment: Bool = false
    var isEnrolled: Bool = false
    var remindersEnabled: Bool = true
    var reminderOffsetsDays: [Int]?
    var card: UserCard?
    @Relationship(deleteRule: .cascade, inverse: \CreditUsage.credit) var usages: [CreditUsage]? = []

    init(name: String, amount: Decimal, period: Period) {
        self.name = name
        self.amount = amount
        self.period = period
    }
}

@Model final class CreditUsage {
    var periodStart: Date = Date()
    var amountUsed: Decimal = 0
    var loggedAt: Date = Date()
    var note: String?
    var credit: Credit?

    init(periodStart: Date, amountUsed: Decimal) {
        self.periodStart = periodStart
        self.amountUsed = amountUsed
    }
}

@Model final class CategorySelection {
    var category: SpendCategory?
    var quarter: String?
    var activated: Bool = false
    var card: UserCard?

    init(category: SpendCategory? = nil, quarter: String? = nil, activated: Bool = false) {
        self.category = category
        self.quarter = quarter
        self.activated = activated
    }
}
