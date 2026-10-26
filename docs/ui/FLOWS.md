# User Flows

Step-by-step journeys across screens. Screen IDs (BC-1, CR-2, …) refer to [SCREENS.md](SCREENS.md); components and copy rules are in [DESIGN_SYSTEM.md](DESIGN_SYSTEM.md). The example wallet and the date "today = Mon, Oct 27, 2026" are the same as in SCREENS.md.

Each flow lists its trigger, the steps (**bold** = user action), what the system does, and the edge cases.

---

## F1. First launch and onboarding

**Goal:** get from install to a useful Best Card screen with as little friction as possible. No account and no permission prompts up front.

1. The app launches on **Best Card → BC-1**. The wallet is empty, so BC-1 shows its empty state underneath.
2. `hasSeenWelcome == false` → present **ON-1 Welcome** as a sheet.
3. **Tap Add Your First Card.** Set `hasSeenWelcome = true`, dismiss ON-1 and present **WA-3 Add Card**.
4. Continue with [F2](#f2-add-a-card-from-the-catalog) or [F3](#f3-add-a-custom-card).
5. After the card is added (and ON-2 if shown), the sheet dismisses to **BC-1**, which now shows the grid and "Comparing 1 card".
6. The user can add more cards from **Wallet → ＋**. BC-1 has no add button, which keeps it clean.

**Alternate path:** **Tap Not Now** on ON-1 → BC-1 empty state ("Add a card to get started" / **Add Card**). The Credits and Wallet tabs show their own empty states, each with **Add Card**.

**Edge cases:**
- **No network on first launch:** nothing changes. Search runs on the bundled catalog, and WA-3's footer says "Offline. Showing cards saved on this iPhone."
- ON-1 is never shown again, even if every card is later deleted. The empty states take over.
- **Notification permission is not requested here.** It waits for the first card with credits (F2 step 6).

---

## F2. Add a card from the catalog

**Goal:** add a catalog card in ≤3 taps after search (PRD F1).

**Trigger:** WA-1 **＋**, any empty-state **Add Card** button, or ON-1.

1. **WA-3** opens with the search field visible and the catalog grouped by issuer.
2. **Type "gold"** → the list filters live to Amex Gold and Robinhood Gold Card.
3. **Tap Amex Gold** (tap 1) → push **WA-4 Review & Add**, which shows the tile preview in the default Royal color, rates and credits summaries, and "Terms checked Oct 1, 2026".
4. *Optional:* fill Nickname, Last 4 ("1005"), Card opened ("March 2023") and pick a color. None of these is required.
5. **Tap Add to Wallet** (tap 2). The app:
   1. Creates a `UserCard` and copies multipliers and credits from the catalog, with `catalogID` set, `catalogRevision` set to the catalog card's `revision`, and `hasLocalEdits = false`.
   2. Plays the `.success` haptic.
6. **Reminder permission:** if this card has ≥1 credit **and** notification status is `.notDetermined`, the sheet content is replaced by **ON-2 Reminder Primer** ("Amex Gold has $77 in credits…").
   - **Tap Turn On Reminders** → the iOS permission alert appears. Allow or Don't Allow → the sheet dismisses. If allowed, `ReminderScheduler` schedules this card's reminders.
   - **Tap Not Now** → the sheet dismisses. The user can turn reminders on later from ST-1.
7. Otherwise the sheet dismisses straight away.
8. **Result:**
   - WA-1 lists the card.
   - BC-1's footer reads "Comparing N cards".
   - CR-1 shows the new credits.
   - If authorized, reminders are scheduled.

**Edge cases:**
- **Retired card** (closed to new applicants): it still appears in search with "No longer offered" and adds the same way, since the user may already hold it.
- **Network differs from the catalog** (e.g. a Capital One card issued on Mastercard instead of Visa): the user changes **Network** on WA-4, or later on WA-2 Details. This is a personal setting, not a local edit of terms.
- **Already in wallet:** the row shows "In your wallet", but adding again is allowed (e.g. two Freedom Flex cards). The second card gets the issuer default color; the user can tell them apart with a nickname or last 4.
- **Cardmember-year credits and no open date:** adding still succeeds. Those credits show "Add card open date to track" on CR-1 and CR-2, with a path to WA-5 (see SCREENS open question 6).
- **Partial last 4** (1–3 digits): **Add to Wallet** is disabled with an inline message. Clearing the field re-enables it.
- **Catalog refreshes while WA-4 is open:** WA-4 keeps the card data it opened with. The newer revision shows up later as "Terms updated" (F7).
- **Save fails:** an alert appears. The user stays on WA-4 with their inputs intact.

---

## F3. Add a custom card

**Goal:** add a card that isn't in the catalog, with at least one rate and one credit (PRD F1).

**Trigger:** WA-3 **Add a Custom Card** row, or the no-results button **Add "Citi Double Cash" as a Custom Card**, which prefills Card name.

1. Push **WA-5** in "New Card" mode. **Save** is disabled.
2. **Fill Issuer "Citi", Card name "Double Cash"**, network Mastercard, annual fee $0.
3. **Rewards → Cash back** (the default). If the user picks **Points** instead, the Program picker appears; choose a program or **Other points or miles**. There is no valuation field.
4. **Tap Everything Else** → **WA-6** (category fixed) → **enter 2** → **Done**. **Save** is now enabled, because issuer, name and base rate are set.
5. *Optional rate:* **Add Rate** → WA-6 → **Category: Dining & Restaurants, Rate 3** → *(optional)* condition, cap → **Done**.
6. *Optional credit:* **Add Credit** → **WA-7** → **Name "Streaming Credit", Amount $15, Repeats Monthly, Resets Calendar** → **Done**.
7. *Optional:* Personalize (nickname, last 4, opened, color, defaulting to Graphite).
8. **Tap Save.** The app:
   1. Creates a `UserCard` with `catalogID = nil`.
   2. Plays the `.success` haptic.
   3. Runs the same post-add steps as F2 steps 6–8 (ON-2 if this is the first card with credits).

**Edge cases:**
- **Cancel with changes** → confirmation dialog: **Discard Changes** / **Keep Editing**. Swipe-to-dismiss is blocked while there are unsaved changes.
- **Duplicate category:** WA-6's category picker hides categories this card already has.
- **"One brand only" condition:** the Brand field is required before **Done**.
- **Custom card currency:** the choice only sets the display unit (`%` vs `x`) and the "points" / "miles" / "back" wording. Ranking compares raw rates, so a 2% card ties a 2x card.

---

## F4. Best-card lookup (at the register)

**Goal:** from launch to the answer in one tap.

**Trigger:** the user opens the app at checkout.

1. A cold launch, or a resume after ≥15 minutes in the background, opens **BC-1**. No network, prompt or animation blocks it.
2. **Tap Dining** (tap 1) → `.selection` haptic → push **BC-2 "Dining & Restaurants"**. The recommendation is computed synchronously before the push.
3. The hero shows **Amex Gold · 4x points**, with caveat "4x up to $50,000 a year, then 1x".
4. **Other Cards** lists the rest: a "Tied for 2nd · all earn 3" group with Freedom Flex 3%, Savor 3%, Sapphire Preferred 3x and Robinhood Gold Card 3%.
5. The footer reads: "Ranked by earn rate. 1x points counts the same as 1% cash back…"
6. *Optional:* **Tap Amount, type 85.40** → every row gains an estimate ("earns ~342 points", "~$2.56 back", "~256 points"). **Tap Done** on the keyboard toolbar.
7. *Optional:* **tap a card** → **WA-2 Card Detail** (inside the Best Card stack) for its full rates and credits.
8. **Back** → BC-1. The amount is cleared.

### Variant A: tie for best (Flights)

- The hero shows "TIE · EITHER CARD EARNS 3", with Amex Gold 3x points (caveat: "Only when booked directly or through the American Express travel portal") and Robinhood Gold Card 3% cash back (its flat rate on everything).
- The engine's order is kept (category-specific rate first), but both cards are presented as equals.

### Variant B: activation hint

On **Online Shopping** in Q4 2026, with Freedom Flex's Q4 categories not activated:
1. Freedom Flex ranks at its base rate (1%) and shows the tappable hint "5% this quarter if you activate it ›".
2. **Tap the hint** → [F8](#f8-activate-a-rotating-bonus-quarter).
3. On returning, BC-2 recomputes. Freedom Flex moves to the top at 5%, with caveats "Q4 2026 bonus category, activated" and "5% up to $1,500 a quarter, then 1%". The reorder animates.

### Variant C: portal rates

- With **Include portal bookings** on (ST-1), portal-only rates count in the ranking. On Flights, Sapphire Preferred shows "5x · Only when booked through the Chase travel portal" and ranks first, ahead of the Amex Gold / Robinhood Gold Card tie at 3.
- BC-1's footer reads "Portal booking rates included."

**Edge cases:**
- **One card:** the hero only, plus "Add more cards to compare." No ranking footer.
- **No cards / all archived:** BC-1 shows its empty state, so BC-2 is never reached.
- **Everything else (`other`):** works like any category and compares base rates.
- **Card archived from WA-2 while BC-2 is in the stack:** BC-2 recomputes on appear. If no cards remain, pop to BC-1.

---

## F5. Mark a credit used

**Goal:** record that a credit was used (fully or partly) so its total and reminders stay accurate (PRD F2, F3).

### Full use from the dashboard (fastest)

1. **Credits tab → CR-1.**
2. **Swipe right on "Dining Credit · Amex Gold" → Mark Used** (a full swipe also works).
3. The app logs `CreditUsage(amountUsed: $10, periodStart: Oct 1, loggedAt: now)`, plays `.success`, and moves the row to **Used this period**. The header total drops by $10 and "ends this month" drops by $10.
4. Pending reminders for this credit's current period are cancelled. The Credits tab badge updates.

### Full use from the detail screen

1. **Tap the row → CR-2.**
2. **Tap Mark as Used.** The remaining amount animates to "✓ Used", the urgency line becomes "Available again Nov 1", and the same data and reminder effects as above apply.

### Partial use

1. **CR-2 → Log Partial Amount** (or swipe left on CR-1 → **Log Amount**) → **CR-3 sheet**.
2. **Type 6**, optionally change the date (within the current period) or add a note → **Save**.
3. The remaining amount becomes $4 and the progress bar fills to 60%. Reminders stay scheduled, since the credit isn't fully used. If this entry brings the remaining amount to $0, the effects are the same as full use.

### Undo or fix a mistake

1. **CR-2 → History → swipe left on the entry → Delete.**
2. The amount returns to remaining. If the credit was fully used, its reminders are rescheduled for any offsets still in the future.

**Edge cases:**
- **Amount > remaining** in CR-3: an inline error appears and **Save** is disabled.
- **Credit needs enrollment and isn't enrolled:** logging is still allowed. The banner reminds the user to enroll; the app doesn't block it.
- **Archived credit or archived card:** CR-2 hides the use buttons. CR-1 never lists them.
- **Notifications not authorized:** everything works the same; there's nothing to cancel.

---

## F6. Reminder notification opens the credit

**Goal:** a reminder takes the user straight to the right credit, ready to mark it used.

**Notification content** (built by `ReminderScheduler`):

| Kind | Title | Body | Payload (`userInfo`) |
|---|---|---|---|
| Credit reminder (offset 1) | "Dining Credit ends tomorrow" | "Amex Gold · $10 left. Use it by Oct 31." | `kind: "credit"`, `creditID`, `periodStart` |
| Credit reminder (offset 7) | "Dining Credit ends in 7 days" | "Amex Gold · $10 left. Use it by Oct 31." | same |
| Monthly summary | "Credits ending this month" | "You have $21 in credits ending by Oct 31." | `kind: "summary"` |
| Annual fee | "Amex Gold annual fee coming up" | "Your $325 fee is due around Mar 1." | `kind: "annualFee"`, `cardID` |

Notifications are grouped by card (`threadIdentifier = cardID`). The amounts in the body are the remaining amounts at scheduling time.

### Flow (credit reminder)

1. **Tap the notification** (Lock Screen, banner or Notification Center).
2. The app launches or foregrounds and dismisses any open sheet. If that sheet has unsaved edits, the app keeps it open and shows the credit after the user finishes or cancels.
3. Switch to the **Credits** tab, reset its stack to CR-1, and push **CR-2** for `creditID`.
4. CR-2 shows the **live** state, which may differ from the notification text, e.g. "$4 left" after a partial use logged on the same day.
5. **Tap Mark as Used** → continue as in [F5](#f5-mark-a-credit-used).

### Routing for the other kinds

- **Monthly summary:** Credits tab → CR-1 at the top.
- **Annual fee:** Wallet tab → reset the stack → push **WA-2** for `cardID`.

**Edge cases:**
- **The credit's period has rolled over** since the notification was delivered (a late tap): show CR-2 for the *current* period. No error.
- **The credit or card was deleted:** open CR-1 (or WA-1 for annual fee) with no push. No error alert.
- **The credit or card is archived:** open CR-2 or WA-2 with the archived banner.
- **Already fully used:** CR-2 shows "✓ Used · Available again Nov 1". This shouldn't happen, because marking used cancels reminders, but it's handled.

---

## F7. Review and apply "Terms updated"

**Goal:** the user sees exactly what changed and decides. Nothing changes silently (PRD F1, CARD_CATALOG "Applying updates").

**Trigger:** `CatalogStore` swaps in a catalog in which Amex Gold's `revision` is higher than the card's `catalogRevision`.

1. The **WA-1** row shows the "⟳ Terms updated" badge. There is no push notification and no alert.
2. **Tap the card → WA-2.** A banner at the top reads: "American Express changed this card's terms. **Review Changes ›**"
3. **Tap Review Changes → WA-8 sheet.** It shows the diff: annual fee $250 → $325, groceries cap $25,000 → $50,000, new Hotels 2x, Streaming removed, new Dunkin' Credit, Dining Credit $10 → $15, Hotel Credit removed (→ archived, history kept).
4. **Tap Apply Update.**
   - **No local edits:** apply immediately.
   - **`hasLocalEdits == true`:** show a confirmation dialog first:
     - Title "Replace your edits?"
     - Message "You changed this card's rates or credits. Applying uses American Express's current terms instead. Credits you added yourself stay."
     - Buttons **Apply and Replace Edits** (destructive) / **Cancel**.
5. **Apply** (the rules in [CARD_CATALOG.md](../CARD_CATALOG.md#applying-updates-to-a-users-cards)):
   - Update the card's fields and replace its multipliers. The user's network choice is kept (see SCREENS open question 7).
   - Update matched credits by `catalogCreditID`, keeping usage history and the user's enrollment and reminder settings.
   - Archive removed credits (cancelling their reminders) and add new credits (scheduling their reminders).
   - Set `catalogRevision` to the new revision and `hasLocalEdits = false`.
6. `.success` haptic, then the sheet dismisses. On WA-2 the banner is gone, the rates and credits reflect the new terms, and **Archived Credits (1)** now lists Hotel Credit. The WA-1 badge clears.
7. Best Card results use the new rates from the next lookup.

**Alternate path:** **Not Now** dismisses and the badge stays. There is no nagging: the badge is the only reminder.

**Edge cases:**
- **Another update arrives before the user applies:** WA-8 always diffs the stored card against the *latest* revision. There is one badge, never a queue.
- **Rotating quarter schedule changed only:** this is applied automatically with no badge (CARD_CATALOG exception). New quarters appear in WA-2 Bonus Categories with Activated off.
- **Card retired in the catalog:** no badge; retiring isn't a terms change. WA-2's footer notes "No longer offered to new applicants." The card stays in Add Card search with a "No longer offered" label.
- **Apply fails:** an alert says "Couldn't apply the update. Your card hasn't changed." and the store is not partly written (one transaction).
- **Archived card with an update:** the badge still shows in the Archived section. Applying works the same.

---

## F8. Activate a rotating bonus quarter

**Goal:** record that the user activated this quarter's 5% categories at the issuer, so the card ranks correctly.

**Trigger:** the BC-2 hint "5% this quarter if you activate it ›", the WA-1 badge "Activate Q4 categories", or opening WA-2 directly.

1. Push **WA-2 Freedom Flex**. If opened from the hint, it scrolls to **Bonus Categories** and pulses the Q4 2026 row.
2. The section footer reads "Activate each quarter on the Chase site or app, then turn it on here." The app doesn't link out to issuer sites.
3. **Turn on Activated** for Q4 2026. The app saves `CategorySelection(quarter: "2026Q4", activated: true)` for each of the quarter's categories.
4. The WA-1 badge clears.
5. **Back** → BC-2 recomputes (see F4 Variant B).

**User-selectable variant:** WA-2 → **Choose your 3% category ›** → pick from `eligibleCategories` → saved immediately. The WA-1 badge "Choose your bonus category" clears.

**Edge cases:**
- **Next quarter is published before it starts:** its row shows with Activated off and no badge until that quarter begins.
- **Past quarters** stay listed collapsed under "Earlier quarters" for reference. Their toggles are read-only.

---

## F9. Archive or delete a card

**Goal:** stop using a card in recommendations and reminders, keeping its history (archive) or removing everything (delete) (PRD F1).

### Archive

1. **WA-1 → swipe left on Savor → Archive** (or **WA-2 → ⋯ → Archive**). There's no confirmation, because it's reversible.
2. Set `isArchived = true`. All of its pending reminders are cancelled. The card moves to WA-1 **Archived** and drops out of Best Card results and CR-1 totals.
3. **Undo:** **swipe on the archived row → Unarchive** (or the WA-2 banner **Unarchive**). Reminders are rescheduled.

### Delete

1. **WA-1 → swipe left → Delete** (or **WA-2 → ⋯ → Delete**). `.warning` haptic, then a confirmation dialog:
   - Title "Delete Savor?"
   - Message "Its credits, usage history and reminders will be deleted. To keep the history, archive it instead."
   - Buttons **Delete Card** (destructive) / **Archive Instead** / **Cancel**.
2. **Delete Card** → the card is deleted with cascading multipliers, credits and usage, and its reminders are cancelled. If WA-2 was open, pop to WA-1.

**Edge cases:**
- **Last non-archived card archived or deleted:** BC-1 and CR-1 show their empty states. A BC-2 already in the stack pops to BC-1.
- **Card deleted while a notification for it is pending:** reminders were cancelled, so this can't happen. A stale tap is handled in F6.

---

## F10. Credit period rollover (system)

**Goal:** credits reset automatically, and the UI is never stale (PRD F2 acceptance).

1. On launch, on foreground, and on the calendar day change (`.NSCalendarDayChanged`) while running, every view that shows periods recomputes from `CreditPeriodCalculator` with the current date.
2. **Example:** Dining Credit was marked used Oct 14. On **Nov 1** CR-1 shows it under **Ends this month** with "$10 left · Ends in 29 days". October's period moves into CR-2 History ("October 2026 · $10 used ✓").
3. A cardmember-year credit (Sapphire Preferred Hotel Credit, card opened March) resets on **Mar 1**, not Jan 1.
4. `ReminderScheduler` tops up reminders for the new period (on launch, foreground or background refresh). The UI does nothing extra.

**Edge cases:**
- **App not opened for months:** on the next launch everything reflects the current periods. Missed periods show in History as "$0 used". No catch-up alerts.
- **Time-zone change:** periods follow the device's current `Calendar` and time zone, matching the services.
