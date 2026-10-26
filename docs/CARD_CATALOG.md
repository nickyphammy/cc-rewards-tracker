# Card Catalog

The catalog is the list of cards a user can pick from when adding a card. It holds each card's multipliers and credits. It **updates over the internet**, so new cards, changed terms, and each quarter's rotating categories reach users without an app release. A copy also ships inside the app so it works offline and on first launch.

## Coverage

For now the catalog only includes cards from these four issuers. Any other card can still be added as a custom card (PRD F1).

| Issuer | Scope |
|---|---|
| Robinhood | Robinhood Gold Card |
| American Express | Amex cards |
| Chase | Chase cards |
| Capital One | Capital One cards |

### Tier 1: ships first (M1)

Personal cards that earn the issuer's own points or cash back:

- **Robinhood:** Robinhood Gold Card
- **Amex:** Platinum, Gold, Classic Green (retired: closed to new applicants July 2026), Blue Cash Preferred, Blue Cash Everyday
- **Chase:** Sapphire Reserve, Sapphire Preferred, Freedom Unlimited, Freedom Flex, Freedom (original Visa; retired: closed to new applicants)
- **Capital One:** Venture X, Venture, VentureOne, Savor, Quicksilver

### Tier 2: added through remote updates once the pipeline works

The rest of each issuer's lineup:
- Co-branded cards, e.g. Amex Delta SkyMiles, Hilton Honors and Marriott Bonvoy cards; Chase United, Southwest, Hyatt, IHG and Marriott cards; Amazon Prime Visa.
- Business cards, e.g. Amex Business Platinum and Business Gold, Chase Ink cards, Capital One Venture X Business and Spark cards.
- Legacy cards that existing holders still carry, e.g. Capital One SavorOne.

> These lists are a starting point. Check each card's current lineup and terms on the issuer's website when writing its catalog entry, and set `lastVerified` to that date. Card names and terms in this doc are not authoritative.

### Card-specific modeling notes

- **Robinhood Gold Card:** it needs a paid Robinhood Gold membership. Model that membership fee as `requiredMembership`, not as `annualFee`. As of Sept 1, 2026 it earns a flat 3% on everything; the old 5% travel-portal bonus is gone. Robinhood sells the membership at $5/month or $50/year, and the card requires the annual plan.
- **Chase Freedom Flex and original Freedom:** both have the same quarterly rotating 5% categories that require activation. Update both cards' `rotating` together. Publish each quarter's categories in `rotating` (see "Applying updates to a user's cards" below).
- **Capital One Venture, VentureOne, Savor, Quicksilver:** Capital One is moving these cards to Discover in waves through early 2027, so an existing holder's card may be Visa, Mastercard or Discover. The catalog says `discover`, which is what new accounts get, and the user edits the network on their own card. Venture X stays on Visa.
- **Gaps the schema can't express yet:** merchant exclusions (e.g. Walmart and Target don't count as groceries), "prepaid only" hotel bonuses, stacked rotating rates (Freedom Flex dining in Q4 2026), and spend-gated credits (some Sapphire Reserve credits unlock only after $75k of spending a year). For now these are described in each credit's `notes` or left out. See the research notes for the first publish.
- **Amex Platinum / Gold:** these cards have many credits on different schedules (monthly, semiannual, annual), some needing enrollment. They are the main test case for F2.

## File format (`catalog.json`)

