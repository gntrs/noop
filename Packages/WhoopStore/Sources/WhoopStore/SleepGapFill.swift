import Foundation

/// Adds a second device's nights only where the primary device has none. The WHOOP stays the source of
/// truth for sleep; Garmin fills a night the strap missed (off to charge, left on the desk).
public enum SleepGapFill {
    /// The device id nights from Garmin Connect (via Apple Health) are stored under.
    public static let garminDeviceId = "garmin"

    /// - Parameters:
    ///   - primary: the sessions already chosen for display.
    ///   - filler: candidate nights from the second device.
    ///   - endDay: the canonical local end-day key, the same keyer the merge uses.
    /// - Returns: `primary` plus every filler night whose end-day has no primary night and which
    ///   overlaps no primary session, sorted by start.
    public static func fill(primary: [CachedSleepSession], filler: [CachedSleepSession],
                            endDay: (CachedSleepSession) -> String) -> [CachedSleepSession] {
        let coveredDays = Set(primary.map(endDay))
        let added = filler.filter { f in
            !coveredDays.contains(endDay(f)) &&
            !primary.contains { p in f.startTs < p.endTs && p.startTs < f.endTs }
        }
        return (primary + added).sorted { $0.startTs < $1.startTs }
    }
}
