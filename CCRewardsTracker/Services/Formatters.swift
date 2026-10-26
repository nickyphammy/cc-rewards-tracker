import Foundation

/// All user-facing number formatting (docs/ui/DESIGN_SYSTEM.md "Formatting rules").
/// Views never build these strings by hand.
nonisolated enum Formatters {
    private static let locale = Locale(identifier: "en_US")

    /// "4", "1.5", "2.25": at most two decimals, trailing zeros dropped.
    static func number(_ value: Decimal) -> String {
        value.formatted(.number.precision(.fractionLength(0...2)).grouping(.never).locale(locale))
    }

    /// "4x" or "3%".
    static func rate(_ rate: Decimal, unit: RateUnit) -> String {
        number(rate) + (unit == .percent ? "%" : "x")
    }

    /// "4x points", "2x miles", "3% cash back".
    static func rateFull(_ rate: Decimal, unit: RateUnit, unitName: String) -> String {
        unit == .percent ? "\(number(rate))% cash back" : "\(number(rate))x \(unitName)"
    }

    /// "4 times points", "3 percent cash back".
    static func rateSpoken(_ rate: Decimal, unit: RateUnit, unitName: String) -> String {
        unit == .percent ? "\(number(rate)) percent cash back" : "\(number(rate)) times \(unitName)"
    }

    /// "earns ~342 points" or "~$2.56 back". Ignores caps (v1 doesn't track spend).
    static func estimate(amount: Decimal, rate: Decimal, unit: RateUnit, unitName: String) -> String {
        if unit == .percent {
            let dollars = rounded(amount * rate / 100, scale: 2)
            return "~\(money(dollars, alwaysCents: true)) back"
        }
        let points = rounded(amount * rate, scale: 0)
        return "earns ~\(points.formatted(.number.grouping(.automatic).locale(locale))) \(unitName)"
    }

    /// "$10", "$325", "$7.50". Pass `alwaysCents` for estimates ("$2.00").
    static func money(_ value: Decimal, alwaysCents: Bool = false) -> String {
        let whole = value == rounded(value, scale: 0)
        let digits = (whole && !alwaysCents) ? 0...0 : 2...2
        return value.formatted(.currency(code: "USD").precision(.fractionLength(digits)).locale(locale))
    }

    /// "$325/yr", "$5/mo membership", "No annual fee".
    static func feeLine(annualFee: Decimal, membershipMonthly: Decimal?, membershipAnnual: Decimal?) -> String {
        if annualFee > 0 { return "\(money(annualFee))/yr" }
        if let monthly = membershipMonthly { return "\(money(monthly))/mo membership" }
        if let annual = membershipAnnual { return "\(money(annual))/yr membership" }
        return "No annual fee"
    }

    /// "4x up to $25,000 a year, then 1x".
    static func cap(rate: Decimal, unit: RateUnit, amount: Decimal, period: Period, afterCapRate: Decimal) -> String {
        let word = switch period {
        case .monthly: "month"
        case .quarterly: "quarter"
        default: "year"
        }
        return "\(Formatters.rate(rate, unit: unit)) up to \(money(amount)) a \(word), then \(Formatters.rate(afterCapRate, unit: unit))"
    }

    /// "Monthly", "Every 6 months", "Every 4 years".
    static func period(_ period: Period, years: Int? = nil) -> String {
        switch period {
        case .monthly: "Monthly"
        case .quarterly: "Quarterly"
        case .semiannual: "Every 6 months"
        case .annual: "Yearly"
        case .multiYear: "Every \(years ?? 4) years"
        }
    }

    /// "2nd", "3rd".
    static func ordinal(_ n: Int) -> String {
        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.numberStyle = .ordinal
        return formatter.string(from: NSNumber(value: n)) ?? "\(n)"
    }

    /// "Q4 2026" from "2026Q4".
    static func quarter(_ key: String) -> String {
        let parts = key.split(separator: "Q")
        guard parts.count == 2 else { return key }
        return "Q\(parts[1]) \(parts[0])"
    }

    // MARK: Credit periods (docs/ui/DESIGN_SYSTEM.md "Periods and dates")

    /// "Ends today", "Ends tomorrow", "Ends in 5 days", else "Ends Dec 31" (year added if not this year).
    static func ends(_ period: CreditPeriod, now: Date, calendar: Calendar) -> String {
        switch CreditPeriodCalculator.daysLeft(in: period, now: now, calendar: calendar) {
        case ...0: "Ends today"
        case 1: "Ends tomorrow"
        case let days where days <= 7: "Ends in \(days) days"
        default: "Ends \(day(CreditPeriodCalculator.lastDay(of: period, calendar: calendar), now: now, calendar: calendar))"
        }
    }

    /// "Nov 1", or "Feb 28, 2027" when not in `now`'s year.
    static func day(_ date: Date, now: Date, calendar: Calendar) -> String {
        let sameYear = calendar.component(.year, from: date) == calendar.component(.year, from: now)
        let style = dateStyle(calendar).month(.abbreviated).day()
        return date.formatted(sameYear ? style : style.year())
    }

    /// "Oct 1 – Oct 31, 2026", or "Mar 1, 2026 – Feb 28, 2027" across years.
    static func span(_ period: CreditPeriod, calendar: Calendar) -> String {
        let last = CreditPeriodCalculator.lastDay(of: period, calendar: calendar)
        let monthDay = dateStyle(calendar).month(.abbreviated).day()
        let full = monthDay.year()
        if calendar.component(.year, from: period.start) == calendar.component(.year, from: last) {
            return "\(period.start.formatted(monthDay)) – \(last.formatted(full))"
        }
        return "\(period.start.formatted(full)) – \(last.formatted(full))"
    }

    /// History heading: "October 2026", "2026", "Jul – Dec 2026", "Mar 2026 – Feb 2027", "2024 – 2027".
    static func periodName(_ period: CreditPeriod, calendar: Calendar) -> String {
        let last = CreditPeriodCalculator.lastDay(of: period, calendar: calendar)
        let (startYear, endYear) = (calendar.component(.year, from: period.start), calendar.component(.year, from: last))
        let (startMonth, endMonth) = (calendar.component(.month, from: period.start), calendar.component(.month, from: last))
        let month = dateStyle(calendar).month(.abbreviated)
        if startYear == endYear && startMonth == endMonth {
            return period.start.formatted(dateStyle(calendar).month(.wide).year())
        }
        if startMonth == 1 && endMonth == 12 {
            return startYear == endYear ? "\(startYear)" : "\(startYear) – \(endYear)"
        }
        if startYear == endYear {
            return "\(period.start.formatted(month)) – \(last.formatted(month)) \(startYear)"
        }
        return "\(period.start.formatted(month.year())) – \(last.formatted(month.year()))"
    }

    /// Footer rule: "Resets on the 1st of each month", "Resets on your card anniversary (Mar 1)".
    static func resetRule(period: Period, years: Int?, basis: ResetBasis, openedOn: Date?, calendar: Calendar) -> String {
        if basis == .cardmemberYear {
            let anniversary = openedOn.map { " (\(anniversaryDay($0, calendar: calendar)))" } ?? ""
            switch period {
            case .multiYear: return "Every \(years ?? 4) years from your card anniversary\(anniversary)"
            case .annual: return "Resets on your card anniversary\(anniversary)"
            default: return "\(Formatters.period(period, years: years)), counted from your card anniversary\(anniversary)"
            }
        }
        return switch period {
        case .monthly: "Resets on the 1st of each month"
        case .quarterly: "Resets Jan 1, Apr 1, Jul 1 and Oct 1"
        case .semiannual: "Resets Jan 1 and Jul 1"
        case .annual: "Resets Jan 1"
        case .multiYear: "Resets every \(years ?? 4) years on Jan 1"
        }
    }

    /// The anniversary is the 1st of the open month (cardmember periods start on the 1st).
    private static func anniversaryDay(_ openedOn: Date, calendar: Calendar) -> String {
        var c = calendar.dateComponents([.year, .month], from: openedOn)
        c.day = 1
        return (calendar.date(from: c) ?? openedOn).formatted(dateStyle(calendar).month(.abbreviated).day())
    }

    private static func dateStyle(_ calendar: Calendar) -> Date.FormatStyle {
        Date.FormatStyle(locale: locale, calendar: calendar, timeZone: calendar.timeZone)
    }

    private static func rounded(_ value: Decimal, scale: Int) -> Decimal {
        var input = value
        var result = Decimal()
        NSDecimalRound(&result, &input, scale, .plain)
        return result
    }
}

nonisolated enum Quarter {
    /// "2026Q4" for a date in Oct–Dec 2026.
    static func key(for date: Date, calendar: Calendar = .current) -> String {
        let c = calendar.dateComponents([.year, .month], from: date)
        return "\(c.year ?? 0)Q\(((c.month ?? 1) - 1) / 3 + 1)"
    }
}
