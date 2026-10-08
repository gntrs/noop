import XCTest
@testable import WhoopStore

final class SleepGapFillTests: XCTestCase {
    private func s(_ start: Int, _ end: Int, _ dev: String) -> CachedSleepSession {
        CachedSleepSession(startTs: start, endTs: end, efficiency: nil, restingHr: nil, avgHrv: nil,
                           stagesJSON: nil, deviceId: dev)
    }
    private func day(_ x: CachedSleepSession) -> String { String(x.endTs / 86_400) }
    let d = 86_400

    func testWhoopNightBeatsGarminSameNight() {
        let out = SleepGapFill.fill(primary: [s(d - 3600, d + 7 * 3600, "whoop")],
                                    filler: [s(d - 3000, d + 7 * 3600, "garmin")], endDay: day)
        XCTAssertEqual(out.map(\.deviceId), ["whoop"])
    }

    func testGarminFillsAMissingNight() {
        let out = SleepGapFill.fill(primary: [s(d - 3600, d + 7 * 3600, "whoop")],
                                    filler: [s(2 * d - 3600, 2 * d + 7 * 3600, "garmin")], endDay: day)
        XCTAssertEqual(out.map(\.deviceId), ["whoop", "garmin"])
    }

    func testOverlapAcrossDayKeysIsStillDropped() {
        // Garmin's night ends a day later but overlaps the WHOOP night: same sleep, keep the WHOOP.
        let out = SleepGapFill.fill(primary: [s(d - 3600, d + 7 * 3600, "whoop")],
                                    filler: [s(d + 6 * 3600, 2 * d + 100, "garmin")], endDay: day)
        XCTAssertEqual(out.map(\.deviceId), ["whoop"])
    }

    func testTouchingIsNotOverlap() {
        let out = SleepGapFill.fill(primary: [s(d - 3600, d + 3600, "whoop")],
                                    filler: [s(d + 3600, 2 * d + 10, "garmin")], endDay: day)
        XCTAssertEqual(out.count, 2)
    }

    func testEmptySides() {
        XCTAssertEqual(SleepGapFill.fill(primary: [], filler: [], endDay: day).count, 0)
        XCTAssertEqual(SleepGapFill.fill(primary: [], filler: [s(0, 100, "garmin")], endDay: day).count, 1)
        XCTAssertEqual(SleepGapFill.fill(primary: [s(0, 100, "whoop")], filler: [], endDay: day).count, 1)
    }

    func testResultIsSortedByStart() {
        let out = SleepGapFill.fill(primary: [s(5 * d, 5 * d + 100, "whoop")],
                                    filler: [s(2 * d, 2 * d + 100, "garmin")], endDay: day)
        XCTAssertEqual(out.map(\.startTs), [2 * d, 5 * d])
    }
}
