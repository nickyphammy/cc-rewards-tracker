# Design System

The visual and interaction rules for CC Rewards Tracker. Screens are specified in [SCREENS.md](SCREENS.md) and user flows in [FLOWS.md](FLOWS.md).

**Ranking rule the UI reflects:** cards are ranked by their **raw earn rate**: 1x point counts the same as 1% cash back, so 4x points beats 3% cash back. The app has **no point valuations**. No screen shows cents-per-point, "effective return" or "% value". Wherever a ranking appears, the footer says so: *"Ranked by earn rate. 1x points counts the same as 1% cash back."*

## Principles

1. **One tap to the answer.** Launch → Best Card grid → tap a category → result. Nothing on that path waits on the network, asks a question or shows a modal.
2. **System first.** Use standard SwiftUI containers (`TabView`, `NavigationStack`, `List`, `Form`, `.sheet`, `.toolbar`, `.searchable`, `ContentUnavailableView`). They pick up Liquid Glass, Dynamic Type, dark mode and accessibility for free.
3. **Glass is for controls, not content.** Liquid Glass belongs on the navigation layer: tab bar, toolbars, primary buttons. Content such as the best-card hero, lists and card tiles sits on standard backgrounds. Don't add a custom `.glassEffect()` unless this doc says so.
4. **Honest numbers.** Rates and credit amounts come from card terms that can change. Show caveats next to the rate, never behind a tap. Show when terms were last checked.
5. **Never color alone.** Every status color is paired with text and usually an SF Symbol.

## Platform

| | |
|---|---|
| Devices | iPhone 17 Pro (402×874 pt), iPhone 17 Pro Max (440×956 pt) |
| Orientation | Portrait only |
| OS | iOS 26 minimum, iOS 27 current |
| Layout | Standard SwiftUI layout only. No hard-coded screen widths or heights; respect safe areas (Dynamic Island, home indicator) |
| Appearance | Light and dark mode both required |

## Color

### Semantic system colors (use these first)

| Use | SwiftUI |
|---|---|
| Primary text | `.primary` |
| Secondary text, sublabels | `.secondary` |
| Tertiary text (footers, timestamps) | `.tertiary` (foreground style) |
| Screen background (lists, forms) | default `List`/`Form` grouped background (`.systemGroupedBackground`) |
| Row / card surface | `.secondarySystemGroupedBackground` |
| Separators | system default |
| Destructive actions | `role: .destructive` (renders system red) |

### Named asset colors (`Assets.xcassets`)

Only these six custom colors exist. Each has a light and a dark value, and all text uses pass WCAG AA (4.5:1) on `.systemBackground` and `.secondarySystemGroupedBackground`.

| Asset name | Light | Dark | Used for |
|---|---|---|---|
| `AccentColor` | `#0B7A55` | `#34C98E` | App tint: buttons, links, toggles, selected tab, the best-card rate |
| `Urgent` | `#C4301F` | `#FF7A6B` | Credit ends today or tomorrow; validation errors |
| `Caution` | `#8A5A00` | `#FFC24D` | Credit ends within 7 days; "Terms updated" badge; local-edits warning |
| `HintTint` | `#3D5AFE` @ 12% opacity | `#8C9EFF` @ 18% opacity | Background of hint rows ("5x if booked through Chase Travel") |
| `TileStroke` | `#000000` @ 8% | `#FFFFFF` @ 14% | 1 pt hairline around card tiles so dark tiles don't vanish in dark mode |
| `OnAccent` | `#FFFFFF` | `#002B1D` | Label on filled `AccentColor` buttons. White on the dark-mode mint is too low-contrast, so dark mode uses a deep green |

### Card tile colors

The user picks one per card (`UserCard.colorHex`). There are nine presets, shown as a 3×3 swatch grid. Tile text is always white, and every preset is at least 4.5:1 against white. The same hex is used in light and dark mode.

