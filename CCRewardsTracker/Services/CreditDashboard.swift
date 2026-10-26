import Foundation

/// One credit's state in its current period. `period` is nil when it can't be tracked
/// (cardmember-year credit on a card without an open date).
nonisolated struct CreditStatus: Identifiable, Sendable {
    let id: UUID
    let name: String
    let amount: Decimal
    let used: Decimal
    let period: CreditPeriod?

    var remaining: Decimal { max(amount - used, 0) }
}

/// Groups and totals for CR-1 (docs/ui/SCREENS.md "CR-1 Credits Dashboard").
nonisolated struct CreditDashboard: Sendable {
    private(set) var endsThisMonth: [CreditStatus] = []
    private(set) var later: [CreditStatus] = []
    private(set) var used: [CreditStatus] = []
    private(set) var needsOpenDate: [CreditStatus] = []

    /// Remaining across every tracked credit's current period.
    private(set) var totalAvailable: Decimal = 0
    /// Remaining on credits whose period ends this calendar month.
    private(set) var endingThisMonth: Decimal = 0
    /// Unused credits whose period ends within 7 days (the Credits tab badge).
    private(set) var dueSoonCount = 0
    /// The earliest reset among fully used credits.
    private(set) var nextReset: Date?

    var availableCount: Int { endsThisMonth.count + later.count }
    var isEmpty: Bool { availableCount + used.count + needsOpenDate.count == 0 }

    init(_ credits: [CreditStatus], now: Date, calendar: Calendar) {
        let thisMonth = calendar.dateInterval(of: .month, for: now)
        for credit in credits {
            guard let period = credit.period else {
                needsOpenDate.append(credit)
                continue
            }
            if credit.remaining == 0 {
                used.append(credit)
                nextReset = min(nextReset ?? period.end, period.end)
                continue
            }
            totalAvailable += credit.remaining
            if CreditPeriodCalculator.daysLeft(in: period, now: now, calendar: calendar) <= 7 { dueSoonCount += 1 }
            if let thisMonth, period.end <= thisMonth.end {
                endsThisMonth.append(credit)
                endingThisMonth += credit.remaining
            } else {
                later.append(credit)
            }
        }
        let order: (CreditStatus, CreditStatus) -> Bool = { a, b in
            if a.period?.end != b.period?.end { return (a.period?.end ?? .distantFuture) < (b.period?.end ?? .distantFuture) }
            if a.remaining != b.remaining { return a.remaining > b.remaining }
            return a.name < b.name
        }
        endsThisMonth.sort(by: order)
        later.sort(by: order)
        used.sort(by: order)
    }
}
