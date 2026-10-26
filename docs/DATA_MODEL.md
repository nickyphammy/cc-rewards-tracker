# Data Model

Two layers:

- **Catalog**: read-only card templates in `catalog.json`. It is downloaded over the internet, and a copy is bundled with the app ([CARD_CATALOG.md](CARD_CATALOG.md)).
- **User data** — the user's own cards, credit usage, and settings, stored in SwiftData.

## Spending categories

A fixed enum so the best-card finder and the multipliers table agree on names. Start with:

| ID | Display name |
|---|---|
| `dining` | Dining & Restaurants |
| `groceries` | Groceries / Supermarkets |
| `gas` | Gas Stations |
| `ev_charging` | EV Charging |
| `flights` | Travel – Flights |
| `hotels` | Travel – Hotels |
| `travel_other` | Travel – Other (car rental, cruises, etc.) |
| `transit` | Transit & Rideshare |
| `streaming` | Streaming Services |
| `drugstores` | Drugstores |
| `online_retail` | Online Shopping |
| `entertainment` | Entertainment |
| `home_improvement` | Home Improvement |
| `utilities` | Utilities & Phone |
| `other` | Everything Else |

Categories are a closed set in code; adding one is a code change and an app release. Older builds skip catalog cards that use a category they don't know (see [CARD_CATALOG.md](CARD_CATALOG.md#validation-rules)). `other` is always present and every card must have a rate for it (its base rate).

## Reward currencies

Cash back and the various points/miles programs are modeled as a **reward currency**. It's used for display ("4x Membership Rewards" vs "3% cash back") and for one tie-break rule. It is **not** used to convert points to a dollar value: ranking is by raw multiplier ([RECOMMENDATION_ENGINE.md](RECOMMENDATION_ENGINE.md)).

```
RewardCurrency
  id: String                 // "cash", "amex_mr", "chase_ur", "cap1_miles", "delta_skymiles", "citi_typ", ...
  name: String
  unitName: String          // "points", "miles", "cash back": used in estimates ("earns ~342 points")
  rateUnit: RateUnit        // .percent → "3%", .multiplier → "4x"
```

Currencies ship in the `currencies` array of `catalog.json`, so new currencies arrive with remote catalog updates.

The `currencies` list is **not** limited to the four catalog issuers. It also ships common programs from other banks (e.g. Citi ThankYou, Bilt), so custom cards have something to pick. A custom card can also choose **Other points** (`rewardCurrencyID = "custom"`).

## Catalog

The catalog file format, field meanings, validation rules and update flow are in [CARD_CATALOG.md](CARD_CATALOG.md).

## Enums

```swift
enum CardNetwork: String, Codable { case visa, mastercard, amex, discover }
enum Period: String, Codable { case monthly, quarterly, semiannual, annual, multiYear = "multi_year" }
enum RateUnit: String, Codable { case percent, multiplier }
enum ResetBasis: String, Codable { case calendar, cardmemberYear = "cardmember_year" }
enum MultiplierCondition: String, Codable {
    case bookedViaPortal = "booked_via_portal"            // excluded from ranking by default
    case requiresActivation = "requires_activation"       // excluded from ranking until activated
    case bookedDirectOrPortal = "booked_direct_or_portal" // caveat only
    case usOnly = "us_only"                               // caveat only
    case brandOnly = "brand_only"                         // e.g. 3x on Delta purchases only; excluded from ranking, shown as a hint
}
// SpendCategory: the category IDs above, as a String-backed enum.
```

## User data (SwiftData)

> **CloudKit-ready:** iCloud sync is planned for later, and SwiftData + CloudKit requires every property to be optional or have a default value, every relationship to be optional, and no `@Attribute(.unique)`. Write the models below that way from the start (the sketch omits defaults for brevity) so turning on sync doesn't need a migration.

