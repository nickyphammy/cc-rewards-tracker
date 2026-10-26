import SwiftData
import SwiftUI

/// CR-1: every credit still available this period, soonest-ending first, with totals.
struct CreditsView: View {
    @Environment(\.calendar) private var calendar
    @Environment(\.scenePhase) private var scenePhase
    @Query(filter: #Predicate<Credit> { !$0.isArchived }, sort: \Credit.name) private var allCredits: [Credit]
    @State private var now = Date.now
    @State private var showUsed = false
    @State private var showingPicker = false
    @State private var editingCard: UserCard?
    @State private var markedCount = 0
    @State private var loggingCredit: Credit?
    @State private var path = NavigationPath()

    /// Credits on cards that are in the wallet and not archived.
    private var credits: [Credit] { allCredits.filter { $0.card.map { !$0.isArchived } ?? false } }

    var body: some View {
        let credits = credits
        let byID = Dictionary(credits.map { ($0.id, $0) }) { first, _ in first }
        let dashboard = CreditDashboard(credits.map { $0.status(now: now, calendar: calendar) }, now: now, calendar: calendar)

        NavigationStack(path: $path) {
            Group {
                if dashboard.isEmpty {
                    ContentUnavailableView {
                        Label("No credits to track", systemImage: "gift")
                    } description: {
                        Text("Cards with monthly or yearly credits show up here once you add them.")
                    } actions: {
                        Button("Add Card") { showingPicker = true }
                            .primaryActionStyle()
                    }
                } else {
                    list(dashboard, byID: byID)
                }
            }
            .navigationTitle("Credits")
            .sheet(isPresented: $showingPicker) { CardPickerView(mode: .addToWallet) }
            .sheet(item: $editingCard) { CardEditorView(card: $0) }
            .sheet(item: $loggingCredit) { LogUsageView(credit: $0) }
            .navigationDestination(for: Credit.self) { CreditDetailView(credit: $0) }
            .task {
                if path.isEmpty, let name = DebugLaunch.openCredit, let credit = credits.first(where: { $0.name == name }) {
                    path.append(credit)
                }
            }
            .sensoryFeedback(.success, trigger: markedCount)
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { now = .now }
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged)) { _ in now = .now }
    }

    private func list(_ dashboard: CreditDashboard, byID: [UUID: Credit]) -> some View {
        List {
            Section {
                SummaryHeader(dashboard: dashboard)
            }

            if dashboard.availableCount == 0, !dashboard.used.isEmpty {
                Section {
                    Label {
                        Text("You've used every credit this period."
                             + (dashboard.nextReset.map { " Next reset: \(Formatters.day($0, now: now, calendar: calendar))." } ?? ""))
                    } icon: {
                        Image(systemName: "checkmark.circle.fill").foregroundStyle(Color.accentColor)
                    }
                }
            }

            rows("Ends This Month", dashboard.endsThisMonth, byID: byID)
            rows("Later", dashboard.later, byID: byID)

            if !dashboard.used.isEmpty {
                Section {
                    DisclosureGroup("Used This Period (\(dashboard.used.count))",
                                    isExpanded: Binding(get: { showUsed || dashboard.availableCount == 0 }, set: { showUsed = $0 })) {
                        ForEach(dashboard.used) { status in
                            if let credit = byID[status.id] {
                                NavigationLink(value: credit) { CreditRow(credit: credit, status: status, now: now) }
                            }
                        }
                    }
                }
            }

            if !dashboard.needsOpenDate.isEmpty {
                Section {
                    ForEach(dashboard.needsOpenDate) { status in
                        if let credit = byID[status.id] {
                            Button { editingCard = credit.card } label: {
                                CreditRow(credit: credit, status: status, now: now)
                            }
                            .buttonStyle(.plain)
                            .accessibilityHint("Opens the card so you can add its open date")
                        }
                    }
                } header: {
                    Text("Needs Card Open Date")
                } footer: {
                    Text("These credits reset on your card anniversary. Add the date you opened the card to track them.")
                }
            }
        }
        .animation(.default, value: markedCount)
    }

    @ViewBuilder
    private func rows(_ title: String, _ statuses: [CreditStatus], byID: [UUID: Credit]) -> some View {
        if !statuses.isEmpty {
            Section(title) {
                ForEach(statuses) { status in
                    if let credit = byID[status.id] {
                        NavigationLink(value: credit) { CreditRow(credit: credit, status: status, now: now) }
                            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                Button("Mark Used", systemImage: "checkmark") { markUsed(credit) }
                                    .tint(Color.accentColor)
                            }
                            .swipeActions(edge: .trailing) {
                                Button("Log Amount", systemImage: "square.and.pencil") { loggingCredit = credit }
                                    .tint(.indigo)
                            }
                            .accessibilityAction(named: "Mark used") { markUsed(credit) }
                            .accessibilityAction(named: "Log amount") { loggingCredit = credit }
                    }
                }
            }
        }
    }

    private func markUsed(_ credit: Credit) {
        if credit.markUsed(now: .now, calendar: calendar) > 0 {
            try? credit.modelContext?.save()
            markedCount += 1
        }
    }
}

/// CR-1 header: total available, how many credits, and how much ends this month.
private struct SummaryHeader: View {
    let dashboard: CreditDashboard

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(Formatters.money(dashboard.totalAvailable))
                .font(.largeTitle.weight(.bold))
                .fontDesign(.rounded)
                .monospacedDigit()
                .contentTransition(.numericText())
            Text(dashboard.availableCount == 1 ? "available across 1 credit" : "available across \(dashboard.availableCount) credits")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            if dashboard.endingThisMonth > 0 {
                Label("\(Formatters.money(dashboard.endingThisMonth)) ends this month", systemImage: "clock")
                    .font(.subheadline)
                    .foregroundStyle(Color("Caution"))
            }
        }
        .padding(.vertical, 8)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
    }

    private var accessibilityText: String {
        var text = "\(Formatters.money(dashboard.totalAvailable)) available across \(dashboard.availableCount) credits."
        if dashboard.endingThisMonth > 0 { text += " \(Formatters.money(dashboard.endingThisMonth)) ends this month." }
        return text
    }
}
