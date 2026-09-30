import XCTest

extension XCUIElement {
    /// 요소가 사라질 때까지 기다린다
    @discardableResult
    func waitForDisappearance(timeout: TimeInterval = 3) -> Bool {
        let exp = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: self)
        return XCTWaiter().wait(for: [exp], timeout: timeout) == .completed
    }
}