```swift
@Model final class UserCard {
    var id: UUID
    var catalogID: String?          // nil for fully custom cards
    var catalogRevision: Int?       // catalog card `revision` this was copied from; lower than catalog → "Terms updated"
    var issuer: String
    var name: String
    var shortName: String?          // from catalog; compact display next to issuer
    var rateUnitOverride: RateUnit? // from catalog card `rateUnit`; nil = use the currency's
    var nickname: String?
    var last4: String?              // display only, optional
    var network: CardNetwork
    var annualFee: Decimal
    var requiredMembershipName: String?       // e.g. "Robinhood Gold"
    var requiredMembershipMonthlyFee: Decimal?
    var rewardCurrencyID: String    // "custom" = user-defined points
    var openedOn: Date?             // needed for cardmember-year credits / fee reminders
    var colorHex: String?
    var isArchived: Bool
    var sortIndex: Int              // manual wallet order
    @Relationship(deleteRule: .cascade) var multipliers: [Multiplier]
    @Relationship(deleteRule: .cascade) var credits: [Credit]
    @Relationship(deleteRule: .cascade) var categorySelections: [CategorySelection] // user-selectable / rotating activations
}

@Model final class Multiplier {
    var category: SpendCategory
    var rate: Decimal
    var capAmount: Decimal?
    var capPeriod: Period?
    var afterCapRate: Decimal?
    var condition: MultiplierCondition?
    var brand: String?              // for .brandOnly, e.g. "Delta"
    var rotatingQuarter: String?    // "2026Q4" if this row only applies that quarter (one row per quarter × category)
    var isUserSelectable: Bool
    var isAutoTopCategory: Bool
    var eligibleCategories: [SpendCategory]? // choices for user-selectable / auto-top rows
}

@Model final class Credit {
    var id: UUID
    var catalogCreditID: String?    // catalog credit `id`; matches this credit across catalog updates. nil = user-added
    var isArchived: Bool            // credit was removed from the catalog; history kept
    var name: String
    var amount: Decimal
    var period: Period
    var periodYears: Int?           // only for .multiYear
    var resetBasis: ResetBasis
    var notes: String?
    var requiresEnrollment: Bool
    var isEnrolled: Bool
    var remindersEnabled: Bool
    var reminderOffsetsDays: [Int]?  // nil = use global default
    @Relationship(deleteRule: .cascade) var usages: [CreditUsage]
}

@Model final class CreditUsage {
    var periodStart: Date           // identifies which period this usage belongs to
    var amountUsed: Decimal
    var loggedAt: Date
    var note: String?
}

@Model final class CategorySelection {
    var category: SpendCategory
    var quarter: String?            // for rotating categories: "2026Q4"
    var activated: Bool
}

```

### App settings (`@AppStorage`, not SwiftData)

Simple global preferences live in `UserDefaults` via `@AppStorage`:

| Key | Default | Used by |
|---|---|---|
| `reminderOffsetsDays` | `[7, 1]` | `ReminderScheduler` (credits without their own offsets) |
| `monthlySummaryEnabled` | `true` | `ReminderScheduler` |
| `annualFeeReminderEnabled` | `true` | `ReminderScheduler` |
| `includePortalRates` | `false` | `RecommendationEngine` request |
| `hasSeenWelcome` | `false` | Onboarding (ON-1) |
| `catalogLastCheckedAt` | none | Settings shows when the catalog was last checked |
| `catalogLastResult` | none | Settings: "Up to date", "Updated to <version>" or the error |

### Derived values (not stored)

- **Cardmember-year credit on a card with no `openedOn`**: the period can't be computed, so the credit is **untracked**. It's left out of dashboard totals, no reminders are scheduled, and the UI asks for the card's open date. `CreditPeriodCalculator` returns `nil` for this case.

- **Terms last verified** for a catalog card: looked up in the current catalog by `catalogID` (not copied into `UserCard`).

- **Current period** for a credit: computed by `CreditPeriodCalculator` from `period`, `resetBasis`, `openedOn`, and "now".
- **Remaining this period** = `amount − sum(usages where periodStart == currentPeriodStart)`.
