import Foundation
import SwiftData

extension Credit {
    /// The period containing `now`, or nil for a cardmember-year credit on a card without an open date.
    func period(containing now: Date, calendar: Calendar = .current) -> CreditPeriod? {
        CreditPeriodCalculator.period(containing: now, period: period, years: periodYears, basis: resetBasis,
                                      openedOn: card?.openedOn, addedAt: card?.addedAt, calendar: calendar)
    }

    /// Usage logged against `period`. Matched by range rather than exact start so a time-zone change
    /// doesn't orphan past entries.
    func usages(in period: CreditPeriod) -> [CreditUsage] {
        (usages ?? []).filter { period.contains($0.periodStart) }.sorted { $0.loggedAt > $1.loggedAt }
    }

    func used(in period: CreditPeriod) -> Decimal {
        usages(in: period).reduce(0) { $0 + $1.amountUsed }
    }

    func remaining(in period: CreditPeriod) -> Decimal {
        max(amount - used(in: period), 0)
    }

    /// The current period first, then earlier ones, back to the period the card was added in.
    func history(now: Date, calendar: Calendar = .current) -> [CreditPeriod] {
        guard var current = period(containing: now, calendar: calendar) else { return [] }
        let earliest = min(card?.addedAt ?? now, (usages ?? []).map(\.periodStart).min() ?? now)
        var periods = [current]
        while current.start > earliest,
              let previous = period(containing: current.start.addingTimeInterval(-1), calendar: calendar) {
            periods.append(previous)
            current = previous
        }
        return periods
    }

    /// Logs `amount` against the period containing `date`.
    @discardableResult
    func logUsage(_ amount: Decimal, on date: Date, note: String? = nil, calendar: Calendar = .current) -> CreditUsage? {
        guard amount > 0, let period = period(containing: date, calendar: calendar) else { return nil }
        let usage = CreditUsage(periodStart: period.start, amountUsed: amount)
        usage.loggedAt = date
        usage.note = note
        usages = (usages ?? []) + [usage]
        return usage
    }

    /// Logs whatever is left this period. Returns the amount logged (0 if nothing was left).
    @discardableResult
    func markUsed(now: Date, calendar: Calendar = .current) -> Decimal {
        guard let period = period(containing: now, calendar: calendar) else { return 0 }
        let left = remaining(in: period)
        logUsage(left, on: now, calendar: calendar)
        return left
    }

    var needsEnrollment: Bool { requiresEnrollment && !isEnrolled }

    func status(now: Date, calendar: Calendar = .current) -> CreditStatus {
        let current = period(containing: now, calendar: calendar)
        return CreditStatus(id: id, name: name, amount: amount, used: current.map(used(in:)) ?? 0, period: current)
    }
}
