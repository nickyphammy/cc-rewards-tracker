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

    @Test func personalEditsApplyAndLeaveRatesAlone() throws {
        let card = try addCard("amex_gold")
        let ratesBefore = card.standardMultipliers.map { "\($0.category.rawValue)=\($0.rate)" }
        var draft = CardEditDraft(card: card)
        #expect(!draft.hasChanges(from: card))
        draft.nickname = "  Gold  "
        draft.last4 = "1005"
        draft.network = .amex
        draft.colorHex = TileColor.copper.hex
        #expect(draft.hasChanges(from: card))
        draft.apply(to: card)
        #expect(card.nickname == "Gold")
        #expect(card.last4 == "1005")
        #expect(card.colorHex == TileColor.copper.hex)
        #expect(card.standardMultipliers.map { "\($0.category.rawValue)=\($0.rate)" } == ratesBefore)
        #expect(!CardEditDraft(card: card).hasChanges(from: card))
    }

    @Test func clearingFieldsStoresNil() throws {
        let card = try addCard("amex_gold")
        card.nickname = "Gold"
        card.last4 = "1005"
        var draft = CardEditDraft(card: card)
        draft.nickname = "   "
        draft.last4 = ""
        draft.apply(to: card)
        #expect(card.nickname == nil)
        #expect(card.last4 == nil)
    }

    @Test func validation() throws {
        let card = try addCard("amex_gold")
        var draft = CardEditDraft(card: card)
        #expect(draft.isValid)
        draft.last4 = "12"
        #expect(!draft.isValid)
        draft.last4 = "1234"
        #expect(draft.isValid)
        draft.last4 = ""
        #expect(draft.isValid)
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
