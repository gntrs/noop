import Foundation

/// Recognises Garmin Connect as an Apple Health source. Garmin publishes under its own bundle id
/// prefix; matching the prefix rather than one exact id keeps regional and beta builds in.
public enum GarminSource {
    public static let bundlePrefix = "com.garmin."

    public static func isGarmin(bundleId: String) -> Bool {
        bundleId.lowercased().hasPrefix(bundlePrefix)
    }
}
