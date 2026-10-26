import Testing
@testable import CCRewardsTracker

@MainActor
struct CatalogSearchTests {
    let cards = try! CatalogStore.bundled().cards

    private func ids(_ query: String) -> Set<String> {
        Set(CatalogSearch.filter(cards, query: query).map(\.id))
    }

    @Test func emptyQueryReturnsEverything() {
        #expect(CatalogSearch.filter(cards, query: "  ").count == cards.count)
    }

    @Test func matchesNameCaseInsensitively() {
        #expect(ids("SAPPHIRE") == ["chase_sapphire_reserve", "chase_sapphire_preferred"])
    }

    @Test func matchesIssuerAliases() {
        #expect(ids("amex").count == 5)
        #expect(ids("amex gold") == ["amex_gold"])
        #expect(ids("capone venture") == ["capone_venture", "capone_venture_x", "capone_ventureone"])
    }

    @Test func noMatch() {
        #expect(ids("citi double cash").isEmpty)
    }
}
