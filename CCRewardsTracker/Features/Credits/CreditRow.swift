import SwiftUI

/// One credit's current period (docs/ui/DESIGN_SYSTEM.md `CreditRow`).
struct CreditRow: View {
    let credit: Credit
    let status: CreditStatus
    let now: Date
    var showsCard = true

    @Environment(\.calendar) private var calendar

    private var isUsed: Bool { status.period != nil && status.remaining == 0 }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if showsCard, let card = credit.card {
                CardTile(card: card, size: .small)
                    .accessibilityHidden(true)
            }
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline) {
                    Text(credit.name)
                        .foregroundStyle(isUsed ? .secondary : .primary)
                    Spacer()
                    trailing
                }
                HStack(alignment: .firstTextBaseline) {
                    subtitle
                        .font(.subheadline)
                    Spacer()
                    if status.period != nil, !isUsed {
                        Text("of \(Formatters.money(status.amount))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                if credit.needsEnrollment, !isUsed {
                    StatusBadge(kind: .enroll)
                }
                if status.period != nil, !isUsed {
                    ProgressView(value: fraction)
                        .tint(Color.accentColor)
                }
            }
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityText)
    }

    @ViewBuilder private var trailing: some View {
        if isUsed {
            Label("Used", systemImage: "checkmark.circle.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.accentColor)
        } else if status.period != nil {
            Text(Formatters.money(status.remaining))
                .font(.body.weight(.semibold).monospacedDigit())
                .contentTransition(.numericText())
        }
    }

    private var subtitle: Text {
        let prefix = showsCard ? "\(credit.card?.displayName ?? "") · " : ""
        guard let period = status.period else {
            return Text("Add card open date to track").foregroundStyle(.secondary)
        }
        if isUsed {
            return Text(prefix + "Available again \(Formatters.day(period.end, now: now, calendar: calendar))")
                .foregroundStyle(.secondary)
        }
        let ends = Formatters.ends(period, now: now, calendar: calendar)
        let urgency = Urgency(daysLeft: CreditPeriodCalculator.daysLeft(in: period, now: now, calendar: calendar))
        let endsText = urgency.symbol.map { Text("\(Image(systemName: $0)) \(ends)") } ?? Text(ends)
        return Text("\(Text(prefix).foregroundStyle(.secondary))\(endsText.foregroundStyle(urgency.color))")
    }

    private var fraction: Double {
        guard status.amount > 0 else { return 0 }
        return min(NSDecimalNumber(decimal: status.used / status.amount).doubleValue, 1)
    }

    private var accessibilityText: String {
        let card = credit.card?.displayName ?? ""
        guard let period = status.period else { return "\(credit.name), \(card). Add card open date to track." }
        if isUsed {
            return "\(credit.name), \(card). Used. Available again \(Formatters.day(period.end, now: now, calendar: calendar))."
        }
        let last = CreditPeriodCalculator.lastDay(of: period, calendar: calendar)
        return "\(credit.name), \(card). \(Formatters.money(status.remaining)) left of \(Formatters.money(status.amount)). "
            + "\(Formatters.ends(period, now: now, calendar: calendar)), \(last.formatted(.dateTime.month(.wide).day()))."
            + (credit.needsEnrollment ? " Enroll first." : "")
    }
}

/// How close a period's end is: within 7 days is Caution, today or tomorrow is Urgent.
enum Urgency {
    case none, soon, urgent

    init(daysLeft: Int) {
        self = daysLeft <= 1 ? .urgent : (daysLeft <= 7 ? .soon : .none)
    }

    var symbol: String? {
        switch self {
        case .none: nil
        case .soon: "clock"
        case .urgent: "exclamationmark.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .none: .secondary
        case .soon: Color("Caution")
        case .urgent: Color("Urgent")
        }
    }
}
