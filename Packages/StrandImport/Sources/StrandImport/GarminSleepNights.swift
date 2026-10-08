import Foundation
import WhoopStore

/// Turns Garmin Connect's Apple Health sleep samples into NOOP sleep sessions: one session per night,
/// with the stage timeline in the on-device `[{"start","end","stage"}]` shape so the Sleep tab draws a
/// real hypnogram. Pure, so the grouping is covered by `swift test`.
public enum GarminSleepNights {
    public enum Kind: Equatable { case inBed, asleep, core, deep, rem, awake }

    public struct Sample: Equatable {
        public let start: Int
        public let end: Int
        public let kind: Kind
        public init(start: Int, end: Int, kind: Kind) { self.start = start; self.end = end; self.kind = kind }
    }

    /// The device id Garmin nights are stored under.
    public static let deviceId = SleepGapFill.garminDeviceId
    /// Samples further apart than this start a new night.
    public static let nightGapSeconds = 60 * 60
    /// A block with less sleep than this is noise, not a nap.
    public static let minAsleepSeconds = 20 * 60

    public static func build(_ samples: [Sample]) -> [CachedSleepSession] {
        let valid = samples.filter { $0.end > $0.start }.sorted { ($0.start, $0.end) < ($1.start, $1.end) }
        var groups: [[Sample]] = []
        var groupEnd = Int.min
        for s in valid {
            if groups.isEmpty || s.start > groupEnd + nightGapSeconds {
                groups.append([s]); groupEnd = s.end
            } else {
                groups[groups.count - 1].append(s); groupEnd = max(groupEnd, s.end)
            }
        }
        return groups.compactMap(session)
    }

    private static func session(_ group: [Sample]) -> CachedSleepSession? {
        let staged = group.filter { $0.kind != .inBed }
        guard let start = group.map(\.start).min(), let end = group.map(\.end).max() else { return nil }
        let asleep = asleepSeconds(staged)
        guard asleep >= minAsleepSeconds else { return nil }
        let segments: [[String: Any]] = staged.compactMap { s in
            guard let stage = label(s.kind) else { return nil }
            return ["start": s.start, "end": s.end, "stage": stage]
        }
        let json = segments.isEmpty ? nil : (try? JSONSerialization.data(withJSONObject: segments, options: [.sortedKeys]))
            .flatMap { String(data: $0, encoding: .utf8) }
        let efficiency = Double(asleep) / Double(end - start)
        return CachedSleepSession(startTs: start, endTs: end, efficiency: min(1, efficiency), restingHr: nil,
                                  avgHrv: nil, stagesJSON: json, deviceId: deviceId)
    }

    /// Seconds asleep, counting overlapping samples once.
    static func asleepSeconds(_ samples: [Sample]) -> Int {
        let spans = samples.filter { $0.kind != .awake && $0.kind != .inBed }.map { ($0.start, $0.end) }.sorted { $0 < $1 }
        var total = 0, curStart = Int.min, curEnd = Int.min
        for (a, b) in spans {
            if a > curEnd { total += max(0, curEnd - curStart); curStart = a; curEnd = b }
            else { curEnd = max(curEnd, b) }
        }
        total += max(0, curEnd - curStart)
        return total
    }

    private static func label(_ k: Kind) -> String? {
        switch k {
        case .core: return "light"
        case .deep: return "deep"
        case .rem: return "rem"
        case .awake: return "wake"
        case .asleep, .inBed: return nil
        }
    }
}
