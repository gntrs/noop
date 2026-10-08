import XCTest
@testable import StrandImport

final class GarminSourceTests: XCTestCase {
    func testGarminConnectIsGarmin() {
        XCTAssertTrue(GarminSource.isGarmin(bundleId: "com.garmin.connect.mobile"))
    }

    func testCaseInsensitive() {
        XCTAssertTrue(GarminSource.isGarmin(bundleId: "COM.Garmin.Connect.Mobile"))
    }

    func testOtherSourcesAreNot() {
        for id in ["com.apple.health", "com.apple.Health.9C7D", "com.example.noop", "com.ouraring.oura",
                   "com.garminx.fake", "garmin.com", ""] {
            XCTAssertFalse(GarminSource.isGarmin(bundleId: id), id)
        }
    }
}
