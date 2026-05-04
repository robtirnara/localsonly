import XCTest
import XCTVapor
@testable import App

final class RouteSmokeTests: XCTestCase {
    func testHealthRoute() throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        try configure(app)

        try app.test(.GET, "health") { response in
            XCTAssertEqual(response.status, .ok)
        }
    }
}
