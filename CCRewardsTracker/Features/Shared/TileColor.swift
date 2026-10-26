import SwiftUI

/// The nine card tile presets (docs/ui/DESIGN_SYSTEM.md "Card tile colors"). White text on each is ≥ 4.5:1.
enum TileColor: String, CaseIterable, Identifiable {
    case graphite, navy, royal, teal, green, burgundy, copper, gold, purple

    var id: String { rawValue }
    var name: String { rawValue.capitalized }

    var hex: String {
        switch self {
        case .graphite: "#3A3A3C"
        case .navy: "#1F3A68"
        case .royal: "#2F5BD3"
        case .teal: "#0F6E6E"
        case .green: "#2E7D32"
        case .burgundy: "#8E1B3A"
        case .copper: "#9A4A14"
        case .gold: "#8C6A12"
        case .purple: "#5B3FA8"
        }
    }

    var color: Color { Color(hex: hex) }

    static func defaultFor(issuer: String) -> TileColor {
        switch issuer {
        case "Chase": .navy
        case "American Express": .royal
        case "Capital One": .burgundy
        case "Robinhood": .gold
        default: .graphite
        }
    }

    static func from(hex: String?) -> TileColor? {
        allCases.first { $0.hex.caseInsensitiveCompare(hex ?? "") == .orderedSame }
    }
}

extension Color {
    init(hex: String) {
        let value = UInt64(hex.trimmingCharacters(in: CharacterSet(charactersIn: "#")), radix: 16) ?? 0
        self.init(
            red: Double((value >> 16) & 0xFF) / 255,
            green: Double((value >> 8) & 0xFF) / 255,
            blue: Double(value & 0xFF) / 255
        )
    }
}
