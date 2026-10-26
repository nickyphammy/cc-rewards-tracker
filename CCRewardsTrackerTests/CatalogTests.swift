import Foundation
import SwiftData
import Testing
@testable import CCRewardsTracker

@MainActor
struct CatalogTests {
    @Test func bundledCatalogDecodesEveryCard() throws {
        let store = try CatalogStore.bundled()
        #expect(store.cards.count == 16)
        #expect(store.card(id: "amex_gold")?.shortName == "Gold")
        #expect(store.card(id: "chase_freedom")?.retired == true)
        #expect(store.currency(id: "cap1_miles")?.unitName == "miles")
    }

    @Test func issuersAreAlphabeticalWithRetiredCardsLast() throws {
        let groups = try CatalogStore.bundled().cardsByIssuer
        #expect(groups.map(\.issuer) == ["American Express", "Capital One", "Chase", "Robinhood"])
        let amex = try #require(groups.first).cards
        #expect(amex.last?.id == "amex_green")
    }

    @Test func cardWithUnknownCategoryIsSkippedNotFatal() throws {
        let json = catalogJSON(cards: [card(id: "good"), card(id: "future", category: "pets")])
        let file = try JSONDecoder().decode(CatalogFile.self, from: Data(json.utf8))
        #expect(file.cards.map(\.id) == ["good"])
    }

    @Test func cardWithoutBaseRateIsSkipped() throws {
        let json = catalogJSON(cards: [card(id: "nobase", category: "dining")])
        let file = try JSONDecoder().decode(CatalogFile.self, from: Data(json.utf8))
        #expect(file.cards.isEmpty)
    }

    @Test func newerSchemaIsRejected() {
        let json = catalogJSON(cards: [], schema: 2)
        #expect(throws: CatalogError.unsupportedSchema(2)) {
            try JSONDecoder().decode(CatalogFile.self, from: Data(json.utf8))
        }
    }

    @Test func addingACardCopiesTermsAndExpandsRotatingRows() throws {
        let container = try ModelContainer(
            for: UserCard.self, Multiplier.self, Credit.self, CreditUsage.self, CategorySelection.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let store = try CatalogStore.bundled()
        let flex = try #require(store.card(id: "chase_freedom_flex"))
        let card = CardFactory.addCard(from: flex, sortIndex: 0, to: container.mainContext)

        #expect(card.catalogRevision == flex.revision)
        #expect(card.rateUnitOverride == .percent)
        #expect(card.colorHex == TileColor.navy.hex)
        let rotating = (card.multipliers ?? []).filter { $0.rotatingQuarter == "2026Q4" }
        #expect(Set(rotating.map(\.category)) == [.groceries, .dining])
        #expect((card.multipliers ?? []).contains { $0.category == .other && $0.condition == nil && $0.rotatingQuarter == nil })

        let platinum = try #require(store.card(id: "amex_platinum"))
        let plat = CardFactory.addCard(from: platinum, sortIndex: 1, to: container.mainContext)
        #expect(plat.credits?.count == platinum.credits.count)
        #expect(plat.credits?.allSatisfy { $0.catalogCreditID != nil } == true)
    }

    private func card(id: String, category: String = "other") -> String {
        """
        {"id":"\(id)","revision":1,"issuer":"X","name":"X \(id)","shortName":"\(id)","network":"visa","annualFee":0,
         "requiredMembership":null,"rewardCurrency":"cash","lastVerified":"2026-10-26","retired":false,
         "multipliers":[{"category":"\(category)","rate":1}],"credits":[]}
        """
    }

    private func catalogJSON(cards: [String], schema: Int = 1) -> String {
        """
        {"schemaVersion":\(schema),"catalogVersion":1,"publishedAt":"2026-10-26T00:00:00Z",
         "currencies":[{"id":"cash","name":"Cash Back","unitName":"cash back","rateUnit":"percent"}],
         "cards":[\(cards.joined(separator: ","))]}
        """
    }
}
