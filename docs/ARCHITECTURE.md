# Architecture

> Proposed defaults — revisit before the first code lands. Decisions still open are listed at the end.

## Stack

| Concern | Choice | Why |
|---|---|---|
| Language | Swift 6 (Xcode 27) | Current Swift, strict concurrency |
| UI | SwiftUI | Native, declarative, fits list/detail-heavy app; standard components pick up the iOS 26 design automatically |
| Devices | **iPhone 17 Pro and iPhone 17 Pro Max**, iPhone only (`TARGETED_DEVICE_FAMILY = 1`, no iPad) | Product target |
| Min iOS | iOS 26 (deployment target); iOS 27 is current | iOS 26 is the 17 Pro / Pro Max launch OS, so owners who haven't updated can still install. Day-to-day testing is on iOS 27 |
| Persistence | SwiftData | Local, first-party, can add CloudKit sync later |
| Notifications | `UserNotifications` (local only) | No server needed for reminders |
| Card catalog | Remote `catalog.json` on GitHub Pages (https://nickyphammy.github.io/cc-rewards-tracker/catalog/catalog.json) + bundled fallback copy | New cards and terms without an app release; see [CARD_CATALOG.md](CARD_CATALOG.md) |
| Tests | Swift Testing (`@Test`) for logic, XCTest UI tests for key flows | |
| Dependencies | None to start | Keep the app first-party only until there's a clear need |

## Target devices

Design and test on these two devices only:

| Device | Screen | Points (portrait) | Simulator name |
|---|---|---|---|
| iPhone 17 Pro | 6.3" | 402 × 874 | `iPhone 17 Pro` |
| iPhone 17 Pro Max | 6.9" | 440 × 956 | `iPhone 17 Pro Max` |

- Portrait only in v1.
- Respect the Dynamic Island and home-indicator safe areas. Don't hard-code layouts to these sizes: use standard SwiftUI layout, which also keeps Dynamic Type working.
- The App Store can't restrict an app to specific iPhone models, so any iPhone that runs iOS 26 or later can install it (including the iPhone 18 line). Other models aren't tested.
- UI is checked by screenshotting both simulators on the latest iOS runtime (iOS 27).
- The iOS 26 minimum is only exercised when the iOS 26 simulator runtime is installed (Xcode → Settings → Components). Run the test suite on it before each release.

## App structure

```
CCRewardsTracker/
├── App/                    # App entry point, root TabView, dependency setup
├── Models/                 # SwiftData @Model types (see DATA_MODEL.md)
├── Catalog/                # CatalogStore (load cached/bundled, fetch, validate, swap). The bundled catalog.json is
│                           #   the repo's catalog/catalog.json, referenced by the app target. No copy is kept here
├── Features/
│   ├── Wallet/             # Card list, add/edit card, card detail
│   ├── Credits/            # Credits dashboard, mark used, history
│   ├── Multipliers/        # Per-card rates and per-category comparison
│   ├── BestCard/           # Category picker + ranked recommendation
│   └── Settings/           # Reminder defaults, portal toggle
├── Services/
│   ├── RecommendationEngine.swift   # Pure logic, no UI, fully unit tested
│   ├── CreditPeriodCalculator.swift # Period start/end + reset rules
│   └── ReminderScheduler.swift      # Builds and (re)schedules local notifications
└── Resources/
```

## Main screens (tab bar)

1. **Best Card** — category grid → ranked result. This is the "at the register" screen, so it's the first tab and must be fast.
2. **Credits** — dashboard of credits remaining this period, soonest-expiring first.
3. **Wallet** — the user's cards; tap for detail (multipliers + credits).
4. **Settings** — reminder timing, "include portal bookings" toggle, notification permission.

## Key design rules

- **Logic lives in services, not views.** `RecommendationEngine` and `CreditPeriodCalculator` are plain Swift types with no SwiftUI or SwiftData imports so they can be unit tested with fixed dates and fixtures.
- **Catalog vs. user data.** Catalog entries are read-only templates. When a user adds a card, its multipliers and credits are copied into the user's SwiftData store so later catalog changes never silently change a user's saved data.
- **Dates.** All period math uses the user's current `Calendar` and time zone. Inject "now" (a clock) into services so tests can pin the date.
- **Money.** Store amounts as `Decimal` (or integer cents), never `Double`.

## Notifications

- Request permission the first time the user adds a card with credits, not on first launch.
- iOS keeps at most **64 pending local notifications** per app. `ReminderScheduler` must only schedule the nearest upcoming reminders (e.g. the next ~60, soonest first) and top up on app launch / when returning to foreground / via a background app refresh task.
- The same background refresh task also runs the catalog update check (`CatalogStore`).
- Rescheduling is idempotent: notification identifiers are derived from `creditID + periodStart + offset`, so re-running the scheduler replaces rather than duplicates.

## Privacy & security

- No full card numbers, CVV, or expiry dates are ever stored. Optional last-4 only.
- The only network call is a plain HTTPS GET of the catalog. It sends no user data. No analytics SDKs.
- Data stays on device (SwiftData store in the app container).

## Open decisions

- iCloud sync (SwiftData + CloudKit) in v1 or later.
- Widgets (WidgetKit) and App Intents / Siri Shortcut: "Which card for groceries?"
