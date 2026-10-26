import Foundation

/// Card search for the picker: matches issuer, card name, short name and common nicknames,
/// case- and diacritic-insensitive.
nonisolated enum CatalogSearch {
    private static let issuerAliases: [String: [String]] = [
        "American Express": ["amex"],
        "Capital One": ["capone", "cap one", "c1"],
        "Chase": [],
        "Robinhood": ["rh"],
    ]

    static func filter(_ cards: [CatalogCard], query: String) -> [CatalogCard] {
        let words = query.split(whereSeparator: \.isWhitespace).map(String.init)
        guard !words.isEmpty else { return cards }
        return cards.filter { card in
            let haystack = ([card.issuer, card.name, card.shortName] + (issuerAliases[card.issuer] ?? []))
                .joined(separator: " ")
            return words.allSatisfy { haystack.localizedStandardContains($0) }
        }
    }
}
