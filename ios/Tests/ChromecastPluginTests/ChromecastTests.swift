import XCTest
@testable import ChromecastPlugin

final class ChromecastTests: XCTestCase {
    func testValidReceiverApplicationIdIsNormalized() throws {
        XCTAssertEqual(try Chromecast.validateReceiverApplicationId(" cc1ad845 "), "CC1AD845")
    }

    func testInvalidReceiverApplicationIdThrows() {
        XCTAssertThrowsError(try Chromecast.validateReceiverApplicationId("invalid"))
    }

    func testLoadMediaRejectsInvalidUrl() {
        let chromecast = Chromecast()

        XCTAssertThrowsError(try chromecast.loadMedia(url: "invalid-url", configuredReceiverApplicationId: nil) { _ in
            XCTFail("loadMedia completion should not be called for invalid URL.")
        }) { error in
            XCTAssertEqual(error as? ChromecastPluginError, .invalidMediaUrl)
        }
    }

    func testLoadMediaWithoutInitializationThrows() {
        let chromecast = Chromecast()

        XCTAssertThrowsError(try chromecast.loadMedia(url: "https://example.com/video.mp4", configuredReceiverApplicationId: nil) { _ in
            XCTFail("loadMedia completion should not be called when Chromecast is not initialized.")
        }) { error in
            XCTAssertEqual(error as? ChromecastPluginError, .notInitialized)
        }
    }

    func testLoadMediaWithoutConnectedSessionThrows() {
        let chromecast = Chromecast()

        XCTAssertThrowsError(try chromecast.loadMedia(url: "https://example.com/video.mp4", configuredReceiverApplicationId: "CC1AD845") { _ in
            XCTFail("loadMedia completion should not be called when no Cast session is connected.")
        }) { error in
            XCTAssertEqual(error as? ChromecastPluginError, .castSessionNotConnected)
        }
    }
}
