import Foundation
import SwiftData
import Testing
@testable import CCRewardsTracker

/// Pinned dates in a fixed calendar and time zone (docs/ROADMAP.md M3).
struct CreditPeriodCalculatorTests {
    static let calendar: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "America/New_York")!
        return c
    }()

    static func date(_ y: Int, _ m: Int, _ d: Int, _ h: Int = 12, _ min: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: y, month: m, day: d, hour: h, minute: min))!
    }

    private func period(_ date: Date, _ period: Period, years: Int? = nil, basis: ResetBasis = .calendar,
                        openedOn: Date? = nil, addedAt: Date? = nil) -> CreditPeriod? {
        CreditPeriodCalculator.period(containing: date, period: period, years: years, basis: basis,
                                      openedOn: openedOn, addedAt: addedAt, calendar: Self.calendar)
    }

    private func expect(_ p: CreditPeriod?, from start: Date, to end: Date, sourceLocation: SourceLocation = #_sourceLocation) {
        #expect(p == CreditPeriod(start: start, end: end), sourceLocation: sourceLocation)
    }

    private func midnight(_ y: Int, _ m: Int, _ d: Int = 1) -> Date { Self.date(y, m, d, 0) }

    @Test func monthlyIncludesTheLastMinuteOfTheMonth() {
        expect(period(Self.date(2026, 10, 31, 23, 59), .monthly), from: midnight(2026, 10), to: midnight(2026, 11))
        expect(period(midnight(2026, 11), .monthly), from: midnight(2026, 11), to: midnight(2026, 12))
        expect(period(Self.date(2026, 12, 31), .monthly), from: midnight(2026, 12), to: midnight(2027, 1))
    }

    @Test func leapYearFebruary() {
        let feb2028 = period(Self.date(2028, 2, 29), .monthly)
        expect(feb2028, from: midnight(2028, 2), to: midnight(2028, 3))
        #expect(CreditPeriodCalculator.lastDay(of: feb2028!, calendar: Self.calendar) == midnight(2028, 2, 29))
        let feb2027 = period(Self.date(2027, 2, 14), .monthly)!
        #expect(CreditPeriodCalculator.lastDay(of: feb2027, calendar: Self.calendar) == midnight(2027, 2, 28))
    }

    @Test func calendarQuartersHalvesAndYears() {
        expect(period(Self.date(2026, 11, 15), .quarterly), from: midnight(2026, 10), to: midnight(2027, 1))
        expect(period(Self.date(2026, 3, 31, 23, 59), .quarterly), from: midnight(2026, 1), to: midnight(2026, 4))
        expect(period(Self.date(2026, 6, 30, 23, 59), .semiannual), from: midnight(2026, 1), to: midnight(2026, 7))
        expect(period(midnight(2026, 7), .semiannual), from: midnight(2026, 7), to: midnight(2027, 1))
        expect(period(Self.date(2026, 10, 26), .annual), from: midnight(2026, 1), to: midnight(2027, 1))
    }

    @Test func cardmemberYearResetsOnTheAnniversaryMonth() {
        let opened = Self.date(2023, 3, 15)
        expect(period(Self.date(2026, 10, 26), .annual, basis: .cardmemberYear, openedOn: opened),
               from: midnight(2026, 3), to: midnight(2027, 3))
        expect(period(Self.date(2026, 2, 28, 23, 59), .annual, basis: .cardmemberYear, openedOn: opened),
               from: midnight(2025, 3), to: midnight(2026, 3))
        expect(period(midnight(2026, 3), .annual, basis: .cardmemberYear, openedOn: opened),
               from: midnight(2026, 3), to: midnight(2027, 3))
    }

    @Test func cardOpenedOnLeapDay() {
        let opened = Self.date(2024, 2, 29)
        expect(period(Self.date(2025, 3, 10), .annual, basis: .cardmemberYear, openedOn: opened),
               from: midnight(2025, 2), to: midnight(2026, 2))
    }

    @Test func cardmemberYearWithoutOpenDateIsUntracked() {
        #expect(period(Self.date(2026, 10, 26), .annual, basis: .cardmemberYear, openedOn: nil) == nil)
    }

    @Test func multiYear() {
        let opened = Self.date(2023, 3, 15)
        expect(period(Self.date(2026, 10, 26), .multiYear, years: 4, basis: .cardmemberYear, openedOn: opened),
               from: midnight(2023, 3), to: midnight(2027, 3))
        expect(period(midnight(2027, 3), .multiYear, years: 4, basis: .cardmemberYear, openedOn: opened),
               from: midnight(2027, 3), to: midnight(2031, 3))
        // Calendar multi-year blocks start Jan 1 of the year the card was added when there's no open date.
        expect(period(Self.date(2026, 10, 26), .multiYear, years: 4, addedAt: Self.date(2026, 6, 1)),
               from: midnight(2026, 1), to: midnight(2030, 1))
    }

    @Test func dateBeforeTheAnchorStillFindsItsPeriod() {
        let opened = Self.date(2027, 3, 1)
        expect(period(Self.date(2026, 10, 26), .annual, basis: .cardmemberYear, openedOn: opened),
               from: midnight(2026, 3), to: midnight(2027, 3))
    }

    @Test func daysLeft() {
        let october = period(Self.date(2026, 10, 1), .monthly)!
        #expect(CreditPeriodCalculator.daysLeft(in: october, now: Self.date(2026, 10, 26, 9), calendar: Self.calendar) == 5)
        #expect(CreditPeriodCalculator.daysLeft(in: october, now: Self.date(2026, 10, 31, 23, 59), calendar: Self.calendar) == 0)
    }

    @Test func formatting() {
        let c = Self.calendar
        let now = Self.date(2026, 10, 26)
        let october = period(now, .monthly)!
        #expect(Formatters.ends(october, now: now, calendar: c) == "Ends in 5 days")
        #expect(Formatters.ends(october, now: Self.date(2026, 10, 30), calendar: c) == "Ends tomorrow")
        #expect(Formatters.ends(october, now: Self.date(2026, 10, 31), calendar: c) == "Ends today")
        #expect(Formatters.ends(period(now, .semiannual)!, now: now, calendar: c) == "Ends Dec 31")
        let cardmember = period(now, .annual, basis: .cardmemberYear, openedOn: Self.date(2023, 3, 15))!
        #expect(Formatters.ends(cardmember, now: now, calendar: c) == "Ends Feb 28, 2027")

        #expect(Formatters.span(october, calendar: c) == "Oct 1 – Oct 31, 2026")
        #expect(Formatters.span(cardmember, calendar: c) == "Mar 1, 2026 – Feb 28, 2027")

        #expect(Formatters.periodName(october, calendar: c) == "October 2026")
        #expect(Formatters.periodName(period(now, .annual)!, calendar: c) == "2026")
        #expect(Formatters.periodName(period(now, .semiannual)!, calendar: c) == "Jul – Dec 2026")
        #expect(Formatters.periodName(cardmember, calendar: c) == "Mar 2026 – Feb 2027")
        #expect(Formatters.periodName(period(now, .multiYear, years: 4, addedAt: now)!, calendar: c) == "2026 – 2029")

        #expect(Formatters.resetRule(period: .monthly, years: nil, basis: .calendar, openedOn: nil, calendar: c)
                == "Resets on the 1st of each month")
        #expect(Formatters.resetRule(period: .annual, years: nil, basis: .cardmemberYear, openedOn: Self.date(2023, 3, 15), calendar: c)
                == "Resets on your card anniversary (Mar 1)")
    }
}

