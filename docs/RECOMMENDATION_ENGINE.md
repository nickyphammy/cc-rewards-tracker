# Recommendation Engine — "Which card should I use?"

Cards are ranked by their **raw multiplier** for the chosen category. 4x points beats 3% cash back. The app doesn't put a cents-per-point value on points or miles. Decided 2026-10-26: valuations are subjective and the user just wants to see the multiplier.

## Input / output

The engine works on plain `Sendable` value types, not the SwiftData `@Model` classes. That lets tests build fixtures directly and keeps the engine free of SwiftData imports. The view layer maps `UserCard` to `CardSnapshot` before calling it.

```swift
struct CardSnapshot: Sendable {
    let id: UUID
    let name: String
    let rewardCurrencyID: String              // display + tie-break only ("cash" vs points)
    let multipliers: [MultiplierSnapshot]
    let activatedRotating: Set<String>        // e.g. ["2026Q4"]
    let selectedCategories: Set<SpendCategory> // for user-selectable rows
}

struct RecommendationRequest: Sendable {
    let category: SpendCategory
    let amount: Decimal?        // optional; only adds "earns ~N points" / "~$N back"
    let date: Date              // injected, for rotating quarters
    let includePortalRates: Bool // Settings toggle, default false
}

struct CardRecommendation: Sendable {
    let cardID: UUID
    let rate: Decimal                   // e.g. 4 (x) or 3 (%)
    let rateUnit: RateUnit              // card override, else the currency's: .percent → "3%", .multiplier → "4x"
    let estimatedEarnings: Decimal?     // cash: amount × rate / 100 dollars; points: amount × rate points
    let caveats: [Caveat]               // condition, cap, hints
    let isTie: Bool
}

enum Caveat: Sendable {
    case condition(MultiplierCondition)        // shown only, does not affect rank
    case cap(amount: Decimal, period: Period, afterCapRate: Decimal)
    case betterRateAvailable(rate: Decimal, reason: MultiplierCondition, brand: String?, quarter: String?) // portal / activation / brand hint
    case chooseCategory(rate: Decimal)         // user-selectable row not yet chosen, and this category is eligible
    case dependsOnSpendMix                     // auto-top-category cards
}

func recommend(_ request: RecommendationRequest, wallet: [CardSnapshot]) -> [CardRecommendation]
```

Returns **all** cards passed in, ranked best first. The caller excludes archived cards. The UI shows #1 prominently and the rest as runners-up.

## Algorithm

For each card in the wallet:

1. **Find the applicable rate for the category.** A card can have several rows for one category (one without a condition plus conditional ones, e.g. 4x hotels direct and 8x hotels via portal). Collect the rows for `request.category`, drop the ones that don't apply right now, and use the **highest remaining rate**:
   - **Rotating rows** apply only if `date` falls in that quarter **and** the user marked the quarter activated.
   - **Portal-only rows** (`condition == .bookedViaPortal`) apply only if `includePortalRates` is on. See [ranking policy](#conditional-multipliers--ranking-policy).
   - **Brand-only rows** (`condition == .brandOnly`, e.g. "3x on Delta purchases") never apply, because a generic flight or hotel purchase isn't that brand.
   - **User-selectable rows** apply only to the category the user chose. If the user hasn't chosen one and `request.category` is in `eligibleCategories`, add `chooseCategory` ("Choose your 3% category").
   - **Auto-top-category rows** are assumed to apply, with caveat `dependsOnSpendMix`.
   - **Any other condition** (`bookedDirectOrPortal`, `usOnly`, …) does **not** drop the row, because booking direct is an ordinary purchase.
   - If no row is left, fall back to the card's `other` (base) rate.
2. **Add hints.** For each dropped row whose rate is higher than the rate used, add `betterRateAvailable` (e.g. "5x if booked through Chase Travel", "5% if you activate this quarter", "3x if it's a Delta purchase").
3. **Attach caveats** for the row that was used. These never change the ranking; only step 1's filtering does.
   - Any remaining `condition` (e.g. "booked directly with the airline or via portal").
   - A `cap`, e.g. "4x up to $25,000/yr, then 1x". v1 can't know cap progress, since spend isn't tracked.
4. **Sort** by `rate` descending. Multipliers are compared as plain numbers: 4x = 4, 3% = 3.

## Tie-breaking (deterministic)

When rates are equal:

1. Prefer the card whose rate came from a **category-specific** multiplier over a base rate. This saves the general-purpose card for other spend.
2. Prefer **cash back** over points. It's simpler to redeem.
3. Prefer a card with **no caveats**.
4. Alphabetical by card name (stable, last resort).

Set `isTie = true` on tied cards so the UI can say "Card A or Card B — both earn 3x".

## Conditional multipliers — ranking policy

Portal-only, activation-required and brand-only rates are **not** used for ranking by default, because the user is usually paying at a merchant directly. Instead:

- Rank using the rate that applies without the condition (usually the base rate).
- Show a hint, e.g. "Card C would earn 5x if booked through the issuer's travel portal."

A Settings toggle, "Include portal bookings in recommendations", switches to ranking with portal rates. Brand-only rates are always hints.

## Examples (test fixtures)

| Card | Currency | Dining | Groceries | Flights | Other |
|---|---|---|---|---|---|
| A | points | 4x | 4x (cap $25k/yr) | 3x | 1x |
| B | cash | 3% | 3% | — | 1.5% |
| C | points | 3x | — | 5x portal-only | 1x |

| Category | Expected ranking | Why |
|---|---|---|
| Dining | A (4x), B (3%), C (3x) | B and C tie at 3; both are category-specific, so cash wins → B first. `isTie = true` on B and C |
| Groceries | A (4x, caveat: cap), B (3%), C (1x) | C falls back to its base rate |
| Flights | A (3x), B (1.5%), C (1x, hint: 5x via portal) | Portal rate excluded by default; with `includePortalRates` on, C (5x) ranks first |
| Gas | B (1.5%), A (1x), C (1x) | No gas multipliers, so base rates are compared. A and C tie at 1, both base rate, both points, no caveats → alphabetical. `isTie = true` on A and C |

These go straight into the unit tests for `RecommendationEngine`.

## Later (not v1)

- **Cap tracking:** if the user logs spend (manually or via import), demote a card whose cap is reached for the period.
- **Merchant lookup:** map a merchant name to a category, including known exceptions. For example, warehouse clubs and superstores often don't code as "groceries".
- **Foreign transaction fees:** when the user marks a purchase as international, penalize cards with FX fees.
- **Credit-aware nudges:** show "You still have a $10 dining credit on Card A this month" alongside the Dining recommendation.
