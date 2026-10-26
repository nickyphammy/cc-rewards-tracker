# CLAUDE.md

iPhone app (iPhone 17 Pro / Pro Max, iOS 26+) that tracks a user's credit cards, reminds them to use recurring credits, and recommends the best card for a purchase category. See [README.md](README.md) for the overview.

## Source of truth

- Requirements: [docs/PRD.md](docs/PRD.md)
- Stack & structure: [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)
- Models: [docs/DATA_MODEL.md](docs/DATA_MODEL.md)
- Card catalog (coverage, `catalog.json` format, remote updates): [docs/CARD_CATALOG.md](docs/CARD_CATALOG.md)
- Best-card logic & test fixtures: [docs/RECOMMENDATION_ENGINE.md](docs/RECOMMENDATION_ENGINE.md)
- Build order: [docs/ROADMAP.md](docs/ROADMAP.md) — check off items as they land
- UI design: [docs/ui/](docs/ui/) (design system, screens, flows). Owned by the `ui-designer` agent (`.claude/agents/ui-designer.md`); use it for UI design and SwiftUI view work

If code and docs disagree, flag it and update whichever is wrong in the same change.

## Stack

Swift 6 / Xcode 27, SwiftUI, SwiftData, iOS 26 deployment target (iOS 27 is current), iPhone only (17 Pro / 17 Pro Max), `UserNotifications` (local only). The only network call is the catalog GET. No third-party dependencies without asking first.

## Conventions

- Business logic (`RecommendationEngine`, `CreditPeriodCalculator`, `ReminderScheduler` planning) lives in `Services/` as plain Swift with no SwiftUI/SwiftData imports, and takes "now" as a parameter.
- Money is `Decimal`, never `Double`.
- Catalog cards are templates; adding a card copies its data into the user's store.
- Never store full card numbers, CVV, or expiry dates.
- Catalog cards are limited to Robinhood Gold, Amex, Chase and Capital One for now; anything else is a custom card.
- Card terms in `catalog/catalog.json` must carry `lastVerified` (checked against the issuer's site); don't present them as guaranteed-current. Never reuse or rename a catalog credit `id`; bump the file's `catalogVersion` on every publish, and the card's `revision` on every change to its terms. Changes to rotating-quarter schedules alone do **not** bump `revision`; see docs/CARD_CATALOG.md. Never delete a catalog card; mark it `retired`.

## Verifying work

- Catalog changes: `python3 catalog/validate.py` must pass before any push to `main`, because pushing `main` publishes the catalog via GitHub Pages (https://nickyphammy.github.io/cc-rewards-tracker/catalog/catalog.json). Add `--previous <last published file>` to check that no card was removed.

- Logic changes: run the unit tests (`xcodebuild test -scheme CCRewardsTracker -destination 'platform=iOS Simulator,name=iPhone 17 Pro'` — adjust the scheme name once the project exists).
- UI changes: build and run on both the `iPhone 17 Pro` and `iPhone 17 Pro Max` simulators and screenshot the affected screen on each.
- Day-to-day runs use the latest installed runtime (iOS 27). The iOS 26 minimum is only tested if the iOS 26 simulator runtime is installed; say so when it wasn't.