```jsonc
{
  "schemaVersion": 1,             // format version; the app ignores catalogs newer than it understands
  "catalogVersion": 2026102601,   // always increases with each publish (YYYYMMDDnn)
  "publishedAt": "2026-10-26T00:00:00Z",
  "currencies": [
    { "id": "cash",       "name": "Cash Back",               "unitName": "cash back", "rateUnit": "percent" },
    { "id": "amex_mr",    "name": "Amex Membership Rewards", "unitName": "points",    "rateUnit": "multiplier" },
    { "id": "chase_ur",   "name": "Chase Ultimate Rewards",  "unitName": "points",    "rateUnit": "multiplier" },
    { "id": "cap1_miles", "name": "Capital One Miles",       "unitName": "miles",     "rateUnit": "multiplier" },
    { "id": "citi_typ",   "name": "Citi ThankYou Points",    "unitName": "points",    "rateUnit": "multiplier" }   // non-catalog issuers too, for custom cards
  ],
  "cards": [
    {
      "id": "example_gold",
      "revision": 3,                  // bumped whenever this card's terms change
      "issuer": "Example Bank",
      "name": "Example Gold Card",
      "shortName": "Gold",            // shown next to the issuer in compact UI ("Example Bank · Gold")
      "rateUnit": null,               // optional override of the currency's rateUnit, e.g. "percent" for Chase Freedom (UR points marketed as % back)
      "network": "amex",              // visa | mastercard | amex | discover
      "annualFee": 250,
      "requiredMembership": null,     // e.g. { "name": "Robinhood Gold", "monthlyFee": 5, "annualFee": 50 }
      "rewardCurrency": "amex_mr",
      "lastVerified": "2026-10-01",   // when the terms were last checked
      "retired": false,               // true = closed to new applicants; still searchable, labeled "No longer offered"
      "multipliers": [
        { "category": "dining",    "rate": 4 },
        { "category": "groceries", "rate": 4, "cap": { "amount": 25000, "period": "annual" }, "afterCapRate": 1 },
        { "category": "flights",   "rate": 3, "condition": "booked_direct_or_portal" },
        { "category": "other",     "rate": 1 }
      ],
      "credits": [
        { "id": "dining_monthly", "name": "Dining Credit",    "amount": 10,  "period": "monthly",    "resetBasis": "calendar" },
        { "id": "rideshare",      "name": "Rideshare Credit", "amount": 10,  "period": "monthly",    "resetBasis": "calendar" },
        { "id": "hotel",          "name": "Hotel Credit",     "amount": 100, "period": "semiannual", "resetBasis": "calendar" }
      ]
    }
  ]
}
```

> The card above is illustrative only. Real terms change often. Every card carries `lastVerified`, and the UI shows it.

### Multiplier fields

