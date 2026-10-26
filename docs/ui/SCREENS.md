# Screens

One section per screen. Tokens, components and formatting rules come from [DESIGN_SYSTEM.md](DESIGN_SYSTEM.md); multi-screen journeys are in [FLOWS.md](FLOWS.md).

Wireframes are drawn at iPhone 17 Pro width (402 pt). On the Pro Max (440 pt) the same layout gets wider rows and tiles; no screen has a width-specific layout.

> **No point valuations.** Cards are ranked by raw earn rate (1x = 1%). No screen shows cents-per-point or an "effective return %", and Settings has no valuation screen.

## Example data

Every wireframe uses this wallet. **The terms are illustrative only, not catalog data.**

| Card (display name) | Issuer | Currency | Tile | Rates | Credits |
|---|---|---|---|---|---|
| Amex Gold ••1005 | American Express | Membership Rewards (points) | Royal | Dining 4x (cap $50,000/yr, then 1x) · Groceries 4x (cap $25,000/yr, then 1x; U.S. only) · Flights 3x (booked direct or via portal) · Everything else 1x | Dining Credit $10 monthly · Uber Cash $10 monthly · Resy Credit $50 every 6 months (needs enrollment) · Dunkin' Credit $7 monthly (needs enrollment) |
| Sapphire Preferred | Chase | Ultimate Rewards (points) | Navy | Dining 3x · Streaming 3x · Flights / Hotels / Other Travel 2x (5x via portal) · Everything else 1x | Hotel Credit $50 yearly (card anniversary) |
| Freedom Flex | Chase | shown as % (see note) | Teal | Rotating 5% (Q4 2026: Online Shopping, Drugstores; needs activation, cap $1,500/quarter) · Dining 3% · Drugstores 3% · Everything else 1% | none |
| Savor | Capital One | Cash back | Burgundy | Dining 3% · Groceries 3% · Streaming 3% · Entertainment 3% · Everything else 1% | none |
| Robinhood Gold Card | Robinhood | Cash back | Gold | Everything else 3% (flat, no category bonuses) | none |

"Today" in the examples is **Mon, Oct 27, 2026**.

Note: Freedom Flex's unit (% or x) comes from its catalog `rewardCurrency`; see the gaps listed at the end of this file.

## Navigation map

```
TabView
├── Best Card    NavigationStack: BC-1 Category Grid → BC-2 Result → WA-2 Card Detail
├── Credits      NavigationStack: CR-1 Dashboard → CR-2 Credit Detail
│                                 sheet: CR-3 Log Usage
├── Wallet       NavigationStack: WA-1 Wallet → WA-2 Card Detail → CR-2 Credit Detail
│                                 sheets: WA-3/WA-4 Add Card, WA-5 Card Editor (→ WA-6, WA-7), WA-8 Terms Update
└── Settings     NavigationStack: ST-1 Settings → ST-2 Reminder Timing
Full-screen / sheets owned by the root: ON-1 Card Picker (first launch), ON-2 Reminder Primer
```

**Launch rule:** a cold launch always opens **Best Card → BC-1**. When the app returns from the background after 15 minutes or more, it also resets to BC-1, unless a sheet with unsaved edits is open. Otherwise the app resumes where the user left it.

**Credits tab badge:** the number of unused credits (remaining > 0, not archived) whose period ends within 7 days. It is hidden at 0.

---

## ON-1 Card Picker (first launch)

> **Changed 2026-10-26 (user decision):** this replaces the earlier Welcome sheet. The first screen is where the user picks their cards.

**Purpose:** let a new user tick every card they carry in one pass.

**Entry:** first launch, shown full-screen when `hasSeenWelcome == false` and the wallet is empty. The same view is the **Add Cards** sheet from WA-1 **＋** and the BC-1 / WA-1 empty states (inline title, **Cancel** in the toolbar, no intro text, no Skip).

```
┌────────────────────────────────────────┐
│               Your Cards               │
│ ┌────────────────────────────────────┐ │
│ │ 🔍 Search cards                    │ │  .searchable, always shown
│ └────────────────────────────────────┘ │
│ Select every card you carry. We'll use │  subheadline, secondary
│ them to tell you which card earns the  │
│ most for each purchase.                │
│ American Express                       │
│ ┌────────────────────────────────────┐ │
│ │ ▭ Blue Cash Everyday           ○   │ │
│ │   No annual fee                    │ │
│ │ ▭ Gold                         ◉   │ │  checkmark.circle.fill, accent
│ │   $325/yr                          │ │
│ │ ▭ Classic Green                ○   │ │
│ │   $150/yr                          │ │
│ │   ◷ No longer offered              │ │
│ └────────────────────────────────────┘ │
│ Capital One …  Chase …  Robinhood …    │
├────────────────────────────────────────┤
│ ╭────────────────────────────────────╮ │  safeAreaBar (scroll edge effect)
│ │            Add 3 Cards             │ │  primaryActionStyle
│ ╰────────────────────────────────────╯ │
│              Skip for Now              │  onboarding only
└────────────────────────────────────────┘
```

**Content:**
- Grouping, sorting, retired cards and search behave the same as WA-3.
- Rows show `CardTile(.small)`, the short name, the fee line and "In your wallet" if the user already has the card.
- While searching, the list is flat and the subtitle adds the issuer ("American Express · $325/yr").

**States:** browse; searching; no results (`ContentUnavailableView.search`). The button reads "Select Your Cards" (disabled) when nothing is selected, then "Add 1 Card" / "Add N Cards".

**Interactions:**
- Tapping a row toggles selection, with a `.selection` haptic.
- **Add N Cards** copies each selected card from the catalog, in catalog order, and then dismisses (sheet) or shows the tabs (first launch).
- **Skip for Now** sets `hasSeenWelcome = true` and shows the BC-1 empty state.

**VoiceOver:** each row is one button, "Gold, American Express, 325 dollars a year", with the Selected trait when ticked.

---

## ON-2 Reminder Primer

**Purpose:** explain reminders before iOS shows its notification permission alert.

