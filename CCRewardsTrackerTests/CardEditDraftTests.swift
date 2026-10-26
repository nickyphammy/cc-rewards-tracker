import Foundation
import SwiftData
import Testing
@testable import CCRewardsTracker

@MainActor
struct CardEditDraftTests {
    let container = try! ModelContainer(
        for: UserCard.self, Multiplier.self, Credit.self, CreditUsage.self, CategorySelection.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )

    private func addCard(_ id: String) throws -> UserCard {
        let template = try #require(try CatalogStore.bundled().card(id: id))
        return CardFactory.addCard(from: template, sortIndex: 0, to: container.mainContext)
    }

    @Test func personalEditsDontMarkLocalEdits() throws {
        let card = try addCard("amex_gold")
        var draft = CardEditDraft(card: card)
        #expect(!draft.hasChanges(from: card))
        draft.nickname = "  Gold  "
        draft.last4 = "1005"
        draft.network = .amex
        draft.colorHex = TileColor.copper.hex
        #expect(draft.hasChanges(from: card))
        draft.apply(to: card, context: container.mainContext)
        #expect(card.nickname == "Gold")
        #expect(card.last4 == "1005")
        #expect(card.colorHex == TileColor.copper.hex)
        #expect(!card.hasLocalEdits)
    }

    @Test func rateEditsMarkLocalEditsAndKeepRotatingRows() throws {
        let card = try addCard("chase_freedom_flex")
        let rotatingBefore = (card.multipliers ?? []).filter { $0.rotatingQuarter != nil }.count
        var draft = CardEditDraft(card: card)
        let dining = try #require(draft.rates.firstIndex { $0.category == .dining })
        draft.rates[dining].rateText = "4"
        draft.addRate()
        draft.rates[0].category = .gas
        draft.rates[0].rateText = "2"
        draft.apply(to: card, context: container.mainContext)

        #expect(card.hasLocalEdits)
        #expect(card.standardMultipliers.first { $0.category == .dining }?.rate == 4)
        #expect(card.standardMultipliers.contains { $0.category == .gas && $0.rate == 2 })
        #expect((card.multipliers ?? []).filter { $0.rotatingQuarter != nil }.count == rotatingBefore)
    }

    @Test func deletingARateRemovesIt() throws {
        let card = try addCard("capone_savor")
        var draft = CardEditDraft(card: card)
        draft.rates.removeAll { $0.category == .streaming }
        draft.apply(to: card, context: container.mainContext)
        try container.mainContext.save()
        #expect(!card.standardMultipliers.contains { $0.category == .streaming })
    }

    @Test func validation() throws {
        let card = try addCard("amex_gold")
        var draft = CardEditDraft(card: card)
        draft.last4 = "12"
        #expect(!draft.isValid)
        draft.last4 = ""
        draft.rates[0].rateText = "abc"
        #expect(!draft.isValid)
        draft.rates[0].rateText = "3"
        #expect(draft.isValid)
        draft.rates.removeAll(where: \.isBase)
        #expect(!draft.isValid)
    }

    @Test func activationIsPerQuarter() throws {
        let card = try addCard("chase_freedom_flex")
        #expect(card.needsActivation(quarter: "2026Q4"))
        card.setActivated(true, quarter: "2026Q4")
        #expect(card.isActivated(quarter: "2026Q4"))
        #expect(!card.needsActivation(quarter: "2026Q4"))
        #expect(card.needsActivation(quarter: "2027Q1"))
        #expect(card.rotatingQuarters(from: "2026Q4").map(\.quarter) == ["2026Q4", "2027Q1"])
    }
}
