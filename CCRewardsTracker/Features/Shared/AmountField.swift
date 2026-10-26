import SwiftUI

/// Optional purchase amount. Accepts up to 2 decimals and $999,999.99; invalid input is ignored as typed.
struct AmountField: View {
    @Binding var text: String
    @FocusState private var focused: Bool

    var body: some View {
        HStack(spacing: 4) {
            Text("$").foregroundStyle(.secondary)
            TextField("Amount (optional)", text: $text)
                .keyboardType(.decimalPad)
                .monospacedDigit()
                .focused($focused)
                .onChange(of: text) { old, new in
                    if !Self.isAllowed(new) { text = old }
                }
            if !text.isEmpty {
                Button("Clear", systemImage: "xmark.circle.fill") { text = "" }
                    .labelStyle(.iconOnly)
                    .foregroundStyle(.secondary)
                    .buttonStyle(.plain)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Purchase amount, optional")
        .accessibilityHint("Shows how much each card would earn")
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { focused = false }
            }
        }
    }

    static func isAllowed(_ text: String) -> Bool {
        if text.isEmpty { return true }
        let parts = text.split(separator: ".", omittingEmptySubsequences: false)
        guard parts.count <= 2, text.allSatisfy({ $0.isASCIIDigit || $0 == "." }) else { return false }
        if parts.count == 2, parts[1].count > 2 { return false }
        guard let value = Decimal(string: text.hasSuffix(".") ? String(text.dropLast()) : text) else { return text == "." }
        return value <= 999_999.99
    }
}
