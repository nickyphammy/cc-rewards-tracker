# CC Rewards Tracker

An iPhone app (iPhone 17 Pro / Pro Max, iOS 26+) that keeps track of a user's credit cards and helps them get the most out of them.

## What it does

1. **Card wallet** — the user adds the credit cards they own (picked from a card catalog that updates over the internet, or entered manually). The catalog starts with the Robinhood Gold Card and Amex, Chase and Capital One cards.
2. **Credits & benefits tracker** — shows recurring credits on each card (monthly, quarterly, semiannual, annual — e.g. a monthly dining credit or an annual travel credit), how much is left, and when each one resets.
3. **Reminders** — local notifications nudge the user to use a credit before it expires.
4. **Category multipliers** — shows each card's earn rates by spending category (e.g. 4x dining, 3x travel, 1x everything else).
5. **"Which card should I use?"** — the user picks what they're paying for (dining, groceries, gas, travel, …) and the app returns the card in their wallet that maximizes their return, plus the runners-up.

## Docs

| File | Purpose |
|---|---|
| [docs/PRD.md](docs/PRD.md) | Product requirements: features, user stories, acceptance criteria, scope |
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | Tech stack, app structure, persistence, notifications |
| [docs/DATA_MODEL.md](docs/DATA_MODEL.md) | Categories, reward currencies, and the user's saved cards, credits and settings |
| [docs/CARD_CATALOG.md](docs/CARD_CATALOG.md) | Which cards are covered, `catalog.json` format, and how remote updates work |
| [docs/RECOMMENDATION_ENGINE.md](docs/RECOMMENDATION_ENGINE.md) | How the "best card" for a purchase is calculated |
| [docs/ROADMAP.md](docs/ROADMAP.md) | Milestones and the order features get built |
| [CLAUDE.md](CLAUDE.md) | Working notes for Claude Code in this repo |

## Status

Planning. No code yet — see [docs/ROADMAP.md](docs/ROADMAP.md) for the first milestone.
