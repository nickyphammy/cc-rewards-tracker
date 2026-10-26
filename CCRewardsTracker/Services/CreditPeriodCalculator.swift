import Foundation

/// One credit period, `start` inclusive and `end` exclusive. Both are local midnights on the 1st of a month.
nonisolated struct CreditPeriod: Hashable, Sendable {
    let start: Date
    let end: Date

    func contains(_ date: Date) -> Bool { start <= date && date < end }
}

/// Works out which period a credit is in (docs/DATA_MODEL.md "Derived values").
///
/// Every period is a block of whole months starting on the 1st:
/// - `calendar` basis: blocks aligned to Jan 1 (each month, Jan/Apr/Jul/Oct, Jan/Jul, each year).
///   Multi-year blocks start Jan 1 of the year the card was opened, or added if the open date is unknown.
/// - `cardmemberYear` basis: blocks start on the 1st of the card's open month (the anniversary month).
///   Without an open date the period is unknown and the credit is untracked (`nil`).
nonisolated enum CreditPeriodCalculator {
    static func months(in period: Period, years: Int? = nil) -> Int {
        switch period {
        case .monthly: 1
        case .quarterly: 3
        case .semiannual: 6
        case .annual: 12
        case .multiYear: 12 * max(years ?? 4, 1)
        }
    }

    static func period(
        containing date: Date,
        period: Period,
        years: Int? = nil,
        basis: ResetBasis,
        openedOn: Date?,
        addedAt: Date? = nil,
        calendar: Calendar
    ) -> CreditPeriod? {
        let length = months(in: period, years: years)
        let anchor: Date
        switch basis {
        case .cardmemberYear:
            guard let openedOn else { return nil }
            anchor = monthStart(of: openedOn, calendar: calendar)
        case .calendar:
            anchor = yearStart(of: period == .multiYear ? (openedOn ?? addedAt ?? date) : date, calendar: calendar)
        }
        let offset = monthIndex(of: date, calendar: calendar) - monthIndex(of: anchor, calendar: calendar)
        let blocks = Int((Double(offset) / Double(length)).rounded(.down))
        guard let start = calendar.date(byAdding: .month, value: blocks * length, to: anchor),
              let end = calendar.date(byAdding: .month, value: length, to: start) else { return nil }
        return CreditPeriod(start: start, end: end)
    }

    /// The final calendar day of the period ("Oct 31").
    static func lastDay(of period: CreditPeriod, calendar: Calendar) -> Date {
        calendar.date(byAdding: .day, value: -1, to: period.end) ?? period.end
    }

    /// Whole days from today to the period's last day: 0 = ends today, 1 = ends tomorrow.
    static func daysLeft(in period: CreditPeriod, now: Date, calendar: Calendar) -> Int {
        let today = calendar.startOfDay(for: now)
        return calendar.dateComponents([.day], from: today, to: lastDay(of: period, calendar: calendar)).day ?? 0
    }

    private static func monthIndex(of date: Date, calendar: Calendar) -> Int {
        let c = calendar.dateComponents([.year, .month], from: date)
        return (c.year ?? 0) * 12 + (c.month ?? 1) - 1
    }

    private static func monthStart(of date: Date, calendar: Calendar) -> Date {
        calendar.date(from: calendar.dateComponents([.year, .month], from: date)) ?? date
    }

    private static func yearStart(of date: Date, calendar: Calendar) -> Date {
        calendar.date(from: calendar.dateComponents([.year], from: date)) ?? date
    }
}
