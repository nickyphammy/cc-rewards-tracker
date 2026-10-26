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
