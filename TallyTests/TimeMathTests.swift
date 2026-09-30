import XCTest

final class TimeMathTests: XCTestCase {
    let cal = TS.calendar()

    // T-3.1
    func testFirstDayOfYear() {
        let y = YearProgress(now: TS.date(2026, 1, 1), calendar: cal)
        XCTAssertEqual(y.dayOfYear, 1)
        XCTAssertEqual(y.daysInYear, 365)
        XCTAssertEqual(y.daysLeft, 364)
    }

    // T-3.2
    func testLeapYear() {
        let y = YearProgress(now: TS.date(2028, 3, 1), calendar: cal)
        XCTAssertEqual(y.daysInYear, 366)
        XCTAssertEqual(y.dayOfYear, 61)
    }

    // T-3.3
    func testLastDayOfYear() {
        let y = YearProgress(now: TS.date(2026, 12, 31), calendar: cal)
        XCTAssertEqual(y.daysLeft, 0)
        XCTAssertEqual(y.percent, 100)
    }

    // T-3.4
    func testLifeWeeks() {
        let birth = TS.date(2000, 1, 1)
        let l = LifeProgress(birth: birth, expectancy: 80, now: TS.date(2000, 1, 15), calendar: cal)
        XCTAssertEqual(l.totalWeeks, 80 * 52)
        XCTAssertEqual(l.livedWeeks, 2)
        let over = LifeProgress(birth: birth, expectancy: 1, now: TS.date(2030, 1, 1), calendar: cal)
        XCTAssertEqual(over.livedWeeks, over.totalWeeks, "기대 수명을 넘기면 가득 참")
        XCTAssertEqual(over.weeksLeft, 0)
    }

    // T-3.5
    func testDDayLabels() {
        let now = TS.date(2026, 10, 1, hour: 23)
        XCTAssertEqual(DDayMath.label(TS.date(2026, 10, 4, hour: 1), now: now, calendar: cal), "D-3")
        XCTAssertEqual(DDayMath.label(TS.date(2026, 10, 1, hour: 0), now: now, calendar: cal), "D-Day")
        XCTAssertEqual(DDayMath.label(TS.date(2026, 9, 29), now: now, calendar: cal), "D+2")
    }

    @MainActor
    func testWallpaperRenders() {
        let img = Wallpaper.render(kind: .year, size: CGSize(width: 100, height: 200), scale: 1)
        XCTAssertEqual(img?.size, CGSize(width: 100, height: 200))
    }
}
