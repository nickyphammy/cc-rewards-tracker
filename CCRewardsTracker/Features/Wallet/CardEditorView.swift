import SwiftData
import SwiftUI

/// WA-5 (edit mode): personal details and earn rates. Catalog terms other than rates stay read-only.
struct CardEditorView: View {
    @Environment(CatalogStore.self) private var catalog
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    let card: UserCard
    @State private var draft: CardEditDraft
    @State private var confirmingDiscard = false

    init(card: UserCard) {
        self.card = card
        _draft = State(initialValue: CardEditDraft(card: card))
    }

    private var terms: CardTerms { CardTerms(card: card, catalog: catalog) }
    private var isDirty: Bool { draft.hasChanges(from: card) }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    CardTile(issuer: card.issuer, name: draft.nickname.isEmpty ? (card.shortName ?? card.name) : draft.nickname,
                             last4: draft.last4IsValid ? draft.last4 : nil, colorHex: draft.colorHex, size: .large)
                        .frame(maxWidth: .infinity)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets())
                }

                Section {
                    LabeledContent("Nickname") {
                        TextField("Nickname", text: $draft.nickname, prompt: Text("e.g. \(card.shortName ?? "Travel card")"))
                            .multilineTextAlignment(.trailing)
                    }
                    LabeledContent("Last 4 digits") {
                        TextField("Last 4 digits", text: $draft.last4, prompt: Text("Optional"))
                            .keyboardType(.numberPad)
                            .textContentType(.none)
                            .multilineTextAlignment(.trailing)
                            .monospacedDigit()
                            .onChange(of: draft.last4) { _, new in
                                let digits = String(new.filter(\.isASCIIDigit).prefix(4))
                                if digits != new { draft.last4 = digits }
                            }
                    }
                    Picker("Network", selection: $draft.network) {
                        ForEach(CardNetwork.allCases) { Text($0.displayName).tag($0) }
                    }
                    Toggle("Card open date", isOn: Binding(
                        get: { draft.openedOn != nil },
                        set: { draft.openedOn = $0 ? (draft.openedOn ?? .now) : nil }
                    ))
                    if let opened = draft.openedOn {
                        DatePicker("Opened", selection: Binding(get: { opened }, set: { draft.openedOn = $0 }),
                                   in: ...Date.now, displayedComponents: .date)
                    }
                    colorPicker
                } header: {
                    Text("Personalize")
                } footer: {
                    if !draft.last4IsValid {
                        Text("Enter all 4 digits or leave it blank.").foregroundStyle(Color("Urgent"))
                    } else if card.issuer == "Capital One" {
                        Text("Check the logo on your card. This card may be Visa, Mastercard or Discover.")
                    } else {
                        Text("Last 4 is optional and only used to tell your cards apart.")
                    }
                }

                Section {
                    ForEach($draft.rates) { $rate in
                        RateEditorRow(rate: $rate, terms: terms, issuer: card.issuer)
                            .deleteDisabled(rate.isBase)
                    }
                    .onDelete { draft.rates.remove(atOffsets: $0) }
                    Button("Add Rate", systemImage: "plus") { draft.addRate() }
                } header: {
                    Text("Earn Rates")
                } footer: {
                    if card.catalogID != nil {
                        Text("Changing rates overrides \(card.issuer)'s terms for you only. Rotating bonus categories are managed by the catalog.")
                    }
                }
            }
            .navigationTitle("Edit Card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isDirty ? (confirmingDiscard = true) : dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        draft.apply(to: card, context: context)
                        try? context.save()
                        dismiss()
                    }
                    .disabled(!draft.isValid)
                }
            }
            .interactiveDismissDisabled(isDirty)
            .confirmationDialog("Discard your changes?", isPresented: $confirmingDiscard, titleVisibility: .visible) {
                Button("Discard Changes", role: .destructive) { dismiss() }
                Button("Keep Editing", role: .cancel) {}
            }
        }
    }

    private var colorPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Color")
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 9), spacing: 8) {
                ForEach(TileColor.allCases) { tile in
                    let selected = TileColor.from(hex: draft.colorHex) == tile
                    Button {
                        draft.colorHex = tile.hex
                    } label: {
                        Circle()
                            .fill(tile.color)
                            .frame(width: 28, height: 28)
                            .overlay {
                                if selected {
                                    Image(systemName: "checkmark")
                                        .font(.caption.weight(.bold))
                                        .foregroundStyle(.white)
                                }
                            }
                            .frame(minWidth: 44, minHeight: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(tile.name)
                    .accessibilityAddTraits(selected ? .isSelected : [])
                }
            }
        }
    }
}

private struct RateEditorRow: View {
    @Binding var rate: CardEditDraft.Rate
    let terms: CardTerms
    let issuer: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                if rate.isBase {
                    Label(SpendCategory.other.displayName, systemImage: SpendCategory.other.symbol)
                } else {
                    Picker(selection: $rate.category) {
                        ForEach(SpendCategory.allCases.filter { $0 != .other }) {
                            Label($0.displayName, systemImage: $0.symbol).tag($0)
                        }
                    } label: {
                        EmptyView()
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                    .fixedSize()
                }
                Spacer()
                TextField("Rate", text: $rate.rateText)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .font(.body.weight(.semibold).monospacedDigit())
                    .frame(width: 64)
                    .foregroundStyle(rate.rate == nil ? Color("Urgent") : .primary)
                Text(terms.unit == .percent ? "%" : "x")
                    .foregroundStyle(.secondary)
            }
            if let condition = rate.condition, let text = CaveatCopy.condition(condition, brand: rate.brand, issuer: issuer) {
                CaveatRow(text: text)
            }
        }
    }
}
