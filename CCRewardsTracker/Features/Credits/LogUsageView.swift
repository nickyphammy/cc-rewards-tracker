import SwiftUI

/// CR-3: log a partial amount against the current period.
struct LogUsageView: View {
    let credit: Credit

    @Environment(\.dismiss) private var dismiss
    @Environment(\.calendar) private var calendar
    @State private var amountText = ""
    @State private var date = Date.now
    @State private var note = ""
    @State private var saveFailed = false
    @State private var savedCount = 0
    @FocusState private var amountFocused: Bool

    enum Validation: Equatable { case empty, overRemaining, valid(Decimal) }

    /// Empty or $0 can't be saved; neither can more than what's left this period.
    static func validate(_ text: String, remaining: Decimal) -> Validation {
        guard let amount = Decimal(string: text), amount > 0 else { return .empty }
        return amount > remaining ? .overRemaining : .valid(amount)
    }

    private var period: CreditPeriod? { credit.period(containing: .now, calendar: calendar) }
    private var remaining: Decimal { period.map(credit.remaining(in:)) ?? 0 }
    private var validation: Validation { Self.validate(amountText, remaining: remaining) }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    LabeledContent("Amount") {
                        HStack(spacing: 2) {
                            Spacer()
                            Text("$").foregroundStyle(.secondary)
                            TextField("0.00", text: $amountText)
                                .keyboardType(.decimalPad)
                                .monospacedDigit()
                                .fixedSize()
                                .focused($amountFocused)
                                .accessibilityLabel("Amount used, dollars")
                                .onChange(of: amountText) { old, new in
                                    let accepted = AmountField.accept(old: old, new: new)
                                    if accepted != new { amountText = accepted }
                                }
                        }
                    }
                    if let period {
                        DatePicker("Date", selection: $date, in: period.start...Date.now, displayedComponents: .date)
                    }
                    LabeledContent("Note") {
                        TextField("Note", text: $note, prompt: Text("Optional"))
                            .multilineTextAlignment(.trailing)
                            .onChange(of: note) { _, new in
                                if new.count > 100 { note = String(new.prefix(100)) }
                            }
                    }
                } header: {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(credit.name) · \(credit.card?.displayName ?? "")")
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Text("\(Formatters.money(remaining)) left this period")
                    }
                    .textCase(nil)
                    .padding(.bottom, 4)
                } footer: {
                    if validation == .overRemaining {
                        Text("You have \(Formatters.money(remaining)) left this period.")
                            .foregroundStyle(Color("Urgent"))
                    }
                }

                Section {
                    Button("Use \(Formatters.money(remaining)) (all of it)") {
                        amountText = Formatters.number(remaining)
                    }
                    .disabled(remaining == 0)
                }
            }
            .navigationTitle("Log Usage")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(!isValid)
                }
            }
            .alert("Couldn't save. Please try again.", isPresented: $saveFailed) {
                Button("OK", role: .cancel) {}
            }
            .onAppear { amountFocused = true }
            .sensoryFeedback(.success, trigger: savedCount)
            .onChange(of: validation == .overRemaining) { _, over in
                if over { AccessibilityNotification.Announcement("You have \(Formatters.money(remaining)) left this period.").post() }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private var isValid: Bool {
        if case .valid = validation { return true }
        return false
    }

    private func save() {
        guard case let .valid(amount) = validation else { return }
        let trimmed = note.trimmingCharacters(in: .whitespaces)
        credit.logUsage(amount, on: date, note: trimmed.isEmpty ? nil : trimmed, calendar: calendar)
        do {
            try credit.modelContext?.save()
            savedCount += 1
            dismiss()
        } catch {
            saveFailed = true
        }
    }
}
