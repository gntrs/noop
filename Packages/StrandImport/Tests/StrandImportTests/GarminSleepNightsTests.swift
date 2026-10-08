import XCTest
import WhoopStore
@testable import StrandImport

final class GarminSleepNightsTests: XCTestCase {
    typealias S = GarminSleepNights.Sample
    let t0 = 1_759_870_800   // 2025-10-07 21:00 UTC

    private func night(at base: Int) -> [S] {
        [S(start: base, end: base + 8 * 3600, kind: .inBed),
         S(start: base + 600, end: base + 3 * 3600, kind: .core),
         S(start: base + 3 * 3600, end: base + 4 * 3600, kind: .deep),
         S(start: base + 4 * 3600, end: base + 4 * 3600 + 900, kind: .awake),
         S(start: base + 4 * 3600 + 900, end: base + 7 * 3600, kind: .rem)]
    }

    func testEmptyInputGivesNoNights() {
        XCTAssertEqual(GarminSleepNights.build([]).count, 0)
    }

    func testOneNightBecomesOneSession() {
        let out = GarminSleepNights.build(night(at: t0))
        XCTAssertEqual(out.count, 1)
        XCTAssertEqual(out[0].startTs, t0)
        XCTAssertEqual(out[0].endTs, t0 + 8 * 3600)
        XCTAssertEqual(out[0].deviceId, "garmin")
    }

    func testUnsortedInputGroupsTheSame() {
        XCTAssertEqual(GarminSleepNights.build(night(at: t0).reversed()), GarminSleepNights.build(night(at: t0)))
    }

    func testTwoNightsSplitOnTheGap() {
        let out = GarminSleepNights.build(night(at: t0) + night(at: t0 + 86_400))
        XCTAssertEqual(out.count, 2)
    }

    func testGapAtTheLimitStaysOneNight() {
        let a = S(start: t0, end: t0 + 2 * 3600, kind: .core)
        let b = S(start: t0 + 2 * 3600 + 3600, end: t0 + 5 * 3600, kind: .core)
        XCTAssertEqual(GarminSleepNights.build([a, b]).count, 1)
        let c = S(start: t0 + 2 * 3600 + 3601, end: t0 + 5 * 3600, kind: .core)
        XCTAssertEqual(GarminSleepNights.build([a, c]).count, 2)
    }

    func testStagesRoundTripThroughTheAppParser() {
        let s = GarminSleepNights.build(night(at: t0))[0]
        let intervals = HealthWriteback.stageIntervals(stagesJSON: s.stagesJSON, sessionStart: s.startTs, sessionEnd: s.endTs)
        XCTAssertEqual(intervals.map(\.kind), [.light, .deep, .awake, .rem])
        XCTAssertEqual(intervals.first?.start, t0 + 600)
    }

    func testInBedOnlyIsDropped() {
        XCTAssertEqual(GarminSleepNights.build([S(start: t0, end: t0 + 8 * 3600, kind: .inBed)]).count, 0)
    }

    func testShortBlockIsNoiseButANapCounts() {
        XCTAssertEqual(GarminSleepNights.build([S(start: t0, end: t0 + 19 * 60, kind: .core)]).count, 0)
        XCTAssertEqual(GarminSleepNights.build([S(start: t0, end: t0 + 20 * 60, kind: .core)]).count, 1)
    }

    func testZeroAndNegativeLengthSamplesAreIgnored() {
        let bad = [S(start: t0, end: t0, kind: .deep), S(start: t0 + 100, end: t0, kind: .rem)]
        XCTAssertEqual(GarminSleepNights.build(bad).count, 0)
        XCTAssertEqual(GarminSleepNights.build(bad + night(at: t0)).count, 1)
    }

    func testOverlappingSamplesCountOnce() {
        let samples = [S(start: t0, end: t0 + 3600, kind: .core), S(start: t0 + 1800, end: t0 + 3600, kind: .asleep)]
        XCTAssertEqual(GarminSleepNights.asleepSeconds(samples), 3600)
    }

    func testEfficiencyIsAsleepOverSpan() {
        let s = GarminSleepNights.build(night(at: t0))[0]
        // asleep: 600..3h (2h50m) + 3h..4h + 4h15..7h = 10200 + 3600 + 9900 = 23700 over 28800
        XCTAssertEqual(s.efficiency ?? 0, 23_700.0 / 28_800.0, accuracy: 1e-9)
    }

    func testUnspecifiedAsleepCountsButDrawsNoStage() {
        let s = GarminSleepNights.build([S(start: t0, end: t0 + 6 * 3600, kind: .asleep)])
        XCTAssertEqual(s.count, 1)
        XCTAssertNil(s[0].stagesJSON)
    }
}
