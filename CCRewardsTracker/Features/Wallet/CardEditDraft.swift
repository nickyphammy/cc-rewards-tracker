import Foundation

/// Editable copy of a card's personal details. Edits are applied on Save so Cancel can discard them.
/// Earn rates and credits come from the catalog and aren't editable.
struct CardEditDraft: Equatable {
    var nickname: String
    var last4: String
    var network: CardNetwork
    var colorHex: String?
    var openedOn: Date?

    init(card: UserCard) {
        nickname = card.nickname ?? ""
        last4 = card.last4 ?? ""
        network = card.network
        colorHex = card.colorHex
        openedOn = card.openedOn
    }

    var last4IsValid: Bool {
        last4.isEmpty || (last4.count == 4 && last4.allSatisfy(\.isASCIIDigit))
    }

    var isValid: Bool { last4IsValid }

    func apply(to card: UserCard) {
        let trimmed = nickname.trimmingCharacters(in: .whitespaces)
        card.nickname = trimmed.isEmpty ? nil : trimmed
        card.last4 = last4.isEmpty ? nil : last4
        card.network = network
        card.colorHex = colorHex
        card.openedOn = openedOn
    }

    func hasChanges(from card: UserCard) -> Bool {
        self != CardEditDraft(card: card)
    }
}

extension Character {
    var isASCIIDigit: Bool { ("0"..."9").contains(self) }
}
