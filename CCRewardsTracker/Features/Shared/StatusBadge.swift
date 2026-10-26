import SwiftUI

/// Capsule with a symbol and a label. The text is always present, never icon-only.
struct StatusBadge: View {
    enum Kind {
        case retired, inWallet, archived, tie, activate(String), localEdits

        var label: String {
            switch self {
            case .retired: "No longer offered"
            case .inWallet: "In your wallet"
            case .archived: "Archived"
            case .tie: "Tie"
            case .activate(let quarter): "Activate \(quarter) categories"
            case .localEdits: "Edited by you"
            }
        }

        var symbol: String {
            switch self {
            case .retired: "clock.arrow.circlepath"
            case .inWallet: "checkmark.circle"
            case .archived: "archivebox"
            case .tie: "equal.circle"
            case .activate: "lightbulb.min"
            case .localEdits: "pencil"
            }
        }

        var tint: Color {
            switch self {
            case .activate: .accentColor
            case .localEdits: Color("Caution")
            default: .secondary
            }
        }
    }

    let kind: Kind

    var body: some View {
        Label(kind.label, systemImage: kind.symbol)
            .labelStyle(BadgeLabelStyle())
            .font(.caption.weight(.semibold))
            .foregroundStyle(kind.tint)
    }

    private struct BadgeLabelStyle: LabelStyle {
        func makeBody(configuration: Configuration) -> some View {
            HStack(spacing: 4) {
                configuration.icon
                configuration.title
            }
        }
    }
}
