import XCTest
import WhoopProtocol
@testable import StrandAnalytics

final class WorkoutHRPickTests: XCTestCase {
    private func every(_ step: Int, from a: Int, to b: Int) -> [HRSample] {
        stride(from: a, through: b, by: step).map { HRSample(ts: $0, bpm: 120) }
    }

    func testFullStrapCoverageKeepsTheStrap() {
        XCTAssertEqual(WorkoutHRPick.choose(strap: every(1, from: 0, to: 3600), other: every(120, from: 0, to: 3600),
                                            start: 0, end: 3600), .strap)
    }

    func testStrapOffForTheSwimUsesGarmin() {
        XCTAssertEqual(WorkoutHRPick.choose(strap: [], other: every(120, from: 0, to: 2400), start: 0, end: 2400), .other)
    }

    func testGapOverTwoMinutesSwitchesToGarmin() {
        let strap = every(1, from: 0, to: 1000) + every(1, from: 1121, to: 3600)
        XCTAssertEqual(WorkoutHRPick.longestGap(strap, start: 0, end: 3600), 121)
        XCTAssertEqual(WorkoutHRPick.choose(strap: strap, other: every(60, from: 0, to: 3600), start: 0, end: 3600), .other)
    }

    func testGapOfExactlyTwoMinutesKeepsTheStrap() {
        let strap = every(1, from: 0, to: 1000) + every(1, from: 1120, to: 3600)
        XCTAssertEqual(WorkoutHRPick.choose(strap: strap, other: every(60, from: 0, to: 3600), start: 0, end: 3600), .strap)
    }

    func testStrapStartingLateCountsAsAGap() {
        XCTAssertEqual(WorkoutHRPick.longestGap(every(1, from: 600, to: 3600), start: 0, end: 3600), 600)
    }

    func testGappyStrapWithNoOtherStillAnswers() {
        let strap = every(1, from: 0, to: 100) + every(1, from: 2000, to: 3600)
        XCTAssertEqual(WorkoutHRPick.choose(strap: strap, other: [], start: 0, end: 3600), .strap)
    }

    func testNothingRecorded() {
        XCTAssertEqual(WorkoutHRPick.choose(strap: [], other: [], start: 0, end: 3600), .none)
    }

    func testSamplesOutsideTheWindowAreIgnoredAndUnsortedIsFine() {
        let strap = (every(1, from: 0, to: 3600) + [HRSample(ts: -500, bpm: 90), HRSample(ts: 9000, bpm: 90)]).reversed()
        XCTAssertEqual(WorkoutHRPick.longestGap(Array(strap), start: 0, end: 3600), 1)
    }

    func testEmptyOrInvertedWindow() {
        XCTAssertEqual(WorkoutHRPick.longestGap([], start: 100, end: 100), 0)
        XCTAssertEqual(WorkoutHRPick.longestGap([], start: 0, end: 600), 600)
    }
}