| Name | Hex | Default for |
|---|---|---|
| Graphite | `#3A3A3C` | Custom cards |
| Navy | `#1F3A68` | Chase |
| Royal | `#2F5BD3` | American Express |
| Teal | `#0F6E6E` | |
| Green | `#2E7D32` | |
| Burgundy | `#8E1B3A` | Capital One |
| Copper | `#9A4A14` | |
| Gold | `#8C6A12` | Robinhood |
| Purple | `#5B3FA8` | |

Each swatch's VoiceOver label is its name ("Navy"), plus "selected" when it is the current color.

## Typography

Use semantic text styles only, so everything scales with Dynamic Type. Use `.monospacedDigit()` wherever numbers sit in columns or change in place: rates, amounts, totals, the amount field.

| Role | Style | Notes |
|---|---|---|
| Screen titles | `.navigationTitle` (large on tab roots, inline on pushed screens) | System-rendered |
| Best-card rate (hero) | `.largeTitle`, `.bold`, `.rounded` design | "4x", colored `AccentColor` |
| Dashboard total | `.largeTitle`, `.bold`, `.rounded` | "$415" |
| Card name in hero / detail header | `.title2`, `.semibold` | |
| Row title | `.body` | |
| Row trailing value (rate, remaining) | `.body`, `.semibold`, `.monospacedDigit()` | |
| Row subtitle | `.subheadline`, `.secondary` | |
| Caveat and hint text | `.footnote` | Must wrap, never truncate |
| Section headers / footers | system `Section` header/footer | |
| Badges | `.caption`, `.semibold` | |
| Card tile issuer | `.caption2`, `.semibold`, uppercase | On the tile only |
| Card tile name | `.footnote`, `.semibold` | On the tile only |

