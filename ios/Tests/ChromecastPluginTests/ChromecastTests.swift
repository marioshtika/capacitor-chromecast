import XCTest
@testable import ChromecastPlugin

final class ChromecastTests: XCTestCase {
    func testValidReceiverApplicationIdIsNormalized() throws {
        XCTAssertEqual(try Chromecast.validateReceiverApplicationId(" cc1ad845 "), "CC1AD845")
    }

    func testInvalidReceiverApplicationIdThrows() {
        XCTAssertThrowsError(try Chromecast.validateReceiverApplicationId("invalid"))
    }
}