@MainActor
struct CreditTrackingTests {
    let container = try! ModelContainer(
        for: UserCard.self, Multiplier.self, Credit.self, CreditUsage.self, CategorySelection.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let calendar = CreditPeriodCalculatorTests.calendar
    let date = CreditPeriodCalculatorTests.date

    private func goldDiningCredit() throws -> Credit {
        let template = try #require(try CatalogStore.bundled().card(id: "amex_gold"))
        let card = CardFactory.addCard(from: template, sortIndex: 0, to: container.mainContext)
        card.addedAt = date(2026, 8, 20, 12, 0)
        return try #require(card.activeCredits.first { $0.period == .monthly && $0.amount == 10 })
    }

    @Test func partialThenFullUse() throws {
        let credit = try goldDiningCredit()
        let now = date(2026, 10, 26, 12, 0)
        let october = try #require(credit.period(containing: now, calendar: calendar))
        #expect(credit.remaining(in: october) == 10)

        credit.logUsage(6, on: now, calendar: calendar)
        #expect(credit.remaining(in: october) == 4)
        #expect(credit.markUsed(now: now, calendar: calendar) == 4)
        #expect(credit.remaining(in: october) == 0)
        #expect(credit.markUsed(now: now, calendar: calendar) == 0)
        #expect(credit.usages(in: october).count == 2)
    }

    @Test func rollsOverOnTheFirst() throws {
        let credit = try goldDiningCredit()
        credit.markUsed(now: date(2026, 10, 14, 12, 0), calendar: calendar)
        let november = try #require(credit.period(containing: date(2026, 11, 1, 0, 0), calendar: calendar))
        #expect(credit.remaining(in: november) == 10)
    }

    @Test func historyGoesBackToWhenTheCardWasAdded() throws {
        let credit = try goldDiningCredit()
        credit.logUsage(10, on: date(2026, 9, 14, 12, 0), calendar: calendar)
        let history = credit.history(now: date(2026, 10, 26, 12, 0), calendar: calendar)
        #expect(history.map { Formatters.periodName($0, calendar: calendar) } == ["October 2026", "September 2026", "August 2026"])
        #expect(credit.used(in: history[1]) == 10)
        #expect(credit.used(in: history[2]) == 0)
    }

    @Test func usageStaysInItsPeriodAfterATimeZoneMove() throws {
        var newYork = Calendar(identifier: .gregorian)
        newYork.timeZone = TimeZone(identifier: "America/New_York")!
        var losAngeles = newYork
        losAngeles.timeZone = TimeZone(identifier: "America/Los_Angeles")!
        var tokyo = newYork
        tokyo.timeZone = TimeZone(identifier: "Asia/Tokyo")!

        let credit = try goldDiningCredit()
        credit.markUsed(now: date(2026, 10, 14, 12, 0), calendar: newYork)
        let later = date(2026, 10, 20, 12, 0)
        for calendar in [losAngeles, tokyo] {
            let october = try #require(credit.period(containing: later, calendar: calendar))
            #expect(credit.remaining(in: october) == 0, "\(calendar.timeZone.identifier)")
            let september = try #require(credit.period(containing: date(2026, 9, 20, 12, 0), calendar: calendar))
            #expect(credit.used(in: september) == 0, "\(calendar.timeZone.identifier)")
        }
    }

    /// Asunción skipped midnight on Oct 1, 2023 (DST began at 00:00), so that period starts at 01:00.
    @Test func historyEndsInAZoneThatSkipsMidnightOnTheFirst() throws {
        var asuncion = Calendar(identifier: .gregorian)
        asuncion.timeZone = TimeZone(identifier: "America/Asuncion")!
        let credit = try goldDiningCredit()
        credit.card?.addedAt = asuncion.date(from: DateComponents(year: 2023, month: 9, day: 15))!
        let now = asuncion.date(from: DateComponents(year: 2023, month: 11, day: 15))!
        let names = credit.history(now: now, calendar: asuncion).map { Formatters.periodName($0, calendar: asuncion) }
        #expect(names == ["November 2023", "October 2023", "September 2023"])
    }

    @Test func deletingAnEntryRestoresTheAmount() throws {
        let credit = try goldDiningCredit()
        let now = date(2026, 10, 26, 12, 0)
        let usage = try #require(credit.logUsage(6, on: now, calendar: calendar))
        container.mainContext.delete(usage)
        try container.mainContext.save()
        let october = try #require(credit.period(containing: now, calendar: calendar))
        #expect(credit.remaining(in: october) == 10)
    }
}
