import Foundation
import Observation

/// Holds the card catalog. For now it loads the copy bundled with the app; the remote
/// fetch, cache and ETag check come in roadmap M5 (docs/CARD_CATALOG.md).
@Observable final class CatalogStore {
    private(set) var catalog: CatalogFile

    init(catalog: CatalogFile) {
        self.catalog = catalog
    }

    static func bundled(_ bundle: Bundle = .main) throws -> CatalogStore {
        guard let url = bundle.url(forResource: "catalog", withExtension: "json") else {
            throw CatalogError.missingBundledCatalog
        }
        let data = try Data(contentsOf: url)
        return CatalogStore(catalog: try JSONDecoder().decode(CatalogFile.self, from: data))
    }

    var cards: [CatalogCard] { catalog.cards }

    func card(id: String?) -> CatalogCard? {
        guard let id else { return nil }
        return catalog.cards.first { $0.id == id }
    }

    func currency(id: String) -> CatalogCurrency? {
        catalog.currencies.first { $0.id == id }
    }

    /// Issuers in display order (alphabetical), each with its cards: current cards first, then retired.
    var cardsByIssuer: [(issuer: String, cards: [CatalogCard])] {
        Dictionary(grouping: catalog.cards, by: \.issuer)
            .sorted { $0.key < $1.key }
            .map { issuer, cards in
                (issuer, cards.sorted { ($0.retired ? 1 : 0, $0.shortName) < ($1.retired ? 1 : 0, $1.shortName) })
            }
    }
}