| Field | Meaning |
|---|---|
| `category` | One of the category IDs in [DATA_MODEL.md](DATA_MODEL.md#spending-categories). Omitted on `rotating` rows |
| `rate` | Points per dollar (or % for cash back — `rate: 3` on a cash card = 3%) |
| `cap` | Optional spend cap: `amount` + `period` (`monthly` / `quarterly` / `annual` — a subset of `Period`) |
| `afterCapRate` | Rate once the cap is hit (usually the base rate) |
| `condition` | Optional `MultiplierCondition`: `booked_via_portal` and `requires_activation` exclude the row from ranking by default; `brand_only` (with `brand`, e.g. `"Delta"`) is excluded too and shown as a hint; the rest (`booked_direct_or_portal`, `us_only`, …) are shown as caveats only. See [RECOMMENDATION_ENGINE.md](RECOMMENDATION_ENGINE.md) |
| `brand` | Required when `condition` is `brand_only` |
| `rotating` | Optional: `{ "quarters": { "2026Q4": ["online_retail", "drugstores"] } }` for rotating-category cards. A rotating row has no `category`; it usually also has `condition: requires_activation` and a quarterly `cap`. In the user's store it becomes one `Multiplier` per quarter × category, with `rotatingQuarter` set |
| `userSelectable` | Optional: user picks which category gets this rate (e.g. "choose your 3% category"); `eligibleCategories` lists the choices |
| `autoTopCategory` | Optional: rate applies to whichever of `eligibleCategories` the user spends most in that cycle |
| `eligibleCategories` | Required when `userSelectable` or `autoTopCategory` is set |

### Credit fields

| Field | Meaning |
|---|---|
| `id` | Stable within the card. Used to match a user's saved credit (and its usage history) to catalog updates. **Never reuse or rename an `id`.** |
| `amount` | Value of the credit per period |
| `period` | `monthly` / `quarterly` / `semiannual` / `annual` / `multi_year` (with `periodYears`, e.g. a Global Entry credit every 4 years) |
| `periodYears` | Required when `period` is `multi_year` |
| `resetBasis` | `calendar` (Jan 1, 1st of month, …) or `cardmember_year` (card anniversary) |
| `requiresEnrollment` | Optional bool. When true, show a one-time "enroll in this benefit" checklist item |
| `notes` | Optional free text (e.g. "Eligible merchants: …") |

### Validation rules

The publish script applies all of these and blocks publishing on any failure. The app applies them in two levels.

**File-level (the app rejects the whole download):**
- The JSON is malformed or doesn't match the schema's structure.
- `schemaVersion` is higher than the newest version the app supports.
- `catalogVersion` is not higher than the version the app already has.
- Card `id`s are not unique.
- A card `id` from the previous catalog is missing. Cards are never removed, only marked `retired`, because existing user cards depend on them. The publish script checks this against the last published file.

**Card-level (the app skips just that card and keeps the rest):**
- A category, period, condition or network value the app doesn't know. This is how a newer catalog can add cards that need a newer app; older builds simply don't offer those cards.
- No unconditional `other` multiplier, or more than one.
- More than one row without a `condition` for the same category. Conditional rows (e.g. portal-only) may share a category with it, and the engine uses the highest applicable rate.
- `rewardCurrency` not found in `currencies`.
- Credit `id`s not unique within the card.
- `periodYears` missing on a `multi_year` credit.
- `eligibleCategories` missing on a `userSelectable` or `autoTopCategory` row.
- `brand` missing on a `brand_only` row.
- `requiredMembership` present without a `name` and at least one of `monthlyFee` / `annualFee`.

## Where it lives

```
catalog/
├── catalog.json        # source of truth, edited by hand and reviewed in git
└── validate.py         # runs the validation rules above (Python 3, stdlib only); must pass before every push
```

- **Publishing:** GitHub Pages serves this repo's `main` branch root, so pushing `catalog/catalog.json` to `main` publishes it at:
  **https://nickyphammy.github.io/cc-rewards-tracker/catalog/catalog.json**
  - Run `python3 catalog/validate.py` before every push. `--previous <old catalog.json>` adds the "no card removed" check.
  - A `.nojekyll` file at the repo root makes Pages serve files as-is.
  - CI enforcement (a GitHub Action running the validator) is a roadmap item. It needs the `workflow` scope on the GitHub token.
  - The app needs only a plain GET. Pages sends `ETag` headers, so step 2 of "How the app updates" works.
- **Bundled copy:** each app build includes the current `catalog.json` as a resource. This is the fallback when there is no network on first launch.

## How the app updates (`CatalogStore`)

1. **On launch**, load the newer of two copies: the cached download (in Application Support) or the bundled file. Do this synchronously, so the Add Card search works immediately.
2. **Check the server in the background** if the last check was more than 24 hours ago. Also check on pull-to-refresh in Add Card search, and during the background refresh task that `ReminderScheduler` already uses.
   - Send `If-None-Match` with the stored ETag. A `304` response means nothing changed.
3. **Validate** the download against the rules above. If a file-level rule fails, keep the current catalog and log the error. If a card-level rule fails, drop only that card and log it; never keep a half-parsed card.
4. **Swap atomically:** write the new file to a temp path, rename it over the cache, then publish the change to the UI.

The request sends no user data: no wallet contents, no IDs. The host does see the device's IP address, as with any web request.

## Applying updates to a user's cards

Adding a card copies its catalog data into the user's store ([DATA_MODEL.md](DATA_MODEL.md)). The app never silently overwrites the user's saved terms, with one exception for rotating schedules (below).

- **What bumps `revision`:** any change to the card's terms (fees, membership, currency, network, name, multipliers, credits). A change to `rotating` quarter schedules alone does **not** bump it.
- `UserCard` stores the `catalogRevision` it was copied from. When the catalog has a higher `revision` for that card, the card shows a **"Terms updated"** badge.
- The card detail screen shows what changed (rates, credits added, removed or changed) and offers **Apply update**.
- Applying the update:
  - Updates `name`, `shortName`, `rateUnit`, `annualFee`, the membership fields and `rewardCurrencyID` from the catalog.
  - Replaces the card's multipliers.
  - Updates catalog credits, matching them by `catalogCreditID` so usage history is kept. The user's own settings on each credit are kept: `isEnrolled`, `remindersEnabled`, `reminderOffsetsDays`.
  - Archives credits that were removed from the catalog. Their history is kept, and their reminders are cancelled.
  - Adds new credits.
  - Never touches credits the user added themselves (`catalogCreditID == nil`).
  - Sets `catalogRevision` to the new revision.
  - Never changes `network`. The network is a fact about the user's physical card (Capital One cards can be on Visa, Mastercard or Discover), so the user owns it.
- Catalog cards' rates and credits aren't user-editable, so Apply never overwrites user changes; only personal fields (nickname, last 4, network, color, open date) and per-credit settings belong to the user, and they're kept.
- **Exception:** `rotating` quarter schedules (e.g. Freedom Flex's categories for next quarter) are applied automatically. They are expected every quarter and don't change the card's terms. For each quarter in the catalog, the card's rotating `Multiplier` rows for that quarter are replaced. Quarters already stored but no longer in the catalog are kept. The user still has to mark each quarter as activated.
- Retired means the issuer no longer takes new applications (e.g. the Amex Classic Green Card since July 2026). Users add cards they already hold, so retired cards stay in Add Card search with a "No longer offered" label, and existing user cards keep working.

## Open decisions

- **Signing:** HTTPS is sufficient for v1. A signature on the catalog file could come later if the catalog ever controls anything sensitive.
