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
                    let accepted = Self.accept(old: old, new: new)
                    if accepted != new { text = accepted }
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

    /// What the field should hold after an edit: the new text with a comma decimal separator
    /// (the decimal pad in many regions, e.g. vi_VN, de_DE) turned into ".", or the old text if invalid.
    static func accept(old: String, new: String) -> String {
        let normalized = new.replacingOccurrences(of: ",", with: ".")
        return isAllowed(normalized) ? normalized : old.replacingOccurrences(of: ",", with: ".")
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
