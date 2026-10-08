import Foundation
import WhoopProtocol

/// Which heart-rate stream answers a workout both devices may have recorded. The WHOOP strap wins
/// unless it lost the signal for longer than `maxGapSeconds` somewhere in the session (off the wrist, in
/// the water, a dropped link); then the other device's stream answers, if it has any beats. Both are
/// optical, so coverage is the tiebreak that can be measured.
public enum WorkoutHRPick {
    public enum Choice: Equatable { case strap, other, none }

    public static let maxGapSeconds = 120

    public static func choose(strap: [HRSample], other: [HRSample], start: Int, end: Int) -> Choice {
        if !strap.isEmpty && longestGap(strap, start: start, end: end) <= maxGapSeconds { return .strap }
        if !other.isEmpty { return .other }
        return strap.isEmpty ? .none : .strap
    }

    /// The longest stretch inside [start, end] with no strap sample, edges included.
    public static func longestGap(_ samples: [HRSample], start: Int, end: Int) -> Int {
        guard end > start else { return 0 }
        let ts = samples.map(\.ts).filter { $0 >= start && $0 <= end }.sorted()
        guard let first = ts.first, let last = ts.last else { return end - start }
        var gap = max(first - start, end - last)
        for (a, b) in zip(ts, ts.dropFirst()) { gap = max(gap, b - a) }
        return gap
    }
}
