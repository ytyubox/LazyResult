import XCTest
@testable import LazyResult

final class LazyResultTests: XCTestCase {
    func testLazyResultisLazy() {
		var target:Int? = nil
		var lazyResult = LazyResult<Int, Error> { () -> Int in
			let success = 1
			target = success
			return success
		}
		XCTAssertNil(target)
		let successValue = try! lazyResult.get()
		XCTAssertEqual(target, successValue)
    }

    static var allTests = [
        ("testLazyResultisLazy", testLazyResultisLazy),
    ]
}
