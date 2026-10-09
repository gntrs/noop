import XCTest
@testable import StrandAnalytics

final class SwimMathTests: XCTestCase {
    func testDistance_prefersTypedDistance() {
        XCTAssertEqual(SwimMath.distance(.init(poolM: 25, lengths: 80, distanceM: 1500)), 1500)
    }

    func testDistance_fromLengths() {
        XCTAssertEqual(SwimMath.distance(.init(poolM: 25, lengths: 60)), 1500)
        XCTAssertEqual(SwimMath.distance(.init(poolM: 50, lengths: 30)), 1500)
    }

    func testDistance_nothingUsable() {
        XCTAssertNil(SwimMath.distance(.init(poolM: 25)))
        XCTAssertNil(SwimMath.distance(.init(poolM: 25, lengths: 0)))
        XCTAssertNil(SwimMath.distance(.init(poolM: 25, lengths: -3)))
        XCTAssertNil(SwimMath.distance(.init(poolM: 0, lengths: 10)))
        XCTAssertNil(SwimMath.distance(.init(poolM: 25, distanceM: 0)))
        XCTAssertNil(SwimMath.distance(.init(poolM: .nan, lengths: 10)))
        XCTAssertEqual(SwimMath.distance(.init(poolM: 25, lengths: 4, distanceM: .infinity)), 100,
                       "a non finite typed distance falls back to lengths")
    }

    func testLengths_roundsToNearest() {
        XCTAssertEqual(SwimMath.lengths(distanceM: 3315, poolM: 22.86), 145)
        XCTAssertEqual(SwimMath.lengths(distanceM: 1510, poolM: 25), 60)
        XCTAssertNil(SwimMath.lengths(distanceM: nil, poolM: 25))
        XCTAssertNil(SwimMath.lengths(distanceM: 1000, poolM: 0))
    }

    func testPace() {
        XCTAssertEqual(SwimMath.secPer100(distanceM: 1500, durationS: 1800), 120)
        XCTAssertNil(SwimMath.secPer100(distanceM: 0, durationS: 1800))
        XCTAssertNil(SwimMath.secPer100(distanceM: 1500, durationS: nil))
        XCTAssertNil(SwimMath.secPer100(distanceM: 1500, durationS: 0))
    }

    func testStrokeRates() {
        XCTAssertEqual(SwimMath.strokesPerMinute(strokes: 900, durationS: 1800), 30)
        XCTAssertNil(SwimMath.strokesPerMinute(strokes: 0, durationS: 1800))
        XCTAssertNil(SwimMath.strokesPerMinute(strokes: 900, durationS: 0))
        XCTAssertEqual(SwimMath.strokesPerLength(strokes: 900, lengths: 60), 15)
        XCTAssertNil(SwimMath.strokesPerLength(strokes: 900, lengths: 0))
        XCTAssertNil(SwimMath.strokesPerLength(strokes: nil, lengths: 60))
    }

    func testLooksOff_theOct6Swim() {
        // 3315 m in 2384 s is 1:12 per 100 m with rests: borderline, not flagged.
        XCTAssertFalse(SwimMath.looksOff(distanceM: 3315, durationS: 2384))
        // the same time over 3625 m (145 lengths of 25 m) is 1:06: flagged.
        XCTAssertTrue(SwimMath.looksOff(distanceM: 3625, durationS: 2384))
        XCTAssertFalse(SwimMath.looksOff(distanceM: 1500, durationS: 2384))
        XCTAssertFalse(SwimMath.looksOff(distanceM: nil, durationS: 2384))
        XCTAssertFalse(SwimMath.looksOff(distanceM: 1000, durationS: 700), "exactly 1:10 is not off")
    }

    func testClock() {
        XCTAssertEqual(SwimMath.clock(102), "1:42")
        XCTAssertEqual(SwimMath.clock(60), "1:00")
        XCTAssertEqual(SwimMath.clock(71.6), "1:12")
    }

    func testFix_roundTripsThroughJSON() throws {
        let fix = SwimMath.Fix(poolM: 50, lengths: 30, distanceM: nil)
        let back = try JSONDecoder().decode(SwimMath.Fix.self, from: JSONEncoder().encode(fix))
        XCTAssertEqual(back, fix)
    }
}