**Dynamic Type:** support every size through `.accessibility5`. Text wraps; it never truncates, except a card name inside a small tile (where VoiceOver still reads the full name). At accessibility sizes:
- Horizontal rows (tile + text + trailing value) switch to a vertical stack. Use `ViewThatFits` or check `dynamicTypeSize.isAccessibilitySize`.
- The category grid becomes a one-column list ([SCREENS.md](SCREENS.md#bc-1-best-card--category-grid)).

## Spacing, sizing and shape

| Token | Value | Use |
|---|---|---|
| `space.xs` | 4 pt | Icon-to-text in badges |
| `space.s` | 8 pt | Between lines in a row; between caveat rows |
| `space.m` | 12 pt | Inside tiles; grid gutter |
| `space.l` | 16 pt | Screen side margins (when not using `List` insets); hero padding |
| `space.xl` | 24 pt | Between major blocks in custom (non-List) layouts |
| `radius.tile` | 10 pt, `.continuous` | Card tiles (all sizes) |
| `radius.surface` | 22 pt, `.continuous` | Hero block, category tiles, dashboard summary |
| `hit.min` | 44×44 pt | Every tappable element |

The card tile aspect ratio is 1.586:1, the ISO ID-1 card shape.

Prefer `List` and `Form` insets over custom padding. The `space.*` tokens are for custom layouts: the hero, the category grid and the dashboard summary.

## Iconography

SF Symbols only, at the text style's size (`.imageScale(.medium)` by default). Check every name in the SF Symbols app against the iOS 26 SDK before use. If one is missing, substitute the closest symbol and update this table.

### Tabs

| Tab | Symbol |
|---|---|
| Best Card | `creditcard.and.123` |
| Credits | `gift` |
| Wallet | `wallet.bifold` |
| Settings | `gearshape` |

### Spending categories

The display names and IDs come from [DATA_MODEL.md](../DATA_MODEL.md#spending-categories).

| ID | Symbol | Short label (grid) |
|---|---|---|
| `dining` | `fork.knife` | Dining |
| `groceries` | `cart` | Groceries |
| `gas` | `fuelpump` | Gas |
| `ev_charging` | `ev.charger` | EV Charging |
| `flights` | `airplane` | Flights |
| `hotels` | `bed.double` | Hotels |
| `travel_other` | `car` | Other Travel |
| `transit` | `tram` | Transit & Rideshare |
| `streaming` | `play.tv` | Streaming |
| `drugstores` | `cross.case` | Drugstores |
| `online_retail` | `shippingbox` | Online Shopping |
| `entertainment` | `ticket` | Entertainment |
| `home_improvement` | `hammer` | Home Improvement |
| `utilities` | `lightbulb` | Utilities & Phone |
| `other` | `ellipsis.circle` | Everything Else |

The grid uses the short label. Result titles and VoiceOver use the full display name ("Dining & Restaurants").

### Status and caveat symbols

| Meaning | Symbol | Color |
|---|---|---|
| Condition / cap caveat | `info.circle` | `.secondary` |
| Better rate available (hint) | `lightbulb.min` | `AccentColor` on `HintTint` |
| Depends on spend mix | `chart.bar` | `.secondary` |
| Tie | `equal.circle` | `.secondary` |
| Ends today / tomorrow | `exclamationmark.circle.fill` | `Urgent` |
| Ends within 7 days | `clock` | `Caution` |
| Fully used | `checkmark.circle.fill` | `AccentColor` |
| Needs enrollment | `person.badge.clock` | `Caution` |
| Terms updated | `arrow.triangle.2.circlepath` | `Caution` |
| Archived | `archivebox` | `.secondary` |
| No longer offered (retired catalog card) | `clock.arrow.circlepath` | `.secondary` |
| Offline | `wifi.slash` | `.secondary` |
| Notifications off | `bell.slash` | `.secondary` |

## Formatting rules

All formatting lives in one formatter type, which is unit-tested. Views never build these strings by hand.

### Earn rates

The unit is the card's `rateUnit` override if set (e.g. Chase Freedom → `%`), otherwise its currency's `rateUnit`: `percent` → `%`, `multiplier` → `x`. Estimate nouns come from the currency's `unitName`.

| Value | Visible | VoiceOver |
|---|---|---|
| rate 4, points | `4x` | "4 times points" |
| rate 1.5, miles | `1.5x` | "1.5 times miles" |
| rate 3, cash | `3%` | "3 percent cash back" |
| rate 2.25, cash | `2.25%` | "2.25 percent cash back" |

- Drop trailing zeros and show at most two decimals.
- The full form adds the unit noun: "4x points", "2x miles", "3% cash back". Use the full form in the hero and on Card Detail; the short form in compact rows.
- In VoiceOver, append the category when the context doesn't make it obvious: "4 times points on dining".

### Estimated earnings (amount entered on the result screen)

| Currency | Formula | Visible | VoiceOver |
|---|---|---|---|
| Points / miles | `amount × rate`, rounded half-up to a whole number | `earns ~342 points` | "earns about 342 points" |
| Cash back | `amount × rate ÷ 100`, rounded to cents | `~$2.56 back` | "about 2 dollars 56 cents back" |

Estimates ignore caps (v1 doesn't track spend). If the card has a cap caveat, the cap is already shown next to it.

### Money

- Credit amounts and fees use USD currency format. Whole dollars drop cents ("$10", "$325"); otherwise show two decimals ("$7.50").
- Totals use the same rule.
- Caps use a grouped whole number: "$25,000".

### Periods and dates

| Data | Visible |
|---|---|
| `monthly` | Monthly |
| `quarterly` | Quarterly |
| `semiannual` | Every 6 months |
| `annual` | Yearly |
| `multi_year`, `periodYears` 4 | Every 4 years |
| `calendar` reset | "Resets Nov 1" |
| `cardmember_year` reset | "Resets on your card anniversary (Mar 1)" |
| Period end within 1 day | "Ends today" / "Ends tomorrow" |
| Period end within 7 days | "Ends in 5 days" |
| Period end later | "Ends Dec 31" (add the year only if it isn't the current year) |
| Current period span | "Oct 1 – Oct 31, 2026" |

Compute days with the user's `Calendar` and time zone, the same as `CreditPeriodCalculator`.

## Components

Each component is one SwiftUI view in `Features/Shared/` (or the feature folder if only one feature uses it). Each gets a `#Preview` for every state listed here, in light and dark mode and at `.accessibility3`.

### `CardTile`

A generic card graphic. **It never shows issuer logos or real card art.**

```
┌──────────────────────┐
│ AMERICAN EXPRESS     │   issuer, caption2 uppercase
│                      │
│ Amex Gold            │   card name, footnote semibold
│               ••1005 │   last 4 (only if set)
└──────────────────────┘
```

| Size | Width | Content |
|---|---|---|
| `.small` | 44 pt | Color only, with a `creditcard` glyph at 50% white. Used in rows |
| `.medium` | 72 pt | Issuer initials (e.g. "AX", "CH", "C1", "RH") |
| `.large` | full width, max 320 pt | Issuer, name, last 4 |

States: normal; archived (desaturated to 40% saturation, plus an "Archived" badge outside the tile). Always draw the `TileStroke` hairline.

Accessibility: the tile is decorative (`.accessibilityHidden(true)`) when a text label next to it names the card. Otherwise its label is "American Express, Amex Gold, ending in 1005".

### `RateLabel`

Shows a rate via the formatter. Variants: `.hero` (largeTitle, accent, full form "4x points"), `.row` (body semibold, short form "4x"), `.struck` (secondary + strikethrough, used for the "before" value on the Terms Update screen).

### `CaveatRow` / `HintRow`

```
ⓘ 4x up to $50,000 a year, then 1x
💡 5x if booked through Chase Travel    ›
```

- `CaveatRow`: `info.circle`, footnote, secondary. Not tappable.
- `HintRow`: `lightbulb.min`, footnote, primary text on `HintTint` with a 8 pt radius. It is tappable only when it has an action ("Activate Q4 categories" → Card Detail); then it shows a chevron and is at least 44 pt tall.
- Copy for each `Caveat` case is listed in [SCREENS.md](SCREENS.md#caveat-and-hint-copy).

### `CategoryTile`

The grid item on Best Card. A rounded rectangle (`radius.surface`) on `.secondarySystemGroupedBackground`, with the symbol (title2) over the short label (subheadline, two lines max, centered). Its minimum height is 88 pt, and it fills the column width.

States: normal; pressed (system button highlight, `.buttonStyle(.plain)` + scale 0.97). There is no selected state, because tapping navigates.

### `CreditRow`

```
▭  Dining Credit                    $10
   Amex Gold · Ends in 5 days ◷   of $10
   ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
```

- Leading: `CardTile(.small)`.
- Title: credit name. Subtitle: card display name · end-date text with urgency symbol.
- Trailing: remaining (semibold), "of $amount" (caption, secondary).
- A `ProgressView(value: used, total: amount)` sits under the text, tinted `AccentColor`.

| State | Treatment |
|---|---|
| Available, > 7 days | Default |
| Ends within 7 days | `clock` + "Ends in 5 days" in `Caution` |
| Ends today / tomorrow | `exclamationmark.circle.fill` + "Ends tomorrow" in `Urgent` |
| Partly used | Remaining "$4" of "$10"; progress 60% |
| Fully used | `checkmark.circle.fill` + "Used" replaces the remaining amount; row in secondary |
| Needs enrollment | `person.badge.clock` + "Enroll first" badge in `Caution` |
| Needs card open date | "Add card open date to track" in secondary (cardmember-year credit on a card with no `openedOn`) |
| Archived | `archivebox` + "Archived"; no progress bar; only on Card Detail |

VoiceOver (one element): "Dining Credit, Amex Gold. 10 dollars left of 10. Ends in 5 days, October 31." Swipe actions are exposed as accessibility actions.

### `StatusBadge`

A capsule containing a symbol and a caption-semibold label. Variants: `termsUpdated` ("Terms updated", Caution), `archived`, `tie` ("Tie"), `enroll` ("Enroll first"), `retired` ("No longer offered", secondary, `clock.arrow.circlepath`), `offline`. The text is always present, never icon-only.

### `SummaryHeader` (Credits dashboard)

A custom block at the top of the Credits list, on `.secondarySystemGroupedBackground` with `radius.surface`. Big total, then a second line. Details in [SCREENS.md](SCREENS.md#cr-1-credits-dashboard).

### `AmountField`

A currency `TextField` with `.keyboardType(.decimalPad)`, `.monospacedDigit()`, a "$" prefix and a clear button. The keyboard toolbar has **Done**. It accepts up to 2 decimals and a maximum of $999,999.99. Invalid input is ignored as typed; it never shows an error.

### Buttons

| Role | Style |
|---|---|
| Primary action on a screen (Add to Wallet, Mark as Used, Apply Update, Add Your First Card) | `.primaryActionStyle()`: `.glassProminent`, `.controlSize(.large)`, `OnAccent` label; full width in sheets |
| Secondary action (Log Partial Amount, Not Now) | `.buttonStyle(.glass)` or plain text button |
| Toolbar actions | System toolbar items (glass is automatic) |
| Destructive | `Button(role: .destructive)` inside confirmation dialogs or menus only |

Only one prominent button per screen.

### Empty states

Use `ContentUnavailableView` with an SF Symbol, a title, one line of description and at most one button. The copy for each screen is in [SCREENS.md](SCREENS.md).

### Banners (in-list)

A `Section` at the top of a list with a symbol, a one-line message and an optional button. Used for "Terms updated", "Archived card", "Notifications are off" and "Offline". They are not floating and never auto-dismiss.

## Motion and haptics

- Use system transitions only: push, sheet and `.contentTransition(.numericText())` for changing numbers (estimates, remaining amounts, totals).
- Re-ranking (e.g. after toggling a portal setting) animates list order with the default spring.
- With **Reduce Motion** on, numeric and reorder animations become cross-fades.
- Haptics via `.sensoryFeedback`:
  - `.selection` on a category tap.
  - `.success` on Mark as Used, Add to Wallet and Apply Update.
  - `.warning` before a destructive confirmation appears.
- No custom loading spinners. Use `ProgressView()` only for the catalog check, which is the app's only network wait.

## Accessibility rules

1. **Labels on every number.** Rates: "4 times points on dining". Amounts: "10 dollars left of 10". Dates: "ends tomorrow, October 31". Never let VoiceOver read "4x" or "$10/$10".
2. **Combine rows.** List rows are one accessibility element (`.accessibilityElement(children: .combine)` or an explicit label), with swipe actions exposed as `.accessibilityActions`.
3. **Ranking is spoken.** Result rows start with their position: "Best card", "Second", "Tied for second".
4. **Hit targets** are at least 44×44 pt, including swatches, chevrons, hint rows and the clear button.
5. **Color is never the only signal.** Urgency, ties, terms updates and used states all carry text and a symbol.
6. **Contrast** for all text colors is at least 4.5:1 (the tokens above are chosen for this). Respect **Increase Contrast**: drop `HintTint` opacity in favor of a 1 pt `AccentColor` border.
7. **Dynamic Type** works up to `.accessibility5` with no clipped text (see Typography).
8. **Bold Text, Smart Invert, Reduce Transparency** all work: tiles are marked `.accessibilityIgnoresInvertColors(true)`, and Reduce Transparency is handled by the system glass components.
9. **Sensitive data never requested.** The last-4 field uses `.keyboardType(.numberPad)`, is limited to 4 digits and has no `textContentType`, so iOS never offers card AutoFill. No screen has fields for a full card number, CVV or expiry.

## Copy style

- Sentence case for everything except buttons and navigation titles, which use title case ("Add to Wallet").
- Address the user as "you". Avoid jargon: say "card anniversary", not "cardmember year".
- Card display name = nickname if set, else the card's `name`. The issuer is shown on the tile and in detail views. Examples in these docs assume catalog names that read well on their own: "Amex Gold", "Sapphire Preferred", "Freedom Flex", "Savor", "Robinhood Gold Card".
- Never imply guarantees: "Terms checked Oct 1, 2026", not "Current terms".
