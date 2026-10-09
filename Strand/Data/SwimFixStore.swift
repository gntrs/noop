import Foundation
import StrandAnalytics

/// The swimmer's own corrections to pool swims, keyed like `RouteStore` by "<startTs>|<sport>". Kept
/// apart from the workout row on purpose: a Health resync rewrites the row with the watch's distance,
/// and the correction has to outlive that.
enum SwimFixStore {
    static let defaultsKey = "noop.swimFixes"

    static func key(startTs: Int, sport: String) -> String { "\(startTs)|\(sport)" }

    static func loadMap(from defaults: UserDefaults = .standard) -> [String: SwimMath.Fix] {
        guard let data = defaults.data(forKey: defaultsKey),
              let map = try? JSONDecoder().decode([String: SwimMath.Fix].self, from: data) else { return [:] }
        return map
    }

    static func load(startTs: Int, sport: String, from defaults: UserDefaults = .standard) -> SwimMath.Fix? {
        loadMap(from: defaults)[key(startTs: startTs, sport: sport)]
    }

    /// Saves the fix, or clears it when `fix` is nil or carries no usable distance.
    static func save(_ fix: SwimMath.Fix?, startTs: Int, sport: String, to defaults: UserDefaults = .standard) {
        var map = loadMap(from: defaults)
        let k = key(startTs: startTs, sport: sport)
        if let fix, SwimMath.distance(fix) != nil { map[k] = fix } else { map.removeValue(forKey: k) }
        if let data = try? JSONEncoder().encode(map) { defaults.set(data, forKey: defaultsKey) }
    }
}
