import SwiftData
import SwiftUI

/// CR-2: one credit's current period, mark used / log partial use, enrollment, and history.
/// Reminder settings arrive with M4.
struct CreditDetailView: View {
    @Bindable var credit: Credit

    @Environment(\.dismiss) private var dismiss
    @Environment(\.calendar) private var calendar
    @Environment(\.scenePhase) private var scenePhase
    @State private var now = Date.now
    @State private var logging = DebugLaunch.openLogUsage
    @State private var editingCard: UserCard?
    @State private var showAllHistory = false

    private static let historyLimit = 12

    var body: some View {
        if credit.modelContext == nil || credit.isDeleted {
            // Deleted while open (e.g. its card was deleted): go back.
            Color.clear.onAppear { dismiss() }
        } else {
            content
        }
    }

    private var content: some View {
        let period = credit.period(containing: now, calendar: calendar)
        let used = period.map(credit.used(in:)) ?? 0
        let cardArchived = credit.card?.isArchived ?? false
        let canLog = !credit.isArchived && !cardArchived

        return List {
            banners(cardArchived: cardArchived)

            Section {
                header(period: period, used: used, canLog: canLog)
            }

            if credit.requiresEnrollment, canLog {
                Section {
                    Toggle("I've enrolled", isOn: $credit.isEnrolled)
                } header: {
                    Text("Enrollment")
                } footer: {
                    Text("This credit only works after you enroll on the \(credit.card?.issuer ?? "issuer") site or app.")
                }
            }

            history

            Section {
                if let notes = credit.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.subheadline)
                }
            } header: {
                if credit.notes?.isEmpty == false { Text("Notes") }
            } footer: {
                Text(Formatters.resetRule(period: credit.period, years: credit.periodYears, basis: credit.resetBasis,
                                          openedOn: credit.card?.openedOn, calendar: calendar))
            }
        }
        .navigationTitle(credit.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $logging) { LogUsageView(credit: credit) }
        .sheet(item: $editingCard) { CardEditorView(card: $0) }
        .sensoryFeedback(trigger: used) { old, new in new > old ? .success : nil }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { now = .now }
        }
    }

    @ViewBuilder private func banners(cardArchived: Bool) -> some View {
        if credit.isArchived {
            Section {
                Label("This credit was removed from the card's terms. Its history is kept.", systemImage: "archivebox")
                    .font(.subheadline)
            }
        } else if cardArchived {
            Section {
                Label("This card is archived. Unarchive it to track this credit.", systemImage: "archivebox")
                    .font(.subheadline)
            }
        } else if credit.needsEnrollment {
            Section {
                Label("Enroll in this credit on the issuer's site before using it.", systemImage: "person.badge.clock")
                    .font(.subheadline)
                    .foregroundStyle(Color("Caution"))
            }
        }
    }

    @ViewBuilder private func header(period: CreditPeriod?, used: Decimal, canLog: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                if let card = credit.card {
                    CardTile(card: card, size: .small)
                        .accessibilityHidden(true)
                }
                Text("\(credit.card?.displayName ?? "") · \(Formatters.period(credit.period, years: credit.periodYears))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if let period {
                let remaining = max(credit.amount - used, 0)
                if remaining == 0 {
                    Text("\(Image(systemName: "checkmark.circle.fill")) Used")
                        .font(.largeTitle.weight(.bold))
                        .fontDesign(.rounded)
                        .foregroundStyle(Color.accentColor)
                } else {
                    Text("\(Formatters.money(remaining)) left")
                        .font(.largeTitle.weight(.bold))
                        .fontDesign(.rounded)
                        .monospacedDigit()
                        .contentTransition(.numericText())
                }
                Text("of \(Formatters.money(credit.amount)) · \(Formatters.span(period, calendar: calendar))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                if remaining == 0 {
                    Text("Available again \(Formatters.day(period.end, now: now, calendar: calendar))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    let urgency = Urgency(daysLeft: CreditPeriodCalculator.daysLeft(in: period, now: now, calendar: calendar))
                    Label {
                        Text(Formatters.ends(period, now: now, calendar: calendar))
                    } icon: {
                        Image(systemName: urgency.symbol ?? "calendar")
                    }
                    .font(.subheadline)
                    .foregroundStyle(urgency.color)
                }
                ProgressView(value: credit.amount > 0 ? min(NSDecimalNumber(decimal: used / credit.amount).doubleValue, 1) : 0)
                    .tint(Color.accentColor)

                if canLog {
                    if remaining > 0 {
                        Button("Mark as Used") {
                            withAnimation { _ = credit.markUsed(now: .now, calendar: calendar) }
                            try? credit.modelContext?.save()
                        }
                        .primaryActionStyle()
                        .frame(maxWidth: .infinity)
                        .padding(.top, 4)
                    }
                    Button("Log Partial Amount") { logging = true }
                        .buttonStyle(.glass)
                        .frame(maxWidth: .infinity)
                        .disabled(remaining == 0)
                }
            } else {
                Text("Add your card open date to track this credit")
                    .font(.headline)
                Button("Add Date") { editingCard = credit.card }
                    .primaryActionStyle()
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 8)
        .buttonStyle(.borderless)
    }

    @ViewBuilder private var history: some View {
        let periods = credit.history(now: now, calendar: calendar)
        if !periods.isEmpty {
            let shown = showAllHistory ? periods : Array(periods.prefix(Self.historyLimit))
            Section("History") {
                ForEach(shown, id: \.start) { period in
                    let used = credit.used(in: period)
                    HStack {
                        Text(Formatters.periodName(period, calendar: calendar))
                        Spacer()
                        Text("\(Formatters.money(used)) used")
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                        if used >= credit.amount {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Color.accentColor)
                        }
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("\(Formatters.periodName(period, calendar: calendar)), \(Formatters.money(used)) used"
                                        + (used >= credit.amount ? ", fully used" : ""))
                    ForEach(credit.usages(in: period)) { usage in
                        UsageRow(usage: usage, now: now)
                            .swipeActions {
                                Button("Delete", systemImage: "trash", role: .destructive) { delete(usage) }
                            }
                    }
                }
                if periods.count > Self.historyLimit, !showAllHistory {
                    Button("Show All") { showAllHistory = true }
                }
            }
        }
    }

    private func delete(_ usage: CreditUsage) {
        guard let context = credit.modelContext else { return }
        withAnimation {
            credit.usages?.removeAll { $0.persistentModelID == usage.persistentModelID }
            context.delete(usage)
        }
        try? context.save()
    }
}

private struct UsageRow: View {
    let usage: CreditUsage
    let now: Date
    @Environment(\.calendar) private var calendar

    var body: some View {
        let parts = [Formatters.day(usage.loggedAt, now: now, calendar: calendar), Formatters.money(usage.amountUsed)]
            + [usage.note.map { "“\($0)”" }].compactMap { $0 }
        Text(parts.joined(separator: " · "))
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .padding(.leading, 16)
    }
}
