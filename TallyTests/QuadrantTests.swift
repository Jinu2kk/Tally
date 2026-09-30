import XCTest

final class QuadrantTests: XCTestCase {
    // T-2.1
    func testRawValueRoundTripAndLabels() {
        for q in Quadrant.allCases {
            XCTAssertEqual(Quadrant(rawValue: q.rawValue), q)
            XCTAssertFalse(q.title.isEmpty)
            XCTAssertFalse(q.subtitle.isEmpty)
        }
        XCTAssertEqual(Quadrant.allCases.map(\.code), ["Q1", "Q2", "Q3", "Q4"])
        let t = TaskItem(title: "x", quadrant: .delegate)
        XCTAssertEqual(t.quadrantRaw, 2)
        t.quadrantRaw = 99
        XCTAssertEqual(t.quadrant, .doFirst, "알 수 없는 값은 Q1으로")
    }
}
