import Foundation
import Testing
@testable import CCRewardsTracker

/// CR-1 grouping and totals (docs/ui/SCREENS.md "CR-1 Credits Dashboard"), pinned to Oct 26, 2026.
struct CreditDashboardTests {
    let calendar = CreditPeriodCalculatorTests.calendar
    let now = CreditPeriodCalculatorTests.date(2026, 10, 26)

    private func status(_ name: String, _ amount: Decimal, used: Decimal = 0, _ period: Period?) -> CreditStatus {
        let p = period.flatMap {
            CreditPeriodCalculator.period(containing: now, period: $0, basis: .calendar, openedOn: nil, calendar: calendar)
        }
        return CreditStatus(id: UUID(), name: name, amount: amount, used: used, period: p)
    }

    @Test func groupsAndTotals() {
        let dashboard = CreditDashboard([
            status("Resy Credit", 50, .semiannual),
            status("Dining Credit", 10, .monthly),
            status("Uber Cash", 10, used: 6, .monthly),
            status("Dunkin' Credit", 7, used: 7, .monthly),
            status("Hotel Credit", 100, nil),
        ], now: now, calendar: calendar)

        #expect(dashboard.endsThisMonth.map(\.name) == ["Dining Credit", "Uber Cash"])
        #expect(dashboard.later.map(\.name) == ["Resy Credit"])
        #expect(dashboard.used.map(\.name) == ["Dunkin' Credit"])
        #expect(dashboard.needsOpenDate.map(\.name) == ["Hotel Credit"])
        #expect(dashboard.totalAvailable == 64)
        #expect(dashboard.endingThisMonth == 14)
        #expect(dashboard.availableCount == 3)
        #expect(dashboard.dueSoonCount == 2)
        #expect(dashboard.nextReset == CreditPeriodCalculatorTests.date(2026, 11, 1, 0))
    }

    @Test func allUsed() {
        let dashboard = CreditDashboard([status("Dining Credit", 10, used: 10, .monthly)], now: now, calendar: calendar)
        #expect(dashboard.totalAvailable == 0)
        #expect(dashboard.availableCount == 0)
        #expect(!dashboard.isEmpty)
    }

    @Test func empty() {
        #expect(CreditDashboard([], now: now, calendar: calendar).isEmpty)
    }
}

/// CR-3 validation (docs/ui/SCREENS.md "CR-3 Log Usage").
struct LogUsageValidationTests {
    @Test func validation() {
        #expect(LogUsageView.validate("", remaining: 10) == .empty)
        #expect(LogUsageView.validate("0", remaining: 10) == .empty)
        #expect(LogUsageView.validate("0.00", remaining: 10) == .empty)
        #expect(LogUsageView.validate("10.01", remaining: 10) == .overRemaining)
        #expect(LogUsageView.validate("6", remaining: 10) == .valid(6))
        #expect(LogUsageView.validate("10", remaining: 10) == .valid(10))
        #expect(LogUsageView.validate("1", remaining: 0) == .overRemaining)
    }
}
