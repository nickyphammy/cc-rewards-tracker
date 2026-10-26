# Catalog research notes

These notes record what to re-check and which values were mapped imperfectly. Add a dated section each time terms are researched.

## 2026-10-26: first publish (`catalogVersion` 2026102601, 15 cards)

The terms were researched on this date from issuer pages first, with secondary sources (NerdWallet, The Points Guy, Doctor of Credit, Frequent Miler, One Mile at a Time, Upgraded Points) used where issuer pages couldn't be fetched. Each card's `sources` array lists its URLs.

### Values not confirmed on the issuer's own site
- **Amex Green:**
  - Every value comes from secondary sources, because the Amex product and terms pages for it weren't fetchable.
  - The CLEAR+ amount varies by source ($169–$219); the catalog uses $219.
- **Amex Gold:** the $325 fee comes from search-result text of the Amex terms page.
- **Amex Blue Cash Preferred:** the $95 fee comes from search-result text plus NerdWallet and Credit Karma.
- **Amex Platinum:**
  - The Uber One credit's enrollment requirement is unclear; Upgraded Points says enrollment is needed.
  - The Saks credit was retired July 1, 2026, so it isn't in the catalog.
- **Amex Blue Cash Everyday:** the $6,000 caps are treated as separate for each category.
- **Capital One Venture, VentureOne, Savor and Quicksilver:** the network is set to `discover`. That reflects reported migration news; Capital One's own pages don't state the network.
- **Capital One Venture X:** the $300 travel credit expiring on the account anniversary comes from search excerpts of Capital One's terms.
- **Capital One VentureOne and Quicksilver:** the 5% on Capital One Entertainment comes from Capital One articles, not the card pages.
- **Chase Freedom Flex, Q4 2026:**
  - Dining may effectively earn 7%: the 5% rotating rate stacked with the card's 3% dining rate. The catalog uses 5.
  - Chase's page gives no activation deadline; InsideFlyer says Dec 14, 2026.

### Bonuses left out
- **Chase Sapphire Reserve and Preferred:** Peloton equipment (10x / 5x).
- **Chase Sapphire Preferred:** 3x on online grocery (pickup and delivery only).
- **Chase Freedom Flex:** the American Red Cross rotating category in Q4 2026.
- **Amex Platinum:**
  - 2x on cruises through AmexTravel.
  - The SoulCycle bike credit, which is per purchase.
- **Amex:** Venue Collection concessions. This is an Amex Offer that ends 12/31/2026.
- **Capital One Venture X:** 5x on vacation rentals through Capital One Travel.
- **Capital One Quicksilver:** 3% on groceries and gas. It applies only to some existing cardholders migrated to Discover.
- **Robinhood:** extra points through Merchant Offers.

### Imperfect mappings
- **Chase Sapphire Preferred:**
  - Vacation homes are six `hotels` rows marked `brand_only` (Airbnb, Vrbo, Plum Guide, HomeAway, Homestay.com, Vacasa).
  - Streaming covers only Chase's list of 18 services.
  - The 2x travel rate also covers `transit`.
- **Amex Gold:**
  - The 2x AmexTravel rate (prepaid car rentals, Airbnb stays, cruises) is mapped to `travel_other` with `booked_via_portal`. That is broader than the actual bonus.
  - Its 5x hotel rate is for prepaid hotels only. So is Platinum's.
- **Amex Platinum:** the Airbnb Experiences credit unlocks only after a prepaid Airbnb Luxe booking.
- **Chase Sapphire Reserve:** the Shops at Chase ($250) and Southwest ($500) credits unlock only after $75k of spending in a calendar year. This is stated in their `notes`.
- **Global Entry / TSA PreCheck credits:** the real cycle is every 4 years from the last credit. The schema approximates it with `multi_year` + `periodYears: 4`.
- **Merchant exclusions can't be expressed** in the schema (e.g. Walmart and Target don't count as groceries), so they're left out.

### Changes found while researching
- **Robinhood Gold Card:** dropped its 5% travel-portal bonus on Sept 1, 2026, and now earns a flat 3%.
- **Amex Green:**
  - Closed to new applicants on July 23, 2026.
  - Renamed the Classic Green Card on Aug 20, 2026.
  - It is marked `retired`.
- **Chase Sapphire Preferred refresh (June 15, 2026):**
  - New 3x on gas, EV charging and vacation homes.
  - The hotel credit rose to $100.
  - New Global Entry credit.
- **Capital One SavorOne:** returned in Aug 2025 as a separate fair-credit card with a $39 fee. It's not in the catalog yet.