**Entry:** right after the user adds their first card that has at least one credit, when notification authorization is `.notDetermined` ([FLOWS.md](FLOWS.md#f2-add-a-card-from-the-catalog)). It is presented as a `.sheet` at `.medium` detent.

```
┌────────────────────────────────────────┐
│               (bell.badge)             │
│                                        │
│      Don't let credits go unused       │
│                                        │
│  Amex Gold has $77 in credits. We'll   │
│  remind you 7 days and 1 day before    │
│  each one ends. You can change this    │
│  in Settings.                          │
│                                        │
│ ╭────────────────────────────────────╮ │
│ │         Turn On Reminders          │ │
│ ╰────────────────────────────────────╯ │
│               Not Now                  │
└────────────────────────────────────────┘
```

**Content:** the dollar figure is the sum of the card's non-archived credit amounts for one period each. The offsets come from the global default (`reminderOffsetsDays`).

**Interactions:**
- **Turn On Reminders** calls `requestAuthorization(options: [.alert, .sound, .badge])` and dismisses once the system alert is answered.
- **Not Now** dismisses. It is never shown again automatically; ST-1 offers "Turn On".

**States:** one state only.

**VoiceOver:** the body reads as written, with "$77" spoken as "77 dollars".

---

## BC-1 Best Card – Category Grid

**Purpose:** the at-the-register screen. One tap on a category shows the answer.

**Entry:** the Best Card tab root; app launch.

```
┌────────────────────────────────────────┐
│ Best Card                              │  large title
│ What are you paying for?               │  subheadline, secondary
│                                        │
│ ╭──────────╮ ╭──────────╮ ╭──────────╮ │
│ │   🍴     │ │   🛒     │ │   ⛽     │ │
│ │  Dining  │ │Groceries │ │   Gas    │ │
│ ╰──────────╯ ╰──────────╯ ╰──────────╯ │
│ ╭──────────╮ ╭──────────╮ ╭──────────╮ │
│ │   ✈︎     │ │   🛏     │ │   🚗     │ │
│ │ Flights  │ │  Hotels  │ │  Other   │ │
│ │          │ │          │ │  Travel  │ │
│ ╰──────────╯ ╰──────────╯ ╰──────────╯ │
│ ╭──────────╮ ╭──────────╮ ╭──────────╮ │
│ │ Transit &│ │Streaming │ │Drugstores│ │
│ │ Rideshare│ │          │ │          │ │
│ ╰──────────╯ ╰──────────╯ ╰──────────╯ │
│ ╭──────────╮ ╭──────────╮ ╭──────────╮ │
│ │  Online  │ │Entertain-│ │   Home   │ │
│ │ Shopping │ │  ment    │ │Improvemnt│ │
│ ╰──────────╯ ╰──────────╯ ╰──────────╯ │
│ ╭──────────╮ ╭──────────╮ ╭──────────╮ │
│ │Utilities │ │EV Charging│ │Everything│ │
│ │ & Phone  │ │          │ │   Else   │ │
│ ╰──────────╯ ╰──────────╯ ╰──────────╯ │
│ Comparing 5 cards                      │  footnote, tertiary
├────────────────────────────────────────┤
│  [Best Card] [Credits•2] [Wallet] [⚙]  │  tab bar (glass)
└────────────────────────────────────────┘
```

**Content:**
- A `ScrollView` with a `LazyVGrid` of 3 flexible columns (`space.m` gutter, `space.l` side margins) holding `CategoryTile`s.
- **Fixed order** for muscle memory: Dining, Groceries, Gas, Flights, Hotels, Other Travel, Transit & Rideshare, Streaming, Drugstores, Online Shopping, Entertainment, Home Improvement, Utilities & Phone, EV Charging, Everything Else.
- At the default text size, all 15 tiles fit above the tab bar on both devices.
- Footer: "Comparing N cards" (non-archived cards). When `includePortalRates` is on, it adds a second line: "Portal booking rates included."

**Dynamic Type:** the grid uses 3 columns up to `.xxxLarge`, 2 columns at `.accessibility1–2`, and at `.accessibility3+` a `List` of rows (symbol + full display name + chevron).

**States:**

| State | Shown |
|---|---|
| Populated (≥1 non-archived card) | Grid as above |
| Empty (no cards, or all archived) | `ContentUnavailableView`: symbol `creditcard`, title "Add a card to get started", description "Add the cards you carry and we'll show which one earns the most for each purchase.", button **Add Card** → WA-3. The grid is hidden |
| Loading | None. Everything is local and synchronous |
| Offline / error | Not applicable. This screen never touches the network |

**Interactions:**
- Tapping a tile pushes BC-2 for that category, with `.selection` haptic.
- There is no search, filter or toolbar button. Keeping the path short matters more than extra features here.

**VoiceOver:**
- Each tile is a button labeled with the full display name ("Dining and Restaurants") and the hint "Shows your best card".
- The subtitle is read after the title.
- The footer reads "Comparing 5 cards".

---

## BC-2 Best Card – Result

**Purpose:** show which card to use for the chosen category, why, and how the rest of the wallet ranks. This screen is also the PRD F4 "category view": it lists every non-archived card's rate for one category.

**Entry:** BC-1 tile tap. Navigation title is the category's full display name, inline.

### Populated: single winner (Dining)

```
┌────────────────────────────────────────┐
│ ‹            Dining & Restaurants      │
│                                        │
│ ╭────────────────────────────────────╮ │
│ │ USE THIS CARD                      │ │  caption, secondary
│ │ ┌────────┐  Amex Gold              │ │  title2 semibold
│ │ │ AX     │  American Express ••1005│ │  subheadline secondary
│ │ └────────┘                         │ │
│ │ 4x points                          │ │  largeTitle bold rounded, accent
│ │ earns ~342 points                  │ │  only when an amount is entered
│ │ ⓘ 4x up to $50,000 a year, then 1x │ │  CaveatRow(s)
│ ╰────────────────────────────────────╯ │
│                                        │
│ ┌────────────────────────────────────┐ │
│ │ $ 85.40                         ⊗  │ │  AmountField, placeholder
│ └────────────────────────────────────┘ │  "Amount (optional)"
│                                        │
│ OTHER CARDS                            │
│ ┌────────────────────────────────────┐ │
│ │ ⊜ Tied for 2nd · all earn 3        │ │  tie group header
│ │ ▭ Freedom Flex             3%  ›   │ │
│ │   ~$2.56 back                      │ │
│ │ ▭ Savor                    3%  ›   │ │
│ │   ~$2.56 back                      │ │
│ │ ▭ Sapphire Preferred       3x  ›   │ │
│ │   ~256 points                      │ │
│ │ ▭ Robinhood Gold Card      3%  ›   │ │
│ │   ~$2.56 back                      │ │
│ └────────────────────────────────────┘ │
│ Ranked by earn rate. 1x points counts  │  section footer
│ the same as 1% cash back. Terms can    │
│ change; check each card for details.   │
└────────────────────────────────────────┘
```

### Populated: tie for best (Flights)

```
│ ╭────────────────────────────────────╮ │
│ │ ⊜ TIE · EITHER CARD EARNS 3        │ │  StatusBadge(.tie) + caption
│ │ ┌────────┐  Amex Gold              │ │
│ │ │ AX     │  American Express ••1005│ │
│ │ └────────┘                         │ │
│ │ 3x points                          │ │
│ │ ⓘ Only when booked directly or     │ │
│ │   through the American Express     │ │
│ │   travel portal                    │ │
│ │ ────────────────────────────────── │ │
│ │ ┌────────┐  Robinhood Gold Card    │ │
│ │ │ RH     │  Robinhood              │ │
│ │ └────────┘                         │ │
│ │ 3% cash back                       │ │
│ ╰────────────────────────────────────╯ │
│ OTHER CARDS                            │
│ ▭ Sapphire Preferred       2x  ›       │
│   ╭──────────────────────────────────╮ │
│   │💡 5x if booked through the Chase │ │  HintRow
│   │  travel portal                   │ │
│   ╰──────────────────────────────────╯ │
│ ⊜ Tied for 4th · both earn 1           │
│ ▭ Freedom Flex             1%  ›       │
│ ▭ Savor                    1%  ›       │
```

**Content:**
- **Hero** (custom block on `.secondarySystemGroupedBackground`, `radius.surface`, `space.l` padding; not glass): "USE THIS CARD" label, `CardTile(.medium)`, display name, issuer + last 4, `RateLabel(.hero)`, an optional estimate line, then all caveats and hints for that card.
- **Hero tie:** when 2 or more cards tie at the top (`isTie` on the first results with the same rate), every tied card goes in the hero, separated by a divider, in engine order. The header becomes "TIE · EITHER CARD EARNS 3" for 2 cards, or "TIE · ANY OF THESE EARNS 3" for 3 or more. "3" is the bare rate number, because the tied cards can mix x and %.
- **Amount field** sits between the hero and the list. It is optional, and editing it updates the estimates live.
- **Other cards:** a `List` section (inset grouped) with one row per remaining card, in engine order:
  - Row: `CardTile(.small)`, display name, `RateLabel(.row)` trailing, chevron.
  - An optional estimate line, then the card's caveats and hints as `CaveatRow`/`HintRow` beneath it.
  - Runs of adjacent tied cards get a group header row "⊜ Tied for 2nd · all earn 3" (or "both earn 3" for two cards).
- **Footer:** "Ranked by earn rate. 1x points counts the same as 1% cash back. Terms can change; check each card for details."

### Caveat and hint copy

| Engine output | Kind | Copy (`{issuer}` = card's issuer) |
|---|---|---|
| `condition(.bookedDirectOrPortal)` | Caveat | "Only when booked directly or through the {issuer} travel portal" |
| `condition(.usOnly)` | Caveat | "U.S. purchases only" |
| `condition(.bookedViaPortal)` (only when portal rates are included) | Caveat | "Only when booked through the {issuer} travel portal" |
| `condition(.requiresActivation)` (activated rotating row) | Caveat | "Q4 2026 bonus category, activated" |
| `cap(amount, period, afterCapRate)` | Caveat | "4x up to $25,000 a year, then 1x" (period word: month / quarter / year) |
| `betterRateAvailable(rate, .bookedViaPortal)` | Hint | "5x if booked through the {issuer} travel portal" |
| `betterRateAvailable(rate, .requiresActivation)` | Hint, tappable | "5% this quarter if you activate it" + chevron. Tapping opens WA-2 scrolled to Bonus Categories |
| `betterRateAvailable(rate, .brandOnly)` | Hint | "3x if it's a {brand} purchase" (needs the brand; see gaps) |
| `dependsOnSpendMix` | Caveat (`chart.bar`) | "Only if this is your top spending category this billing cycle" |

Caveats come before hints. Neither is ever truncated.

**States:**

| State | Shown |
|---|---|
| Populated, ≥2 cards | Hero + Other Cards as above |
| One card | Hero only. The Other Cards section is replaced by a footnote: "Add more cards to compare." with an **Add Card** link → WA-3 |
| No cards | Not reachable: BC-1 shows its empty state instead. If the last card is archived while BC-2 is open, pop to BC-1 |
| All cards earn the base rate | Normal ranking. No special state |
| Amount empty | No estimate lines |
| Amount entered | Estimate line under every rate (formats in [DESIGN_SYSTEM.md](DESIGN_SYSTEM.md#estimated-earnings-amount-entered-on-the-result-screen)) |
| Loading / offline / error | None. The engine is local and synchronous |

**Interactions:**
- Typing in the amount field recomputes estimates (`.numericText()` transition). The ranking never changes with the amount.
- The amount is kept while the user stays on BC-2 and is cleared when they pop back to BC-1.
- Tapping a hero card or a row pushes WA-2 Card Detail inside the Best Card stack.
- A tappable activation hint pushes WA-2 and scrolls to "Bonus Categories".
- On return from WA-2 (e.g. after activating), the result recomputes and re-sorts with animation.
- Tapping the hero card name area does the same as tapping a row; there is no separate button.

**VoiceOver:**
- Hero, single winner: "Best card: Amex Gold, American Express ending in 1005. 4 times points on dining. Earns about 342 points. 4 times up to 50,000 dollars a year, then 1 times."
- Hero, tie: "Tie for best card. Amex Gold, 3 times points on flights. Only when booked directly or through the American Express travel portal. Robinhood Gold Card, 3 percent cash back on flights." Each card is its own element, starting with "Tied for best".
- Rows: "Tied for second: Savor, 3 percent cash back on dining. About 2 dollars 56 cents back." Non-tied rows say "Second", "Third", and so on.
- Amount field: label "Purchase amount, optional"; hint "Shows how much each card would earn".

---

## CR-1 Credits Dashboard

**Purpose:** show every credit still available this period, soonest-ending first, with totals (PRD F2).

**Entry:** Credits tab root; monthly-summary notification.

```
┌────────────────────────────────────────┐
│ Credits                                │
│ ╭────────────────────────────────────╮ │
│ │ $121                               │ │  largeTitle bold rounded
│ │ available across 5 credits         │ │  subheadline secondary
│ │ ◷ $21 ends this month              │ │  subheadline, Caution
│ ╰────────────────────────────────────╯ │
│                                        │
│ ENDS THIS MONTH                        │
│ ┌────────────────────────────────────┐ │
│ │ ▭ Dining Credit               $10  │ │
│ │   Amex Gold · ◷ Ends in 4 days of $10│
│ │   ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░   │ │
│ │ ▭ Uber Cash                    $4  │ │
│ │   Amex Gold · ◷ Ends in 4 days of $10│
│ │   ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓░░░░░░░░░░░░   │ │
│ │ ▭ Dunkin' Credit               $7  │ │
│ │   Amex Gold · ◷ Ends in 4 days  of $7│
│ │   ⧗ Enroll first                   │ │
│ └────────────────────────────────────┘ │
│ LATER                                  │
│ ┌────────────────────────────────────┐ │
│ │ ▭ Resy Credit                 $50  │ │
│ │   Amex Gold · Ends Dec 31     of $50│ │
│ │ ▭ Hotel Credit                $50  │ │
│ │   Sapphire Preferred · Ends Feb 28, │ │
│ │   2027                        of $50│ │
│ └────────────────────────────────────┘ │
└────────────────────────────────────────┘
```

**Content:**
- `SummaryHeader`:
  - Total remaining across all non-archived credits on non-archived cards (current period).
  - "available across N credits", where N counts credits with remaining > 0.
  - "◷ $X ends this month": the remaining amount of credits whose current period ends this calendar month. The line is hidden when $0.
- **Sections:**
  - **Ends this month:** remaining > 0, period ends this calendar month.
  - **Later:** remaining > 0, ends after this month.
  - **Used this period:** remaining = 0, collapsed by default, hidden when empty.
  - Each section is sorted by period end ascending, then by remaining descending.
- Rows are `CreditRow`. Unenrolled credits (`requiresEnrollment && !isEnrolled`) still count in the totals and show "Enroll first".

**States:**

| State | Shown |
|---|---|
| Populated | As above |
| No credits at all (no cards, or cards without credits) | `ContentUnavailableView`: symbol `gift`, title "No credits to track", description "Cards with monthly or yearly credits show up here once you add them.", button **Add Card** → WA-3 |
| All credits used this period | Header shows "$0 available"; the Ends this month / Later sections are replaced by a row "✓ You've used every credit this period. Next reset: Nov 1." The Used section is expanded |
| Credit missing a card open date | Row shows "Add card open date to track" and is excluded from totals; tapping it opens WA-5 for that card at the Card Open Date field |
| Loading / offline / error | None (local data) |

**Interactions:**
- Tapping a row pushes CR-2.
- Leading swipe (full swipe allowed): **Mark Used** (`AccentColor`, `checkmark`). It logs the remaining amount for today, then plays `.success` haptic and re-sorts the row into Used. A trailing swipe offers **Log Amount**, which opens CR-3.
- Pull to refresh is not offered, since there is nothing remote.
- At midnight or on foreground, recompute periods so rolled-over credits reappear (`.onChange(of: scenePhase)` + a day-change notification).

**VoiceOver:**
- Header: "121 dollars available across 5 credits. 21 dollars ends this month."
- Rows: see `CreditRow` in the design system.
- The swipe actions "Mark used" and "Log amount" are exposed as custom actions.

---

## CR-2 Credit Detail

**Purpose:** see one credit's current period, mark it used, log partial use, manage enrollment and reminders, and view history.

**Entry:** CR-1 row; WA-2 credit row; reminder notification tap ([FLOWS.md](FLOWS.md#f6-reminder-notification-opens-the-credit)). The title is the credit name, inline.

```
┌────────────────────────────────────────┐
│ ‹ Credits          Dining Credit       │
│                                        │
│ ▭ Amex Gold · Monthly                  │
│ $10 left                               │  largeTitle bold rounded
│ of $10 · Oct 1 – Oct 31, 2026          │
│ ◷ Ends in 4 days                       │  Caution
│ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓   │
│ ╭────────────────────────────────────╮ │
│ │           Mark as Used             │ │  glassProminent
│ ╰────────────────────────────────────╯ │
│         Log Partial Amount             │  glass
│                                        │
│ ENROLLMENT                (if needed)  │
│ ┌────────────────────────────────────┐ │
│ │ I've enrolled              [  ○ ]  │ │
│ └────────────────────────────────────┘ │
│ This credit only works after you       │
│ enroll on the issuer's site or app.    │
│                                        │
│ REMINDERS                              │
│ ┌────────────────────────────────────┐ │
│ │ Remind me                  [ ●  ]  │ │
│ │ When        7 and 1 days before ›  │ │
│ └────────────────────────────────────┘ │
│                                        │
│ HISTORY                                │
│ ┌────────────────────────────────────┐ │
│ │ October 2026               $0 used │ │
│ │ September 2026      $10 used ✓     │ │
│ │   Sep 14 · $10 · "Grubhub order"   │ │
│ │ August 2026          $6 used       │ │
│ │   Aug 3 · $6                       │ │
│ └────────────────────────────────────┘ │
│ NOTES                                  │
│ Eligible merchants: Grubhub, The       │
│ Cheesecake Factory, Goldbelly…         │
│ Resets on the 1st of each month.       │  footer
└────────────────────────────────────────┘
```

**Content:**
- Header block: card tile (small) + card display name + period word; remaining (`.largeTitle`); "of $amount · current period span"; urgency line; progress bar.
- **Enrollment** section, only when `requiresEnrollment`: a toggle bound to `isEnrolled`.
- **Reminders** section: the **Remind me** toggle (`remindersEnabled`) and a **When** row showing either "Default (7 and 1 days before)" or the custom offsets; it pushes ST-2 in per-credit mode.
- **History:**
  - The current period first, then past periods newest first, each with its total used.
  - Usage entries are listed under their period (date · amount · note).
  - Past periods with no usage show "$0 used" with no entries.
  - Show the last 12 periods, then a **Show All** row.
- **Notes** from the catalog, if any.
- **Footer:** the reset rule ("Resets on the 1st of each month", "Resets on your card anniversary (Mar 1)", "Every 4 years from your card anniversary").

**States:**

| State | Shown |
|---|---|
| Available | As above |
| Partly used | "$4 left · of $10"; both buttons. **Mark as Used** logs the remaining $4 |
| Fully used | Remaining line becomes "✓ Used" (`AccentColor`); the urgency line becomes "Available again Nov 1"; **Mark as Used** is hidden and **Log Partial Amount** is disabled; the Reminders section footer reads "No reminders until it resets." |
| Needs enrollment, not enrolled | A banner at the top: "person.badge.clock Enroll in this credit on the issuer's site before using it." Buttons stay enabled |
| Archived credit | A banner: "archivebox This credit was removed from the card's terms. Its history is kept." Buttons, Enrollment and Reminders are hidden; History is read-only |
| Card archived | A banner: "This card is archived. Unarchive it to track this credit." Buttons and Reminders are hidden |
| Missing card open date (cardmember-year credit) | The header shows "Add your card open date to track this credit" with an **Add Date** button → WA-5 at that field |
| Deleted while open (e.g. from a notification) | Pop to CR-1 |

**Interactions:**
- **Mark as Used:** logs a `CreditUsage` for the remaining amount with `loggedAt = now`. Then `.success` haptic, a numeric transition to "✓ Used", and the period's pending reminders are cancelled.
- **Log Partial Amount:** opens CR-3.
- Swiping a usage entry offers **Delete** (destructive, no confirmation; the amount returns to remaining and reminders reschedule). Past-period entries can be deleted too.
- Turning **Remind me** off cancels this credit's pending reminders. Turning it on reschedules them.

**VoiceOver:**
- Header: "Dining Credit, Amex Gold, monthly. 10 dollars left of 10. Current period October 1 to October 31, 2026. Ends in 4 days."
- History period: "September 2026, 10 dollars used, fully used."

---

## CR-3 Log Usage (sheet)

**Purpose:** log a partial amount against the current period.

**Entry:** CR-2 **Log Partial Amount**; CR-1 trailing swipe **Log Amount**. Presented as a `.sheet` at the `.medium` detent with its own `NavigationStack`.

```
┌────────────────────────────────────────┐
│ Cancel       Log Usage           Save  │
│                                        │
│ Uber Cash · Amex Gold                  │
│ $10 left this period                   │
│ ┌────────────────────────────────────┐ │
│ │ Amount                    $ 6.00   │ │
│ │ Date                      Oct 27 › │ │
│ │ Note                  Optional     │ │
│ └────────────────────────────────────┘ │
│ Use $10 (all of it)                    │  button, fills the amount
└────────────────────────────────────────┘
```

**Content:** the amount field is focused on appear, empty. The date defaults to today and is limited to the current period's start…today. The note is limited to 100 characters.

**States and validation:**

| State | Behavior |
|---|---|
| Empty or $0 | **Save** disabled |
| Amount > remaining | Inline `Urgent` footnote "You have $10 left this period." **Save** disabled |
| Valid | **Save** enabled |
| Save fails | Alert "Couldn't save. Please try again." with **OK** |

**Interactions:** **Save** logs the usage, dismisses with `.success` haptic, and updates the reminders (cancelled if the credit is now fully used). **Cancel** discards without confirmation, since there are at most 3 fields.

**VoiceOver:** the amount field is labeled "Amount used, dollars". The validation message is announced when it appears.

---

## WA-1 Wallet

**Purpose:** list the user's cards; add a card; reach a card's details.

**Entry:** Wallet tab root.

```
┌────────────────────────────────────────┐
│ Wallet                             ＋  │
│ ┌────────────────────────────────────┐ │
│ │ ▭ Amex Gold                      › │ │
│ │   American Express ••1005          │ │
│ │   $325/yr · 4 credits              │ │
│ │   ⟳ Terms updated                  │ │  StatusBadge, Caution
│ │ ▭ Sapphire Preferred             › │ │
│ │   Chase · $95/yr · 1 credit        │ │
│ │ ▭ Freedom Flex                   › │ │
│ │   Chase · No annual fee            │ │
│ │   💡 Activate Q4 categories         │ │
│ │ ▭ Savor                          › │ │
│ │   Capital One · No annual fee      │ │
│ │ ▭ Robinhood Gold Card            › │ │
│ │   Robinhood · $5/mo membership     │ │
│ └────────────────────────────────────┘ │
│ ▸ ARCHIVED (1)                         │
└────────────────────────────────────────┘
```

**Content:**
- An inset-grouped `List`, sorted by the user's manual order (drag in **Edit** mode), defaulting to the order added.
- Row: `CardTile(.small)`; display name; issuer + last 4; a fee line ("$325/yr", "No annual fee", or "$5/mo membership" when there's a required membership and no annual fee); a credit count.
- Badges, at most one per row, in priority order: Terms updated → Activate Qn categories (rotating row this quarter not activated) → Choose your bonus category (user-selectable row with no selection).
- **Archived** is a collapsed `DisclosureGroup` section showing archived cards with desaturated tiles.

**Toolbar:** **＋** (`plus`) opens WA-3. An **Edit** button appears when there are 2 or more cards, enabling reordering.

**States:**

| State | Shown |
|---|---|
| Populated | As above |
| Empty | `ContentUnavailableView`: symbol `wallet.bifold`, title "Your wallet is empty", description "Add cards from the catalog or enter your own.", button **Add Card** → WA-3 |
| Only archived cards | The empty view, plus the Archived section below it |
| Loading / offline / error | None |

**Interactions:**
- Tapping a row pushes WA-2.
- Trailing swipe: **Archive** (gray, `archivebox`) and **Delete** (destructive), which opens the delete confirmation from [FLOWS.md](FLOWS.md#f9-archive-or-delete-a-card).
- On archived rows the swipe offers **Unarchive** and **Delete**.

**VoiceOver:** "Amex Gold, American Express ending in 1005. 325 dollars a year. 4 credits. Terms updated." The swipe actions are custom actions.

---

## WA-2 Card Detail

**Purpose:** everything about one card: rates, bonus-category activation, credits, terms status, personal details.

**Entry:** WA-1 row; BC-2 row or hero; annual-fee notification. The title is the card display name, inline.

```
┌────────────────────────────────────────┐
│ ‹ Wallet          Amex Gold        ⋯   │  menu: Edit, Archive, Delete
│ ┌────────────────────────────────────┐ │
│ │ AMERICAN EXPRESS                   │ │  CardTile(.large), Royal
│ │                                    │ │
│ │ Amex Gold                   ••1005 │ │
│ └────────────────────────────────────┘ │
│ ⟳ TERMS UPDATED                        │  banner section (if applicable)
│ ┌────────────────────────────────────┐ │
│ │ American Express changed this      │ │
│ │ card's terms.      Review Changes ›│ │
│ └────────────────────────────────────┘ │
│ EARN RATES                             │
│ ┌────────────────────────────────────┐ │
│ │ 🍴 Dining & Restaurants    4x      │ │
│ │    ⓘ 4x up to $50,000 a year, then 1x│
│ │ 🛒 Groceries / Supermarkets 4x     │ │
│ │    ⓘ U.S. purchases only           │ │
│ │    ⓘ 4x up to $25,000 a year, then 1x│
│ │ ✈︎ Travel – Flights         3x      │ │
│ │    ⓘ Only when booked directly or  │ │
│ │      through the American Express  │ │
│ │      travel portal                 │ │
│ │ ⋯ Everything Else          1x      │ │
│ └────────────────────────────────────┘ │
│ Membership Rewards points              │  footer
│ CREDITS                                │
│ ┌────────────────────────────────────┐ │
│ │ ▭ Dining Credit   $10 of $10   ›   │ │  CreditRow (no card name)
│ │ ▭ Uber Cash        $4 of $10   ›   │ │
│ │ ▭ Resy Credit     $50 of $50   ›   │ │
│ │ ▭ Dunkin' Credit   $7 of $7    ›   │ │
│ │   ⧗ Enroll first                   │ │
│ └────────────────────────────────────┘ │
│ DETAILS                                │
│ ┌────────────────────────────────────┐ │
│ │ Annual fee                 $325    │ │
│ │ Card opened             March 2023 │ │
│ │ Network       American Express   › │ │
│ │ Nickname                    —      │ │
│ └────────────────────────────────────┘ │
│ Terms checked Oct 1, 2026. Rates and   │  footer, tertiary
│ credits can change; confirm with       │
│ American Express.                      │
│ ▸ ARCHIVED CREDITS (1)       (if any)  │
└────────────────────────────────────────┘
```

**Bonus Categories section** (only for cards with rotating or user-selectable rows; placed above Earn Rates):

```
│ BONUS CATEGORIES                       │
│ ┌────────────────────────────────────┐ │
│ │ Q4 2026 · 5%                       │ │
│ │ Online Shopping, Drugstores        │ │
│ │ ⓘ 5% up to $1,500 a quarter, then 1%│
│ │ Activated                  [ ○  ]  │ │
│ ├────────────────────────────────────┤ │
│ │ Q1 2027 · 5%                       │ │  only once the catalog publishes it
│ │ Gas Stations, Groceries            │ │
│ │ Activated                  [ ○  ]  │ │
│ └────────────────────────────────────┘ │
│ Activate each quarter on the Chase     │
│ site or app, then turn it on here.     │
```

For a user-selectable row: "Your 3% category: **Dining** ›" opens a `Picker` of `eligibleCategories`. With no choice yet it reads "Choose your 3% category ›".

**Content:**
- Earn rates are sorted by rate descending, with Everything Else always last. Each row: category symbol, full display name, `RateLabel(.row)`, caveats beneath. Portal-only and brand-only rows appear here as normal rows with their caveat: "5x · Only when booked through the Chase travel portal", "3x · Delta purchases only".
- The Earn Rates footer names the reward currency ("Ultimate Rewards points", "Cash back").
- The Details section also shows Last 4, the reward program and (for Robinhood) "Robinhood Gold membership · $5/mo".
- **Network** is editable right here: tapping the row opens a menu picker (Visa, Mastercard, American Express, Discover) and saves on selection. Some issuers (e.g. Capital One) issue the same card on different networks, so the catalog value is only a default. Changing the network is a personal setting and does not set `hasLocalEdits`.
- For custom cards the terms footer reads "Custom card. You entered these terms." For a retired catalog card: "No longer offered to new applicants. Your terms stay as they are."

**States:**

| State | Shown |
|---|---|
| Normal | As above |
| Terms updated | Banner section at top with **Review Changes** → WA-8 |
| Local edits on a catalog card | Terms footer adds: "You've edited this card's rates or credits." |
| Archived card | Banner "archivebox Archived. Not used in recommendations and no reminders." with an **Unarchive** button; credits show without progress bars |
| No credits | The Credits section shows a single row "No credits" (secondary) plus **Add Credit**, which opens WA-7 directly and marks the card `hasLocalEdits` if it's a catalog card |
| Catalog card missing from the current catalog (validation dropped it) | Footer: "Terms details unavailable on this app version." Everything else works from the user's stored copy |

**Interactions:**
- The **⋯** menu offers **Edit** (→ WA-5), **Archive** / **Unarchive**, and **Delete** (destructive → confirmation).
- Credit rows push CR-2.
- The Activated toggle writes `CategorySelection` for that quarter immediately.
- When reached from a BC-2 activation hint, scroll to Bonus Categories on appear and briefly highlight the current quarter's row (a 1 s background pulse; a fade under Reduce Motion).

**VoiceOver:**
- Tile: "American Express, Amex Gold, ending in 1005".
- Rate rows: "Dining and Restaurants, 4 times points. 4 times up to 50,000 dollars a year, then 1 times."
- Activation toggle: "Q4 2026, 5 percent on Online Shopping and Drugstores, activated, switch, off".

---

## WA-3 Add Card – Catalog Search (sheet)

**Purpose:** find a card in the catalog, or go to custom entry.

**Entry:** WA-1 **＋**; empty-state **Add Card** buttons; ON-1. Presented as a `.sheet` (`.large`) with its own `NavigationStack`.

```
┌────────────────────────────────────────┐
│ Cancel          Add Card               │
│ ┌────────────────────────────────────┐ │
│ │ 🔍 Search cards                    │ │  .searchable, always shown
│ └────────────────────────────────────┘ │
│ AMERICAN EXPRESS                       │
│ ┌────────────────────────────────────┐ │
│ │ ▭ Blue Cash Everyday     $0/yr   › │ │
│ │ ▭ Blue Cash Preferred    $95/yr  › │ │
│ │ ▭ Amex Gold             $325/yr  › │ │
│ │   In your wallet                   │ │
│ │ ▭ Amex Green            $150/yr  › │ │
│ │ ▭ Amex Platinum         $895/yr  › │ │
│ └────────────────────────────────────┘ │
│ CAPITAL ONE                            │
│ │ ...                                │ │
│ CHASE  ·  ROBINHOOD                    │
│ ┌────────────────────────────────────┐ │
│ │ ✎ Add a Custom Card              › │ │
│ └────────────────────────────────────┘ │
│ Don't see your card? Add it yourself.  │
│ Catalog updated Oct 26, 2026.          │  footer, tertiary
└────────────────────────────────────────┘
```

**Content:**
- All catalog cards grouped by issuer (alphabetical), cards alphabetical within each issuer. **Retired cards are included**, because people add cards they already hold. They sort after the issuer's current cards and show a secondary "No longer offered" label (`StatusBadge(.retired)`).
- Row: `CardTile(.small)` in the issuer's default color, card name, annual fee, and "In your wallet" (secondary) if the user already has it. Duplicates are allowed, e.g. two of the same card.
- Search matches issuer, card name and common words ("sapphire", "venture", "amex"). It is case- and diacritic-insensitive and filters as the user types.
- The **Add a Custom Card** row is always last, including under search results.

**States:**

| State | Shown |
|---|---|
| Browse | Grouped list as above |
| Searching, results | Flat list of matches + Add a Custom Card row |
| No results | `ContentUnavailableView.search(text:)`, then an **Add "Citi Double Cash" as a Custom Card** button that prefills the card name in WA-5 |
| Refreshing (pull to refresh) | System refresh spinner, then the footer updates to "Catalog updated just now." New cards appear in place |
| Offline / refresh failed | The footer reads "wifi.slash Offline. Showing cards saved on this iPhone (Oct 26, 2026)." There is no alert, and search keeps working from the cached or bundled catalog |

**Interactions:**
- Tapping a card pushes WA-4.
- **Add a Custom Card** pushes WA-5 in "new custom" mode.
- Pull to refresh triggers the catalog check.
- **Cancel** dismisses.

**VoiceOver:** rows read "Amex Gold, American Express, 325 dollars a year, in your wallet". Retired rows add "no longer offered". The footer is read as status text.

---

## WA-4 Add Card – Review & Add

**Purpose:** confirm the card and optionally personalize it. Adding takes one tap: tap a search result, then **Add to Wallet** (PRD: ≤3 taps after search).

**Entry:** WA-3 row. Pushed inside the Add Card sheet.

```
┌────────────────────────────────────────┐
│ ‹ Add Card         Amex Gold           │
│ ┌────────────────────────────────────┐ │
│ │ AMERICAN EXPRESS                   │ │  CardTile(.large), live preview
│ │ Amex Gold                          │ │
│ └────────────────────────────────────┘ │
│ $325/yr · Membership Rewards points    │
│                                        │
│ EARN RATES                             │
│ │ Dining 4x · Groceries 4x ·         │ │  compact summary, 2–3 lines
│ │ Flights 3x · Everything else 1x    │ │
│ CREDITS                                │
│ │ Dining Credit $10/mo · Uber Cash   │ │
│ │ $10/mo · Resy $50 every 6 months · │ │
│ │ Dunkin' $7/mo                      │ │
│ Terms checked Oct 1, 2026.             │
│                                        │
│ PERSONALIZE (OPTIONAL)                 │
│ ┌────────────────────────────────────┐ │
│ │ Nickname          e.g. Gold        │ │
│ │ Last 4 digits     1005             │ │
│ │ Network     American Express     › │ │
│ │ Card opened       Month, Year    › │ │
│ │ Color   ● ● ● ● ● ● ● ● ●          │ │
│ └────────────────────────────────────┘ │
│ The card open date resets anniversary  │  only if needed
│ credits and times the fee reminder.    │
├────────────────────────────────────────┤
│ ╭────────────────────────────────────╮ │  pinned bottom (safeAreaInset)
│ │          Add to Wallet             │ │  glassProminent
│ ╰────────────────────────────────────╯ │
└────────────────────────────────────────┘
```

**Content:**
- Summary sections are read-only text. Full detail is on WA-2 after adding.
- **Last 4:** number pad, 4 digits max, no AutoFill. Footer: "Optional. Only used to tell your cards apart."
- **Card opened:** a month + year wheel picker, showing years from 30 years ago to the current year. When the card has `cardmember_year` credits or an annual fee, a footer explains why it's useful. It is never required.
- **Color:** 9 swatches (44 pt hit targets), with the issuer default preselected.
- For a membership card, a line under the fee: "Requires Robinhood Gold membership ($5/mo)".
- For a retired card, a line under the fee: "No longer offered to new applicants. Add it if you already have it." Adding works the same as for any card.
- **Network** row in Personalize, prefilled from the catalog, menu picker of the four networks. Footer when the issuer is Capital One: "Check the logo on your card. This card may be Visa, Mastercard or Discover."

**States:**

| State | Shown |
|---|---|
| Default | As above |
| Last 4 has fewer than 4 digits | Footnote "Enter all 4 digits or leave it blank." (`Urgent`); **Add to Wallet** disabled |
| Saving | Button shows `ProgressView` (normally instant) |
| Save failed | Alert "Couldn't add this card. Please try again." |

**Interactions:**
- **Add to Wallet** copies the catalog data into the store (`catalogRevision` set) and plays `.success`. Then:
  - If this is the first card with credits and notification status is `.notDetermined`, it replaces the sheet content with ON-2.
  - Otherwise it dismisses the sheet.
  - The new card appears in WA-1 and the Best Card footer count updates.

**VoiceOver:** each swatch reads "Royal, selected". The Card opened row reads "Card opened, not set, optional".

---

## WA-5 Card Editor (new custom card / edit any card)

**Purpose:** create a custom card, or edit an existing card's details, rates and credits.

**Entry:**
- WA-3 **Add a Custom Card** (pushed, title "New Card").
- WA-2 **⋯ → Edit** (sheet, title "Edit Card").
- CR-1 / CR-2 "Add card open date" (sheet, scrolled and focused on Card opened).

```
┌────────────────────────────────────────┐
│ Cancel          New Card         Save  │
│ CARD                                   │
│ ┌────────────────────────────────────┐ │
│ │ Issuer           Citi              │ │
│ │ Card name        Double Cash       │ │
│ │ Network          Mastercard      › │ │
│ │ Annual fee       $0                │ │
│ └────────────────────────────────────┘ │
│ REWARDS                                │
│ ┌────────────────────────────────────┐ │
│ │ Type      [ Cash back | Points ]   │ │  segmented
│ │ Program   Citi ThankYou Points  ›   │ │  only when Points
│ └────────────────────────────────────┘ │
│ EARN RATES                             │
│ ┌────────────────────────────────────┐ │
│ │ Everything Else            2%    › │ │  always present, can't delete
│ │ ＋ Add Rate                         │ │
│ └────────────────────────────────────┘ │
│ CREDITS                                │
│ ┌────────────────────────────────────┐ │
│ │ ＋ Add Credit                       │ │
│ └────────────────────────────────────┘ │
│ PERSONALIZE                            │
│ ┌────────────────────────────────────┐ │
│ │ Nickname / Last 4 / Card opened /  │ │
│ │ Color  (same as WA-4)              │ │
│ └────────────────────────────────────┘ │
└────────────────────────────────────────┘
```

**Content:**
- A `Form`.
- Network picker: Visa, Mastercard, American Express, Discover.
- **Rewards:**
  - Type: Cash back sets the currency to `cash`.
  - Points shows the **Program** picker, listing the currencies from the catalog's `currencies` array plus **Other points or miles** (`custom`).
  - There is **no cents-per-point field**.
- **Earn rates:** Everything Else is always first and required (default empty; placeholder "1"). Other rows are listed by rate. Tapping a row pushes WA-6.
- **Credits:** each row pushes WA-7. Swipe to delete.
- **Edit mode on a catalog card:**
  - Card name, issuer, fee and rewards are read-only, with footer "From the catalog. Updated through 'Terms updated'."
  - **Network stays editable** (moved into the Personalize section for catalog cards). Editing it does not set `hasLocalEdits`.
  - Rates and credits are editable. The Earn Rates footer reads: "Changing rates or credits overrides American Express's terms for you only. A future catalog update will ask before replacing your changes."
  - Rotating and auto-top-category rows appear read-only ("Managed by the catalog").

**States:**

| State | Behavior |
|---|---|
| New, incomplete | **Save** disabled until Issuer, Card name and Everything Else rate are filled |
| Valid | **Save** enabled |
| Unsaved changes + Cancel | Confirmation dialog: **Discard Changes** (destructive) / **Keep Editing** |
| Unsaved changes + swipe down | Blocked (`.interactiveDismissDisabled`); shows the same dialog |
| Save failed | Alert "Couldn't save. Please try again." |

**Interactions:**
- **Save** (new) adds the card and follows the same post-add steps as WA-4, including ON-2.
- **Save** (edit) writes the changes. If rates or credits changed on a catalog card, it sets `hasLocalEdits = true`. Editing only personal fields does not set it.

**VoiceOver:** standard form labels. Each rate row reads "Everything Else, 2 percent cash back, edit".

---

## WA-6 Earn Rate Editor

**Purpose:** add or edit one category rate.

**Entry:** WA-5 Add Rate / rate row. Pushed.

```
┌────────────────────────────────────────┐
│ ‹ New Card        Earn Rate      Done  │
│ ┌────────────────────────────────────┐ │
│ │ Category        Dining & Rest… ›   │ │  hidden for Everything Else
│ │ Rate                    3   x      │ │  unit suffix from card type
│ └────────────────────────────────────┘ │
│ CONDITION                              │
│ ┌────────────────────────────────────┐ │
│ │ None                           ✓   │ │
│ │ Only via the issuer's travel portal│ │
│ │ Booked directly or via portal      │ │
│ │ U.S. purchases only                │ │
│ │ One brand only                     │ │
│ └────────────────────────────────────┘ │
│ Brand            e.g. Delta            │  only for "One brand only"
│ SPENDING CAP                           │
│ ┌────────────────────────────────────┐ │
│ │ Has a cap                  [ ●  ]  │ │
│ │ Up to                  $ 25,000    │ │
│ │ Per              Year            › │ │  Month / Quarter / Year
│ │ Then                   1   x       │ │
│ └────────────────────────────────────┘ │
│ "Only via portal" and "One brand only" │
│ rates aren't used to rank cards; they  │
│ show as hints instead.                 │
│                           Delete Rate  │  destructive, edit only
└────────────────────────────────────────┘
```

**Content:**
- The Category picker lists categories that don't already have a rate on this card.
- Rate: decimal pad, > 0, ≤ 100.
- Condition is a single choice. **Requires activation** is not offered for custom cards; rotating categories are catalog-only.

**States:** **Done** is disabled until category and rate are valid. With "One brand only", Brand is required. With a cap, Up to (> 0) and Then are required.

**VoiceOver:** "Rate, 3, times points". The cap section is grouped.

---

## WA-7 Credit Editor

**Purpose:** add or edit one recurring credit.

**Entry:** WA-5 Add Credit / credit row; WA-2 Add Credit. Pushed (or a sheet from WA-2).

```
┌────────────────────────────────────────┐
│ ‹ New Card         Credit        Done  │
│ ┌────────────────────────────────────┐ │
│ │ Name            Streaming Credit   │ │
│ │ Amount                 $ 15        │ │
│ │ Repeats         Monthly          › │ │
│ │ Every          4 years   [ − + ]   │ │  only for "Every few years"
│ │ Resets      [ Calendar | Anniversary ]│
│ └────────────────────────────────────┘ │
│ Calendar: resets on the 1st of each    │  dynamic footer explains choice
│ month.                                 │
│ ┌────────────────────────────────────┐ │
│ │ Requires enrollment        [ ○  ]  │ │
│ │ Notes            Optional          │ │
│ └────────────────────────────────────┘ │
│                         Delete Credit  │  destructive, edit only
└────────────────────────────────────────┘
```

**Content:**
- Repeats: Monthly, Quarterly, Every 6 months, Yearly, Every few years (→ the Every stepper, 2–10, default 4).
- When Anniversary is chosen and the card has no open date, a footer warns: "Add the card open date so this credit resets on time."

**States:** **Done** is disabled until Name and Amount (> 0) are set.
- Deleting a catalog credit asks for confirmation: "Delete Dining Credit? Its usage history is deleted too." Then **Delete** / **Cancel**.
- Deleting a user-added credit uses the same dialog.

**VoiceOver:** standard form labels. The Resets segmented control reads "Resets, Calendar, selected, 1 of 2".

---

## WA-8 Terms Update Review (sheet)

**Purpose:** show exactly what the catalog changed on a card and let the user apply it (PRD F1, CARD_CATALOG "Applying updates").

**Entry:** WA-2 banner **Review Changes**. Presented as a `.sheet` (`.large`) with its own `NavigationStack`.

```
┌────────────────────────────────────────┐
│ Not Now      Terms Updated             │
│ ┌──────┐ Amex Gold                     │
│ │ AX   │ American Express              │
│ └──────┘ Checked Oct 20, 2026          │
│                                        │
│ ⚠ You've edited this card. Applying    │  local-edits banner (Caution)
│   replaces your rate and credit edits. │  only when hasLocalEdits
│                                        │
│ FEES                                   │
│ │ Annual fee         ~~$250~~ → $325 │ │
│ EARN RATES                             │
│ │ Dining             4x  (no change) │ │  unchanged rows collapsed:
│ │ Groceries          4x              │ │  "2 rates unchanged ›"
│ │   cap ~~$25,000~~ → $50,000 a year │ │
│ │ ＋ Hotels           2x   New        │ │
│ │ − Streaming        ~~2x~~ Removed  │ │
│ CREDITS                                │
│ │ ＋ Dunkin' Credit  $7/mo     New    │ │
│ │ ~ Dining Credit  ~~$10~~ → $15 /mo │ │
│ │ − Hotel Credit   Removed           │ │
│ │   Archived. Its history is kept.   │ │
│ Credits you added yourself won't       │
│ change. Usage history is kept.         │
├────────────────────────────────────────┤
│ ╭────────────────────────────────────╮ │
│ │           Apply Update             │ │  glassProminent, pinned
│ ╰────────────────────────────────────╯ │
└────────────────────────────────────────┘
```

**Content:**
- A diff of the user's stored card against the catalog card at the new revision:
  - Fees: annual fee and membership.
  - Name and reward currency, if changed (network is the user's; see open question 7).
  - Earn rates: added, removed, or changed rate / cap / condition.
  - Credits, matched by `catalogCreditID`: added, removed (→ archived), or changed amount / period / reset basis / enrollment.
- Change markers are symbols plus words: `plus.circle` "New", `minus.circle` "Removed", `arrow.right` with the old value struck through. They are never color-only.
- Unchanged rows collapse into one "N rates unchanged" disclosure row.

**States:**

| State | Shown |
|---|---|
| Changes, no local edits | As above without the warning banner |
| Changes + `hasLocalEdits` | Warning banner; **Apply Update** first shows a confirmation dialog (see [FLOWS.md](FLOWS.md#f7-review-and-apply-terms-updated)) |
| Only unchanged fields differ (edge case) | Body "No changes that affect you." The button reads **Mark as Reviewed** and sets `catalogRevision` |
| Applying | Button shows `ProgressView`; the sheet can't be dismissed |
| Apply failed | Alert "Couldn't apply the update. Your card hasn't changed." |

**Interactions:**
- **Apply Update** applies the update (rules in CARD_CATALOG), plays `.success`, dismisses, and removes the WA-2 banner and the WA-1 badge. Reminders for archived credits are cancelled; new credits get reminders.
- **Not Now** dismisses. The badge stays.

**VoiceOver:** each diff row is one element: "Annual fee changed from 250 dollars to 325 dollars." / "New credit: Dunkin' Credit, 7 dollars monthly." / "Removed credit: Hotel Credit. It will be archived and its history kept."

---

## ST-1 Settings

**Purpose:** recommendation and reminder preferences, catalog status and privacy info. **There is no point-valuation setting.**

**Entry:** Settings tab root.

```
┌────────────────────────────────────────┐
│ Settings                               │
│ RECOMMENDATIONS                        │
│ ┌────────────────────────────────────┐ │
│ │ Include portal bookings    [ ○  ]  │ │
│ └────────────────────────────────────┘ │
│ Rank cards using rates that only apply │
│ when you book through a card's travel  │
│ portal. Cards are ranked by earn rate: │
│ 1x points counts the same as 1% cash   │
│ back.                                  │
│ REMINDERS                              │
│ ┌────────────────────────────────────┐ │
│ │ Notifications              On      │ │  or "Off · Turn On ›"
│ │ Credit reminders  7 and 1 days ›   │ │  → ST-2
│ │ Monthly summary            [ ●  ]  │ │
│ │ Annual fee reminders       [ ●  ]  │ │
│ └────────────────────────────────────┘ │
│ Annual fee reminders need the card's   │
│ open date.                             │
│ CARD CATALOG                           │
│ ┌────────────────────────────────────┐ │
│ │ Last updated        Oct 26, 2026   │ │
│ │ Check for Updates                  │ │
│ └────────────────────────────────────┘ │
│ PRIVACY                                │
│ Your cards stay on this iPhone. The    │
│ app never asks for full card numbers,  │
│ security codes or expiry dates, and    │
│ only goes online to download the card  │
│ catalog.                               │
│ Version 1.0 (1)                        │
└────────────────────────────────────────┘
```

**Content:**
- **Notifications row**, by authorization status:
  - Authorized: "On".
  - Not determined: "Off" with a **Turn On** button that runs the system prompt.
  - Denied: "Off in iOS Settings" with an **Open Settings** button (`UIApplication.openNotificationSettingsURLString`).
- **Monthly summary** and **Annual fee reminders** are disabled (but keep their values) when notifications are off.
- **Card Catalog:** the date of the catalog in use, cached or bundled.

**States:**

| State | Shown |
|---|---|
| Default | As above |
| Notifications denied | A banner section at the top: "bell.slash Notifications are off, so you won't get credit reminders." with **Open Settings** |
| Checking catalog | The Check for Updates row shows a trailing `ProgressView` and is disabled |
| Check result | The row's subtitle shows "Up to date", "Updated: 2 new cards" or "Couldn't check. You're offline." for 4 s, then reverts. No alerts |

**Interactions:**
- Toggles write `@AppStorage` immediately.
- Changing the portal toggle re-ranks BC-2 the next time it's shown.
- Changing reminder settings reschedules notifications.

**VoiceOver:** standard. The footer text is read after each section.

---

## ST-2 Reminder Timing

**Purpose:** pick when credit reminders fire. Used for the global default and for per-credit overrides.

**Entry:** ST-1 **Credit reminders** (global mode); CR-2 **When** (per-credit mode). Pushed.

```
┌────────────────────────────────────────┐
│ ‹ Settings      Credit Reminders       │
│ ┌────────────────────────────────────┐ │
│ │ Use default (7 and 1 days)     ✓   │ │  per-credit mode only
│ └────────────────────────────────────┘ │
│ REMIND ME                              │
│ ┌────────────────────────────────────┐ │
│ │ 30 days before                     │ │
│ │ 14 days before                     │ │
│ │ 7 days before                  ✓   │ │
│ │ 3 days before                      │ │
│ │ 1 day before                   ✓   │ │
│ │ On the last day                    │ │
│ └────────────────────────────────────┘ │
│ Reminders arrive at 9:00 AM.           │
└────────────────────────────────────────┘
```

**Content:** multi-select of offsets [30, 14, 7, 3, 1, 0] days. In per-credit mode, the **Use default** row clears `reminderOffsetsDays` (sets it to nil), and choosing any offset replaces the default.

**States:** at least one offset must stay selected. Deselecting the last one is blocked, with the footer "To stop reminders, turn off Remind me on the credit." (or "…turn off notifications" in global mode).

**VoiceOver:** each row is a button with the `.isSelected` trait.

---

## Resolved product questions (2026-10-26)

These were open when the screens were drafted. The product docs now settle them, and the screens above follow these answers.

1. **Rate unit:** each currency has a `rateUnit` (`percent` / `multiplier`), and a catalog card can override it. Chase Freedom Flex and Unlimited use `percent`. See [CARD_CATALOG.md](../CARD_CATALOG.md#file-format-catalogjson).
2. **Unit noun:** each currency has a `unitName` ("points", "miles", "cash back").
3. **Hints:** `Caveat.betterRateAvailable` carries `brand` and `quarter` ([RECOMMENDATION_ENGINE.md](../RECOMMENDATION_ENGINE.md)).
4. **Unchosen bonus category:** the engine emits `Caveat.chooseCategory(rate:)`, so BC-2 shows "Choose your 3% category" for that card.
5. **Reminder time:** 9:00 AM local time. The monthly summary goes out on the 1st, the annual-fee reminder 30 days before the anniversary, and an offset of 0 means the last day of the period ([PRD.md](../PRD.md) F3).
6. **Missing open date:** a cardmember-year credit on a card with no `openedOn` is untracked. It's left out of totals, has no reminders, and the UI prompts for the date ([DATA_MODEL.md](../DATA_MODEL.md)).
7. **Network:** Apply Update never changes `network`, so WA-8 doesn't list network changes.
8. **New keys:** `hasSeenWelcome`, `catalogLastCheckedAt` and `catalogLastResult` (`@AppStorage`), plus `UserCard.sortIndex` for manual wallet order.
9. **Card names:** catalog cards have a `shortName` ("Gold", "Sapphire Reserve") for compact display next to the issuer. `name` is the full marketing name.
