import SwiftUI

/// Generic card graphic. Never shows issuer logos or real card art (docs/ui/DESIGN_SYSTEM.md `CardTile`).
struct CardTile: View {
    enum Size { case small, medium, large }

    let issuer: String
    let name: String
    var last4: String?
    var colorHex: String?
    var size: Size = .small
    var isArchived = false

    private var color: Color { Color(hex: colorHex ?? TileColor.defaultFor(issuer: issuer).hex) }
    private var shape: RoundedRectangle { RoundedRectangle(cornerRadius: 10, style: .continuous) }

    var body: some View {
        content
            .foregroundStyle(.white)
            .modifier(TileFrame(width: width))
            .background(color, in: shape)
            .overlay(shape.strokeBorder(Color("TileStroke"), lineWidth: 1))
            .saturation(isArchived ? 0.4 : 1)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(accessibilityText)
    }

    @ViewBuilder private var content: some View {
        switch size {
        case .small:
            Image(systemName: "creditcard")
                .font(.caption)
                .opacity(0.5)
        case .medium:
            Text(Self.initials(for: issuer))
                .font(.subheadline.weight(.bold))
        case .large:
            VStack(alignment: .leading) {
                Text(issuer.uppercased())
                    .font(.caption2.weight(.semibold))
                Spacer()
                HStack(alignment: .firstTextBaseline) {
                    Text(name)
                        .font(.footnote.weight(.semibold))
                        .lineLimit(1)
                    Spacer()
                    if let last4, !last4.isEmpty {
                        Text("••\(last4)")
                            .font(.footnote.weight(.semibold).monospacedDigit())
                    }
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
    }

    private var width: CGFloat? {
        switch size {
        case .small: 44
        case .medium: 72
        case .large: nil
        }
    }

    private var accessibilityText: String {
        var parts = [issuer, name]
        if let last4, !last4.isEmpty { parts.append("ending in \(last4)") }
        return parts.joined(separator: ", ")
    }

    /// Fixed sizes keep the ID-1 card shape (1.586:1); the large tile fills the width up to 320 pt.
    private struct TileFrame: ViewModifier {
        let width: CGFloat?

        func body(content: Content) -> some View {
            if let width {
                content.frame(width: width, height: (width / 1.586).rounded())
            } else {
                content
                    .frame(maxWidth: 320)
                    .aspectRatio(1.586, contentMode: .fit)
            }
        }
    }

    static func initials(for issuer: String) -> String {
        switch issuer {
        case "American Express": "AX"
        case "Capital One": "C1"
        case "Chase": "CH"
        case "Robinhood": "RH"
        default: String(issuer.split(separator: " ").compactMap(\.first).prefix(2)).uppercased()
        }
    }
}

extension CardTile {
    init(card: UserCard, size: Size) {
        self.init(issuer: card.issuer, name: card.displayName, last4: card.last4,
                  colorHex: card.colorHex, size: size, isArchived: card.isArchived)
    }
}

#Preview {
    VStack(spacing: 16) {
        HStack {
            CardTile(issuer: "American Express", name: "Gold", size: .small)
            CardTile(issuer: "Chase", name: "Sapphire Reserve", size: .medium)
            CardTile(issuer: "Capital One", name: "Savor", size: .small, isArchived: true)
        }
        CardTile(issuer: "American Express", name: "Gold", last4: "1005", size: .large)
    }
    .padding()
}
