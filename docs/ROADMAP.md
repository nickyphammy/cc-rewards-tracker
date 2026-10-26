# Roadmap

Each milestone ends with something runnable on a device/simulator.

## M0 — Project setup
- [x] Create Xcode project (SwiftUI, SwiftData, iOS 26 deployment target, iPhone only, portrait), `.gitignore` for Xcode
- [x] Folder structure from [ARCHITECTURE.md](ARCHITECTURE.md)
- [x] Unit test target with Swift Testing; one passing test
- [x] Root `TabView` (Best Card + Wallet for now; Credits and Settings tabs are added with M3/M4), screenshotted on iPhone 17 Pro and iPhone 17 Pro Max simulators

## M1 — Wallet + catalog
- [x] `SpendCategory`, `RewardCurrency`, SwiftData models from [DATA_MODEL.md](DATA_MODEL.md)
- [x] `catalog/catalog.json` with the Tier 1 cards from [CARD_CATALOG.md](CARD_CATALOG.md) (Robinhood Gold, Amex, Chase, Capital One), terms checked against issuer sites
- [x] Catalog validation script (`catalog/validate.py`)
- [x] Swift decode tests; bundle `catalog/catalog.json` into the app
- [x] `CatalogStore` loading the bundled copy (remote fetch comes in M5)
- [x] Add cards from catalog (search, multi-select picker), remove (swipe or Edit mode) / archive, reorder, edit personal details (nickname, last 4, network, color, open date). Catalog rates and credits are read-only
- [ ] Add custom card (the user enters its rates and credits)
- [x] Card detail screen showing multipliers, bonus-category activation and credits

## M2 — Best card finder
- [x] `RecommendationEngine` + unit tests using the fixtures in [RECOMMENDATION_ENGINE.md](RECOMMENDATION_ENGINE.md)
- [x] Category grid → ranked result screen with caveats and runners-up
- [x] Optional amount input → "you'd earn ~$X"
- [ ] Settings: "Include portal bookings" toggle (engine + `@AppStorage` key done; needs the Settings screen)
- [x] Category comparison view (one category, all cards): the BC-2 result lists every card
- [x] Rotating categories with per-quarter activation (Chase Freedom / Freedom Flex)
- [ ] User-selectable category picker on Card Detail (engine support done; no catalog card uses it yet)

## M3 — Credits tracker
- [x] `CreditPeriodCalculator` (monthly / quarterly / semiannual / annual / multi-year; calendar vs. cardmember year) + tests with pinned dates, incl. month-end and leap-year edges
- [x] Credits dashboard: remaining this period, soonest expiring first, totals (Credits tab with badge; swipe to mark used)
- [x] Mark used / log partial use; history of past periods (CR-2 Credit Detail, CR-3 Log Usage; CR-2's Reminders section lands with M4)

## M4 — Reminders
- [ ] Notification permission flow (on first card with credits)
- [ ] `ReminderScheduler` honoring the 64-pending-notification limit; idempotent identifiers
- [ ] Default offsets (7 days, 1 day) + per-credit overrides
- [ ] Reschedule on launch / foreground / background refresh; cancel on "used"
- [ ] Optional monthly summary + annual-fee reminder

## M5 — Remote catalog updates
- [x] Catalog hosted on GitHub Pages; `catalog/validate.py` runs before every push
- [ ] CI: GitHub Action that runs `validate.py` on push (needs `gh auth refresh -s workflow` to push workflow files)
- [ ] `CatalogStore`: cached-vs-bundled load, 24h background check with ETag, pull-to-refresh in Add Card search, validate + atomic swap
- [ ] "Terms updated" badge, change summary, Apply update (keeps credit history via `catalogCreditID`)
- [ ] Auto-apply rotating quarter schedules
- [ ] Tests: newer/older/invalid/higher-schema catalogs, offline first launch
- [ ] Publish Tier 2 cards (co-branded, legacy) remotely, with no app release. Cards that need a new spending category (e.g. business cards' office-supply, shipping or advertising rates) need an app release that adds the category first; until then older builds skip just those cards

## M6 — Polish
- [ ] Empty states, onboarding ("add your first card")
- [ ] Accessibility pass (Dynamic Type, VoiceOver labels on rates and amounts)
- [ ] App icon, card colors

## Later
- iCloud sync (SwiftData + CloudKit)
- Widgets: "expiring credits", "best card for …"
- App Intents / Siri: "Which card for groceries?"
- Manual spend logging → cap tracking
- Merchant search → category mapping
