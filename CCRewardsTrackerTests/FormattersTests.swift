import Foundation
import Testing
@testable import CCRewardsTracker

struct FormattersTests {
    @Test(arguments: [
        (Decimal(4), RateUnit.multiplier, "4x"),
        (Decimal(string: "1.5")!, .multiplier, "1.5x"),
        (Decimal(3), .percent, "3%"),
        (Decimal(string: "2.25")!, .percent, "2.25%"),
        (Decimal(string: "2.50")!, .percent, "2.5%"),
    ])
    func shortRate(rate: Decimal, unit: RateUnit, expected: String) {
        #expect(Formatters.rate(rate, unit: unit) == expected)
    }

    @Test func fullRate() {
        #expect(Formatters.rateFull(4, unit: .multiplier, unitName: "points") == "4x points")
        #expect(Formatters.rateFull(2, unit: .multiplier, unitName: "miles") == "2x miles")
        #expect(Formatters.rateFull(3, unit: .percent, unitName: "points") == "3% cash back")
    }

    @Test func estimates() {
        #expect(Formatters.estimate(amount: Decimal(string: "85.40")!, rate: 4, unit: .multiplier, unitName: "points") == "earns ~342 points")
        #expect(Formatters.estimate(amount: Decimal(string: "85.40")!, rate: 3, unit: .percent, unitName: "cash back") == "~$2.56 back")
        #expect(Formatters.estimate(amount: 1000, rate: 5, unit: .multiplier, unitName: "points") == "earns ~5,000 points")
    }

    @Test func money() {
        #expect(Formatters.money(10) == "$10")
        #expect(Formatters.money(325) == "$325")
        #expect(Formatters.money(Decimal(string: "12.95")!) == "$12.95")
        #expect(Formatters.money(25000) == "$25,000")
    }

    @Test func feeLine() {
        #expect(Formatters.feeLine(annualFee: 325, membershipMonthly: nil, membershipAnnual: nil) == "$325/yr")
        #expect(Formatters.feeLine(annualFee: 0, membershipMonthly: 5, membershipAnnual: 50) == "$5/mo membership")
        #expect(Formatters.feeLine(annualFee: 0, membershipMonthly: nil, membershipAnnual: nil) == "No annual fee")
    }

    @Test func capAndQuarter() {
        #expect(Formatters.cap(rate: 4, unit: .multiplier, amount: 25000, period: .annual, afterCapRate: 1) == "4x up to $25,000 a year, then 1x")
        #expect(Formatters.quarter("2026Q4") == "Q4 2026")
        let oct = Calendar(identifier: .gregorian).date(from: DateComponents(year: 2026, month: 10, day: 26))!
        #expect(Quarter.key(for: oct, calendar: Calendar(identifier: .gregorian)) == "2026Q4")
    }
}

struct AmountFieldTests {
    @Test(arguments: ["", "8", "85.4", "85.40", "999999.99", ".", "0."])
    func allowed(_ text: String) {
        #expect(AmountField.isAllowed(text))
    }

    @Test(arguments: ["85.401", "1.2.3", "abc", "-5", "1000000"])
    func rejected(_ text: String) {
        #expect(!AmountField.isAllowed(text))
    }

    @Test func commaDecimalSeparatorBecomesAPoint() {
        #expect(AmountField.accept(old: "12", new: "12,") == "12.")
        #expect(AmountField.accept(old: "12.9", new: "12.95") == "12.95")
        #expect(AmountField.accept(old: "12,9", new: "12,95") == "12.95")
        #expect(AmountField.accept(old: "12.9", new: "12.9,") == "12.9")
        #expect(AmountField.accept(old: "12.95", new: "12.951") == "12.95")
    }
}
