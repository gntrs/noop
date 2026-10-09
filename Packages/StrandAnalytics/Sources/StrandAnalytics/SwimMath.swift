import Foundation

/// Pool swim numbers worked out from a distance the swimmer trusts. A wrist counts lengths by spotting
/// turns, so a push-off, a mid-pool turn or a rest at the wall can add lengths that were never swum, and
/// a pool size left on the last pool's setting scales every length wrong. Distance, pace and strokes per
/// length all follow from that count, so a corrected count or distance fixes all three.
public enum SwimMath {
    /// The pools offered when fixing a swim.
    public static let poolSizes: [Double] = [25, 50]

    /// A swimmer's correction for one session. `distanceM` wins when both are set: it is what they typed
    /// last and it is what they know for certain.
    public struct Fix: Codable, Equatable, Sendable {
        public var poolM: Double
        public var lengths: Int?
        public var distanceM: Double?
        public init(poolM: Double, lengths: Int? = nil, distanceM: Double? = nil) {
            self.poolM = poolM; self.lengths = lengths; self.distanceM = distanceM
        }
    }

    /// The corrected distance, or nil when the fix carries nothing usable.
    public static func distance(_ fix: Fix) -> Double? {
        if let d = fix.distanceM, d.isFinite, d > 0 { return d }
        if let l = fix.lengths, l > 0, fix.poolM.isFinite, fix.poolM > 0 { return Double(l) * fix.poolM }
        return nil
    }

    /// Whole lengths in `distanceM` of a `poolM` pool, rounded to the nearest length.
    public static func lengths(distanceM: Double?, poolM: Double) -> Int? {
        guard let d = distanceM, d.isFinite, d > 0, poolM.isFinite, poolM > 0 else { return nil }
        return Int((d / poolM).rounded())
    }

    /// Seconds per 100 m over the whole session, rests included.
    public static func secPer100(distanceM: Double?, durationS: Double?) -> Double? {
        guard let d = distanceM, d.isFinite, d > 0, let t = durationS, t.isFinite, t > 0 else { return nil }
        return t / d * 100
    }

    /// Strokes per minute over the whole session, rests included.
    public static func strokesPerMinute(strokes: Double?, durationS: Double?) -> Double? {
        guard let s = strokes, s.isFinite, s > 0, let t = durationS, t.isFinite, t > 0 else { return nil }
        return s / (t / 60)
    }

    public static func strokesPerLength(strokes: Double?, lengths: Int?) -> Double? {
        guard let s = strokes, s.isFinite, s > 0, let l = lengths, l > 0 else { return nil }
        return s / Double(l)
    }

    /// Faster than 1:10 per 100 m averaged over a whole session with its rests is beyond almost every
    /// swimmer, so the watch counted lengths that were not swum.
    public static let implausibleSecPer100: Double = 70

    public static func looksOff(distanceM: Double?, durationS: Double?) -> Bool {
        guard let p = secPer100(distanceM: distanceM, durationS: durationS) else { return false }
        return p < implausibleSecPer100
    }

    /// "1:42" for 102 seconds.
    public static func clock(_ seconds: Double) -> String {
        let s = Int(seconds.rounded())
        return "\(s / 60):" + String(format: "%02d", s % 60)
    }
}
