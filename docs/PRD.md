# Product Requirements

## Problem

People with several rewards credit cards leave value on the table in two ways:

1. **Unused credits.** Many cards come with recurring statement credits (monthly dining or rideshare credits, semiannual hotel credits, annual airline/travel credits). They are use-it-or-lose-it, reset on different schedules, and are easy to forget.
2. **Wrong card at checkout.** Each card earns different multipliers per spending category. At the register, most people don't remember which card earns the most for groceries vs. gas vs. dining, so they default to one card and earn less than they could.

## Goal

A personal iOS app that (a) tracks the user's cards and their recurring credits, (b) reminds them to use credits before they expire, and (c) tells them which card to use for a given type of purchase.

## Target user

A single person managing their own cards (2–10 cards is the typical case). No household/shared accounts in v1.

## Supported devices

iPhone 17 Pro and iPhone 17 Pro Max on iOS 26 or later (iOS 27 is current). iPhone only, portrait only. See [ARCHITECTURE.md](ARCHITECTURE.md#target-devices).

## Features

### F1. Card wallet

- Add a card by searching the **card catalog**. The card's issuer, name, network, annual fee, multipliers and credits are pre-filled.
- The catalog **updates over the internet**, and a copy ships with the app for offline use. For now it covers the **Robinhood Gold Card and cards from Amex, Chase and Capital One** ([CARD_CATALOG.md](CARD_CATALOG.md)).
- When the catalog changes a card the user already has, the card shows **"Terms updated"**. The user reviews the changes and applies them; nothing changes silently.
- Add a **custom card** manually when it isn't in the catalog.
- Per-card user settings: nickname, last 4 digits (optional, display only), card open date / anniversary month (needed for cardmember-year credits), color/art.
- Edit, archive (hide but keep history), or delete a card. Editing a catalog card's multipliers or credits overrides the catalog values for that user only.

**Acceptance**
- User can add a catalog card in ≤ 3 taps after search.
- User can add a fully custom card with at least one multiplier and one credit.
- Archiving or deleting a card removes its reminders; archived cards are excluded from recommendations.
- A card added to the hosted catalog appears in search after the next catalog check, with no app update.
- Applying a "Terms updated" change keeps the card's credit usage history.
- With no network on first launch, search still works from the bundled catalog.

### F2. Credits & benefits tracker

- For each card, list its recurring credits: name, amount, period (monthly / quarterly / semiannual / annual / multi-year, e.g. a Global Entry credit every 4 years), reset basis (calendar vs. cardmember year), and remaining amount for the current period.
- User marks a credit as **used** (fully) or logs a **partial** amount.
- A **dashboard** across all cards shows credits expiring soonest first, with total value still available this period.
- Credits automatically reset at the start of each new period; history of past periods is kept.
- A credit that was removed from the catalog in an applied update is archived. It drops off the dashboard and its reminders are cancelled, but its history stays visible on the card.

**Acceptance**
- A monthly credit marked used in October shows as available again on Nov 1.
- A cardmember-year credit resets on the card's anniversary month, not Jan 1.
- Dashboard shows the total still available across every credit's current period, and separately "$X expiring this month" (credits whose current period ends this calendar month).

### F3. Reminders

- Local notifications for credits not yet fully used, sent N days before the period ends (default: 7 days and 1 day before; configurable globally and per credit).
- Optional monthly summary notification ("You have $45 in credits expiring this month").
- No reminder once a credit is marked fully used for the period, or for archived credits and cards.
- Annual-fee reminder before the card's anniversary (optional).

**Acceptance**
- Marking a credit used cancels its pending reminders for that period.
- Reminders survive app restart and reschedule correctly after the period rolls over.

### F4. Category multipliers

- Each card shows its earn rates by category (e.g. Dining 4x, Groceries 4x, Flights 3x, Other 1x).
- Show caps and conditions where they exist (e.g. "4x on groceries up to $25k/yr, then 1x", "5% rotating category — requires activation", "3x travel only when booked through issuer portal").
- A **category view** that flips the table: pick a category, see every card's rate for it.

**Acceptance**
- Every card has a base ("everything else") rate.
- Conditional multipliers are visibly marked with their condition.

### F5. "Which card should I use?" (best card finder)

- User picks a **purchase category** from the list in [DATA_MODEL.md](DATA_MODEL.md#spending-categories) (Dining & Restaurants, Groceries, Gas Stations, Travel – Flights, …, Everything Else).
- Optionally enters an amount.
- App returns the **best card in the user's wallet** for that category, showing its multiplier (e.g. "Card A — 4x"), followed by ranked runners-up.
- Cards are compared by **raw multiplier only**: 4x points beats 3% cash back. Points aren't converted to a dollar value.
- Explains caveats on the result (e.g. "5x if booked via the issuer's portal", "rotating category not activated", "4x up to $25k/yr, then 1x").
- Logic is defined in [RECOMMENDATION_ENGINE.md](RECOMMENDATION_ENGINE.md).

**Acceptance**
- With two cards (Card A: 4x dining in points valued at 1.0¢; Card B: 2% cash back on everything), choosing Dining returns Card A first (4.0% vs 2.0%).
- Points and cash-back cards are compared by multiplier as plain numbers (4x > 3%).
- Ties are broken deterministically and the tie is shown to the user.

## Non-goals (v1)

- Linking bank accounts or reading real transactions (no Plaid / account aggregation).
- Tracking actual spend toward caps automatically (manual spend logging may come later).
- Merchant-level lookup ("I'm at Costco") — v1 is category-based. See roadmap.
- Multi-user / household sharing, Android, web.
- Storing full card numbers. **The app never stores full card numbers, CVV, or expiration dates.**

## Open questions

- iCloud sync across the user's devices in v1, or local-only?
- Home-screen / lock-screen widget for "best card" and "expiring credits" — v1 or later?

## Decided

- **Devices:** iPhone 17 Pro and Pro Max, minimum iOS 26 (2026-10-26).
- **Catalog:** updates over the internet, with a bundled fallback. It covers only Robinhood Gold, Amex, Chase and Capital One cards for now, which makes it US-only (2026-10-26).
- **Ranking:** by raw multiplier only, with no point valuations (2026-10-26).
- **Catalog host:** GitHub Pages from this repo (public), at https://nickyphammy.github.io/cc-rewards-tracker/catalog/catalog.json (2026-10-26).
